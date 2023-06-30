addpath('./dependencies');
addpath('./dependencies/im2mesh');
addpath('./dependencies/mfile');
addpath('./dependencies/aco-v1.1/aco');
close all;

k=1;
c1 = 1.0;
c2 = 0.0;
upper_bound = 0.9999;

static = Mesh.imread('img/hbs_seg/img1.png');
moving = Mesh.imread('img/hbs_seg/tp1.png');
static = imresize(static, [256*k,256*k]);
moving = imresize(moving, [256*k,256*k]);
static = c1*(static >= 0.5);
moving = c1*(moving >= 0.5);


[m,n] = size(static);
bound_point_num = 500;
circle_point_num = 1000;
hbs_mesh_density = 50;
smooth_eps = 0;
iteration = 500;
mu_upper_bound = 0.9999;
bound = Mesh.get_bound(moving, bound_point_num);

%% Compute HBS and initial map
[face, vert] = Mesh.rect_mesh(m, n, 0);
mesh_density = min([m,n]/4);
normal_vert = (vert - ([n, m]-1)/2) ./ mesh_density;

[hbs, ~, ~, ~, disk_face, disk_vert, ~] = HBS(bound, circle_point_num, hbs_mesh_density);
[reconstructed_bound, inner, outer, extend_vert, extend_face] = HBS_reconstruct(hbs, disk_face, disk_vert, m, n, mesh_density);
extend_map = Tools.complex2real([reconstructed_bound;inner;outer]);

interp_map_x = scatteredInterpolant(extend_vert,extend_map(:, 1));
interp_map_y = scatteredInterpolant(extend_vert,extend_map(:, 2));
normal_map = [interp_map_x(normal_vert),interp_map_y(normal_vert)];
hbs_mu = bc_metric(face, normal_vert, normal_map, 2);
hbs_mu = Tools.mu_chop(hbs_mu, mu_upper_bound);

unit_disk = zeros(m, n);
unit_disk(Tools.norm(normal_vert)<=(1+smooth_eps)) = 1;

map = normal_map .* mesh_density + ([n, m]-1)/2;
reconstructed_bound = Tools.complex2real(reconstructed_bound) .* mesh_density + ([n, m]-1)/2;
init_moving = Tools.move_pixels(unit_disk, normal_vert, normal_map);

% Display init_moving, map and mu
figure;
sp1 = subplot(1,3,1);
imshow(init_moving)
hold on;
Plot.pri_scatter(reconstructed_bound);
% plot(real(reconstructed_bound), imag(reconstructed_bound), 'g','LineWidth',1);
subplot(1,3,2);
Plot.pri_plot_mesh(face, map);
subplot(1,3,3);
Plot.pri_plot_mu(hbs_mu, face, vert);
colormap(sp1, "gray");
set(gcf,'unit','normalized','position',[0 0 1 1])
drawnow();
