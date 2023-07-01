function y = computePTv(y,m,K)

y = reshape(y,[m,2]);
% K = 1/8*ones(2,2,2,1);
y = convn(y,K,'valid');
y = y(:);
