

function [c1,c2,c3] = getFittingTermTriDiagonal(m,Ker,d2psi,dT)

dT1 = dT(:,1);
dT2 = dT(:,2);

c1 = 1/4*computePTv_1(d2psi*dT1.*dT1,m,Ker);
c2 = 1/4*computePTv_1(d2psi*dT1.*dT2,m,Ker);
c3 = 1/4*computePTv_1(d2psi*dT2.*dT2,m,Ker);



function y = computePTv_1(y,m,K)

y = reshape(y,m);
y = convn(y,K,'valid');
y = y(:);
