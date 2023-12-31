function polemat = org2pol(origin,units)
%ORG2POL  Location of north pole on rotated map
%
%  pole = ORG2POL(origin) computes the location of the north pole (0,90)
%  in a transformed map.  This determines the location of (0,90) in
%  the coordinate system, which is centered on the origin of the map.
%
%  The input matrix is of the form origin = [lat, lon] or
%  origin = [lat, lon, orient], where [lat, lon] = the center
%  point of the map and orient = the north pole azimuth measured
%  from the center point.  If orient is omitted, then
%  orient = 0 is assumed.  Lat, lon and orient may be column vectors.
%  The output matrix is of the form pole = [lat, lon, meridian],
%  where [lat,lon] is the location of the north pole in the
%  transformed coordinate system, and meridian is the central meridian
%  from the original map on which the transformed system is centered.
%
%  pole = ORG2POL(origin,'units') defines the 'units' of the input
%  and output data.  If omitted, 'degrees' are assumed.
%
%  See also PUTPOLE, NEWPOLE.

% Copyright 1996-2021 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(1,2)

if nargin == 1
    units = 'degrees';
end

%  Argument dimensionality tests
%  Remember that origin may be a three column matrix where
%  each row is a represents an origin vector

if ndims(origin) > 2                       % Prohibit n dimensional inputs
     error(['map:' mfilename ':mapError'], ...
         'Origin input can not contain pages')
end

if size(origin,2) == 1
    origin = origin';
end   % Ensure row vectors

if size(origin,2) == 2
    origin(:,3) = 0;
elseif size(origin,2) ~= 3
    error(['map:' mfilename ':mapError'], ...
        'Origin input must have three columns')
end

%  Transform input data to radians

origin = real(toRadians(units, origin));

%  Construct the north pole point in the new coordinate system

cmeridian = origin(:,2);
latvec = pi/2;
latvec = latvec(ones(size(cmeridian)));

%  Rotate the north pole into the new coordinate system

plat = zeros([size(origin,1) 1]);  % Pre-allocate memory for faster looping
plon = zeros(size(plat));

for i = 1:size(origin,1)
   [plat(i),plon(i)] = rotatem(latvec(i),cmeridian(i),origin(i,:),'forward');
end

%  Transform the pole data for proper output

polemat = wrapToPi([plat plon cmeridian]);
polemat = fromRadians(units, polemat);
