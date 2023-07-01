function lon = refmatResolveLongitude(refmat, lat, lon)
% Resolve longitude ambiguity when transforming lat-lon to intrinsic
% coordinates via a referencing matrix.
%
% For which values of n, if any is row >= 0.5 and col >= 0.5, where
%   [row, col] = transform(R, lon + cycle * n, lat)?

% Copyright 2021 The MathWorks, Inc.

cycle = 360;  % Degrees only for now

% Start with values for n = 0 and n = 1 (all we need because of linearity).
[row0, col0] = map.internal.refmatApplyInverse(refmat, lon, lat);          % n = 0
[row1, col1] = map.internal.refmatApplyInverse(refmat, lon + cycle, lat);  % n = 1

% Find limiting values of n as separately constrained by the rows and
% columns.
[rLower, rUpper] = findLimits(row0,row1);
[cLower, cUpper] = findLimits(col0,col1);

% Choose a value for n within the intersection of the limits (if possible)
n = max(rLower,cLower);
t = min(rUpper,cUpper);
n(n == -Inf) = t(n == -Inf);
n(n ==  Inf) = 0;

lon = lon + cycle * n;

%--------------------------------------------------------------------------

function [lowerLim, upperLim] = findLimits(c0, c1)

d = c1 - c0;
Z = (0.5 - c0) ./ d;

lowerLim = -Inf * ones(size(Z));
lowerLim(d > 0) = ceil(Z(d > 0));

upperLim = Inf * ones(size(Z));
upperLim(d < 0) = floor(Z(d < 0));
