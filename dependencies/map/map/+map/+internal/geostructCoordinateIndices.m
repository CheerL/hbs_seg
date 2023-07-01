function indx = geostructCoordinateIndices(mstruct,objects,method)
%geostructCoordinateIndices   Coordinate indices from line or patch display structure

% Copyright 2022 The MathWorks, Inc.

    % This code is adapted from extractm, which has been removed.

    objects = convertStringsToChars(objects);

    %  Determine the objects to extract

    if isempty(objects)
        indx = 1:length(mstruct);
    else
        indx = [];
        if iscell(objects)
            for i=1:length(objects)
                if nargin ==3
                    thisindx = findstrmat(str2mat(mstruct(:).tag),objects{i},method);
                else
                    thisindx = strmatch(lower(objects{i}), lower(strvcat(mstruct(:).tag)));
                end
                indx = [indx(:); thisindx(:)];
            end % for
        else
            for i=1:size(objects,1)
                if nargin ==3
                    thisindx = findstrmat(str2mat(mstruct(:).tag),...
                        deblank(objects(i,:)),method);
                else
                    thisindx = strmatch( lower(deblank(objects(i,:))),...
                        lower(strvcat(mstruct(:).tag)));
                end
                indx = [indx(:); thisindx(:)];
            end % for i
        end % if iscell(objects)
        if isempty(indx)
            error(message("map:geostruct:objectNotFound"))
        end
    end
    
    indx = unique(indx);
end

function indx = findstrmat(strmat,searchstr,method)

    % find matches in vector
    
    method = validatestring(method,["findstr","strmatch","exact"]);
    switch method
        case "findstr"
            strmat(:,end+1) = 13; % add a line-ending character to prevent matches across rows
            % make string matrix a vector
            sz = size(strmat);
            strmat = strmat';
            strvec = strmat(:)';
            vecindx = findstr(searchstr,strvec);
            % vector indices to row indices
            indx = unique(ceil(vecindx/sz(2)));
        case "strmatch"
            indx = strmatch(searchstr,strmat);
        case "exact"
            indx = strmatch(searchstr,strmat,"exact");
    end
end

