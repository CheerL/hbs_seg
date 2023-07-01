classdef (Sealed, InferiorClasses = {?matlab.graphics.axis.GeographicAxes,?map.graphics.axis.MapAxes}) ...
        maplineshape < map.shape.MapShape
%MAPLINESHAPE Line shape in planar coordinates
%
%   A MAPLINESHAPE object represents a line or multiline in planar
%   coordinates. A multiline is an individual line shape that contains a
%   set of separate lines.
%
%   SHAPE = MAPLINESHAPE(X,Y) creates a MAPLINESHAPE object or array of
%   MAPLINESHAPE objects with vertex coordinates specified by X and Y. To
%   create a MAPLINESHAPE scalar, specify X and Y as numeric vectors. To
%   create a multiline, include line breaks by specifying NaN values in X
%   and Y. To create a MAPLINESHAPE array, specify X and Y as cell arrays
%   with each cell containing a numeric vector.
%
%   The size of SHAPE matches the size of X and Y, with each element
%   containing a line or multiline as specified by the numeric vectors in
%   the corresponding cells of X and Y. The X and Y inputs must match each
%   other in size. In the case of cell array input, the size of the numeric
%   vector in a given element of X must equal the size of the numeric
%   vector in the corresponding element of Y. In the case of either numeric
%   or cell input, the inclusion of NaN values must be consistent between X
%   and Y.
%
%   Examples
%   --------
%   % MAPLINESHAPE scalar with a one-part line:
%   shape = maplineshape([4 59 121 98],[65 62 53 66])
%
%   % MAPLINESHAPE scalar with a two-part line:
%   shape = maplineshape([78 56 63 NaN 83 106 104 126],[55 34 18 NaN 14 19 42 26])
%
%   % 2x1 MAPLINESHAPE vector with a one-part line in each element:
%   shape = maplineshape({[78 56 63],[83 106 104 126]}',{[55 34 18],[14 19 42 26]}')
% 
%   See also geolineshape, mappointshape, mappolyshape

% Copyright 2021-2022 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        NumParts  % Number of parts ("line strings") in each line shape
    end
    
    
    methods (Static)
        function obj = empty(sz)
            % Construct an empty maplineshape array. Examples:
            %    s = maplineshape.empty         % 0-by-0 maplineshape
            %    s = maplineshape.empty(0,1)    % 0-by-1 maplineshape
            %    s = maplineshape.empty([3 0])  % 3-by-0 maplineshape
            
            arguments (Repeating)
                sz (1,:) double {mustBeInteger, mustBeNonnegative}
            end
            obj = maplineshape;
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
            obj = maplineshape;
            obj.InternalData = restoreFromStructure(obj.InternalData, S);
            obj.ProjectedCRS = S.CoordinateReferenceSystem;
        end
    end
    
    
    methods
        function obj = maplineshape(X,Y)
            % Construct a maplineshape scalar from NaN-delimited X and Y
            % vertex vectors or from cell arrays of NaN-delimited X and Y
            % vectors. In the case of cell array input, the output object
            % has the same size as the input cell arrays.

             switch nargin
                case 0
                    % Construct default object.
                    data = map.shape.internal.LineStringData;

                case 2
                    validateConstructorInput(obj, X, Y, "X", "Y")
                    validateX(obj, X)
                    validateY(obj, Y)
                    data = map.shape.internal.LineStringData;
                    if isnumeric(X)
                        validateVectorOrEmpty(obj, X, Y, "X", "Y")
                        data = fromNumericVectors(data, X, Y);
                    else
                        data = fromCellArrays(data, X, Y);
                    end
                    obj.InternalData = data;

                otherwise
                    narginchk(2,2)
            end
            obj.InternalData = data;
        end
        
        
        function num = get.NumParts(obj)
            num = double(obj.InternalData.NumVertexSequences);
        end


        function clipped = mapclip(obj, xlimits, ylimits)
            arguments
                obj maplineshape
                xlimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
                ylimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
            end

            S = shapeToStructure(obj);
            % NOTE: Avoid adding any comments above this line to keep them
            % from appearing when "help maplineshape/mapclip" is run.

            % Input limits can be any numeric type; use double
            % to ensure that full precision is maintained.
            xlimits = double(xlimits);
            ylimits = double(ylimits);

            for k = 1:length(S.X)
                [xc, yc] = map.internal.clip.clipLineToRectangle( ...
                    S.X{k}, S.Y{k}, xlimits(1), xlimits(2), ylimits(1), ylimits(2));
                S.X{k} = xc';
                S.Y{k} = yc';
            end
            clipped = maplineshape(S.X, S.Y);
            clipped.ProjectedCRS = obj.ProjectedCRS;
        end


        function h = geoplot(varargin)
        %GEOPLOT Plot line shapes with projected coordinates
        %
        %   GEOPLOT(SHAPE) plots the line shapes specified by the
        %   maplineshape scalar or array SHAPE in a geographic axes. The
        %   ProjectedCRS property of SHAPE must be non-empty.
        %
        %   GEOPLOT(SHAPE,LineSpec) uses a LineSpec to specify the color
        %   and line style of the line.
        %
        %   GEOPLOT(___,Name,Value) specifies line properties using one
        %   or more Name-Value arguments.
        %
        %   GEOPLOT(gx,___) creates the plot in the geographic axes
        %   specified by gx instead of the current axes.
        %
        %   H = GEOPLOT(___) additionally returns a Line object. Use H to
        %   modify the properties of the object after it is created.
        %
        %   Example
        %   -------
        %   GT = readgeotable("concord_roads.shp");
        %   roads = GT.Shape(1:4);
        %   geoplot(roads)
        %
        %   See also GEOPLOT, GEOLINESHAPE/GEOPLOT

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
            % "maplineshape" for each element of obj.
            str = repmat("maplineshape", size(obj));
        end
    end
end
