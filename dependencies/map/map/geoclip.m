%GEOCLIP Clip geographic shape to latitude-longitude limits
%
%   CLIPPED = GEOCLIP(SHAPE,LATLIM,LONLIM) clips a geopointshape,
%   geolineshape, or geopolyshape object or array to the latitude-longitude
%   limits specified by the 1-by-2 vectors LATLIM and LONLIM. Specify
%   LATLIM as a vector of the form [southern-limit northern-limit] and
%   LONLIM as a vector of the form [western-limit eastern-limit]. Specify
%   angles in degrees. CLIPPED is the same type and size as SHAPE. If an
%   element of SHAPE lies completely outside the specified limits, then the
%   corresponding element of CLIPPED does not contain coordinate data.
%
%   Example
%   -------
%   land = readgeotable("landareas.shp");
%   rivers = readgeotable("worldrivers.shp");
%   cities = readgeotable("worldcities.shp");
%   latlim = [ 4  42];
%   lonlim = [65 130];
%   lclip = geoclip(land.Shape,latlim,lonlim);
%   rclip = geoclip(rivers.Shape,latlim,lonlim);
%   cclip = geoclip(cities.Shape,latlim,lonlim);
%   figure
%   geoplot(lclip)
%   geobasemap('none')
%   hold on
%   geoplot(rclip)
%   geoplot(cclip,'Marker','o')
%   geoplot(latlim([1 2 2 1 1]),lonlim([1 1 2 2 1]),'Color','k')
%
%   See also GEOCROP, MAPCLIP

% Copyright 2021 The MathWorks, Inc.

function clipped = geoclip(obj, latlim, lonlim) %#ok<*STOUT> 
    arguments
        obj map.shape.GeographicShape %#ok<*INUSA> 
        latlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits, ...
            mustBeGreaterThanOrEqual(latlim, -90), mustBeLessThanOrEqual(latlim,90)}
        lonlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite}
    end
    % No function body is needed here because if obj is actually a
    % GeographicShape, execution will dispatch to the geoclip method of
    % class(obj).
end
