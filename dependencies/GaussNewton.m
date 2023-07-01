

function  [yc,c1,c2,iter,FC] = GaussNewton(T,m,omega,hd,alpha,beta,yc,yRef,xCenter,Ker,X,in,out,c1,c2,DR,DRT)
maxIter = 500;
tolJ = 1e-3;
tolY = 1e-2;
tolG = 1e-2;

T = getSplineCoefficients(T,'inter','splineInter','regularizer','moments','theta',1);

func = @(yc,c1,c2) NPIRobjFctn(T,omega,m,hd,yRef,yc,alpha,beta,Ker,xCenter,in,out,c1,c2,DR,DRT);

iter = 0;
Jstop = func(yRef,0,0);
[Jc,dJ,H,Tri] = func(yc,c1,c2);
Jold  = Jc;
y0 = yc;
yOld = 0*yc;
c10 = c1;
c20 = c2;
c1old = 0;
c2old = 0;

FC = [];
FC = [FC,Jc];

while 1
  % check stopping rules
  STOP(1) = (iter>0) && abs(Jold-Jc)  <= tolJ*(1+abs(Jstop));
  STOP(2) = (iter>0) && (norm([yc;c1;c2]-[yOld;c1old;c2old]) <= tolY*(1+norm([y0;c10;c20])));
  STOP(3) = norm(dJ)      <= tolG*(1+abs(Jstop));
  STOP(4) = norm(dJ)      <= 1e6*eps;
  STOP(5) = (iter >= maxIter);
  if all(STOP(1:3)) || any(STOP(4:5))
      break;  
  end

  iter = iter + 1;
  dy = solveGN(-dJ,H,Tri);

  descent =   dJ' * dy; 
  if descent > 0
    warning('no descent direction, switch to -dy!')
    dy      = -dy;
  end

  [t,yt,c1t,c2t] = lineSearch(func,yc,dy,Jc,dJ,m,omega,X,yRef,c1,c2);
  if (t == 0)
      break; 
  end  
  
  yOld = yc; Jold = Jc; yc = yt; c1old = c1; c2old = c2; c1 = c1t; c2=c2t;  
  [Jc,dJ,H,Tri] = func(yc,c1,c2);

  FC = [FC,Jc];
   
end 



end

function dy = solveGN(rhs,H,Tri)
maxIterCG = 50; tolCG = 1e-1;

[dy,flag,relres,iter] = minres(H,rhs,tolCG,maxIterCG,Tri);

end