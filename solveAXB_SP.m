function x = solveAXB_SP(A, B)
    %used for solving AX = B, X is [row*col,1];
    %only works for squire matrix.
    %by ys.

    %additional A is sparse.
    iteration = 100;
    % A_bak = A;
    x0 = sparse(size(A, 1), 1);
    x = x0;
    r = B - A * x;
    p = r;
    r_norm = r' * r;

    for i = 1:iteration
        % rb = r;
        % rb(bd) = 0;
        % p = A * rb;
        % %  mini residual
        % % alpha = (p' * r) / (p' * p + eps);
        % % steepest descent
        % alpha = (r' * r) / (p' * r + eps);
        % dx = alpha * rb;
        % dr = alpha * p;
        % dr_norm = norm(dr);
        % if dr_norm < 1e-6
        %     break
        % end

        % x = x + dx;
        % r = r - dr;

        % CG method
        Ap = A * p;
        pAp = p' * Ap;
        % rAp = r' * Ap;
        alpha = r_norm / (pAp + eps);
        dx = alpha * p;
        dr = alpha * Ap;
        dr_norm = norm(dr);
        if dr_norm < 1e-6
            break
        end
        x = x + dx;
        r = r - dr;
        r_norm_new = r' * r;
        beta = r_norm_new / (r_norm + eps);
        % beta = (r_norm_new * rAp ) / (r_norm * pAp + eps);
        p = r + beta * p;
        r_norm = r_norm_new;
    end
end