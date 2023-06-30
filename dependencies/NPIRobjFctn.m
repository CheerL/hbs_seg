
function [Jc,dJ,H,Tri] = NPIRobjFctn(T,omega,m,hd,yRef,yc,alpha,beta,Ker,xCenter,in,out,c1,c2,DR,DRT)

doDerivative = (nargout>=2);           

R = zeros(m);
R(in)  = c1;
R(out) = c2;

% compute interpolated image and derivative, formally: center(yc) = P*yc
[Tc,dT] = splineInter(T,omega,m,computePv(yc-yRef,m,Ker)+xCenter,doDerivative);

% compute distance measure
[Dc,rc,dD,dres,d2psi,dc1,dc2,d2c1,d2c2] = SSD(Tc,R(:),hd,doDerivative,in,out,c1,c2);

% compute regularizer
[Sc,dS,d2S,a1,a2,a3] = regularizer(yc-yRef,omega,m,hd,alpha,beta,doDerivative);

% evaluate joint function and return if no derivatives need to be computed
Jc = Dc + Sc;

if ~doDerivative
    return; 
end

s = dD';
dD = computePTv([dT(:,1).*s;dT(:,2).*s],m,Ker);

dJ = [(dD + dS);dc1;dc2];
H  = @(x) Hessianproduct(dT,x,m,Ker,d2psi,d2S,d2c1,d2c2,DR,DRT);

[C1,C2,C3] = getFittingTermTriDiagonal(m,Ker,d2psi,dT);
Tri = @(x) computeTriPreconditioner(C1+a1,C2+a2,C3+a3,d2c1,d2c2,x);
  

function Result = Hessianproduct(dT,x,m,Ker,d2psi,d2S,d2c1,d2c2,DR,DRT)

x1 = x(1:end-2);
x2 = x(end-1:end);

w1 = computePv(x1,m,Ker);
w1 = reshape(w1,[],2);
w1 = sum(dT.*w1,2);

w2 = DR*x2;

w = w1-w2;
r1 = d2psi*computePTv([dT(:,1).*w;dT(:,2).*w],m,Ker)+d2S.d2S(x1,m);

r2 = [d2c1*x(end-1);d2c2*x(end)]-d2psi*DRT*w1;

Result = [r1;r2];

