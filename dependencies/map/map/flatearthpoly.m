function [latf, lonf] = flatearthpoly(lat, lon, centerlon)
%FLATEARTHPOLY Convert polygon to planar topology
%
%   [LATF,LONF] = FLATEARTHPOLY(LAT,LON) clips NaN-delimited polygons
%   specified by the latitude and longitude vectors LAT and LON to the
%   limits [-180 180] in longitude and [-90 90] in latitude and inserts
%   straight segments along the +/- 180-degree meridians and at the
%   poles. Inputs and outputs are in degrees.
%
%   [LATF,LONF] = FLATEARTHPOLY(LAT,LON,CENTERLON) centers the
%   longitude limits on the longitude specified by the scalar CENTERLON.
%
%   Example
%   -------
%   % Extract Antartica, the first polygon in coastlat/coastlon
%   load coastlines
%   firstnan = find(isnan(coastlat),1,'first');  
%   lat = coastlat(1:firstnan);
%   lon = coastlon(1:firstnan);
%
%   % Plot the input coastline
%   figure
%   plot(lon,lat)
%   axis equal
%   xlim([-200 200])
%
%   % Convert Antarctica to planar polygon topology and plot the result
%   [latf,lonf] = flatearthpoly(lat,lon);
%   figure
%   mapshow(lonf,latf,'DisplayType','polygon')
%   ylim([-100 -60])
%
%   See also MAPTRIMP

% Copyright 1996-2021 The MathWorks, Inc.

% Validate inputs
arguments
    lat {mustBeFloat, mustBeVector}
    lon {mustBeFloat, mustBeVector}
    centerlon (1,1) {mustBeNumeric, mustBeReal, mustBeFinite} = 0
end
checklatlon(lat, lon, mfilename, 'LAT', 'LON', 1, 2)

% Construct new polygons
latlim = [-90 90];
lonlim = centerlon + [-180 180];
[latf, lonf] = maptrimp(lat, lon, latlim, lonlim);
