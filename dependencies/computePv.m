

function y = computePv(y,m,K)

y = reshape(y,[m-1,2]);
% K = 1/8*ones(2,2,2,1);
y = convn(y,K);
y = y(:);

