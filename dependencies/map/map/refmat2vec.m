function refvec = refmat2vec(refmat,rasterSize)
%REFMAT2VEC Convert referencing matrix to referencing vector
%
%        REFMAT2VEC will be removed in a future release.
%        Create a geographic raster reference object instead using
%        refmatToGeoRasterReference.
%
%   REFVEC = REFMAT2VEC(REFMAT,rasterSize) converts a referencing matrix,
%   REFMAT, to the referencing vector REFVEC.  REFMAT is a 3-by-2
%   referencing matrix defining a 2-dimensional affine transformation from
%   pixel coordinates to geographic coordinates.  rasterSize is the size of
%   the data grid that is being referenced. REFVEC is a 1-by-3 referencing
%   vector with elements:
%
%         [cells/angleunit north-latitude west-longitude].  
%
%   See also refmatToGeoRasterReference

% Copyright 1996-2021 The MathWorks, Inc.

warning(message("map:removing:refmat2vec", "REFMAT2VEC", "refmatToGeoRasterReference"))
refvec = map.internal.referencingMatrixToVector(refmat, rasterSize);
