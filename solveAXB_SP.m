function x = solveAXB_SP(A, B, boundary_pos)
    %used for solving AX = B, X is [row*col,1];
    %only works for squire matrix.
    %by ys.
    n = size(A, 1);
    if nargin == 2
        boundary_pos = [];
    end
    %additional A is sparse.
    iteration = 200;
    x0 = sparse(n, 1);
    x = x0;
    r = B - A * x;
    p = r;

    for i = 1:iteration
        % CG method
        p(boundary_pos) = 0;
        Ap = A * p;
        pAp = p' * Ap;
        alpha = (r' * p) / (pAp + eps);
        dx = alpha * p;
        dr = alpha * Ap;
        x = x + dx;
        r = r - dr;
        % r_norm_old = r_norm;
        r_norm = r' * r;
        % beta = r_norm / (r_norm_old + eps);
        beta = -(r' * Ap) / (pAp + eps);
        p = r + beta * p;

        if r_norm < 1e-6
            break
        end
        
    end
end