
function [Tc,dT] = splineInter(T,omega,m,x,doDerivative)
         
% get data size m, cell size h, dimension d, and number n of interpolation points
dim = length(omega)/2; 
h   = (omega(2:2:end)-omega(1:2:end))./m; 
n   = length(x)/dim;    
x   = reshape(x,n,dim);
% map x from [h/2,omega-h/2] -> [1,m],
for i=1:dim, x(:,i) = (x(:,i)-omega(2*i-1))/h(i) + 0.5; end

Tc = zeros(n,1); dT = [];                   % initialize output
if doDerivative, dT = zeros(n,dim);  end    % allocate memory in column format
% BIG-fix 2011
Valid = @(j) (-1<x(:,j) & x(:,j)<m(j)+2);   % determine indices of valid points

valid = find( Valid(1) & Valid(2) );   

if isempty(valid)                       
  if doDerivative
      dT = sparse(n,dim*n); 
  end % allocate memory incolumn format
  return; 
end

pad = 3; TP = zeros(m+2*pad);             % pad data to reduce cases

P = floor(x); x = x-P;                    % split x into integer/remainder
p = @(j) P(valid,j);

x1 = x(valid,1);
x2 = x(valid,2);

% increments for linearized ordering
i1 = 1; i2 = size(T,1)+2*pad;

b0  = @(j,xi) motherSpline(j,xi);         % shortcuts for the mother spline
db0 = @(j,xi) motherSpline(j+4,xi);


TP(pad+(1:m(1)),pad+(1:m(2))) = T;
clear T;
p  = (pad + p(1)) + i2*(pad + p(2) - 1);

T_t  = zeros(length(valid),1);

S1_1 = b0(4,x1+1);
S1_2 = b0(3,x1);
S1_3 = b0(2,x1-1);
S1_4 = b0(1,x1-2);

S2_1 = b0(4,x2+1);
S2_2 = b0(3,x2);
S2_3 = b0(2,x2-1);
S2_4 = b0(1,x2-2);

choose_S1 = @(j) choose_j(j,S1_1,S1_2,S1_3,S1_4);
choose_S2 = @(j) choose_j(j,S2_1,S2_2,S2_3,S2_4);

if doDerivative
   
    dT = zeros(n,dim);
    
    dT_1 = T_t;
    dT_2 = T_t;
    
    M1_1 = db0(4,x1+1);
    M1_2 = db0(3,x1);
    M1_3 = db0(2,x1-1);
    M1_4 = db0(1,x1-2);
    
    M2_1 = db0(4,x2+1);
    M2_2 = db0(3,x2);
    M2_3 = db0(2,x2-1);
    M2_4 = db0(1,x2-2);
     
    choose_M1 = @(j) choose_j(j,M1_1,M1_2,M1_3,M1_4);
    choose_M2 = @(j) choose_j(j,M2_1,M2_2,M2_3,M2_4);
    
end

for j1=-1:2                              
    for j2=-1:2
        K = TP(p+j1*i1+j2*i2);
        S1 = choose_S1(j1);
        S2 = choose_S2(j2);  
        T_t = T_t + K.*S1.*S2;
        if doDerivative
            M1 = choose_M1(j1);
            M2 = choose_M2(j2);
            dT_1 = dT_1 + K.*M1.*S2;
            dT_2 = dT_2 + K.*S1.*M2;
        end
    end
end
  
Tc(valid) = T_t;

if doDerivative
    dT(valid,1) = dT_1/h(1);
    dT(valid,2) = dT_2/h(2);
end
                                       
function Result = choose_j(j,P1,P2,P3,P4)

switch j
    case -1,  Result = P1;
    case 0,   Result = P2;
    case 1,   Result = P3;
    case 2,   Result = P4;
end