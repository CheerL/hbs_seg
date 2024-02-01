function [ux, uy] = solve_u(I, J, map, vert, Op, boundary_pos, eta, k1, k2)
    [m, n] = size(I);
    num = m * n;
    
    k3 = 0.0;
    k4 = 0.0;

    E = speye(num);
    res_x = map(:,1) - vert(:,1);
    res_y = map(:,2) - vert(:,2);
    
%     FI = scatteredInterpolant(vert, I(:));
%     Imap = FI(map);
    
%     I = reshape(Imap, m, n);
%     J = colored_unit_disk;
    
%     [gIx, gIy] = gradient(I);
    [gJx, gJy] = gradient(J);
%     intp_diff = scatteredInterpolant(vert, I(:)-J(:));
%     diff = intp_diff(map);
    diff = J(:) - I(:);
    
    gx = reshape(gJx, [], 1);
    gy = reshape(gJy, [], 1);
    
    

    A = spdiags(eta * gx.^2, 0, num, num) + (k1+k3) * E - (k2+k4) * Op.laplacian;
    % B = spdiags(0 * gx .* gy, 0, num, num);
    C = spdiags(eta * gy.^2, 0, num, num) + (k1+k3) * E - (k2+k4) * Op.laplacian;

    s = - eta * diff .* gx - k3 * res_x + k4 * Op.laplacian * res_x;
    t = - eta * diff .* gy - k3 * res_y + k4 * Op.laplacian * res_y;

    % M = [A B ; B C];
    % f = [s ; t];
    ux = solveAXB_SP(A, s, boundary_pos);
    uy = solveAXB_SP(C, t, boundary_pos);
    ux(isnan(ux)) = 0;
    uy(isnan(uy)) = 0;

    % u = solveAXB_SP(M, f, [boundary_pos;boundary_pos]);
    % u(isnan(u)) = 0;
    
    % ux = u(1:num);
    % uy = u(num+1:2*num);
end