function [lat,lon,val] = findm(varargin)
%FINDM  Latitudes and longitudes of non-zero data grid elements
%
%   [LAT,LON] = FINDM(Z,R) computes the latitudes and longitudes of the
%   non-zero elements of the regular data grid, Z.  R is a geographic
%   raster reference object. Its RasterSize property must be consistent
%   with size(Z).
%
%   [LAT,LON] = FINDM(Z,REFMAT) and [LAT,LON] = FINDM(Z,REFVEC), where
%   REFMAT is a 3-by-2 referencing matrix and REFVEC is a 1-by-3
%   referencing vector, will be removed in a future release. Use
%   [LAT,LON] = FINDM(Z,R) instead, where R is a geographic raster reference
%   object.
%
%   [LAT,LON] = FINDM(LATZ,LONZ,Z) returns the latitudes and
%   longitudes of the non-zero elements of a geolocated data grid Z.
%   Z is an M-by-N logical or numeric array.  Typically LATZ and LONZ
%   are M-by-N latitude-longitude arrays, but LATZ may be a latitude
%   vector of length M and LONZ may be a longitude vector of length N.
%
%   [LAT,LON,VAL] = FINDM(...) returns the values of the non-zero
%   elements of Z, in addition to their locations.
%
%   MAT = FINDM(...) returns a single output, where MAT = [LAT LON].
%
%   See also FIND

% Copyright 1996-2022 The MathWorks, Inc.

narginchk(2, 3)

if nargin == 2
    % FINDM(Z, R)
    [lat,lon,val] = findRegular(varargin{:});
else
    % FINDM(LATZ, LONZ, Z)
    [lat,lon,val] = findGeolocated(varargin{:});
end

if nargout == 1
    % Combine output, if necessary.
    lat = [lat lon];
end

%-----------------------------------------------------------------------

function [lat, lon, Z] = findRegular(Z, R)

% Validate Z.
validateattributes(Z, {'numeric','logical'}, {'2d'}, mfilename, 'Z', 1)

% If R is already spatial referencing object, validate it. Otherwise
% convert the input referencing vector or matrix.
R = internal.map.convertToGeoRasterRef( ...
    R, size(Z), 'degrees', 'FINDM', 'R', 2);

% Compute the latitudes and longitudes of the cell centers
lat = R.intrinsicYToLatitude( (1:R.RasterSize(1))');
lon = R.intrinsicXToLongitude((1:R.RasterSize(2))');

[r,c] = find(Z);
lat = lat(r);
lon = lon(c);
Z = Z(r+(c-1)*size(Z,1));

%-----------------------------------------------------------------------

function [lat, lon, Z] = findGeolocated(lat, lon, Z)

checklatlonz(lat, lon, Z, mfilename, 'LATZ', 'LONZ', 'Z', 1, 2, 3)

[r,c] = find(Z);
indx = r+(c-1)*size(Z,1);

if isvector(lat)
    lat = lat(r);
    lat = lat(:);
else
    lat = lat(indx);
end

if isvector(lon)
    lon = lon(c);
    lon = lon(:);
else
    lon = lon(indx);
end

Z = Z(indx);

%-----------------------------------------------------------------------

function checklatlonz(lat, lon, Z, func_name, ...
    lat_var_name, lon_var_name, z_var_name, lat_pos, lon_pos, z_pos)

validateattributes(lat, {'double','single'}, {'2d','real'}, ...
    func_name, lat_var_name, lat_pos)

validateattributes(lon, {'double','single'}, {'2d','real'}, ...
    func_name, lon_var_name, lon_pos)

validateattributes(Z, {'numeric','logical'}, {'2d','real'},...
    func_name, z_var_name, z_pos)

assert(isequal(size(Z), size(lat)) ...
    || isvector(lat) && size(Z,1) == numel(lat), ...
    'map:findm:inconsistentLatSize', ...
    ['%s must be an array that matches %s in size or a vector ', ...
    'whose length matches the number of rows in Z.'], ...
    lat_var_name, z_var_name)

assert(isequal(size(Z), size(lon)) ...
    || isvector(lon) && size(Z,2) == numel(lon), ...
    'map:findm:inconsistentLonSize', ...
    ['%s must be an array that matches %s in size or a vector ', ...
    'whose length matches the number of columns in Z.'], ...
    lon_var_name, z_var_name)
