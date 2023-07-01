addpath('./dependencies');
addpath('./dependencies/im2mesh');
addpath('./dependencies/mfile');
addpath('./dependencies/aco-v1.1/aco');
addpath('./dependencies/map/map');
close all;

k=1;
upper_bound = 0.9999;

static = Mesh.imread('img/hbs_seg/img1.png');
static = imresize(static, [256*k,256*k]);

[m,n] = size(static);
[face,vert] = Mesh.rect_mesh(m,n,0);
op = Mesh.mesh_operator(face,vert);
outer_boundary_idx = any([vert(:, 1)==0, vert(:, 1) == (n-1), vert(:,2) == 0, vert(:,2)== (m-1)], 2);
landmark = find(outer_boundary_idx);

moving = Mesh.imread('img/hbs_seg/tp1.png');  
moving = imresize(moving, [256*k,256*k]);
% init_map = vert;
% load('mv.mat');
% moving = unit_disk;
static = double(static >= 0.5);
moving = double(moving >= 0.5);

HBS_seg(static,moving);

% seg_main(static,moving,face,vert,init_map,0,200);
% iteration = 200;
% times = 20;
% eta = 1;
% k1 = 0.05;
% k2 = 40;
% alpha = 1;  % similarity with mu_f 
% beta = 0;   % similarity with HBS
% delta = 0.0;    % grad of mu
% lambda = 0.1;       % abs of mu
% gaussian = [0,5];

% if exist('best_i', 'var')
%     init_map = best_map;
% elseif exist('init_map', 'var')
%     best_map = init_map;
%     best_loss = 1e10;
%     best_i = 0;
% end
% 
% map = init_map;
% temp_moving = Tools.move_pixels(moving,vert,best_map);
% mid = 0.5;
% c1 = mean(static(temp_moving>=mid));
% c2 = mean(static(temp_moving<mid));
% temp_moving = c1*(best_moving>=mid)+c2*(best_moving<mid);
% 
% for i=1:iteration
%     [seg_vert,seg] = compute_u(static,temp_moving,vert,vert,op,times,gaussian,eta,k1,k2,c1,c2);
%     Fx = scatteredInterpolant(vert,seg_vert(:,1));
%     Fy = scatteredInterpolant(vert,seg_vert(:,2));
%     map = [Fx(map),Fy(map)];
% %     [u,map,seg] = compute_u(static,moving,vert,map,op,times,gaussian,eta,k1,k2,c1,c2);
% 
% 
%     temp_mu = bc_metric(face,vert,map,2);
%     temp_mu = Tools.mu_chop(temp_mu,upper_bound);
%     smooth_mu = smoothing(temp_mu,0,op,alpha,beta,lambda,delta);
%     smooth_mu = Tools.mu_chop(smooth_mu,upper_bound);
% 
%     map = lsqc_solver(face,vert,smooth_mu,landmark,map(landmark,:));
% %     temp_moving = Tools.move_pixels(temp_moving,vert,smooth_vert);
% %     temp_moving = Tools.move_pixels(temp_moving,vert,smooth_vert);
%     temp_moving = Tools.move_pixels(moving,vert,map);
% 
%     mid = (c1+c2)/2;
%     tg = temp_moving >= mid;
%     bg = temp_moving < mid;
%     c1 = mean(static(tg));
%     c2 = mean(static(bg));
%     temp_moving = c1*tg + c2*bg;
% %     temp_moving2 = c1*(temp_moving2>=mid)+c2*(temp_moving2<mid);
% 
%     subplot(1,3,1);
%     imshow(abs(temp_moving-static));
%     subplot(1,3,2);
%     hold on;
%     imshow(temp_moving);
%     Plot.pri_scatter(map(idx,:)+[1,1]);
%     hold off;
%     subplot(1,3,3);
% %     hold on;
%     imshow(seg);
% %     Plot.pri_scatter(map(idx,:));
% %     hold off;
%     drawnow;
%     loss = norm(static-temp_moving, 'fro');
%     fprintf('%d %f %f %f\n', i, c1, c2, loss);
%     if loss < best_loss
%         best_moving = temp_moving;
%         best_loss = loss;
%         best_map = map;
%         best_i = i;
%     end
% 
% end