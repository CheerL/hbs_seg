classdef (AllowedSubclasses = {?mappointshape, ?maplineshape, ?mappolyshape}) ...
        MapShape < map.shape.Shape
%map.shape.MapShape Point, line, or polygon shapes in planar coordinates
%
%   A map.shape.MapShape array can contain a combination of mappointshape,
%   maplineshape, and mappolyshape objects. The ProjectedCRS property of
%   the shapes must be equivalent.

% Copyright 2021-2022 The MathWorks, Inc.

%   The map.shape.MapShape class plays two roles at the same time:
%
%   (a) Heterogeneous shape type for projected/planar shapes
%   (b) Superclass for homogeneous projected/planar shape types
%       (mappointshape, maplineshape, mappolyshape)
% 
%   It builds on the abstract map.shape.Shape class, adding properties
%   specific to projected/planar coordinate systems:
%
%      CoordinateSystemType (always "planar")
%      ProjectedCRS (projcrs scalar or empty)
%
%   and implements heterogeneous shape behaviors.


    properties (Dependent, SetAccess = protected)
        % This property could be declared in map.shape.Shape, but it's
        % declared here so that "Geometry" precedes "CoordinateSystemType"
        % and "ProjectedCRS" in command-line displays.
        Geometry
    end
    
    properties (Constant)
        CoordinateSystemType = "planar"
    end
    
    properties
        ProjectedCRS = []
    end
    
    properties (Constant, Access = protected)
        CRSPropertyName = "ProjectedCRS"
    end


    methods (Static)
        function obj = empty(sz)
            % Construct an empty array. Examples:
            %    s = map.shape.MapShape.empty         % 0-by-0
            %    s = map.shape.MapShape.empty(0,1)    % 0-by-1
            %    s = map.shape.MapShape.empty([3 0])  % 3-by-0
            
            arguments (Repeating)
                sz (1,:) double {mustBeInteger, mustBeNonnegative}
            end
            obj = map.shape.MapShape;
            try
                obj.InternalData.GeometryType = uint8.empty(sz{:});
            catch e
                throw(e)
            end
        end
    end


    methods (Static, Hidden)
        function obj = loadobj(S)
            obj = map.shape.MapShape;
            obj.InternalData = restoreFromStructure(obj.InternalData, S);
            obj.ProjectedCRS = S.CoordinateReferenceSystem;
        end
    end


    methods
        function obj = MapShape(objIn)
            data = map.shape.internal.HeterogeneousData;
            if nargin > 0
                % "Promote" homogeneous input to heterogeneous output.
                validateattributes(objIn, "map.shape.MapShape", {})
                obj.ProjectedCRS = objIn.ProjectedCRS;
                data = map.shape.internal.HeterogeneousData(objIn.InternalData);
            end
            obj.InternalData = data;
        end


        function geometry = get.Geometry(obj)
            geometry = obj.InternalData.geometry();
        end


        function obj = set.ProjectedCRS(obj, crs)
            arguments
                obj map.shape.MapShape
                crs {mustBeScalarOrEmpty}
            end
            if ~isempty(crs) && ~isa(crs,"projcrs")
                error(message('map:shape:InvalidCRS',"projcrs"))
            end
            obj.ProjectedCRS = crs;
        end


        function clipped = mapclip(obj, xlimits, ylimits)
            arguments
                obj map.shape.MapShape
                xlimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
                ylimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
            end

            data = obj.InternalData;
            % NOTE: Avoid adding any comments above this line to keep them
            % from appearing when "help map.shape.MapShape/mapclip" is run.

            % Clip points, if any
            shape = mappointshape;
            shape.InternalData = data.PointData;
            shape = mapclip(shape, xlimits, ylimits);
            data.PointData = shape.InternalData;

            % Clip lines, if any
            shape = maplineshape;
            shape.InternalData = data.LineStringData;
            shape = mapclip(shape, xlimits, ylimits);
            data.LineStringData = shape.InternalData;

            % Clip polygons, if any
            shape = mappolyshape;
            shape.InternalData = data.PolygonData;
            shape = mapclip(shape, xlimits, ylimits);
            data.PolygonData = shape.InternalData;

            % Construct output
            sizes = num2cell(size(obj));
            clipped(sizes{:}) = map.shape.MapShape;
            clipped.ProjectedCRS = obj.ProjectedCRS;
            clipped.InternalData = data;
        end
    end


    methods (Hidden, Static)
        function shape = makeMapShape(S)
            % This static factory method constructs a mappointshape,
            % maplineshape, mappolyshape, or MapShape array
            % from a scalar structure with fields:
            %
            %     GeometryType (n,1) uint8
            %     NumVertices  (n,1) uint32
            %     NumVertexSequences (n,1) uint32
            %     IndexOfLastVertex (1,m) uint32
            %     RingType (1,m) uint8
            %     Coordinate1 (1,p) double (X)
            %     Coordinate2 (1,p) double (Y)
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
                shape = mappointshape();
            elseif any(geometryType == 2) && all(geometryType == 2 | geometryType == 0 | geometryType > 3)
                shape = maplineshape();
            elseif any(geometryType == 3) && all(geometryType == 3 | geometryType == 0 | geometryType > 3)
                shape = mappolyshape();
            else
                shape = map.shape.MapShape();
            end
            
            vertexCoordinateField1 = "Coordinate1";  % X
            vertexCoordinateField2 = "Coordinate2";  % Y
            
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
            % the static makeMapShape method.
            
            vertexCoordinateField1 = "Coordinate1";  % X
            vertexCoordinateField2 = "Coordinate2";  % Y
            
            S = toStructOutput(shape.InternalData, ...
                    vertexCoordinateField1, vertexCoordinateField2);
        end


        function S = shapeToStructure(shape)
            % Convert a shape array to a scalar structure
            %
            %   S = shapeToStructure(shape) accepts any type of map shape
            %   (in planar coordinates) and returns a struct scalar, S,
            %   with the vertex coordinates of the shape in X and Y fields.
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
            %   arrays), a CoordinateSystemType field (“planar”) and a
            %   ProjectedCRS field. The values in these fields match the
            %   corresponding properties of the input shape.
            
            S = struct('X',[],'Y',[], ...
                'Geometry',shape.Geometry, ...
                'CoordinateSystemType',"planar", ...
                'ProjectedCRS',shape.ProjectedCRS);
            data = shape.InternalData;
            if ismethod(data,"toCellArrays")
                [X, Y] = toCellArrays(data);
                S.X = X;
                S.Y = Y;
            end
        end
    end


    methods (Access = protected)
        function obj = makeHeterogeneous(obj)
            obj = map.shape.MapShape(obj);
        end

        function crs = getCRS(obj)
            crs = obj.ProjectedCRS;
        end

        function obj = setCRS(obj,crs)
            obj.ProjectedCRS = crs;
        end


        function validateX(obj, x)
            if isnumeric(x) && ~isempty(x)
                if ~isreal(x) || any(~(isfinite(x) | isnan(x)),"all")
                    throwAsCaller(MException(message("map:shape:XMustBeRealAndFinite")))
                end
            elseif iscell(x)
                for k = 1:numel(x)
                    validateX(obj, x{k})
                end
            end
        end


        function validateY(obj, y)
            if isnumeric(y) && ~isempty(y)
                if ~isreal(y) || any(~(isfinite(y) | isnan(y)),"all")
                    throwAsCaller(MException(message("map:shape:YMustBeRealAndFinite")))
                end
            elseif iscell(y)
                for k = 1:numel(y)
                    validateY(obj, y{k})
                end
            end
        end


        function obj = updateShape(obj, data)
            % Reset the internal data of a map shape and change it
            % to a homogeneous type if possible.
            if isHomogeneous(data)
                projectedCRS = obj.ProjectedCRS;
                switch class(data)
                    case "map.shape.internal.HeterogeneousData"
                        sz = num2cell(size(data.GeometryType));
                        if all(data.GeometryType == 1, "all")
                            obj = mappointshape();
                            data = reshapeArray(data.PointData, sz);
                        elseif all(data.GeometryType == 2, "all")
                            obj = maplineshape();
                            data = reshapeArray(data.LineStringData, sz);
                        elseif all(data.GeometryType == 3, "all")
                            obj = mappolyshape();
                            data = reshapeArray(data.PolygonData, sz);
                        end
                    case "map.shape.internal.PointData"
                        obj = mappointshape();
                    case "map.shape.internal.LineStringData"
                        obj = maplineshape();
                    case "map.shape.internal.PolygonData"
                        obj = mappolyshape();
                end
                obj.ProjectedCRS = projectedCRS;
            end
            obj.InternalData = data;
        end


        function heterogeneousType = heterogeneousShapeType(~)
            heterogeneousType = "map.shape.MapShape";
        end
    end
end


function mustBeNondecreasingLimits(limits)
    if limits(2) < limits(1)
        error(message('map:validators:mustBeNondecreasingLimits'))
    end
end
