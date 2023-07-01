%ISMULTIPOINT Determine which array elements are multipoint shapes
%
%   TF = ISMULTIPOINT(SHAPE) returns an array that contains logical 1
%   (true) for each element of SHAPE that is a multipoint shape and logical
%   0 (false) for all other elements of SHAPE. SHAPE is an array of
%   geopointshape, geolineshape, geopolyshape, mappointshape, maplineshape,
%   or mappolyshape objects.  A shape object is "multipoint" if its type
%   is geopointshape or mappointshape and its NumPoints value is greater
%   than 1.
%
%   See also geopointshape, mappointshape

% Copyright 2022 The MathWorks, Inc.

function tf = ismultipoint(obj) %#ok<STOUT> 
    arguments
        obj {mustBeA(obj, [ ...
                "geopointshape", ...
                "mappointshape", ...
                "geolineshape", ...
                "maplineshape", ...
                "geopolyshape", ...
                "mappolyshape", ...
                "map.shape.GeographicShape", ...
                "map.shape.MapShape"])} %#ok<INUSA> 
    end
    % No function body is needed here because if obj is actually a
    % GeographicShape or MapShape object or array, MATLAB will dispatch its
    % ismultipoint method rather than executing this function.
end
