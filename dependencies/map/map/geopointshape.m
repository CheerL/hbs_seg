classdef (Sealed, InferiorClasses = {?matlab.graphics.axis.GeographicAxes,?map.graphics.axis.MapAxes}) ...
        geopointshape < map.shape.GeographicShape & matlab.mixin.CustomDisplay
%GEOPOINTSHAPE Point shape in geographic coordinates
%
%   A GEOPOINTSHAPE object represents a geographic point or multipoint. A
%   multipoint is an individual point shape that contains a set of point
%   locations.
%
%   SHAPE = GEOPOINTSHAPE(LAT,LON) returns a GEOPOINTSHAPE object or an
%   array of GEOPOINTSHAPE objects with the specified latitude and
%   longitude coordinates. To create a GEOPOINTSHAPE scalar representing an
%   individual point, specify LAT and LON as numeric scalars. For an array
%   of individual points, specify LAT and LON as numeric arrays. To create
%   a GEOPOINTSHAPE scalar representing a multipoint, specify LAT and LON
%   as numeric vectors enclosed within cell scalars. For a multipoint
%   array, specify LAT and LON as cell arrays of numeric vectors.
%
%   The size of SHAPE matches the size of LAT and LON. The LAT and LON
%   inputs must match each other in size. In the case of cell inputs, the
%   size of the numeric vector in a given element of LAT must equal the
%   size of the numeric vector in the corresponding element of LON. Create
%   placeholders for points with missing data by including NaN values
%   in LAT and LON. In the case of either numeric or cell input, the
%   inclusion of NaN values must be consistent between LAT and LON.
%
%   Examples
%   --------
%   % GEOPOINTSHAPE scalar with an individual point:
%   shape = geopointshape(39,-113)
%
%   % 3x1 GEOPOINTSHAPE vector with one point per element:
%   shape = geopointshape([38 -30 29]',[-66 -31 42]')
%
%   % GEOPOINTSHAPE scalar with a multipoint:
%   shape = geopointshape({[38 -30 29]},{[-66 -31 42]})
%
%   % 1x2 GEOPOINTSHAPE vector with an individual point and a multipoint:
%   shape = geopointshape({39, [38 -30 29]},{-113,[-66 -31 42]})
% 
%   See also geolineshape, geopolyshape, ismultipoint, mappointshape

