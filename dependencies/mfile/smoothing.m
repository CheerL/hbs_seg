function smooth_mu = smoothing(mu,hbs,Operator,alpha,beta,lambda,delta)
% Solve the linear system
% laplacian = Operator.laplacian;
laplacian = Operator.v2f * Operator.laplacian * Operator.f2v;
A = (alpha+beta+delta)*speye(length(mu)) - 0.5*lambda*laplacian;
B = alpha * mu + beta * hbs;
smooth_mu = solveAXB_SP(A,B);
% nmu = Smooth_Operator\abs(right_hand);
% smooth_mu = nmu.* right_hand ./ abs(right_hand);
end