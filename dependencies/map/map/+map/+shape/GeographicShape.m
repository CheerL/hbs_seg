classdef (AllowedSubclasses = {?geopointshape, ?geolineshape, ?geopolyshape}) ...
        GeographicShape < map.shape.Shape
%map.shape.GeographicShape Point, line, or polygon shapes in geographic coordinates
%
%   A map.shape.GeographicShape array can contain a combination of
%   geopointshape, geolineshape, and geopolyshape objects. The
%   GeographicCRS property of the shapes must be equivalent.
%
%   See also geopointshape, geolineshape, geopolyshape

% Copyright 2020-2022 The MathWorks, Inc.

%   The map.shape.GeographicShape class plays two roles at the same time:
%
%   (a) Heterogeneous shape type for geographic shapes
%   (b) Superclass for homogeneous geographic shape types
%       (geopointshape, geolineshape, geopolyshape)
% 
%   It builds on the abstract map.shape.Shape class, adding properties
%   specific to geographic systems:
%
%      CoordinateSystemType (always "geographic")
%      GeographicCRS (geocrs scalar or empty)
%
%   and implements heterogeneous shape behaviors.


    properties (Dependent, SetAccess = protected)
        % This property could be declared in map.shape.Shape, but it's
        % declared here so that "Geometry" precedes "CoordinateSystemType"
        % and "GeographicCRS" in command-line displays.
        Geometry
    end

    properties (Constant)
        CoordinateSystemType = "geographic"
    end
    
    properties
        GeographicCRS = []
    end
    
    properties (Constant, Access = protected)
        CRSPropertyName = "GeographicCRS"
    end


    methods (Static)
        function obj = empty(sz)
            % Construct an empty array. Examples:
            %    s = map.shape.GeographicShape.empty         % 0-by-0
            %    s = map.shape.GeographicShape.empty(0,1)    % 0-by-1
            %    s = map.shape.GeographicShape.empty([3 0])  % 3-by-0
            
            arguments (Repeating)
                sz (1,:) double {mustBeInteger, mustBeNonnegative}
            end
            obj = map.shape.GeographicShape;
            try
                obj.InternalData.GeometryType = uint8.empty(sz{:});
            catch e
                throw(e)
            end
        end
    end


    methods (Static, Hidden)
        function obj = loadobj(S)
            obj = map.shape.GeographicShape;
            obj.InternalData = restoreFromStructure(obj.InternalData, S);
            obj.GeographicCRS = S.CoordinateReferenceSystem;
        end
    end


    methods
        function obj = GeographicShape(objIn)
            data = map.shape.internal.HeterogeneousData;
            if nargin > 0
                % "Promote" homogeneous input to heterogeneous output.
                validateattributes(objIn, "map.shape.GeographicShape", {})
                obj.GeographicCRS = objIn.GeographicCRS;
                data = map.shape.internal.HeterogeneousData(objIn.InternalData);
            end
            obj.InternalData = data;
        end


        function geometry = get.Geometry(obj)
            geometry = obj.InternalData.geometry();
        end


        function obj = set.GeographicCRS(obj, crs)
            arguments
                obj map.shape.GeographicShape
                crs {mustBeScalarOrEmpty}
            end
            if ~isempty(crs) && ~isa(crs,"geocrs")
                error(message('map:shape:InvalidCRS',"geocrs"))
            end
            obj.GeographicCRS = crs;
        end


        function clipped = geoclip(obj, latlim, lonlim)
            arguments
                obj map.shape.GeographicShape
                latlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits, ...
                    mustBeGreaterThanOrEqual(latlim, -90), mustBeLessThanOrEqual(latlim,90)}
                lonlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite}
            end

            data = obj.InternalData;
            % NOTE: Avoid adding any comments above this line to keep them
            % from appearing when "help map.shape.GeographicShape/geoclip"
            % is run.

            % Clip points, if any
            shape = geopointshape;
            shape.InternalData = data.PointData;
            shape = geoclip(shape, latlim, lonlim);
            data.PointData = shape.InternalData;

            % Clip lines, if any
            shape = geolineshape;
            shape.InternalData = data.LineStringData;
            shape = geoclip(shape, latlim, lonlim);
            data.LineStringData = shape.InternalData;

            % Clip polygons, if any
            shape = geopolyshape;
            shape.InternalData = data.PolygonData;
            shape = geoclip(shape, latlim, lonlim);
            data.PolygonData = shape.InternalData;

            % Construct output
            sizes = num2cell(size(obj));
            clipped(sizes{:}) = map.shape.GeographicShape;
            clipped.GeographicCRS = obj.GeographicCRS;
            clipped.InternalData = data;
        end
    end


    methods (Hidden, Static)
        function shape = makeGeographicShape(S)
            % This status factor method constructs a geopointshape,
            % geolineshape, geopolyshape, or GeographicShape
            % array from a scalar structure with the following fields:
            %
            %     GeometryType (n,1) uint8
            %     NumVertices  (n,1) uint32
            %     NumVertexSequences (n,1) uint32
            %     IndexOfLastVertex (1,m) uint32
            %     RingType (1,m) uint8
            %     Coordinate1 (1,p) double (longitude)
            %     Coordinate2 (1,p) double (latitude)
            %
            % GeometryType code: 0 : Not a geometry
            %                    1 : point
            %                    2 : line
            %                    3 : polygon
            %
            % RingType code:     0 : line string
            %                    1 : region boundary
            %                    2 : hole boundary
            
            arguments
                S (1,1) struct
            end
            
            geometryType = S.GeometryType(:);
            if any(geometryType == 1) && all(geometryType == 1 | geometryType == 0)
                shape = geopointshape();
            elseif any(geometryType == 2) && all(geometryType == 2 | geometryType == 0 | geometryType > 3)
                shape = geolineshape();
            elseif any(geometryType == 3) && all(geometryType == 3 | geometryType == 0 | geometryType > 3)
                shape = geopolyshape();
            else
                shape = map.shape.GeographicShape();
            end
            
            vertexCoordinateField1 = "Coordinate2";  % Latitude
            vertexCoordinateField2 = "Coordinate1";  % Longitude
            
            data = fromStructInput(shape.InternalData, S, ...
                vertexCoordinateField1, vertexCoordinateField2);
            
            shape.InternalData = data;
        end
    end
    
    
    methods (Hidden)
        function h = geoplot(varargin) %#ok<STOUT> 
            error(message("map:graphics:MustBeHomogenousShape"))
        end


        function S = exportShapeData(shape)
            % Return a struct scalar that's consistent with the input to
            % the static makeGeographicShape method.

            vertexCoordinateField1 = "Coordinate2";  % Latitude
            vertexCoordinateField2 = "Coordinate1";  % Longitude

            S = toStructOutput(shape.InternalData, ...
                vertexCoordinateField1, vertexCoordinateField2);
        end


        function S = shapeToStructure(shape)
            % Convert a shape array to a scalar structure
            %
            %   S = shapeToStructure(shape) accepts any type of
            %   geographic shape and returns a struct scalar, S, with its
            %   the vertex coordinates of the shape in Latitude and
            %   Longitude fields.
            %
            %   The coordinate fields contain cell arrays with a numeric
            %   (double) row vector in each cell, consistent with the cell
            %   array inputs that are accepted by the various shape type
            %   constructors. The cell arrays match in size and have the
            %   same size as the input. In the case of multipart lines and
            %   multi-ring polygons, NaN values in the numeric vectors
            %   delimit the parts/rings.
            %
            %   S also contains a Geometry field (a string scalar equal to
            %   "point", "line", or "polygon", at least for homogeneous
            %   arrays), a CoordinateSystemType field (“geographic”) and a
            %   GeographicCRS field. The values in these fields match the
            %   corresponding properties of the input shape.
            
            S = struct('Latitude',[],'Longitude',[], ...
                'Geometry',shape.Geometry, ...
                'CoordinateSystemType',"geographic", ...
                'GeographicCRS',shape.GeographicCRS);
            data = shape.InternalData;
            if ismethod(data,"toCellArrays")
                [lat, lon] = toCellArrays(shape.InternalData);
                S.Latitude = lat;
                S.Longitude = lon;
            end
        end
    end
    
    
    methods (Access = protected)
        function obj = makeHeterogeneous(obj)
            obj = map.shape.GeographicShape(obj);
        end

        function crs = getCRS(obj)
            crs = obj.GeographicCRS;
        end

        function obj = setCRS(obj,crs)
            obj.GeographicCRS = crs;
        end


        function validateLatitude(obj, lat)
            if isnumeric(lat) && ~isempty(lat)
                if ~isreal(lat) || any(~(isfinite(lat) | isnan(lat)),"all")
                    throwAsCaller(MException(message("map:shape:LatitudeMustBeRealAndFinite")))
                else
                    if any(lat(:) < -90 | 90 < lat(:))
                        throwAsCaller(MException(message('map:shape:LatitudeMustBeInRange')))
                    end
                end
            elseif iscell(lat)
                for k = 1:numel(lat)
                    validateLatitude(obj, lat{k})
                end
            end
        end


        function validateLongitude(obj, lon)
            if isnumeric(lon) && ~isempty(lon)
                if ~isreal(lon) || any(~(isfinite(lon) | isnan(lon)),"all")
                    throwAsCaller(MException(message("map:shape:LongitudeMustBeRealAndFinite")))
                end
            elseif iscell(lon)
                for k = 1:numel(lon)
                    validateLongitude(obj, lon{k})
                end
            end
        end


        function obj = updateShape(obj, data)
            % Reset the internal data of a geographic shape and change it
            % to a homogeneous type if possible.
            if isHomogeneous(data)
                geographicCRS = obj.GeographicCRS;
                switch class(data)
                    case "map.shape.internal.HeterogeneousData"
                        sz = num2cell(size(data.GeometryType));
                        if all(data.GeometryType == 1, "all")
                            obj = geopointshape();
                            data = reshapeArray(data.PointData, sz);
                        elseif all(data.GeometryType == 2, "all")
                            obj = geolineshape();
                            data = reshapeArray(data.LineStringData, sz);
                        elseif all(data.GeometryType == 3, "all")
                            obj = geopolyshape();
                            data = reshapeArray(data.PolygonData, sz);
                        end
                    case "map.shape.internal.PointData"
                        obj = geopointshape();
                    case "map.shape.internal.LineStringData"
                        obj = geolineshape();
                    case "map.shape.internal.PolygonData"
                        obj = geopolyshape();
                end
                obj.GeographicCRS = geographicCRS;
            end
            obj.InternalData = data;
        end


        function heterogeneousType = heterogeneousShapeType(~)
            heterogeneousType = "map.shape.GeographicShape";
        end
    end
end


function mustBeNondecreasingLimits(limits)
    if limits(2) < limits(1)
        error(message('map:validators:mustBeNondecreasingLimits'))
    end
end
