addpath('./dependencies');
addpath('./dependencies/im2mesh');
addpath('./dependencies/mfile');
addpath('./dependencies/aco-v1.1/aco');
addpath('./dependencies/map/map');
close all;

m = 256;
n = 256;
bound_point_num = 500;
circle_point_num = 1000;
hbs_mesh_density = 60;
smooth_eps = 5e-3;
mu_upper_bound = 0.9999;
input_dir = 'img/hbs_seg/brains/type2/';
mean_img_path = 'img/hbs_seg/mean_brain.png';
mean_hbs_path = 'img/hbs_seg/mean_brain.mat';


[face, vert] = Mesh.rect_mesh(m, n, 0);
mesh_density = min([m, n] / 4);
normal_vert = (vert - [n / 2, m / 2]) ./ mesh_density;
unit_disk = zeros(m, n);
unit_disk(Tools.norm(normal_vert) <= (1 + smooth_eps)) = 1;

start_num = 1;
num = 7;
hbs_cell = cell(num, 1);
hbs_mu_cell = cell(num, 1);
reconstructed_cell = cell(num, 1);
map_cell = cell(num, 1);

for i=start_num:start_num+num-1
static_path = [input_dir, num2str(i), '.png'];
img_path = [input_dir, num2str(i), 'm.png'];

if ~isfile(static_path) || ~isfile(img_path)
    continue
end

img = Mesh.imread(img_path);
img = double(img >= 0.5);
img = imresize(img, [m,n]);

static = Mesh.imread(static_path);
static = imresize(static, [m,n]);



%% Compute HBS and initial map
bound = Mesh.get_bound(img, bound_point_num);
[hbs, ~, ~, ~, disk_face, disk_vert, ~] = HBS(bound, circle_point_num, hbs_mesh_density);
[reconstructed_bound, inner, outer, extend_vert, ~] = HBS_reconstruct(hbs, disk_face, disk_vert, m, n, mesh_density);

extend_map = Tools.complex2real([reconstructed_bound; inner; outer]);
interp_map_x = scatteredInterpolant(extend_vert, extend_map(:, 1));
interp_map_y = scatteredInterpolant(extend_vert, extend_map(:, 2));
normal_map = [interp_map_x(normal_vert), interp_map_y(normal_vert)];
hbs_mu = bc_metric(face, normal_vert, normal_map, 2);
hbs_mu = Tools.mu_chop(hbs_mu, mu_upper_bound);

map = normal_map .* mesh_density + [n, m] / 2;
% reconstructed_bound = Tools.complex2real(reconstructed_bound) .* mesh_density + [n, m] / 2;
init_moving = double(Tools.move_pixels(unit_disk, vert, map) >= 0.5);

figure;
set(gcf, 'unit', 'normalized', 'position', [0 0 1 1]);
sp1 = subplot(1, 3, 1);
imshow(static);
hold on;
contour(img, 1, 'EdgeColor', 'g', 'LineWidth', 1);
hold off;
sp2 = subplot(1, 3, 2);
imshow(fliplr(init_moving'));
subplot(1, 3, 3);
Plot.pri_plot_mu(hbs_mu, face, vert);
colormap(sp1, "gray");
colormap(sp2, "gray");
drawnow;
saveas(gcf, replace(mean_img_path, 'mean', int2str(i)));

hbs_cell{i} = hbs;
hbs_mu_cell{i} = hbs_mu;
reconstructed_cell{i} = init_moving;
map_cell{i} = map;
end

mean_hbs = zeros(size(hbs));
count = 0;
for i=start_num:start_num+num-1
    if size(hbs_cell{i})
        mean_hbs = mean_hbs + hbs_cell{i};
        count = count + 1;
    end
end
mean_hbs = mean_hbs / count;

[reconstructed_bound, inner, outer, extend_vert, ~] = HBS_reconstruct(mean_hbs, disk_face, disk_vert, m, n, mesh_density);

extend_map = Tools.complex2real([reconstructed_bound; inner; outer]);
interp_map_x = scatteredInterpolant(extend_vert, extend_map(:, 1));
interp_map_y = scatteredInterpolant(extend_vert, extend_map(:, 2));
normal_map = [interp_map_x(normal_vert), interp_map_y(normal_vert)];
hbs_mu = bc_metric(face, normal_vert, normal_map, 2);
hbs_mu = Tools.mu_chop(hbs_mu, mu_upper_bound);

map = normal_map .* mesh_density + [n, m] / 2;
% reconstructed_bound = Tools.complex2real(reconstructed_bound) .* mesh_density + [n, m] / 2;
init_moving = double(Tools.move_pixels(unit_disk, vert, map) >= 0.5);

f1 = figure;
set(gcf, 'unit', 'normalized', 'position', [0 0 1 1]);
% sp1 = subplot(1, 3, 1);
% imshow(static);
% hold on;
% contour(img, 1, 'EdgeColor', 'g', 'LineWidth', 1);
% hold off;
sp2 = subplot(1, 3, 2);
imshow(fliplr(init_moving'));
subplot(1, 3, 3);
Plot.pri_plot_mu(hbs_mu, face, vert);
colormap(sp1, "gray");
colormap(sp2, "gray");
drawnow;
saveas(f1, mean_img_path);
save(mean_hbs_path, 'mean_hbs', 'hbs_mu');

