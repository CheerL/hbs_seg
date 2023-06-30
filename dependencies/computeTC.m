function TC=computeTC(T,YC,yRef,omega,m,Ker,xCenter)

TC = linearInter(T,omega,computePv(YC-yRef,m,Ker)+xCenter);
TC = reshape(TC,m);

