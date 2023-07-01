function [ map, mu, seg, moving ] = HBS_seg(static, moving)
%
%
% This program computes the segmentation of an input image based on the QC model.
% Only input argument "static" is essential.
%
% Input:
% static             m x n, grayscale input image in [0, 1]
% moving             binary template image
%
% Outpt:
% map                QC registration function from moving to static
% map_mu             pointwise Beltrami coefficient of the registration
% seg                deformed moving image

%% Initializations
[m,n] = size(static);
bound_point_num = 500;
circle_point_num = 1000;
hbs_mesh_density = 50;
smooth_eps = 0;
iteration = 500;
mu_upper_bound = 0.9999;
mesh_density = min([m,n]/4);

%% Compute HBS and initial map
bound = Mesh.get_bound(moving, bound_point_num);

[face, vert] = Mesh.rect_mesh(m, n, 0);
normal_vert = (vert - [n/2, m/2]) ./ mesh_density;


[hbs, ~, ~, ~, disk_face, disk_vert, ~] = HBS(bound, circle_point_num, hbs_mesh_density);
[reconstructed_bound, inner, outer, extend_vert, ~] = HBS_reconstruct(hbs, disk_face, disk_vert, m, n, mesh_density);
extend_map = Tools.complex2real([reconstructed_bound;inner;outer]);

interp_map_x = scatteredInterpolant(extend_vert,extend_map(:, 1));
interp_map_y = scatteredInterpolant(extend_vert,extend_map(:, 2));
normal_map = [interp_map_x(normal_vert),interp_map_y(normal_vert)];
hbs_mu = bc_metric(face, normal_vert, normal_map, 2);
hbs_mu = Tools.mu_chop(hbs_mu, mu_upper_bound);

unit_disk = zeros(m, n);
unit_disk(Tools.norm(normal_vert)<=(1+smooth_eps)) = 1;

map = normal_map .* mesh_density + [n, m]/2;
reconstructed_bound = Tools.complex2real(reconstructed_bound) .* mesh_density + [n,m]/2;
init_moving = Tools.move_pixels(unit_disk, vert, map) >= 0.5;

% Display init_moving, map and mu
figure;
sp1 = subplot(1,3,1);
imshow(static)
hold on;
% contour(moving,[0,1],'g','LineWidth',2);
Plot.pri_scatter(bound);
plot(real(bound), imag(bound), 'g','LineWidth',1);
hold off;

sp2 = subplot(1,3,2);
imshow(init_moving)
hold on;
Plot.pri_scatter(reconstructed_bound);
plot(real(reconstructed_bound), imag(reconstructed_bound), 'g','LineWidth',1);
% Plot.pri_plot_mesh(face, map);
hold off;

subplot(1,3,3);
Plot.pri_plot_mu(hbs_mu, face, vert);
colormap(sp1, "gray");
colormap(sp2, "gray");
set(gcf,'unit','normalized','position',[0 0 1 1])
drawnow();

%% Transform initial moving
params = [1.491131e+00 6.309427e+00 2.828952e-03 1.312800e-02];
[scaling, rotation, a, b] = get_transformation_params(static,init_moving,params);
% [scaling, rotation, a, b] = get_transformation_params(static, init_moving);
rotation_matrix = [cos(rotation),sin(rotation);-sin(rotation),cos(rotation)];
updated_map = (map-[n,m]/2)*rotation_matrix*scaling+[a,b]*max(m,n)/2+[n,m]/2;
updated_moving = Tools.move_pixels(unit_disk, vert, updated_map) >= 0.5;

% figure;
% subplot(1,3,1)
% imshow(static);
% subplot(1,3,2);
% imshow(updated_moving);
% subplot(1,3,3);
% imshow(abs(static - updated_moving));
% set(gcf,'unit','normalized','position',[0 0 1 1])
% drawnow();


%% Compute the object boundary (Main Program)

% 1st time computation
[map,mu,seg] = seg_main(static,unit_disk,face,vert,updated_map,hbs_mu,iteration);

% Operator = meshOperator(vert,face);
% map_mu = reshape(Operator.f2v*map_mu,m,n);

% Re-initialize the algorithm if required
% if regrid
%     u = reshape(map(:,1),size(static));
%     v = reshape(map(:,2),size(static));
%     for ii = 1:regrid
%         pause(0.01)
%         figure
%         [ux,uy] = gradient(u); [vx,vy] = gradient(v);
%         tau = ((ux+vy)-1i*(vx-uy))./((ux+vy)+1i*(vx-uy));
%         map_mu_p = map_mu;
%         for kk = 1:numel(boundary_ind)
%             [~,boundary_ind{kk}] = ismember(round(map(boundary_ind{kk},1:2)),vertex(:,1:2),'rows');
%         end
%         [map,map_mu,reg] = registration_v2(reg,static,10);
%         map_mu = Operator.f2v*map_mu;
%         mu_comp_f = interp2(reshape(vertex(:,1),size(static)),reshape(vertex(:,2),size(static)),reshape(map_mu,size(static)),u,v);
%         mu_comp_f = reshape(mu_comp_f,size(tau));
%         map_mu = (map_mu_p+mu_comp_f.*tau)./(ones(size(tau))+conj(map_mu_p).*mu_comp_f.*tau);
%         u = scatteredInterpolant(u(:),v(:),map(:,1)); u = reshape(u.Values,size(static));
%         v = scatteredInterpolant(u(:),v(:),map(:,2)); v = reshape(v.Values,size(static));
%     end
%     map = [u(:),v(:)];
% end

%% Display final output

% % Plot the grid
% figure
% [x,y] = meshgrid(0:size(static,1)-1,0:size(static,2)-1);
% f = delaunay(x,y);
% mesh = makeMesh([map(:,1),-map(:,2)],f);
% plotMesh(mesh)
% set(gcf,'units','normalized','outerposition',[0 0.15 1 0.85])

% Plot the image
% figure
% reg(reg>=0.2)=1;
% reg(reg<0.2)=0;
% showphi(static,reg,'end')
% imshow(static)
% hold on
% for ii = 1:numel(boundary_ind)
%     boundary_ind{ii} = [boundary_ind{ii};boundary_ind{ii}(1,:)];
% end
% plot(map(boundary_ind{1},1),map(boundary_ind{1},2),'g','LineWidth',2)
% contour(reg,[min(reg, [], [1,2]),max(reg, [], [1,2])],'g','LineWidth',2);
% set(gcf,'units','normalized','outerposition',[0 0.15 1 0.85])
% xlabel('Final segmentation result')
%%
end

function [scaling,rotation,a,b] = get_transformation_params(static, moving, params)
s = 256;
[m, n] = size(static);
if nargin == 3
    scaling = params(1);
    rotation = params(2);
    a = params(3);
    b = params(4);
else
    if m ~= n
        static = Mesh.pad2square(static);
        moving = Mesh.pad2square(moving);
    end

    if max(m, n) ~= s
        static = imresize(static, [s, s]);
        moving = imresize(moving, [s, s]);
    end
    static = cast(static*255, 'uint8');
    moving = cast(moving*255, 'uint8');

    url = 'http://aws.cheerl.space:8880/get_params';
    data = struct('static', static, 'moving', moving);
    json = jsonencode(data);
    options = weboptions('MediaType', 'application/json');
    options.Timeout = 300;
    response = webwrite(url, json, options);
    scaling = response(1);
    rotation = response(2);
    a = response(3);
    b = response(4);
    fprintf('%d %d %d %d\n', scaling, rotation, a, b)
end
end
