function varargs = designateAxesArgAsParentArg(fcnName, varargin)
%designateAxesArgAsParentArg Designate axes argument as Parent argument
%
%   VARARGS = designateAxesArgAsParentArg(fcnName, VARARGIN) returns the
%   VARARGIN cell array with the first argument moved to the end of
%   VARARGIN preceded by 'Parent' if the first argument is an axes handle.
%   fcnName is a character vector containing the function name to be used
%   for creating error messages.
%
%   See also GEOSHOW, MAPSHOW.

% Copyright 2006-2022 The MathWorks, Inc.

varargs = varargin;

handleMayBePresent = ...
    ~isempty(varargin) && ...
    isscalar(varargin{1}) && ...
    ishghandle(varargin{1}) && ...
    ~ishghandle(varargin{1},'root');

numDataArgs = internal.map.getNumberOfDataArgs(varargin{:});

% containsVectorFeatures is true, for syntax (ax,S), if second argument is
% a struct, dynamic vector, or geotable. Check tabular and not geotable
% here in order to issue more appropriate error message later.
containsVectorFeatures = numDataArgs == 2 ...
    && (isstruct(varargin{2}) || isa(varargin{2}, 'map.internal.DynamicVector') ...
    || isa(varargin{2}, 'tabular')); 
firstArgIsHgHandle = handleMayBePresent && ...
    (numDataArgs == 1 || ...      % GEOSHOW(H,'FILENAME')
    containsVectorFeatures || ... % GEOSHOW(H,S)
    numDataArgs > 2);             % GEOSHOW(H,LAT,LON)

if firstArgIsHgHandle
    ax = varargin{1};
    if ishghandle(ax, 'axes')
        if nargin > 2
            % Designate first argument (axes handle) as Parent.
            varargs = [varargin(2:end), {'Parent'}, varargin(1)];
        else
            % Remove the axes from varargin.
            % Let the function show with no data.
            varargs = {};
        end
    else
        validateattributes(ax, {'matlab.graphics.axis.Axes'}, ...
            {'nonempty'}, fcnName, 'AX', 1)
    end
elseif isa(varargin{1}, 'matlab.graphics.axis.Axes')
    % handle is deleted or non-scalar.
    % axescheck returns axes.
    axescheck(varargin{1});
else
    % Parent is not the first argument. Check that the parent is an axes.
    % Ensure that only name-value pairs are checked by findNameValuePair.
    nvargs = varargs(numDataArgs+1:end);
    parent = map.internal.findNameValuePair('Parent', [], nvargs{:});
    if isempty(parent)
        parent = gca;
    end
    if ~isa(parent, 'matlab.graphics.axis.Axes')
        % Parent is not an axes. Provide specific error message for
        % other axes types like geoaxes and mapaxes.
        if isa(parent,'matlab.graphics.axis.AbstractAxes')
            error(message('map:validate:expectedAxesParent',...
                extractAfter(class(parent),'axis.'),fcnName))
        else
            validateattributes(parent, {'matlab.graphics.axis.Axes'}, ...
                {'nonempty'}, fcnName, 'Parent')
        end
    end
end
