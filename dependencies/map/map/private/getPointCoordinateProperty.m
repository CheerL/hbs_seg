function c = getPointCoordinateProperty(obj, vertexCoordinateProperty)
% Get coordinate property value (X, Y, Latitude, or Longitude) of a
% geopointshape or mappointshape.

% Copyright 2022 The MathWorks, Inc.

    data = obj.InternalData;
    numv = data.NumVertices;
    if isscalar(numv)
        if numv > 0
            c = data.(vertexCoordinateProperty);
        else
            c = NaN;
        end
    elseif allSinglePoints(data)
        c = reshape(data.(vertexCoordinateProperty), size(numv));
    elseif ~any(ismultipoint(data),"all")
        c = NaN(size(numv));
        c(numv == 1) = data.(vertexCoordinateProperty);
    else
        throwAsCaller(MException(message("map:shape:NonscalarMultipointCoordinateAccess", class(obj))))
    end
end
