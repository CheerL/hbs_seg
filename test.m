addpath('./dependencies');
addpath('./dependencies/im2mesh');
addpath('./dependencies/mfile');
addpath('./dependencies/aco-v1.1/aco');
addpath('./dependencies/map/map');

static = Mesh.imread('img/hbs_seg/img3.png');
static = imresize(static, [256,256]);
[m, n] = size(static);
[face, vert] = Mesh.rect_mesh(m, n, 0);
op = Mesh.mesh_operator(face, vert);
normal_vert = (vert - [128, 128]) ./ 45;
unit_disk = zeros(m, n);
unit_disk(Tools.norm(normal_vert) <= (1 + 1e-5)) = 1;

eta = 1;
k1 = 0.000;
k2 = 1;

map = vert;

% target_color = mean(static(seg>=0.5),'all');
% background_color = mean(static(seg<0.5), 'all');
[seg, target_color, background_color] = Tools.move_seg(unit_disk,vert,map,static);
landmark = vert(:, 1) == 0 | vert(:, 1) == n - 1 | vert(:, 2) == 0 | vert(:, 2) == m - 1;

for i=1:200
[new_map, ~] = compute_u( ...
    static, seg, unit_disk, vert, map, landmark, ...
    op, [0, 1], eta, k1, k2, target_color, background_color ...
    );

e1 = u_energy(static,seg,new_map - map, map, vert, eta, k1, k2);
e2 = u_energy(static,seg,map-map, map, vert, eta, k1, k2);
e3 = u_energy(static,seg,new_map-new_map, new_map, vert, eta, k1, k2);
[e1, e2, e3]

[seg, target_color, background_color] = Tools.move_seg_inv(unit_disk,vert,new_map,static);
imshow(seg);
map = new_map;
end




function [ux,uy] = solve_u2(I, J, map, vert, op, landmark, eta, k1, k2, times, step)
n = size(map, 1);
u = zeros(n, 2);
for i=1:times
    g = u_gradient(I, J, u, op, landmark, eta, k1, k2);
    u = u - step * g;
    e = u_energy(I, J, u, eta, k1, k2)
end
ux = u(:, 1);
uy = u(:, 2);
end

function g = u_gradient(I, J, u, op, landmark, eta, k1, k2)
[gIx, gIy] = gradient(I);
gIx = gIx(:);
gIy = gIy(:);

a = I(:) - J(:) + gIx .* u(:, 1) + gIy .* u(:, 2);
g = eta * a.* [gIx,gIy] + k1 * u - k2 * op.laplacian * u;
g(landmark) = 0;
end

function e = u_energy(I, J, u, map, vert, eta, k1, k2)
[m,n] = size(I);

intp_diff = scatteredInterpolant(vert, I(:)-J(:));
diff = intp_diff(map);
[gdx, gdy] = gradient(reshape(diff, m, n));
    
gx = reshape(gdx, [], 1);
gy = reshape(gdy, [], 1);

ux = reshape(u(:,1),m,n);
uy = reshape(u(:,2),m,n);
[guxx, guxy] = gradient(ux);
[guyx, guyy] = gradient(uy);

% intp = scatteredInterpolant(vert,I(:)-J(:));
% r = intp(map);

term1 = diff + gx .* u(:,1) + gy .* u(:,2);
term2 = u;
term3 = [guxx(:),guxy(:),guyx(:),guyy(:)];

e = eta*norm(term1,'fro') + k1*norm(term2,'fro') + k2 * norm(term3,'fro');
end

function map = u2map(u, map, vert)
    Fx = scatteredInterpolant(vert, u(:,1) + vert(:,1));
    Fy = scatteredInterpolant(vert, u(:,2) + vert(:,2));
    map = [Fx(map), Fy(map)];
end