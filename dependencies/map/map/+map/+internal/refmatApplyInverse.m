function [row, col] = refmatApplyInverse(R, x, y)
% Invert the transformation 
%
%     [x y] = [row col 1] * R
%
% where R is a 3-by-2 referencing matrix, in a way that is robust with
% respect to large offsets from the origin.

% Copyright 2021 The MathWorks, Inc.

sz = size(x);

P = [x(:) - R(3,1), y(:) - R(3,2)] / R(1:2,:);

row = reshape(P(:,1), sz);
col = reshape(P(:,2), sz);
