classdef (Sealed, InferiorClasses = {?matlab.graphics.axis.GeographicAxes,?map.graphics.axis.MapAxes}) ...
        mappointshape < map.shape.MapShape & matlab.mixin.CustomDisplay
%MAPPOINTSHAPE Point shape in planar coordinates
%
%   A MAPPOINTSHAPE object represents a point or multipoint in planar
%   coordinates. A multipoint is an individual point shape that contains a
%   set of point locations.
%
%   SHAPE = MAPPOINTSHAPE(X,Y) returns a MAPPOINTSHAPE object or an array
%   of MAPPOINTSHAPE objects with the specified X and Y coordinates. To
%   create a MAPPOINTSHAPE scalar representing an individual point, specify
%   X and Y as numeric scalars. For an array of individual points, specify
%   X and Y as numeric arrays. To create a MAPPOINTSHAPE scalar
%   representing a multipoint, specify X and Y as numeric vectors enclosed
%   within cell scalars. For a multipoint array, specify X and Y as cell
%   arrays of numeric vectors.
%
%   The size of SHAPE matches the size of X and Y. The X and Y inputs must
%   match each other in size. In the case of cell inputs, the size of the
%   numeric vector in a given element of X must equal the size of the
%   numeric vector in the corresponding element of Y. Create placeholders
%   for points with missing data by including NaN values in X and Y.
%   In the case of either numeric or cell input, the inclusion of NaN
%   values must be consistent between X and Y.
%
%   Examples
%   --------
%   % MAPPOINTSHAPE scalar with an individual point:
%   shape = mappointshape(-113,39)
%
%   % 3x1 MAPPOINTSHAPE vector with one point per element:
%   shape = mappointshape([-66 -31 42]',[38 -30 29]')
%
%   % MAPPOINTSHAPE scalar with a multipoint:
%   shape = mappointshape({[-66 -31 42]},{[38 -30 29]})
%
%   % 1x2 MAPPOINTSHAPE vector with an individual point and a multipoint:
%   shape = mappointshape({-113,[-66 -31 42]},{39, [38 -30 29]})
% 
%   See also geopointshape, ismultipoint, maplineshape, mappolyshape

