function [Z, refvec] = nanm(latlim, lonlim, scale)
%NANM  Construct regular data grid of NaNs
%
%   NANM will be removed in a future release.
%   Instead, create a geographic raster reference object using GEOREFCELLS
%   and then use NAN to create an array of the appropriate size:
%
%       R = georefcells(latlim,lonlim,1/scale,1/scale);
%       Z = nan(R.RasterSize);
%
%   [Z, REFVEC] = NANM(LATLIM, LONLIM, SCALE) constructs a regular
%   data grid consisting entirely of NaNs.  The two-element vectors
%   LATLIM and LONLIM define the latitude and longitude limits of the
%   grid, in degrees.  They should be of the form [south north] and
%   [west east], respectively.  The number of rows and columns per
%   degree is set by the scalar value SCALE.  REFVEC is the
%   three-element referencing vector for the data grid.
%
%   See also GEOREFCELLS, NAN

% Copyright 1996-2021 The MathWorks, Inc.

warning(message("map:removing:nanm", "NANM", "GEOREFCELLS", "NAN"))
S = warning('OFF',"map:removing:sizem");
cleanupObj = onCleanup(@() warning(S));
[nrows, ncols, refvec] = sizem(latlim, lonlim, scale); %#ok<SIZEM>
Z = nan(nrows, ncols);
