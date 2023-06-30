function [u,map,moving] = compute_u(static,init_moving,vert,init_map,op,times,gaussian_params,eta,k1,k2,c1,c2)
[m,n] = size(static);
moving=init_moving;
map = init_map;
mid = (c1+c2)/2;

for i=1:times
    if vert ~= map
        moving = Tools.move_pixels(init_moving, vert, map);
        moving = c1*(moving>=mid)+c2*(moving<mid);
    end
    [ux,uy] = solve_u(static,moving,op,eta,k1,k2);
    ux(isnan(ux))=0;
    uy(isnan(uy))=0;
    ux = reshape(ux,[m,n]);
    uy = reshape(uy,[m,n]);
    if gaussian_params(1) > 0
        uxs = gaussian_params(2)*imgaussfilt(ux, gaussian_params(1));
        uys = gaussian_params(2)*imgaussfilt(uy, gaussian_params(1));
    else
        uxs = gaussian_params(2) * ux;
        uys = gaussian_params(2) * uy;
    end

    Fx = scatteredInterpolant(vert,uxs(:));
    Fy = scatteredInterpolant(vert,uys(:));
    map = map + [Fx(map),Fy(map)];
%     map = map + [uxs(:),uys(:)];
end
u = map - vert;
end