% Copyright 2021-2022 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        NumPoints  % Number of points in each point/multipoint shape
    end
    
    properties (Dependent)
        X
        Y
    end
    
    
    methods (Static)
        function obj = empty(sz)
            % Construct an empty mappointshape array. Examples:
            %    s = mappointshape.empty         % 0-by-0 mappointshape
            %    s = mappointshape.empty(0,1)    % 0-by-1 mappointshape
            %    s = mappointshape.empty([3 0])  % 3-by-0 mappointshape
            
            arguments (Repeating)
                sz (1,:) double {mustBeInteger, mustBeNonnegative}
            end
            obj = mappointshape;
            try
                obj.InternalData.NumVertices = uint32.empty(sz{:});
            catch e
                throw(e)
            end
        end
    end


    methods (Static, Hidden)
        function obj = loadobj(S)
            obj = mappointshape;
            obj.InternalData = restoreFromStructure(obj.InternalData, S);
            obj.ProjectedCRS = S.CoordinateReferenceSystem;
        end
    end


    methods
        function obj = mappointshape(X, Y)
            % Construct a mappointshape object from numeric X and Y arrays
            % or from cell arrays of X and Y vectors. In both cases, the
            % mappointshape object has the same size as the input arrays.
            
            switch nargin
                case 0
                    % Construct default object.
                    data = map.shape.internal.PointData;

                case 2
                    validateConstructorInput(obj, X, Y, "X", "Y")
                    validateX(obj, X)
                    validateY(obj, Y)
                    data = map.shape.internal.PointData;
                    if isnumeric(X)
                        data = fromNumericInput(data, X, Y);
                    else
                        data = fromCellInput(data, X, Y);
                    end

                otherwise
                    narginchk(2,2)
            end
            obj.InternalData = data;
        end
        
        
        function num = get.NumPoints(obj)
            num = double(obj.InternalData.NumVertices);
        end


        function x = get.X(obj)
            x = getPointCoordinateProperty(obj, "VertexCoordinate1");
        end


        function obj = set.X(obj, x)
            arguments
                obj mappointshape
                x double
            end
            validatefcn = @(c) validateX(obj,c);
            obj = setPointCoordinateProperty(obj, x, ...
                "X", validatefcn, "VertexCoordinate1");
        end


        function y = get.Y(obj)
            y = getPointCoordinateProperty(obj, "VertexCoordinate2");
        end


        function obj = set.Y(obj, y)
            arguments
                obj mappointshape
                y double
            end
            validatefcn = @(c) validateY(obj,c);
            obj = setPointCoordinateProperty(obj, y, ...
                "Y", validatefcn, "VertexCoordinate2");
        end


        function clipped = mapclip(obj, xlimits, ylimits)
            arguments
                obj mappointshape
                xlimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
                ylimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
            end

            clipped = obj;
            % NOTE: Avoid adding any comments above this line to keep them
            % from appearing when "help mappointshape/mapclip" is run.

            % Input limits can be any numeric type; use double
            % to ensure that full precision is maintained.
            xlimits = double(xlimits);
            ylimits = double(ylimits);

            clipped.InternalData = clip(obj.InternalData, xlimits, ylimits);
        end


        function h = geoplot(varargin)
        %GEOPLOT Plot point shapes with projected coordinates
        %
        %   GEOPLOT(SHAPE) plots the point shapes specified by the
        %   mappointshape scalar or array SHAPE in a geographic axes. The
        %   ProjectedCRS property of SHAPE must be non-empty.
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
        %   GT = readgeotable("boston_placenames.shp");
        %   places = GT.Shape;
        %   geoplot(places)
        %
        %   See also GEOPLOT, GEOPOINTSHAPE/GEOPLOT, GEOSCATTER

            narginchk(1,inf)

            obj = map.graphics.internal.shapeplot(varargin{:});
            if nargout > 0
                h = obj;
            end
        end
    end


    methods (Access = protected)
        function propgroup = getPropertyGroups(obj)
            % Customize display to omit the coordinate properties (X and Y)
            % when obj is nonscalar.
            if isscalar(obj)
                propgroup = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            elseif any(ismultipoint(obj),"all")
                propgroup = matlab.mixin.util.PropertyGroup(struct( ...
                    "NumPoints",            obj.NumPoints, ...
                    "Geometry",             obj.Geometry, ...
                    "CoordinateSystemType", obj.CoordinateSystemType, ...
                    "ProjectedCRS",         obj.ProjectedCRS));
            else
                propgroup = matlab.mixin.util.PropertyGroup(struct( ...
                    "NumPoints",            obj.NumPoints, ...
                    "X",                    obj.X, ...
                    "Y",                    obj.Y, ...
                    "Geometry",             obj.Geometry, ...
                    "CoordinateSystemType", obj.CoordinateSystemType, ...
                    "ProjectedCRS",         obj.ProjectedCRS));
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
            %   S = shapeToStructure(shape), when shape is a mappointshape
            %   array, returns a struct scalar, S, with the vertex
            %   coordinates of the shape array in its X and Y fields. The
            %   output, S, also has Geometry, CoordinateSystemType, and
            %   ProjectedCRS fields.
            %
            %   When NumPoints == 1 for all elements of shape, the
            %   coordinate arrays are type double and match the input shape
            %   in size, with a one-to-one correspondence between elements
            %   of X and Y and the corresponding element of shape. The
            %   value of the Geometry field is "point".
            %
            %   Otherwise, one or more elements of shape is a multipoint
            %   (which can include shapes with no points at all), and the
            %   coordinate fields contain cell arrays with a numeric
            %   (double) row vector in each cell. The cell arrays match the
            %   input shape in size and the value of the Geometry field is
            %   "multipoint".
            %
            %   The value of the CoordinateSystemType field equals “planar”
            %   and the value of the ProjectedCRS field matches the
            %   ProjectedCRS property of the input shape.
            
            data = shape.InternalData;
            sz = size(data.NumVertices);
            if allSinglePoints(data)
                xValue = reshape(data.VertexCoordinate1, sz);
                yValue = reshape(data.VertexCoordinate2, sz);
                geometry = "point";
            elseif ~ismultipoint(data)
                singlePointElement = (data.NumVertices == 1);
                xValue = NaN(sz);
                yValue = NaN(sz);
                xValue(singlePointElement) = data.VertexCoordinate1;
                yValue(singlePointElement) = data.VertexCoordinate2;
                geometry = "point";
            else
                [xValue, yValue] = toCellArrays(data);
                geometry = "multipoint";
            end
            S = struct('X',[],'Y',[], ...
                'Geometry', geometry, ...
                'CoordinateSystemType', "planar", ...
                'ProjectedCRS', shape.ProjectedCRS);
            S.X = xValue;
            S.Y = yValue;
        end
        
        
        function str = string(obj)
            % Return a string array the same size as obj. Display a
            % formatted x-y pair for each single-point element and display
            % <mappointshape> for zero-point and multipoint elements.
            sz = size(obj);
            n = prod(sz);
            data = obj.InternalData;
            data = reshapeArray(data, {n 1});
            singlePoint = (data.NumVertices == 1);
            str = repmat("mappointshape", [n 1]);
            if any(singlePoint)
                data = parenDeleteArray(data, {~singlePoint, ':'});
                x = data.VertexCoordinate1;
                y = data.VertexCoordinate2;
                singlePointStr = xy2string(obj, x, y);
                str(singlePoint) = singlePointStr;
                str = strjust(pad(str),"center");
            end
            str = reshape(str, sz);
        end
    end


    methods (Access = private)
        function str = xy2string(obj, x, y)
            % Format x-y coordinate pairs as decimal numbers.  Include
            % enough decimal places for a precision of 2 cm or better, if
            % the projectedCRS and hence the length units are known.
            % Otherwise, include two digits past the decimal point.
            % Assume non-empty x and y.
            if isempty(obj.ProjectedCRS)
                digits = 2;
            else
                crs = obj.ProjectedCRS;
                digits = max(0, 2 + ceil(log10(unitsratio("meter",crs.LengthUnit))));
            end
            x = x(:);
            y = y(:);
            n = isnan(x) | isnan(y);
            x(n) = 0;
            y(n) = 0;
            fmt = "%12." + num2str(digits) + "f";
            xstr = split(sprintf(fmt + "#", x), "#");
            ystr = split(sprintf(fmt + "#", y), "#");
            xstr(end) = [];
            ystr(end) = [];
            fmt = "%" + num2str(12) + "s";
            xstr(n) = sprintf(fmt,"NaN");
            ystr(n) = sprintf(fmt,"NaN");
            while all(startsWith(xstr," "))
                xstr = eraseBetween(xstr,1,1);
            end
            while all(startsWith(ystr," "))
                ystr = eraseBetween(ystr,1,1);
            end
            str = "(" + xstr + ", " + ystr + ")";
        end
    end    
end
