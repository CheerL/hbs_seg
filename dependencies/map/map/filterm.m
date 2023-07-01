function [newlat,newlon,indx] = filterm(lat,lon,map,R,allowed)
%FILTERM  Filter latitudes/longitudes based on underlying data grid
%
%   [latout,lonout] = FILTERM(lat,lon,Z,R,allowed) filters a set of
%   latitudes and longitudes to include only those data points which have a
%   corresponding value in Z equal to allowed.  R is a geographic raster
%   reference object. Its RasterSize property must be consistent with
%   size(Z).
%
%   [latout,lonout] = FILTERM(lat,lon,Z,REFMAT,allowed), and
%   [latout,lonout] = FILTERM(lat,lon,Z,REFVEC,allowed), where REFMAT is a
%   3-by-2 referencing matrix and REFVEC is a 1-by-3 referencing vector,
%   will be removed in a future release. Use
%   [latout,lonout] = FILTERM(lat,lon,Z,R,allowed) instead, where R is a
%   geographic raster reference object.
%
%   [latout,lonout,indx] = FILTERM(lat,lon,Z,R,allowed) also returns the
%   indices of the included points.
%
%  See also IMBEDM, HISTR, HISTA

% Copyright 1996-2022 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Validate inputs
checklatlon(lat, lon, 'filterm', 'LAT', 'LON', 1, 2)
validateattributes(lat, ...
    {'double','single'}, {'real','finite','vector'}, 'filterm', 'LAT', 1)
validateattributes(lon, ...
    {'double','single'}, {'real','finite','vector'}, 'filterm', 'LON', 2)
validateattributes(map, ...
    {'numeric','logical'}, {'real','2d'}, 'filterm', 'Z', 3)

%  Retrieve the code for each lat/lon data point

R = internal.map.convertToGeoRasterRef(R, size(map), 'degrees', 'FILTERM', 'R', 4);
code = geointerp(map, R, lat, lon, 'nearest');

%  Test for each allowed code

indx = [];
for i = 1:length(allowed)
    testindx = find(code == allowed(i));

    if ~isempty(testindx)           %  Save allowed indices
	   indx  = [indx;  testindx];
    end
end

%  Sort indices so as to NOT alter the data point ordering in the
%  original vectors.  Eliminate double counting of data points.

if numel(indx) > 1
	indx = sort(indx); 
	indx = [indx(diff(indx)~=0); indx(length(indx))];
end

%  Accept allowed data points

if ~isempty(indx)
	newlat = lat(indx);
    newlon = lon(indx);
else
    newlat = [];
    newlon = [];
end

%  Set output arguments if necessary

if nargout < 2
    newlat = [newlat newlon];
end
