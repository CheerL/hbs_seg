function [Z, indxPointOutsideGrid]  = imbedm(lat, lon, value, Z, R, units)
%IMBEDM  Encode data points into regular data grid
%
%   Z = IMBEDM(LAT,LON,VALUE,Z,R) resets certain entries of a regular data
%   grid, Z. R is a geographic raster reference object. Its RasterSize
%   property must be consistent with size(Z). The entries to be reset
%   correspond to the locations defined by the latitude and longitude
%   position vectors LAT and LON. The entries are reset to the same number
%   if VALUE is a scalar, or to individually specified numbers if VALUE is
%   a vector of the same size as LAT and LON. If any points lie outside the
%   input grid, a warning is issued.  All input angles are in degrees.
%
%   Z = IMBEDM(LAT,LON,VALUE,Z,REFMAT) and
%   Z = IMBEDM(LAT,LON,VALUE,Z,REFVEC) where REFMAT is a 3-by-2 referencing
%   matrix and REFVEC is a 1-by-3 referencing vector, will be removed in a
%   future release. Use Z = IMBEDM(LAT,LON,VALUE,Z,R) instead, where R is a
%   geographic raster reference object.
%
%   Z = IMBEDM(LAT,LON,VALUE,Z,R,UNITS) specifies the units of the vectors
%   LAT and LON, where UNITS is any valid angle unit ('degrees' by
%   default).
%
%   [Z, indxPointOutsideGrid] = IMBEDM(...) returns the indices of
%   LAT and LON corresponding to points outside the grid in the variable
%   indxPointOutsideGrid.

% Copyright 1996-2022 The MathWorks, Inc.

% Validate inputs
narginchk(5, 6)

if nargin == 6
    [lat, lon] = toDegrees(units, lat, lon);
end

if isscalar(value)
    value = value + zeros(size(lat));
end

validateattributes(lat,{'numeric'},{'real'},'imbedm','LAT',1)
validateattributes(lon,{'numeric'},{'real'},'imbedm','LON',2)

assert(isequal(size(lat),size(lon),size(value)), ...
    'map:validate:inconsistentSizes3', ...
    'Function %s expected its %s, %s, and %s inputs to have the same size.', ...
    'imbedm', 'LAT', 'LON', 'VALUE')

%  If R is already spatial referencing object, validate it. Otherwise
%  convert the input referencing vector or matrix.
R = internal.map.convertToGeoRasterRef(R, size(Z), 'degrees', 'IMBEDM', 'R', 5);

%  Eliminate NaNs from the input data
qNaN = isnan(lat) | isnan(lon);
lat(qNaN) = [];
lon(qNaN) = [];
value(qNaN) = [];

%  Identify the rows and columns for cells (or samples) corresponding to
%  the input latitude-longitude locations.
[r, c, indxPointOutsideGrid] = geographicToDiscreteOmitOutside(R, lat, lon);

%  Embed the values into the grid
value(indxPointOutsideGrid) = [];
indx = (c-1)*size(Z,1) + r;
Z(indx) = value;
