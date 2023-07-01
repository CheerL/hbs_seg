function refmat = refvec2mat(refvec,rasterSize)
%REFVEC2MAT Convert referencing vector to referencing matrix
%
%        REFVEC2MAT will be removed in a future release.
%        Create a geographic raster reference object instead using
%        refvecToGeoRasterReference.
%
%   REFMAT = REFVEC2MAT(REFVEC,rasterSize) converts a referencing vector,
%   REFVEC, to the referencing matrix REFMAT.  REFVEC is a 1-by-3
%   referencing vector with elements:
%
%       [cells/angleunit north-latitude west-longitude].
%
%   rasterSize is the size of the raster that is being referenced. REFMAT
%   is a 3-by-2 referencing matrix defining a 2-dimensional affine
%   transformation from intrinsic coordinates to geographic coordinates.
%
%   See also refvecToGeoRasterReference

% Copyright 1996-2021 The MathWorks, Inc.

warning(message("map:removing:refvec2mat", "REFVEC2MAT", "refvecToGeoRasterReference"))
refmat = map.internal.referencingVectorToMatrix(refvec,rasterSize);
