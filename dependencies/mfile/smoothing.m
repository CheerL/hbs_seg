function smooth_mu = smoothing(mu,hbs,Operator,inner_idx,alpha,beta,lambda,delta)
% Solve the linear system
% laplacian = Operator.laplacian;
if length(beta) == 2
    beta2 = beta(2);
    beta = beta(1);
else
    beta2 = 0;
end

face_inner_idx = Operator.v2f * inner_idx(:);
hbs_vector = beta * face_inner_idx + beta2 * (1-face_inner_idx);        

num = length(mu);
laplacian = Operator.v2f * Operator.laplacian * Operator.f2v;
A = (alpha+delta)*speye(num) + spdiags(hbs_vector,0,num,num) - 0.5*lambda*laplacian;
B = alpha * mu + hbs .* hbs_vector;
smooth_mu = solveAXB_SP(A,B);
% nmu = Smooth_Operator\abs(right_hand);
% smooth_mu = nmu.* right_hand ./ abs(right_hand);
end