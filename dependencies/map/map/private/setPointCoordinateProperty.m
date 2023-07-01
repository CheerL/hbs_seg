function obj = setPointCoordinateProperty(obj, c, ...
    propname, validatefcn, vertexCoordinateProperty)
% Set coordinate property (X, Y, Latitude, or Longitude) of a
% geopointshape or mappointshape.

% Copyright 2022 The MathWorks, Inc.

    data = obj.InternalData;
    if isscalar(data.NumVertices)
        % Input is scalar object (with exactly one element).
        switch data.NumVertices
            case 0
                % The element contains no coordinate data.
                if numel(c) > 1
                    throwAsCaller(MException(message("map:shape:MismatchedCoordinateSize", propname)))
                elseif isscalar(c) && ~isnan(c)
                    throwAsCaller(MException(message("map:shape:MismatchedCoordinateNaNs", propname, class(obj))))
                end
            case 1
                % The element contains a single set of coordinates.
                if ~isscalar(c)
                    throwAsCaller(MException(message("map:shape:MismatchedCoordinateSize", propname)))
                elseif isnan(c) && ~isnan(data.(vertexCoordinateProperty))
                    throwAsCaller(MException(message("map:shape:MismatchedCoordinateNaNs", propname, class(obj))))
                end
            otherwise
                % The element contains a multipoint.
                if ~isequal(size(c), size(obj.(propname)))
                    throwAsCaller(MException(message("map:shape:MismatchedCoordinateSize", propname)))
                elseif ~isequal(isnan(c(:)), isnan(obj.(propname)(:)))
                    throwAsCaller(MException(message("map:shape:MismatchedCoordinateNaNs", propname, class(obj))))
                end
        end
    elseif isempty(data.NumVertices)
        % Input is an empty array.
        if ~isempty(c)
            throwAsCaller(MException(message("map:shape:MismatchedCoordinateSize", propname)))
        end
    else
        % Input is an array with 2 or more elements; we allow
        % assigment to such arrays as long as there are no
        % multipoint elements and sizes and NaN-positions match.
        if any(ismultipoint(data),"all")
            throwAsCaller(MException(message("map:shape:NonscalarMultipointCoordinateAssignment", class(obj))))
        elseif ~isequal(size(c), size(obj.(propname)))
            throwAsCaller(MException(message("map:shape:MismatchedCoordinateSize", propname)))
        elseif ~isequal(isnan(c), isnan(obj.(propname)))
            throwAsCaller(MException(message("map:shape:MismatchedCoordinateNaNs", propname, class(obj))))
        end
    end
    validatefcn(c)

    % Assign new value. Remove NaN elements from c, but only if
    % the corresponding elements of obj have no coordinate
    % vertices. This allows for preservation of NaN values that
    % were placed into data in a way that bypassed the point shape
    % constructor and set methods or that were saved from R2021b.
    c = c(:);
    c(isnan(c) & (data.NumVertices(:) == 0)) = [];
    data.(vertexCoordinateProperty) = c';
    obj.InternalData = data;
end
