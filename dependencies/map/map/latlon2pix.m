function [row, col] = latlon2pix(R, lat, lon)
%LATLON2PIX Convert latitude-longitude coordinates to pixel coordinates
%
%      LATLON2PIX will be removed in a future release.
%      Use geographicToIntrinsic instead.
%
%   [ROW, COL] = LATLON2PIX(R,LAT,LON) calculates pixel  coordinates ROW,
%   COL from latitude-longitude coordinates LAT, LON.  R is either a 3-by-2
%   referencing matrix that transforms intrinsic pixel coordinates to
%   geographic coordinates, or a geographic raster reference object.  LAT
%   and LON are vectors or arrays of matching size.  The outputs ROW and
%   COL have the same size as LAT and LON.  LAT and LON must be in degrees.
%
%   Longitude wrapping is handled: Results are invariant under the
%   substitution LON = LON +/- N * 360 where N is an integer.  Any point on
%   the earth that is included in the image or gridded data set
%   corresponding to R will yield row/column values between 0.5 and 0.5 +
%   the image height/width, regardless of what longitude convention is
%   used.
%
%   Example
%   -------
%   % Find the pixel coordinates of the upper left and lower right
%   % outer corners of a 2-by-2 degree gridded data set.  
%   R = georefcells([-90 90],[0 360],2,2,'ColumnsStartFrom','north')
%   [UL_row, UL_col] = latlon2pix(R,  90, 0)
%   [LR_row, LR_col] = latlon2pix(R, -90, 360)
%
%   See also georefcells, georefpostings,
%            map.rasterref.GeographicCellsReference/geographicToIntrinsic

% Copyright 1996-2022 The MathWorks, Inc.

narginchk(3,3)
warning(message("map:removing:latlon2pix","LATLON2PIX","geographicToIntrinsic"))

% Validate referencing matrix or geographic raster reference object.
map.rasterref.internal.validateRasterReference(R, ...
    'geographic', 'latlon2pix', 'R', 1)

if isobject(R)
    [col, row] = geographicToIntrinsic(R, lat, lon);
else
    lon = map.internal.refmatResolveLongitude(R, lat, lon);
    [row, col] = map2pix(R, lon, lat); %#ok<MAP2PIX> 
end
