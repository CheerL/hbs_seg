function bound = get_bound_by_matching(T, isshow)
alpha = 100;
beta  = 1000;
MinLevel = 3;
MaxLevel = 9;
m = [2^MaxLevel,2^MaxLevel];
omega = [0 1 0 1];

minlevel = 3;
maxlevel = 9;

dataT = double(flipud(T)');

MLdata = getMultileveldata(dataT,m,omega,MinLevel,MaxLevel);

Ker = 1/4*ones(2,2,1);

% % input prior image
% imshow(flipud((MLdata{MaxLevel}.T)'),[])
% [M,xi,yi] = roipoly;  % select a polygonal region by hand;
% phi = double(M);
% phi = flipud(phi)';

% square prior image
phi = zeros(m);
phi(m/4:3*m/4,m/4:3*m/4) = 1;
ki = 10;
xi = [m/ki,m*(ki-1)/ki,m*(ki-1)/ki,m/ki,m/ki];
yi = [m/ki,m/ki,m*(ki-1)/ki,m*(ki-1)/ki,m/ki];



% Level_iter = [];

for Level = MaxLevel-1:-1:MinLevel
    mLevel = m/(2^(MaxLevel-Level));
    
    Mask{Level+1}.phi=phi;
    phi = (phi(1:2:end-1,1:2:end-1)+phi(1:2:end-1,2:2:end)+phi(2:2:end,1:2:end-1)+phi(2:2:end,2:2:end))/4; 

end
Mask{MinLevel}.phi=phi;



tic
for Level = minlevel:maxlevel
    
    m = MLdata{Level}.m;
    hd = prod((omega(2:2:end)-omega(1:2:end))./m);
    T = MLdata{Level}.T;
    xc = getNodalGrid(omega,m);
    xCenter = getCellCenteredGrid(omega,m);
    yRef = xc;
    if Level == minlevel
        y0 = yRef;
    else
        X(2:end-1,2:end-1,:)=reshape(yc,[m/2-1,2]);
        Yc = X(:);
        xOld = getNodalGrid_2(omega,m/2);
        y0 = getNodalGrid_2(omega,m) + mfPu(Yc - xOld,omega,m/2);
        Y0 = reshape(y0,[m+1,2]);
        
        Y0(2:2:end,2:2:end,:)=0.5*(Y0(3:2:end,1:2:end-2,:)+Y0(1:2:end-2,3:2:end,:));
        
        Y0 = Y0(2:end-1,2:end-1,:);
        y0 = Y0(:);
    end
    
    X = getNodalGrid_1(omega,m);
    
    phi = Mask{Level}.phi;
    in = find(phi >= 0.5);
    out = find(phi < 0.5);
    
    if Level==minlevel
       c10 = sum(T(in))/length(in);
       c20 = sum(T(out))/length(out);
    else
       TC=computeTC(T,y0,yRef,omega,m,Ker,xCenter);
       c10 = sum(TC(in))/length(in);
       c20 = sum(TC(out))/length(out);
    end
    
    DR = zeros(prod(m),2);
    DR(in,1)  = 1;
    DR(out,2) = 1;
    DRT = DR';
    
%     [yc,c1,c2,iter,FC] = GaussNewton(T,m,omega,hd,alpha,beta,y0,yRef,xCenter,Ker,X,in,out,c10,c20,DR,DRT);
    [yc,c1,c2,~,~] = GaussNewton(T,m,omega,hd,alpha,beta,y0,yRef,xCenter,Ker,X,in,out,c10,c20,DR,DRT);
       
%     Level_iter = [Level_iter,iter];
end
% time = toc;

R = zeros(m);
R(in)  = c1;
R(out) = c2;

[b_x1,b_x2] = get_plotresult(MLdata,Level,yc,yRef,omega,m,xCenter,X,phi,isshow);
bound = flipud(Tools.real2complex(b_x1(3:end)', 2^MaxLevel-b_x2(3:end)'));
end