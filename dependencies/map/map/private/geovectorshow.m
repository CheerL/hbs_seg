function varargout = geovectorshow(S, varargin)
%GEOVECTORSHOW Display geographic vector data with projection
%
%   GEOVECTORSHOW(S) displays the vector geographic features stored in the
%   object S according to the geometry of the object. S may be a geopoint
%   or geoshape vector, or a geospatial table containing geographic shapes.
%   
%   If S is a geopoint or geoshape vector or a geospatial table with
%   geographic shapes, then the coordinate values are projected to map
%   coordinates using the projection stored in the axes if available;
%   otherwise the values are projected using the Plate Carree default
%   projection.
%   
%   If S is a mappoint or mapshape vector a warning is issued and the
%   coordinate values are plotted as map coordinates. If S is a geospatial
%   table with map shapes an error is issued.
%
%   GEOVECTORSHOW(..., Name, Value) specifies name-value pairs that modify
%   the type of display or set MATLAB graphics properties. Parameter names
%   can be abbreviated and are case-insensitive.
%
%   Parameters include:
%
%   'DisplayType'  The DisplayType parameter specifies the type of graphic
%                  display for the data.  The value must be consistent with
%                  the Geometry field in the input.
%
%   Graphics       In addition to specifying a parent axes, the graphics
%   Properties     properties may be set for line, point, and polygon.
%                  Refer to the MATLAB Graphics documentation on line,
%                  and patch for a complete description of these properties 
%                  and their values.
%
%   'SymbolSpec'   The SymbolSpec parameter specifies the symbolization
%                  rules used for vector data through a structure returned
%                  by MAKESYMBOLSPEC. 
%
%                  In  the case where both SymbolSpec and one or more
%                  graphics properties are specified, the graphics
%                  properties last specified will override any settings in 
%                  the symbol spec structure. 
%
%   H = GEOVECTORSHOW(...) returns the handle to an hggroup object with one
%   child per feature in the geostruct, excluding any features that are
%   completely trimmed away.  In the case of polygon Geometry, each
%   child is a modified patch object; otherwise it is a line object.
%
%   Example 1 
%   ---------
%   % Display world land areas, using the Plate Carree projection.
%   figure
%   land = geoshape(shaperead('landareas.shp','UseGeocoords',true));
%   geovectorshow(land, 'FaceColor', [0.5 1.0 0.5]);
%
%   Example 2 
%   ---------
%   % Override the SymbolSpec default rule.
%
%   % Create a worldmap of North America
%   figure
%   worldmap('na');
%
%   % Read the USA high resolution data
%   states = geoshape(shaperead('usastatehi', 'UseGeoCoords', true));
%
%   % Create a SymbolSpec to display Alaska and Hawaii as red polygons.
%   symbols = makesymbolspec('Polygon', ...
%                            {'Name', 'Alaska', 'FaceColor', 'red'}, ...
%                            {'Name', 'Hawaii', 'FaceColor', 'red'});
%
%   % Display all the other states in blue.
%   geovectorshow(states, 'SymbolSpec', symbols, ...
%                         'DefaultFaceColor', 'blue', ...
%                         'DefaultEdgeColor', 'black');
%
%   Example 3
%   ---------
%   % Worldmap with land areas, major lakes and rivers, and cities and
%   % populated places
%   land = geoshape(shaperead('landareas', 'UseGeoCoords', true));
%   lakes = geoshape(shaperead('worldlakes', 'UseGeoCoords', true));
%   rivers = geoshape(shaperead('worldrivers', 'UseGeoCoords', true));
%   cities = geopoint(shaperead('worldcities', 'UseGeoCoords', true));
%   ax = worldmap('World');
%   setm(ax, 'Origin', [0 180 0])
%   geovectorshow(land,  'FaceColor', [0.5 0.7 0.5],'Parent',ax)
%   geovectorshow(lakes, 'FaceColor', 'blue')
%   geovectorshow(rivers, 'Color', 'blue')
%   geovectorshow(cities, 'Marker', '.', 'Color', 'red')
%
%   See also GEOSHOW, GEOSTRUCTSHOW, GEOVECSHOW

