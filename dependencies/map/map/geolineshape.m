classdef (Sealed, InferiorClasses = {?matlab.graphics.axis.GeographicAxes,?map.graphics.axis.MapAxes}) ...
        geolineshape < map.shape.GeographicShape
%GEOLINESHAPE Line shape in geographic coordinates
%
%   A GEOLINESHAPE object represents a geographic line or multiline. A
%   multiline is an individual line shape that contains a set of separate
%   lines.
%
%   SHAPE = GEOLINESHAPE(LAT,LON) creates a GEOLINESHAPE object or array of
%   GEOLINESHAPE objects with vertex coordinates specified by LAT and LON.
%   To create a GEOLINESHAPE scalar, specify LAT and LON as numeric
%   vectors. To create a multiline, include line breaks by specifying NaN
%   values in LAT and LON. To create a GEOLINESHAPE array, specify LAT and
%   LON as cell arrays with each cell containing a numeric vector. The size
%   of SHAPE matches the size of LAT and LON, with each element containing
%   a line or multiline as specified by the numeric vectors in the
%   corresponding cells of LAT and LON. The LAT and LON inputs must match
%   each other in size. In the case of cell array input, the size of the
%   numeric vector in a given element of LAT must equal the size of the
%   numeric vector in the corresponding element of LON. In the case of
%   either numeric or cell input, the inclusion of NaN values must be
%   consistent between LAT and LON.
%
%   Examples
%   --------
%   % GEOLINESHAPE scalar with a one-part line:
%   shape = geolineshape([65 62 53 66],[4 59 121 98])
%
%   % GEOLINESHAPE scalar with a two-part line:
%   shape = geolineshape([55 34 18 NaN 14 19 42 26],[78 56 63 NaN 83 106 104 126])
%
%   % 2x1 GEOLINESHAPE vector with a one-part line in each element:
%   shape = geolineshape({[55 34 18],[14 19 42 26]}',{[78 56 63],[83 106 104 126]}')
% 
%   See also geopointshape, geopolyshape, maplineshape

% Copyright 2020-2022 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        NumParts  % Number of parts ("line strings") in each line shape
    end
    
    
    methods (Static)
        function obj = empty(sz)
            % Construct an empty geolineshape array. Examples:
            %    s = geolineshape.empty         % 0-by-0 geolineshape
            %    s = geolineshape.empty(0,1)    % 0-by-1 geolineshape
            %    s = geolineshape.empty([3 0])  % 3-by-0 geolineshape
            
            arguments (Repeating)
                sz (1,:) double {mustBeInteger, mustBeNonnegative}
            end
            obj = geolineshape;
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
            obj = geolineshape;
            obj.InternalData = restoreFromStructure(obj.InternalData, S);
            obj.GeographicCRS = S.CoordinateReferenceSystem;
        end
    end
    
    
    methods
        function obj = geolineshape(lat,lon)
            % Construct a geolineshape scalar from NaN-delimited latitude
            % and longitude vertex vectors or from cell arrays of
            % NaN-delimited latitude and longitude vectors. In the case of
            % cell array input, the output object has the same size as the
            % input cell arrays.

             switch nargin
                case 0
                    % Construct default object.
                    data = map.shape.internal.LineStringData;

                case 2
                    validateConstructorInput(obj, lat, lon, "LAT", "LON")
                    validateLatitude(obj, lat)
                    validateLongitude(obj, lon)
                    data = map.shape.internal.LineStringData;
                    if isnumeric(lat)
                        validateVectorOrEmpty(obj, lat, lon, "LAT", "LON")
                        data = fromNumericVectors(data, lat, lon);
                    else
                        data = fromCellArrays(data, lat, lon);
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


        function clipped = geoclip(obj, latlim, lonlim)
            arguments
                obj geolineshape
                latlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits, ...
                    mustBeGreaterThanOrEqual(latlim, -90), mustBeLessThanOrEqual(latlim,90)}
                lonlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite}
            end

            S = shapeToStructure(obj);
            % NOTE: Avoid adding any comments above this line to keep them
            % from appearing when "help geolineshape/geoclip" is run.

            % Input limits can be any numeric type; use double
            % to ensure that full precision is maintained.
            latlim = double(latlim);
            lonlim = double(lonlim);

            for k = 1:length(S.Latitude)
                [latc, lonc] = map.internal.clip.clipLineToQuadrangle( ...
                    S.Latitude{k}, S.Longitude{k}, latlim(1), latlim(2), lonlim(1), lonlim(2));
                S.Latitude{k} = latc';
                S.Longitude{k} = lonc';
            end
            clipped = geolineshape(S.Latitude, S.Longitude);
            clipped.GeographicCRS = obj.GeographicCRS;
        end


        function h = geoplot(varargin)
        %GEOPLOT Plot line shapes with geographic coordinates
        %
        %   GEOPLOT(SHAPE) plots the line shapes specified by the
        %   geolineshape scalar or array SHAPE in a geographic axes.
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
        %   GT = readgeotable("worldrivers.shp");
        %   rhine = GT.Shape(GT.Name == "Rhine");
        %   geoplot(rhine)
        %
        %   See also GEOPLOT, MAPLINESHAPE/GEOPLOT

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
            % "geolineshape" for each element of obj.
            str = repmat("geolineshape", size(obj));
        end


        function [vertexData, stripData, shapeIndices] = lineStripData(obj)
            [vertexData, stripData, shapeIndices] = lineStripData(obj.InternalData);
        end
    end
end
