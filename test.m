addpath('./dependencies');
addpath('./dependencies/im2mesh');
addpath('./dependencies/mfile');
addpath('./dependencies/aco-v1.1/aco');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
boundary_point_num = 200;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

m = 10; n = 10;
num = m*n;
Ix = rand(m,n);
Iy = rand(m,n);
ux = rand(m,n);
uy = rand(m,n);
a = 2;

[f,v] = Mesh.rect_mesh(m,n);
op = Mesh.mesh_operator(f,v);

L = op.laplacian;

s = Ix(:).*Ix(:).*ux(:) + Ix(:).*Iy(:).*uy(:) + a*ux(:) - a*L*ux(:);
t = Ix(:).*Iy(:).*ux(:) + Iy(:).*Iy(:).*uy(:) + a*uy(:) - a*L*uy(:);

E = speye(num);
Rx3 = (E.*(Ix(:).*Ix(:)+a)-a*L)*ux(:)+E.*(Ix(:).*Iy(:))*uy(:);
Ry3 = (E.*(Iy(:).*Iy(:)+a)-a*L)*uy(:)+E.*(Ix(:).*Iy(:))*ux(:);
A = E.*(Ix(:).*Ix(:)+a)-a*L;
B = E.*(Ix(:).*Iy(:));
C = E.*(Ix(:).*Iy(:));
D = E.*(Iy(:).*Iy(:)+a)-a*L;

y = (D-C/A*B) \ (t - C/A*s);
x = (A-B/D*C) \ (s - B/D*t);

r = solveAXB_SP([A,B;C,D],[s;t]);