% Copyright 2012-2021 The MathWorks, Inc.

fcnName = 'geoshow';

if isgeotable(S)
    % Convert geotable to geostruct with Latitude/Longitude fields.
    % Do not switch to mapshow for planar coordinates.
    S = geotable2geostruct(S);
elseif istable(S)
    error(message('map:validate:expectedGeographicTable'))
else
    % Validate S.
    classes = {'struct', 'geopoint', 'mappoint', ...
        'geoshape', 'mapshape', 'table'};
    validateattributes(S, classes, {}, fcnName, 'S')
end

% Obtain the Geometry value.
geometry = lower(convertStringsToChars(S(1).Geometry));

% Parse the properties from varargin.
[symspec, defaultProps, otherProps] = parseShowParameters( ...
    geometry, fcnName, varargin);

% Determine if using geovectorshow or mapvectorshow.
if any(strcmp(class(S), {'geopoint','geoshape','struct'}))   
    % Find or construct the projection mstruct.
    mstruct = getProjection(varargin{:});
    
    % Switch display and projection operations based on Geometry
    objectType = ['geo' geometry ];
    
    % Trim and forward project the dynamic vector S, using function
    % symbolizeMapVectors. For its third argument use an anonymous
    % function, defined via geovec or globevec, with the prerequisite
    % signature:
    %
    %    plotfcn(s, prop1, val1, pro2, val2, ...)
    %
    % where s is a single feature, prop1, prop2, ... are graphics
    % property names, and val1, val2, ... are the corresponding property
    % values.
    if strcmpi(mstruct.mapprojection,'globe')
        % Treat globe axes separately because of the third dimension.
        height = [];
        fcn = @(s, varargin) globevec(mstruct, s.Latitude, s.Longitude, ...
            height, objectType, varargin{:});
    else
        % Project and display in 2-D map coordinates.
        mapfcn = mapvecfcn(geometry, fcnName);
        fcn = @(s, varargin) geovec(mstruct, s.Latitude, s.Longitude,  ...
            objectType, mapfcn, varargin{:});
    end
    h = symbolizeMapVectors(S, symspec, fcn, defaultProps, otherProps);
else    
    % Display the X and Y coordinates using mapvectorshow
    fcnName = upper(fcnName);
    warning(message('map:geoshow:usingMAPSHOW', fcnName, fcnName, 'MAPSHOW'))
    h = mapvectorshow(S, varargin{:});
end

%  Restack to ensure standard child order in the map axes.
map.graphics.internal.restackMapAxes(h)

% Allow usage without ; to suppress output.
if nargout > 0
    varargout{1} = h;
end
end

%--------------------------------------------------------------------------

function S = geotable2geostruct(T)
% Convert a table, T, with a point shape, line shape, or polygon
% shape-valued Shape field, to a geostruct with Latitude and Longitude
% fields.

    shape = T.Shape;  
    if ~isequal(shape.CoordinateSystemType, "geographic")
        error(message('map:validate:expectedGeographicTable'))
    end
    
    if shape.Geometry == "heterogeneous"
        error(message('map:validate:expectedHomogeneousTable'))
    end

    % Convert geometry and vertex coordinates to a geostruct.        
    ST = shapeToStructure(T.Shape);
    T.Latitude = ST.Latitude;
    T.Longitude = ST.Longitude;
    T.Geometry = repmat(convertGeometry(ST),size(shape));
    T.Shape = [];
    wstate = warning('off', 'MATLAB:table:ModifiedVarnames');
    warnObj = onCleanup(@()warning(wstate));
    S = table2struct(T);
    
    % Convert all strings to char vectors.
    S = convertContainedStringsToChars(S);
end

%--------------------------------------------------------------------------

function geometry = convertGeometry(ST)
    switch lower(ST.Geometry)
        case "point"
            geometry = 'Point';
        case "multipoint"
            geometry = 'MultiPoint';
        case "line"
            geometry = 'Line';
        case "polygon"
            geometry = 'Polygon';
    end
end
