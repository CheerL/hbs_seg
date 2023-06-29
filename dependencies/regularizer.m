function [Sc,dS,d2S,a1,a2,a3] = regularizer(uc,omega,m,hd,alpha,beta,doDerivative)

persistent omegaOld mOld LDiag K1_1 K2_1 K1 K2 KT1 KT2 K11 K22 K12

dS = []; d2S = []; a1 = [];a2 = [];a3 = [];

build = isempty(mOld) || isempty(omegaOld) ...
    || length(mOld) ~= length(m) || length(omegaOld) ~= length(omega) ...
    || any(mOld ~= m) || any(omegaOld~=omega);
if build
    mOld = m; omegaOld = omega;
    [K1_1,K2_1] = generateKer(m,omega);
    [K1,K2] = generateKer_PQR(m,omega);
    [KT1,KT2] = generateKer_PQRT(m,omega);
    [K11,K22,K12] = generateKer_PQRT_diga(KT1,KT2);    
    LDiag = getDiffDiag(omega,m,alpha);
end


yc = reshape(uc,[m-1,2]);

[y11,y12] = computePQRv(yc(:,:,1),K1,K2);
[y21,y22] = computePQRv(yc(:,:,2),K1,K2);

y11 = y11+1;
y22 = y22+1;


r = y11.*y22-y12.*y21;


d2S.d2S1 = @(x,m) (alpha*hd)*ATAvector(x,m,K1_1,K2_1);
dS1   = d2S.d2S1(uc,m);
Sc1   = .5*dS1'*uc;


Sc2   = beta*hd/2*sum((r-1).^4./r.^2); 

Sc    = Sc1+Sc2;

if doDerivative
     
    d2sigmar = (2*(r-1).^2.*(r.^2+2*r+3))./(r.^4);
    d2S.d2S2  = @(p,m)...
        beta *hd/2*...
        BeltramiTermHessian_componentwise(p,m,d2sigmar,y11,y12,y21,y22,K1,K2,KT1,KT2);
    
    d2S.d2S    = @(p,m) d2S.d2S1(p,m)+d2S.d2S2(p,m);
          
    [a1,a2,a3] = getBeltramiTermTriDiag(m,hd,beta,y11,y12,y21,y22,d2sigmar,K11,K22,K12);
    
    a1 = a1+LDiag;
    a3 = a3+LDiag;
    
    dsigmar = (2*(r-1).^3.*(r+1))./(r.^3);
    dS2   = hd/2*BeltramiTermGradient_componentwise(beta,dsigmar,y11,y12,y21,y22,m,K1,K2,KT1,KT2);
   
    dS = dS1+dS2;

end


function [K1_1,K2_1] = generateKer(m,omega)
m = m./omega(2:2:end);

K1_1 = zeros(3,1,1);
K1_1(1,1,1,1)=-m(1)*m(1);
K1_1(2,1,1,1)=2*m(1)*m(1);
K1_1(3,1,1,1)=-m(1)*m(1);


K2_1 = zeros(1,3,1);
K2_1(1,1,1,1)=-m(2)*m(2);
K2_1(1,2,1,1)=2*m(2)*m(2);
K2_1(1,3,1,1)=-m(2)*m(2);


function [K1,K2] = generateKer_PQR(m,omega)

m = m./omega(2:2:end);

K = zeros(2,2,2);
K(:,:,1) = [0 1;0,-1];
K(:,:,2) = [1 0;-1 0];
K1 = m(1)*K;

K = zeros(2,2,2);
K(:,:,1) = [0 0;1 -1];
K(:,:,2) = [1 -1;0 0];
K2 = m(2)*K;

function [KT1,KT2] = generateKer_PQRT(m,omega)

m = m./omega(2:2:end);

K = zeros(2,2,2);
K(:,:,1) = [-1 0;1,0];
K(:,:,2) = [0 -1;0 1];
KT1 = m(1)*K;

K = zeros(2,2,2);
K(:,:,1) = [-1 1;0 0];
K(:,:,2) = [0 0;-1 1];
KT2 = m(2)*K;


function [K11,K22,K12] = generateKer_PQRT_diga(KT1,KT2)

K11 = KT1.*KT1;
K22 = KT2.*KT2;
K12 = KT1.*KT2;


%%%% Beltrami Term Gradient
function dsigmar = BeltramiTermGradient_componentwise(beta,dsigmar,l1,l2,l3,l4,m,K1,K2,KT1,KT2)

dsigmar = BeltramiTermOperator(dsigmar,m,'BTy',l1,l2,l3,l4,K1,K2,KT1,KT2);
dsigmar = beta*dsigmar;

%%%% Hessian of Beltrami Term * vector
function p = BeltramiTermHessian_componentwise(p,m,d2sigmar,l1,l2,l3,l4,K1,K2,KT1,KT2)

p = BeltramiTermOperator(p,m,'By',l1,l2,l3,l4,K1,K2,KT1,KT2);
p = BeltramiTermOperator(d2sigmar.*p,m,'BTy',l1,l2,l3,l4,K1,K2,KT1,KT2);  




function p = BeltramiTermOperator(p,m,flag,y11,y12,y21,y22,K1,K2,KT1,KT2)
        
    flag = sprintf('%s',flag);
    
switch flag
  case {'By'}
      
      p = reshape(p,[m-1,2]);
      
      [p11,p12] = computePQRv(p(:,:,1),K1,K2);
      [p21,p22] = computePQRv(p(:,:,2),K1,K2);
      
      p = y22.*p11-y21.*p12-y12.*p21+y11.*p22;
      
         
  case {'BTy'}
         
      c11 = compute_PQRTv_2(y22.*p,-y21.*p,m,KT1,KT2);
      c21 = compute_PQRTv_2(-y12.*p,y11.*p,m,KT1,KT2);
         
      p = [c11;c21];
     
end
        

%%%% get the diagnal element
function v = getDiffDiag(omega,m,alpha)

hd    = prod((omega(2:2:end)-omega(1:2:end))./m);
M = m;
m = m./omega(2:2:end);

v = alpha*hd*ones(prod(M-1),1)*(2*(sum(m.^2,2)));


function [c1,c2,c3] = getBeltramiTermTriDiag(m,hd,beta,y11,y12,y21,y22,d,K11,K22,K12)
 
d = beta*hd/2*d;

c1 = compute_PQR_diag_1(y22.*y22.*d,-2*y22.*y21.*d,y21.*y21.*d,m,K11,K22,K12);
c2 = compute_PQR_diag_1(-y22.*y12.*d,(y22.*y11+y21.*y12).*d,-y21.*y11.*d,m,K11,K22,K12);
c3 = compute_PQR_diag_1(y12.*y12.*d,-2*y12.*y11.*d,y11.*y11.*d,m,K11,K22,K12);

