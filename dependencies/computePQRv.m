function [P,Q] = computePQRv(p,K1,K2)


P1 = reshape(convn(p,K1(:,:,1)),[],1);
P2 = reshape(convn(p,K1(:,:,2)),[],1);

P = cat(1,P1,P2);



P1 = reshape(convn(p,K2(:,:,1)),[],1);
P2 = reshape(convn(p,K2(:,:,2)),[],1);

Q = cat(1,P1,P2);

