function [ux,uy] = solve_u(I, J, Op, eta, k1,k2)
[m,n] = size(I);
num = m*n;

[Ix,Iy] = gradient(I);
[Jx,Jy] = gradient(J);
Ix = Ix(:); Iy = Iy(:);
Jx = Jx(:); Jy = Jy(:);

E = speye(num);
diff = J(:)-I(:);

A_diag = (Ix.^2+Iy.^2);
% A = eta*E.*A_diag;
A = spdiags(eta*A_diag,0,num,num);
A = A + k1*E-k2*Op.laplacian;
% B = eta*E.*Ixy;
% C = B;
% D = eta*E.*Iyy + k1*E-k2*Op.laplacian;
% B_inv = E.*Ixy_inv / eta;
% C_inv = B_inv;

% s = eta*diff.*Ix;
% t = eta*diff.*Iy;
% s = eta*(I(:).*Ix-IJx(:));
% t = eta*(I(:).*Iy-IJy(:));
s = eta*diff.*(Ix+Jx)/2;
t = eta*diff.*(Iy+Jy)/2;


% left_x = C-D*B_inv*A;
% right_x = t - D*B_inv*s;
% ux = solveAXB_SP(left_x, right_x);
% left_y = B-A*C_inv*D;
% right_y = s - A*C_inv*t;
% uy = solveAXB_SP(left_y, right_y);
ux = solveAXB_SP(A,s);
uy = solveAXB_SP(A,t);
end

% function [ux,uy] = solve_u(I, J, Op, eta, k1,k2)
% [m,n] = size(I);
% num = m*n;
% 
% [Ix,Iy] = gradient(I);
% [Jx,Jy] = gradient(J);
% % [IJx,IJy] = gradient(I.*J);
% 
% Ix = Ix(:); Iy = Iy(:);
% Jx = Jx(:); Jy = Jy(:);
% Ixx = Ix.*Ix;
% Iyy = Iy.*Iy;
% Ixy = Ix.*Iy;
% % Ixy_inv = 1./(Ixy+eps);
% 
% E = speye(num);
% diff = J(:)-I(:);
% 
% A = spdiags(eta*Ixx,0,num,num) + k1*E-k2*Op.laplacian;
% B = spdiags(eta*Ixy,0,num,num);
% C = B;
% D = spdiags(eta*Iyy,0,num,num) + k1*E-k2*Op.laplacian;
% % B_inv = E.*Ixy_inv / eta;
% % C_inv = B_inv;
% 
% % s = eta*diff.*Ix;
% % t = eta*diff.*Iy;
% % s = eta*(I(:).*Ix-IJx(:));
% % t = eta*(I(:).*Iy-IJy(:));
% s = eta*diff.*(Ix+Jx);
% t = eta*diff.*(Iy+Jy);
% 
% 
% % left_x = C-D*B_inv*A;
% % right_x = t - D*B_inv*s;
% % ux = solveAXB_SP(left_x, right_x);
% % left_y = B-A*C_inv*D;
% % right_y = s - A*C_inv*t;
% % uy = solveAXB_SP(left_y, right_y);
% r = solveAXB_SP([A,B;C,D],[s;t]);
% ux = r(1:num);
% uy = r(num+1:end);
% end