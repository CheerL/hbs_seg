function [x, y] = refmatApplyForward(R, row, col)
% Apply the transformation (using referencing matrix R)
%
%     [x y] = [row col 1] * R
%
% where R is a 3-by-2 referencing matrix, in a way that is robust with
% respect to large offsets from the origin.

% Copyright 2021 The MathWorks, Inc.

sz = size(row);

t = [row(:) col(:)] * R(1:2,:);
x = t(:,1) + R(3,1);
y = t(:,2) + R(3,2);

x = reshape(x, sz);
y = reshape(y, sz);
