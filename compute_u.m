function [map,moving] = compute_u(static,init_moving,vert,init_map,op,times,gaussian_params,eta,k1,k2,c1,c2)
[m,n] = size(static);
map = init_map;
mid = (c1+c2)/2;

if vert == init_map
    method = 1;
    moving = init_moving;
else
    method = 2;
    moving = Tools.move_pixels(init_moving, vert, map);
    moving = c1*(moving>=mid)+c2*(moving<mid);
end
    

for i=1:times
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
    
    if method == 1
        map = map + [uxs(:),uys(:)];
    else
        Fx = scatteredInterpolant(vert,uxs(:));
        Fy = scatteredInterpolant(vert,uys(:));
        map = map + [Fx(map),Fy(map)];
    end
    moving = Tools.move_pixels(init_moving, vert, map);
    moving = c1*(moving>=mid)+c2*(moving<mid);
end
end
