function [MaxJacdet,MinJacdet,b_x1,b_x2]=plotresult(MLdata,n,YC,yRef,omega,m,xCenter,X,phi,xi,yi)

[K1,K2] = generateKer(m,omega);


T = MLdata{n}.T;
% R = MLdata{n}.R;

Tc = linearInter(T,omega,xCenter);
Tc = reshape(Tc,m);



yc = reshape(YC-yRef,[],2);
[y11,y12] = computePQRv(reshape(yc(:,1),m-1),K1,K2);
[y21,y22] = computePQRv(reshape(yc(:,2),m-1),K1,K2);

y11 = y11+1;
y22 = y22+1;
  
r = y11.*y22-y12.*y21;

MaxJacdet = max(r);
MinJacdet = min(r);


S = reshape(YC,[m-1,2]);
X(2:end-1,2:end-1,:)=S;
YC = X(:);

figure(1)
imshow(flipud(Tc'),[])

hold on
plot(xi,yi,'r-','LineWidth',2)

hold off

print -depsc Initial

figure(2)

l = contour(phi,1);
l = l+0.5;
imshow(flipud(Tc'))

hold on

yC = reshape(YC,[],2);
yc1 = reshape(yC(:,1),m+1);
yc2 = reshape(yC(:,2),m+1);

P1 = interp2(yc1,l(1,:),l(2,:));
P2 = interp2(yc2,l(1,:),l(2,:));

b_x1 = m(1)*P1+0.5;
b_x2 = m(2)-m(2)*P2-0.5;
plot(b_x1,b_x2,'g-','LineWidth',2)

print -depsc Result


figure(3)
Y = reshape(YC,[],2);
U = reshape(Y(:,1),m+1);
U = imresize(U,[65,65],'bilinear');
V = reshape(Y(:,2),m+1);
V = imresize(V,[65,65],'bilinear');
mesh(U,V,zeros(65,65));
% 
view([0 90]);
axis image
axis off

print -depsc Transformation



function [K1,K2] = generateKer(m,omega)

m = m./omega(2:2:end);

K = zeros(2,2,2);
K(:,:,1) = [0 1;0,-1];
K(:,:,2) = [1 0;-1 0];
K1 = m(1)*K;

K = zeros(2,2,2);
K(:,:,1) = [0 0;1 -1];
K(:,:,2) = [1 -1;0 0];
K2 = m(2)*K;