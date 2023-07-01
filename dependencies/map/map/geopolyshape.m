classdef (Sealed, InferiorClasses = {?matlab.graphics.axis.GeographicAxes,?map.graphics.axis.MapAxes}) ...
        geopolyshape < map.shape.GeographicShape
%GEOPOLYSHAPE Polygon in geographic coordinates
%
%   A GEOPOLYSHAPE object represents a polygon or multipolygon in
%   geographic coordinates. A polygon is a region bounded by a closed curve
%   that may include interior holes (or voids) with boundaries of their
%   own. A multipolygon is an individual polygon shape that includes two or
%   more non-intersecting regions.
%
%   SHAPE = GEOPOLYSHAPE(LAT,LON) creates a GEOPOLYSHAPE or array of
%   GEOPOLYSHAPE objects with the vertex coordinates of the polygon
%   boundaries specified by LAT and LON. To create a GEOPOLYSHAPE scalar,
%   specify LAT and LON as numeric vectors. If the polygon has one or more
%   holes and/or two or more regions, specify breaks between the region and
%   hole boundaries by including NaN values in LAT and LON. To create a
%   GEOPOLYSHAPE array, specify LAT and LON as cell arrays with each cell
%   containing a numeric vector. The size of SHAPE matches the size of LAT
%   and LON, with each element representing a polygon or multipolygon as
%   specified by the numeric vectors in the corresponding cells of LAT and
%   LON. The LAT and LON inputs must match each other in size. In the case
%   of cell array input, the size of the numeric vector in a given
%   element of LAT must equal the size of the numeric vector in the
%   corresponding element of LON. In the case of either numeric or cell
%   input, the inclusion of NaN values must be consistent between LAT and
%   LON.
%
%   The GEOPOLYSHAPE function assumes that LAT and LON define polygons with
%   valid topology, which means that region interiors are to the right when
%   tracing boundaries from vertex to vertex and the boundaries have no
%   self-intersections. In general, this means the outer boundaries of
%   polygon regions have a clockwise vertex order and the interior holes of
%   polygon regions have a counterclockwise vertex order.
%
%   Examples
%   --------
%   % GEOPOLYSHAPE scalar with one region and no holes:
%   shape = geopolyshape([39 45 19 39],[-113 -49 -100 -113])
%
%   % GEOPOLYSHAPE scalar with two regions and one hole:
%   lat = [37 46  31 20 37 NaN 45 49 35 32 45 NaN 35 40 42 35];
%   lon = [69 90 105 79 69 NaN  6 52 43 14  6 NaN 18 32 22 18];
%   shape = geopolyshape(lat,lon)
%
%   % 2x1 GEOPOLYSHAPE vector with one region in each element:
%   lat = {[37 46  31 20 37],[45 49 35 32 45 NaN 35 40 42 35]}';
%   lon = {[69 90 105 79 69],[ 6 52 43 14  6 NaN 18 32 22 18]}';
%   shape = geopolyshape(lat,lon)
%
%   See also geopointshape, geolineshape, mappolyshape

