addpath('./dependencies');
addpath('./dependencies/im2mesh');
addpath('./dependencies/mfile');
addpath('./dependencies/aco-v1.1/aco');
addpath('./dependencies/map/map');
close all;

k=1;
c1 = 1.0;
c2 = 0.0;
upper_bound = 0.9999;

% static = Mesh.imread('img/hbs_seg/img2.png');
% moving = Mesh.imread('img/hbs_seg/tp3.png');
% static = imresize(static, [256*k,256*k]);
% moving = imresize(moving, [256*k,256*k]);
% static = c1*(static >= 0.5);
% moving = c1*(moving >= 0.5);


% [m,n] = size(static);
% bound_point_num = 500;
% circle_point_num = 1000;
% hbs_mesh_density = 50;
% smooth_eps = 0;
% iteration = 500;
% mu_upper_bound = 0.9999;
% bound = Mesh.get_bound(moving, bound_point_num);

% %% Compute HBS and initial map
% k = 4;
% % m = k*m;
% % n = k*n;
% mesh_density = min([m,n]/4);
% [hbs, he, ~, ~, disk_face, disk_vert, ~] = HBS(bound, circle_point_num, hbs_mesh_density);

%%%%%%%%%%%%%%%%%%%
% [reconstructed_bound, inner, outer, extend_vert, extend_face] = HBS_reconstruct(hbs, disk_face, disk_vert, m/2, n/2, mesh_density/2);

% [face, vert] = Mesh.rect_mesh(k*m, k*n, 0);
% normal_vert = (vert - (k*[n, m]-1)/2) ./ (k*mesh_density);


% extend_map = Tools.complex2real([reconstructed_bound;inner;outer]);

% interp_map_x = scatteredInterpolant(extend_vert,extend_map(:, 1));
% interp_map_y = scatteredInterpolant(extend_vert,extend_map(:, 2));
% normal_map = [interp_map_x(normal_vert),interp_map_y(normal_vert)];

% unit_disk = zeros(k*m, k*n);
% unit_disk(Tools.norm(normal_vert)<=(1+smooth_eps)) = 1;

% map = normal_map .* (k*mesh_density) + (k*[n, m]-1)/2;
% reconstructed_bound = Tools.complex2real(reconstructed_bound) .* (k*mesh_density) + (k*[n, m]-1)/2;
% init_moving = Tools.move_pixels(unit_disk, normal_vert, normal_map);

% hbs_mu = bc_metric(face, normal_vert, normal_map, 2);
% hbs_mu = Tools.mu_chop(hbs_mu, mu_upper_bound);
n = 200;
[disk_face, disk_vert] = Mesh.rect_mesh(n, n, 1);
dis = 1/(n-1);
x = disk_vert(:,1);
y = disk_vert(:,2);
z = x + 1i*y;
zt = x - 1i*y;
he = x.^3 - 1*y.^3 + 5i * x .* y.^2 - 1i * x.^2 .* y + 3*x.^2 .* y;
% he = z.^2 - 1*zt.^2 + 0*1i * z .* zt;
% he = (x+1i*y).^3;
% he = x.^2 - 2*y.^2 + 3i * x .* y;
% p = 0.6+0.6i;
% he = (he-p)./(1-conj(p)*he);
[dx,dy] = gradient(reshape(he,n,n), dis);
dz = (dx - 1i*dy)/2;
dp = (dx + 1i*dy)/2;
hbs_p = dp ./ dz;
hbs_p = hbs_p(:);

hbs = bc_metric(disk_face, disk_vert, Tools.complex2real(he), 2);
Op = Mesh.mesh_operator(disk_face, disk_vert);
hbs_v = Op.f2v * hbs;

log_hbs = log(hbs_v);
% hbs_v = log(hbs_v);
% hbs_v(1) = hbs_v(2);
% lp_he = Op.laplacian * he;
lp_he = del2(reshape(he,n,n), dis);
% lp_hbs = Op.laplacian * hbs_v;
lp_hbs = del2(reshape(log_hbs,n,n), dis);
% lp_hbs_imag = Op.laplacian * imag(hbs_v);
lp_hbs_imag = del2(reshape((imag(log_hbs)),n,n), dis);
% lp_hbs_real = Op.laplacian * real(hbs_v);
lp_hbs_real = del2(reshape((real(log_hbs)),n,n), dis);

mean(abs(lp_he), 'all')
mean(abs(lp_hbs), 'all')
mean(abs(lp_hbs_imag), 'all')
mean(abs(lp_hbs_real), 'all')
% Display init_moving, map and mu
% figure;
% sp1 = subplot(1,3,1);
% imshow(init_moving)
% hold on;
% Plot.pri_scatter(reconstructed_bound);
% % plot(real(reconstructed_bound), imag(reconstructed_bound), 'g','LineWidth',1);
% subplot(1,3,2);
% Plot.pri_plot_mesh(face, map);
% subplot(1,3,3);
% Plot.pri_plot_mu(hbs_mu, face, vert);
% colormap(sp1, "gray");
% set(gcf,'unit','normalized','position',[0 0 1 1])
% Plot.imshow(init_moving);
% drawnow();

