function [V,lat,lon] = neworig(V,R,origin,direction,units)
%NEWORIG Orient regular data grid to oblique aspect
%
%   [Z,lat,lon] = NEWORIG(Z0,R,origin) and
%   [Z,lat,lon] = NEWORIG(Z0,R,origin,'forward') will transform regular
%   data grid Z0 into an oblique aspect, while preserving the matrix
%   storage format.  In other words, the oblique map origin is not
%   necessarily at (0,0) in the Greenwich coordinate frame. This allows
%   operations to be performed on the matrix representing the oblique map.
%   For example, azimuthal calculations for a point in a data grid become
%   row and column operations if the data grid is transformed so that the
%   north pole of the oblique map represents the desired point on the
%   globe.  R is a geographic raster reference object. Its RasterSize
%   property must be consistent with size(Z).
%
%   [Z,lat,lon] = NEWORIG(Z0,R,origin,'inverse') transforms
%   the regular data grid from the oblique frame to the Greenwich
%   coordinate frame.
%
%   [Z,lat,lon] = NEWORIG(Z0,REFMAT,__) and
%   [Z,lat,lon] = NEWORIG(Z0,REFVEC,__), where REFMAT is a 3-by-2
%   referencing matrix and REFVEC is a 1-by-3 referencing vector, will be
%   removed in a future release. Use [Z,lat,lon] = NEWORIG(Z0,R,__)
%   instead, where R is a geographic raster reference object.
%
%   See also ROTATEM, ORG2POL.

% Copyright 1996-2022 The MathWorks, Inc.
% Written by:  E. Brown, E. Byrns

narginchk(3, 5)

if nargin == 3
    direction = [];
    units = [];
elseif nargin == 4
    units = [];
end

%  Empty argument tests

if isempty(direction) || ...
        (isStringScalar(direction) && strlength(direction) == 0)
    direction = 'forward';
else
    direction = validatestring(direction, {'forward','inverse'}, ...
    'neworig', 'DIRECTION', 4);
end

if isempty(units) || ...
        (isStringScalar(units) && strlength(units) == 0)
    units = 'degrees'; 
end

%   Compute the starting grid locations

R = internal.map.convertToGeoRasterRef( ...
    R, size(V), 'degrees', mfilename, 'R', 2);
[lat, lon] = map.internal.graticuleFromRasterReference(R, size(V));

%  Convert units

[lat, lon, origin] = toRadians(units, lat, lon, origin);

%  Set the proper direction for rotatem.  If the user has entered
%  forward, then this is actually an inverse using rotatem.  We
%  must find out what Greenwich coordinates will produce the [lat lon]
%  grid.  It is the codes of these Greenwich coordinates that we
%  want to move into the positions corresponding to [lat lon].  This
%  process works in reverse when the user is going in the inverse direction.

if strcmp(direction,'forward')
     direction = 'inverse';
else
     direction = 'forward';
end

%  Rotate the grid to the corresponding starting locations.

[lat,lon] = rotatem(lat,lon,origin,direction);

%  Convert the grid to the units in which the map is stored

[lat, lon] = fromRadians(units, lat, lon);

%  Compute the starting positions of the map coordinates

[row, col] = geographicToDiscrete(R, lat(:), lon(:));
n = isnan(row);
row(n) = [];
col(n) = [];
indx = (col - 1) * R.RasterSize(1) + row;

%  Set these indices in the new map.

[r,c] = size(V);
V = V(indx);
V = reshape(V,r,c);
end