% Copyright 2020-2022 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        NumPoints  % Number of points in each point/multipoint shape
    end
    
    properties (Dependent)
        Latitude
        Longitude
    end
    
    properties (Constant, Access = private)
        DegreeSymbol = string(sprintf('\x00B0'));
    end
    
    properties (Hidden)
        PositiveLatitudeDirection  (1,1) char = 'N';
        NegativeLatitudeDirection  (1,1) char = 'S';
        PositiveLongitudeDirection (1,1) char = 'E';
        NegativeLongitudeDirection (1,1) char = 'W';
    end
    
    
    methods (Static)
        function obj = empty(sz)
            % Construct an empty geopointshape array. Examples:
            %    s = geopointshape.empty         % 0-by-0 geopointshape
            %    s = geopointshape.empty(0,1)    % 0-by-1 geopointshape
            %    s = geopointshape.empty([3 0])  % 3-by-0 geopointshape
            
            arguments (Repeating)
                sz (1,:) double {mustBeInteger, mustBeNonnegative}
            end
            obj = geopointshape;
            try
                obj.InternalData.NumVertices = uint32.empty(sz{:});
            catch e
                throw(e)
            end
        end
    end


    methods (Static, Hidden)
        function obj = loadobj(S)
            obj = geopointshape;
            obj.InternalData = restoreFromStructure(obj.InternalData, S);
            obj.GeographicCRS = S.CoordinateReferenceSystem;
        end
    end
    
    
    methods
        function obj = geopointshape(lat, lon)
            % Construct a geopointshape object from numeric latitude and
            % longitude arrays or from cell arrays of latitude and
            % longitude vectors. In both cases, the geopointshape object
            % has the same size as the input arrays.

            switch nargin
                case 0
                    % Construct default object.
                    data = map.shape.internal.PointData;

                case 2
                    validateConstructorInput(obj, lat, lon, "LAT", "LON")
                    validateLatitude(obj, lat)
                    validateLongitude(obj, lon)
                    data = map.shape.internal.PointData;
                    if isnumeric(lat)
                        data = fromNumericInput(data, lat, lon);
                    else
                        data = fromCellInput(data, lat, lon);
                    end
                    obj.InternalData = data;

                otherwise
                    narginchk(2,2)
            end
            obj.InternalData = data;
        end

        
        function num = get.NumPoints(obj)
            num = double(obj.InternalData.NumVertices);
        end


        function lat = get.Latitude(obj)
            lat = getPointCoordinateProperty(obj, "VertexCoordinate1");
        end


        function obj = set.Latitude(obj, lat)
            arguments
                obj geopointshape
                lat double
            end
            validatefcn = @(c) validateLatitude(obj,c);
            obj = setPointCoordinateProperty(obj, lat, ...
                "Latitude", validatefcn, "VertexCoordinate1");
        end


        function lon = get.Longitude(obj)
            lon = getPointCoordinateProperty(obj, "VertexCoordinate2");
        end


        function obj = set.Longitude(obj, lon)
            arguments
                obj geopointshape
                lon double
            end
            validatefcn = @(c) validateLongitude(obj,c);
            obj = setPointCoordinateProperty(obj, lon, ...
                "Longitude", validatefcn, "VertexCoordinate2");
        end


        function clipped = geoclip(obj, latlim, lonlim)
            arguments
                obj geopointshape
                latlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits, ...
                    mustBeGreaterThanOrEqual(latlim, -90), mustBeLessThanOrEqual(latlim,90)}
                lonlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite}
            end

            data = obj.InternalData;
            % NOTE: Avoid adding any comments above this line to keep them
            % from appearing when "help geopointshape/geoclip" is run.

            % Input limits can be any numeric type; use double
            % to ensure that full precision is maintained.
            % Refine wrapping of longitude limits as needed.
            latlim = double(latlim);
            lonlim = double(lonlim);
            lonlim = map.internal.conditionLongitudeLimits(lonlim);

            lon = data.VertexCoordinate2;
            data.VertexCoordinate2 = lonlim(1) + wrapTo360(lon - lonlim(1));
            clipped = obj;
            clipped.InternalData = clip(data, latlim, lonlim);
        end


        function h = geoplot(varargin)
        %GEOPLOT Plot point shapes with geographic coordinates
        %
        %   GEOPLOT(SHAPE) plots the point shapes specified by the
        %   geopointshape scalar or array SHAPE in a geographic axes.
        %
        %   GEOPLOT(SHAPE,LineSpec) uses a LineSpec to specify the edge
        %   color and marker symbol of the point.
        %
        %   GEOPLOT(___,Name,Value) specifies point properties using one
        %   or more Name-Value arguments.
        %
        %   GEOPLOT(gx,___) creates the plot in the geographic axes
        %   specified by gx instead of the current axes.
        %
        %   H = GEOPLOT(___) additionally returns a Point object. Use H to
        %   modify the properties of the object after it is created.
        %
        %   Example
        %   -------
        %   GT = readgeotable("worldcities.shp");
        %   latlim = [-54 10];
        %   lonlim = [90 180];
        %   cities = geoclip(GT.Shape,latlim,lonlim);
        %   geoplot(cities)
        %
        %   See also GEOPLOT, MAPPOINTSHAPE/GEOPLOT, GEOSCATTER

            narginchk(1,inf)

            obj = map.graphics.internal.shapeplot(varargin{:});
            if nargout > 0
                h = obj;
            end
        end
    end
    
    
    methods (Access = protected)
        function propgroup = getPropertyGroups(obj)
            % Customize display to omit the coordinate properties (Latitude
            % and Longitude) when obj is nonscalar and multipoint.
            if isscalar(obj)
                propgroup = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            elseif any(ismultipoint(obj),"all")
                propgroup = matlab.mixin.util.PropertyGroup(struct( ...
                    "NumPoints",            obj.NumPoints, ...
                    "Geometry",             obj.Geometry, ...
                    "CoordinateSystemType", obj.CoordinateSystemType, ...
                    "GeographicCRS",        obj.GeographicCRS));
            else
                propgroup = matlab.mixin.util.PropertyGroup(struct( ...
                    "NumPoints",            obj.NumPoints, ...
                    "Latitude",             obj.Latitude, ...
                    "Longitude",            obj.Longitude, ...
                    "Geometry",             obj.Geometry, ...
                    "CoordinateSystemType", obj.CoordinateSystemType, ...
                    "GeographicCRS",        obj.GeographicCRS));
            end
        end
    end
    
    
    methods (Hidden)
        function S = shapeToStructure(shape)
            % Convert a shape array to a scalar structure
            %
            %     This hidden method is for internal use only and may be
            %     changed or removed in a future release.
            %
            %   S = shapeToStructure(shape), when shape is a geopointshape
            %   array, returns a struct scalar, S, with the vertex
            %   coordinates of the shape array in its Latitude and
            %   Longitude fields. The output, S, also has Geometry,
            %   CoordinateSystemType, and GeographicCRS fields.
            %
            %   When NumPoints == 1 for all elements of shape, the
            %   coordinate arrays are type double and match the input shape
            %   in size, with a one-to-one correspondence between elements
            %   of Latitude and Longitude and the corresponding element of
            %   shape. The value of the Geometry field is "point".
            %
            %   Otherwise, one or more elements of shape is a multipoint
            %   (which can include shapes with no points at all), and the
            %   coordinate fields contain cell arrays with a numeric
            %   (double) row vector in each cell. The cell arrays match the
            %   input shape in size and the value of the Geometry field is
            %   "multipoint".
            %
            %   The value of the CoordinateSystemType field equals
            %   “geographic” and the value of the GeographicCRS field
            %   matches the GeographicCRS property of the input shape.
            
            data = shape.InternalData;
            sz = size(data.NumVertices);
            if allSinglePoints(data)
                lat = reshape(data.VertexCoordinate1, sz);
                lon = reshape(data.VertexCoordinate2, sz);
                geometry = "point";
            elseif ~any(ismultipoint(data),"all")
                singlePointElement = (data.NumVertices == 1);
                lat = NaN(sz);
                lon = NaN(sz);
                lat(singlePointElement) = data.VertexCoordinate1;
                lon(singlePointElement) = data.VertexCoordinate2;
                geometry = "point";
            else
                [lat, lon] = toCellArrays(data);
                geometry = "multipoint";
            end
            S = struct('Latitude',[],'Longitude',[], ...
                'Geometry', geometry, ...
                'CoordinateSystemType', "geographic", ...
                'GeographicCRS', shape.GeographicCRS);
            S.Latitude = lat;
            S.Longitude = lon;
        end
        
        
        function str = string(obj)
            % Return a string array the same size as obj. Display a
            % formatted latitude-longitude pair for each single-point
            % element and display <geopointshape> for zero-point and
            % multipoint elements.
            sz = size(obj);
            n = prod(sz);
            data = obj.InternalData;
            data = reshapeArray(data, {n 1});
            singlePoint = (data.NumVertices == 1);
            str = repmat("geopointshape", [n 1]);
            if any(singlePoint)
                data = parenDeleteArray(data, {~singlePoint, ':'});
                lat = data.VertexCoordinate1;
                lon = data.VertexCoordinate2;
                singlePointStr = latlon2string(obj, lat, lon);
                str(singlePoint) = singlePointStr;
                str = strjust(pad(str),"center");
            end
            str = reshape(str, sz);
        end


        function [vertexData, shapeIndices] = markerData(obj)
            [vertexData, shapeIndices] = markerData(obj.InternalData);
        end
    end


    methods (Access = private)
        function str = latlon2string(obj, lat, lon)
            % Format latitude-longitude pairs as decimal numbers, with
            % degree symbols and letters (N,S,E,W) indicating cardinal
            % directions. Include 4 decimal places for a precision of
            % roughly 10 meters, consistent with the default MATLAB
            % command-line display for numbers in the range 1-360.

            D = obj.DegreeSymbol;

            lat = lat(:);
            lon = lon(:);

            latsuffix(length(lat), 1) = "";
            latsuffix(lat < 0)  = D + obj.NegativeLatitudeDirection;
            latsuffix(lat >= 0) = D + obj.PositiveLatitudeDirection;

            lonsuffix(length(lon), 1) = "";
            lonsuffix(lon < 0)  = D + obj.NegativeLongitudeDirection;
            lonsuffix(lon >= 0) = D + obj.PositiveLongitudeDirection;

            n = isnan(lat) | isnan(lon);
            lat(n) = 0;
            lon(n) = 0;

            latstr = split(sprintf("%7.4f#", abs(lat)), "#");
            lonstr = split(sprintf("%8.4f#", abs(lon)), "#");
            latstr(end) = [];
            lonstr(end) = [];
            latstr = latstr + latsuffix;
            lonstr = lonstr + lonsuffix;

            latstr(n) = sprintf( "%9s","NaN");
            lonstr(n) = sprintf("%10s","NaN");

            while all(startsWith(latstr," "))
                latstr = eraseBetween(latstr,1,1);
            end
            while all(startsWith(lonstr," "))
                lonstr = eraseBetween(lonstr,1,1);
            end

            str = "(" + latstr + ", " + lonstr + ")";
        end
    end
end