% Copyright 2021-2022 The MathWorks, Inc.

    properties (Hidden, Dependent, SetAccess = private)
        NumRings  % Number of parts ("rings") in each polygon
    end
    
    properties (Dependent, SetAccess = private)
        NumRegions  % Number of regions in each polygon
        NumHoles    % Number of holes in each polygon
    end
    
    
    methods (Static)
        function obj = empty(sz)
            % Construct an empty geopolyshape array. Examples:
            %    s = geopolyshape.empty         % 0-by-0 geopolyshape
            %    s = geopolyshape.empty(0,1)    % 0-by-1 geopolyshape
            %    s = geopolyshape.empty([3 0])  % 3-by-0 geopolyshape
            
            arguments (Repeating)
                sz (1,:) double {mustBeInteger, mustBeNonnegative}
            end
            obj = geopolyshape;
            try
                v = uint32.empty(sz{:});
                obj.InternalData.NumVertexSequences = v;
                obj.InternalData.NumVertices = v;
            catch e
                throw(e)
            end
        end
    end


    methods (Static, Hidden)
        function obj = loadobj(S)
            obj = geopolyshape;
            obj.InternalData = restoreFromStructure(obj.InternalData, S);
            obj.GeographicCRS = S.CoordinateReferenceSystem;
        end
    end
    
    
    methods
        function obj = geopolyshape(lat,lon)
            % Construct a geopolyshape scalar from NaN-delimited latitude
            % and longitude vertex vectors or from cell arrays of
            % NaN-delimited latitude and longitude vectors. In the case of
            % cell array input, the output object has the same size as the
            % input cell arrays.

             switch nargin
                case 0
                    % Construct default object.
                    data = map.shape.internal.PolygonData;

                case 2
                    validateConstructorInput(obj, lat, lon, "LAT", "LON")
                    validateLatitude(obj, lat)
                    validateLongitude(obj, lon)
                    handedness = "left";
                    data = map.shape.internal.PolygonData;
                    if isnumeric(lat)
                        validateVectorOrEmpty(obj, lat, lon, "LAT", "LON")
                        data = fromNumericVectors(data, lat, lon, handedness);
                    else
                        data = fromCellArrays(data, lat, lon, handedness);
                    end
                    obj.InternalData = data;

                otherwise
                    narginchk(2,2)
            end
            obj.InternalData = data;
        end
        
        
        function num = get.NumRings(obj)
            num = double(obj.InternalData.NumVertexSequences);
        end
        
        
        function num = get.NumRegions(obj)
            ringType = 1;
            num = numRingType(obj.InternalData, ringType);
        end
        
        
        function num = get.NumHoles(obj)
            ringType = 2;
            num = numRingType(obj.InternalData, ringType);
        end


        function clipped = geoclip(obj, latlim, lonlim)
            arguments
                obj geopolyshape
                latlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits, ...
                    mustBeGreaterThanOrEqual(latlim, -90), mustBeLessThanOrEqual(latlim,90)}
                lonlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite}
            end

            S = shapeToStructure(obj);
            % NOTE: Avoid adding any comments above this line to keep them
            % from appearing when "help geopolyshape/geoclip" is run.

            % Input limits can be any numeric type; use double
            % to ensure that full precision is maintained.
            latlim = double(latlim);
            lonlim = double(lonlim);

            for k = 1:length(S.Latitude)
                [latc, lonc] = maptrimp(S.Latitude{k}, S.Longitude{k}, latlim, lonlim);
                S.Latitude{k} = latc;
                S.Longitude{k} = lonc;
            end
            clipped = geopolyshape(S.Latitude, S.Longitude);
            clipped.GeographicCRS = obj.GeographicCRS;
        end


        function [inpoly, onboundary] = isinterior(obj, querypoint)
        %ISINTERIOR True for points in polygon with geographic coordinates
        %
        %   INPOLY = ISINTERIOR(SHAPE,QUERYPOINT) returns a logical array
        %   whose elements are true when a polygon SHAPE contains the
        %   corresponding points in QUERYPOINT. Specify SHAPE as a
        %   geopolyshape scalar. Specify QUERYPOINT as a geopointshape
        %   array. A point is in the polygon shape if it is either inside a
        %   solid region or on one of the boundaries.
        %
        %   [INPOLY,ONBOUNDARY] = ISINTERIOR(__) returns an additional
        %   logical array whose elements are true when the corresponding
        %   points in QUERYPOINT are on a boundary of the polygon shape.
        %
        %   The INPOLY and ONBOUNDARY outputs are the same size as
        %   QUERYPOINT.
        %
        %   Example
        %   -------
        %   cities = readgeotable("worldcities.shp");
        %   landareas = readgeotable("landareas.shp");
        %   australia = landareas.Shape(landareas.Name=="Australia");
        %   tf = isinterior(australia,cities.Shape);
        %   citiesInAustralia = cities(tf,:)
        %
        %   figure
        %   geoplot(australia)
        %   hold on
        %   geoplot(citiesInAustralia,Marker='o',MarkerEdgeColor='m')
        %
        %   See also INPOLYGON, MAPPOLYSHAPE/ISINTERIOR, POLYSHAPE/ISINTERIOR        

            arguments
                obj (1,1) geopolyshape
                querypoint geopointshape
            end

            if ~isequal(obj.GeographicCRS, querypoint.GeographicCRS) ...
                    && ~isempty(obj.GeographicCRS) ...
                    && ~isempty(querypoint.GeographicCRS)
                error(message("map:shape:IsinteriorWithMismatchedCRS","GeographicCRS"))
            end

            if hasNoCoordinateData(obj) || isempty(querypoint)
                inpoly = false(size(querypoint));
                onboundary = false(size(querypoint));
            else
                if lessThanThreeVertices(obj)
                    inpoly = false(size(querypoint));
                    onboundary = false(size(querypoint));
                else
                    S = shapeToStructure(obj);
                    lat = S.Latitude{1};
                    lon = S.Longitude{1};
                    if max(lon) <= min(lon) + 360
                        % The polygon spans less than 360 degrees in
                        % longitude.
                        querypoint = wrapQueryPointLongitude(querypoint, min(lon));
                        pshape = polyshape(lat, lon, ...
                            SolidBoundaryOrientation = "ccw", ...
                            Simplify = false, KeepCollinearPoints = true);
                        [inpoly, onboundary] = isinterior(querypoint.InternalData, pshape);
                    else
                        % The polygon spans more than 360 degrees in
                        % longitude. Clip polygon and query points to a
                        % span of 360 degrees, but do it twice to avoid
                        % false positives in onBoundary for points on a cut
                        % meridian.

                        minlon = -180;
                        querypoint = wrapQueryPointLongitude(querypoint, minlon);
                        [lat, lon] = clipLongitudeExtent(obj, minlon);
                        pshape = polyshape(lat, lon, ...
                            SolidBoundaryOrientation = "ccw", ...
                            Simplify = false, KeepCollinearPoints = true);
                        [inpoly180, onboundary180] = isinterior(querypoint.InternalData, pshape);

                        minlon = 0;
                        querypoint = wrapQueryPointLongitude(querypoint, minlon);
                        [lat, lon] = clipLongitudeExtent(obj, minlon);
                        pshape = polyshape(lat, lon, ...
                            SolidBoundaryOrientation = "ccw", ...
                            Simplify = false, KeepCollinearPoints = true);
                        [inpoly360, onboundary360] = isinterior(querypoint.InternalData, pshape);

                        inpoly = inpoly180 & inpoly360;
                        onboundary = onboundary180 & onboundary360;
                    end
                end
            end
        end


        function h = geoplot(varargin)
        %GEOPLOT Plot polygons with geographic coordinates
        %
        %   GEOPLOT(SHAPE) plots the polygons specified by the geopolyshape
        %   scalar or array SHAPE in a geographic axes.
        %
        %   GEOPLOT(SHAPE,LineSpec) uses a LineSpec to specify the color of
        %   the polygon faces.
        %
        %   GEOPLOT(___,Name,Value) specifies polygon properties using one
        %   or more Name-Value arguments.
        %
        %   GEOPLOT(gx,___) creates the plot in the geographic axes
        %   specified by gx instead of the current axes.
        %
        %   H = GEOPLOT(___) additionally returns a Polygon object. Use H
        %   to modify the properties of the object after it is created.
        %
        %   Example
        %   -------
        %   GT = readgeotable("worldlakes.shp");
        %   erie = GT.Shape(GT.Name == "Lake Erie");
        %   geoplot(erie)
        %
        %   See also GEOPLOT, MAPPOLYSHAPE/GEOPLOT

            narginchk(1,inf)
            obj = map.graphics.internal.shapeplot(varargin{:});
            if nargout > 0
                h = obj;
            end
        end
    end
    
    
    methods (Hidden)
        function str = string(obj)
            % Return a string array the same size as obj containing
            % "geopolyshape" for each element of obj.
            str = repmat("geopolyshape", size(obj));
        end


        function [vertexData, stripData, shapeIndices] = lineStripData(obj)
            [vertexData, stripData, shapeIndices] = lineStripData(obj.InternalData);
        end


        function [vertexData, vertexIndices, shapeIndices] = triangleStripData(obj)
            method = "polyshape";
            [vertexData, vertexIndices, shapeIndices] = triangleStripData(obj.InternalData, method);
        end
    end


    methods (Access = private)
        function tf = lessThanThreeVertices(obj)
            tf = obj.InternalData.NumVertices < 3;
        end

        function [lat, lon] = clipLongitudeExtent(obj, minlon)
            % If necessary, clip the polygon such that its extent in
            % longitude does not exceed 360 degrees. Return vectors of
            % vertex coordinates that can be passed to polyshape.
            obj = geoclip(obj, [-90 90], minlon + [0 360]);
            S = shapeToStructure(obj);
            lat = S.Latitude{1};
            lon = S.Longitude{1};
        end
    end
end


function querypoint = wrapQueryPointLongitude(querypoint, minlon)
    % Assuming a polygon that spans no more than 360 degrees in longitude,
    % wrap query point longitudes to match the polygon longitude limits.
    data = querypoint.InternalData;
    data.VertexCoordinate2 = minlon + wrapTo360(data.VertexCoordinate2 - minlon);
    querypoint.InternalData = data;
end
