function smooth_mu = smoothing(mu,hbs,op,inner_idx,tao,lambda,alpha,beta,eta)
% Solve the linear system
% laplacian = Operator.laplacian;
% face_inner_idx = Operator.v2f * inner_idx(:);
[m,n] = size(mu);
mu = mu(:);
nu = mu;
iteration = 100;
e0 = nu_energy(nu,mu,hbs,op,alpha,beta,lambda,eta,tao,m,n);
best_e = e0;
best_nu = nu;

for i = 1:iteration
    if i < 10
        step = 1;
    elseif i < 20
        step = 0.25;
    elseif i < 40
        step = 0.1;
    end
    
    g = nu_gradient(nu,mu,hbs,op,alpha,beta,lambda,eta,tao,m,n);
    abs_g = max(abs(g));
    if abs_g > 1
        g = g / (10*abs_g);
    elseif abs_g < 1e-5
        break
    end
    nu = nu - g * step;
    e = nu_energy(nu,mu,hbs,op,alpha,beta,lambda,eta,tao,m,n);

    if e < best_e
        best_nu = nu;
        best_e = e;
    end
end
smooth_mu = best_nu;
% nmu = Smooth_Operator\abs(right_hand);
% smooth_mu = nmu.* right_hand ./ abs(right_hand);
end

function smooth_mu = smoothing2(mu,hbs,Operator,inner_idx,alpha,beta,lambda,delta)
% Solve the linear system
% laplacian = Operator.laplacian;
if length(beta) == 2
    beta2 = beta(2);
    beta = beta(1);
else
    beta2 = 0;
end

% face_inner_idx = Operator.v2f * inner_idx(:);
hbs_vector = beta * inner_idx + beta2 * (1-inner_idx);
num = length(mu);
laplacian = Operator.laplacian;
A = (alpha+delta)*speye(num) + spdiags(hbs_vector,0,num,num) - 0.5*lambda*laplacian;
B = alpha * mu + hbs .* hbs_vector;
smooth_mu = solveAXB_SP(A,B);
% nmu = Smooth_Operator\abs(right_hand);
% smooth_mu = nmu.* right_hand ./ abs(right_hand);
end

function e = nu_energy(nu,mu,hbs,op,alpha,beta,lambda,eta,tao,m,n)
    [gx_nu,gy_nu] = gradient(reshape(nu,m,n));
    harmonic_term = del2(reshape(angle(nu), m,n));
    e = [norm(nu);
        norm([gx_nu,gy_nu], 'fro');
        norm(nu-hbs);
        norm(harmonic_term, 'fro');
        norm(nu - mu)];
    e = [alpha,beta,lambda,eta,tao] * e.^2;
end

function g = nu_gradient(nu,mu,hbs,op,alpha,beta,lambda,eta,tao,m,n)
nu_matrix = reshape(nu, m, n);
harmonic_term = (1i * reshape(del2(del2(angle(nu_matrix))), m*n,1)) ./ conj(nu);
harmonic_term(nu==0) = 0;

% harmonic_term2 = reshape(del2(del2(angle(nu_matrix))), m*n,1) .* imag(1 ./ nu);
% harmonic_term2(isnan(harmonic_term2)) = 0;


% g = [nu, reshape(del2(nu_matrix),m*n,1), hbs, mu, harmonic_term];
g = [nu, op.laplacian * nu, hbs, mu, harmonic_term];
g = g * [alpha + lambda + tao; -beta; -lambda; -tao; eta]; 
end