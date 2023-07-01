classdef (Sealed, InferiorClasses = {?matlab.graphics.axis.GeographicAxes,?map.graphics.axis.MapAxes}) ...
        mappolyshape < map.shape.MapShape
%MAPPOLYSHAPE Polygon in planar coordinates
%
%   A MAPPOLYSHAPE object represents a polygon or multipolygon in planar
%   coordinates. A polygon is a region bounded by a closed curve that may
%   include interior holes (or voids) with boundaries of their own. A
%   multipolygon is an individual polygon shape that includes two or more
%   non-intersecting regions.
%
%   SHAPE = MAPPOLYSHAPE(X,Y) creates a MAPPOLYSHAPE or array of
%   MAPPOLYSHAPE objects with the vertex coordinates of the polygon
%   boundaries specified by X and Y. To create a MAPPOLYSHAPE scalar,
%   specify X and Y as numeric vectors. If the polygon has one or more
%   holes and/or two or more regions, specify breaks between the region and
%   hole boundaries by including NaN values in X and Y. To create a
%   MAPPOLYSHAPE array, specify X and Y as cell arrays with each cell
%   containing a numeric vector. The size of SHAPE matches the size of X
%   and Y, with each element representing a polygon or multipolygon as
%   specified by the numeric vectors in the corresponding cells of X and Y.
%   The X and Y inputs must match each other in size. In the case of cell
%   array input, the size of the numeric vector in a given element of X
%   must equal the size of the numeric vector in the corresponding element
%   of Y. In the case of either numeric or cell input, the inclusion of NaN
%   values must be consistent between X and Y.
%
%   The MAPPOLYSHAPE function assumes that X and Y define polygons with
%   valid topology, which means that region interiors are to the right when
%   tracing boundaries from vertex to vertex and the boundaries have no
%   self-intersections. In general, this means the outer boundaries of
%   polygon regions have a clockwise vertex order and the interior holes of
%   polygon regions have a counterclockwise vertex order.
%
%   Examples
%   --------
%   % MAPPOLYSHAPE scalar with one region and no holes:
%   shape = mappolyshape([-113 -49 -100 -113],[39 45 19 39])
%
%   % MAPPOLYSHAPE scalar with two regions and one hole:
%   X = [69 90 105 79 69 NaN  6 52 43 14  6 NaN 18 32 22 18];
%   Y = [37 46  31 20 37 NaN 45 49 35 32 45 NaN 35 40 42 35];
%   shape = mappolyshape(X,Y)
%
%   % 2x1 MAPPOLYSHAPE vector with one region in each element:
%   X = {[69 90 105 79 69],[ 6 52 43 14  6 NaN 18 32 22 18]}';
%   Y = {[37 46  31 20 37],[45 49 35 32 45 NaN 35 40 42 35]}';
%   shape = mappolyshape(X,Y)
%
%   See also geopolyshape, mappointshape, maplineshape

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
            % Construct an empty mappolyshape array. Examples:
            %    s = mappolyshape.empty         % 0-by-0 mappolyshape
            %    s = mappolyshape.empty(0,1)    % 0-by-1 mappolyshape
            %    s = mappolyshape.empty([3 0])  % 3-by-0 mappolyshape
            
            arguments (Repeating)
                sz (1,:) double {mustBeInteger, mustBeNonnegative}
            end
            obj = mappolyshape;
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
            obj = mappolyshape;
            obj.InternalData = restoreFromStructure(obj.InternalData, S);
            obj.ProjectedCRS = S.CoordinateReferenceSystem;
        end
    end
    
    
    methods
        function obj = mappolyshape(X,Y)
            % Construct a mappolyshape scalar from NaN-delimited latitude
            % and longitude vertex vectors or from cell arrays of
            % NaN-delimited latitude and longitude vectors. In the case of
            % cell array input, the output object has the same size as the
            % input cell arrays.
            
             switch nargin
                case 0
                    % Construct default object.
                    data = map.shape.internal.PolygonData;

                case 2
                    validateConstructorInput(obj, X, Y, "X", "Y")
                    validateX(obj, X)
                    validateY(obj, Y)
                    handedness = "right";
                    data = map.shape.internal.PolygonData;
                    if isnumeric(X)
                        validateVectorOrEmpty(obj, X, Y, "X", "Y")
                        data = fromNumericVectors(data, X, Y, handedness);
                    else
                        data = fromCellArrays(data, X, Y, handedness);
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


        function clipped = mapclip(obj, xlimits, ylimits)
            arguments
                obj mappolyshape
                xlimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
                ylimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
            end

            S = shapeToStructure(obj);
            % NOTE: Avoid adding any comments above this line to keep them
            % from appearing when "help mappolyshape/mapclip" is run.

            % Input limits can be any numeric type; use double
            % to ensure that full precision is maintained.
            xlimits = double(xlimits);
            ylimits = double(ylimits);

            cliprect = matlab.internal.polygon.builtin.cpolygon( ...
                xlimits([1 1 2 2 1]), ylimits([1 2 2 1 1]), "ccw", uint32(0));
            keepCollinear = true;
            for k = 1:length(S.X)
                cpoly = matlab.internal.polygon.builtin.cpolygon( ...
                    S.X{k}, S.Y{k}, "ccw", uint32(0));
                intersection = intersect(cpoly, cliprect, keepCollinear);
                [xc, yc] = boundary(intersection, 1:intersection.NumBoundaries);
                S.X{k} = xc';
                S.Y{k} = yc';
            end
            clipped = mappolyshape(S.X, S.Y);
            clipped.ProjectedCRS = obj.ProjectedCRS;
        end


        function [inpoly, onboundary] = isinterior(obj, querypoint)
        %ISINTERIOR True for points in polygon with planar coordinates
        %
        %   INPOLY = ISINTERIOR(SHAPE,QUERYPOINT) returns a logical array
        %   whose elements are true when a polygon SHAPE contains the
        %   corresponding points in QUERYPOINT. Specify SHAPE as a
        %   mappolyshape scalar. Specify QUERYPOINT as a mappointshape
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
        %   GT = readgeotable("concord_hydro_area.shp");
        %   pond = GT(14,:)
        %   xq = [207768  208399  208218  208044  207879  208210  208076];
        %   yq = [912697  912324  912290  912453  912476  912542  912127];
        %   querypoint = mappointshape(xq,yq);
        %   tf = isinterior(pond.Shape,querypoint)
        %
        %   figure
        %   mapshow(pond)
        %   mapshow(xq,yq,DisplayType="point",MarkerEdgeColor="green")
        %   mapshow(xq(tf),yq(tf),DisplayType="point",MarkerEdgeColor="blue")
        %
        %   See also INPOLYGON, GEOPOLYSHAPE/ISINTERIOR, POLYSHAPE/ISINTERIOR

            arguments
                obj (1,1) mappolyshape
                querypoint mappointshape
            end

            if ~isequal(obj.ProjectedCRS, querypoint.ProjectedCRS) ...
                    && ~isempty(obj.ProjectedCRS) ...
                    && ~isempty(querypoint.ProjectedCRS)
                error(message("map:shape:IsinteriorWithMismatchedCRS","ProjectedCRS"))
            end

            S = shapeToStructure(obj);
            if isempty(S.X) || isempty(querypoint)
                inpoly = false(size(querypoint));
                onboundary = false(size(querypoint));
            else
                x = S.X{1};
                y = S.Y{1};
                if length(x) < 3
                    inpoly = false(size(querypoint));
                    onboundary = false(size(querypoint));
                else
                    pshape = polyshape(x, y, ...
                        SolidBoundaryOrientation = "cw", ...
                        Simplify = false, KeepCollinearPoints = true);
                    [inpoly, onboundary] = isinterior(querypoint.InternalData, pshape);
                end
            end
        end


        function h = geoplot(varargin)
        %GEOPLOT Plot polygons with projected coordinates
        %
        %   GEOPLOT(SHAPE) plots the polygons specified by the mappolyshape
        %   scalar or array SHAPE in a geographic axes. The ProjectedCRS
        %   property of SHAPE must be non-empty.
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
        %   GT = readgeotable("concord_hydro_area.shp");
        %   pond = GT.Shape(14);
        %   geoplot(pond)
        %
        %   See also GEOPLOT, GEOPOLYSHAPE/GEOPLOT

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
            % "mappolyshape" for each element of obj.
            str = repmat("mappolyshape", size(obj));
        end
    end
end
