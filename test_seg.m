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
[face,vert] = Mesh.rect_mesh(m,n,0);
op = Mesh.mesh_operator(face,vert);
outer_boundary_idx = any([vert(:, 1)==0, vert(:, 1) == (n-1), vert(:,2) == 0, vert(:,2)== (m-1)], 2);
landmark = find(outer_boundary_idx);
temp_moving = moving;
idx = moving>=0.5;
map = vert;


iteration = 200;
times = 20;
eta = 1;
k1 = 0.01;
k2 = 10;
alpha = 1;  % similarity with mu_f 
beta = 0;   % similarity with HBS
delta = 0.0;    % grad of mu
lambda = 0.0;       % abs of mu
gaussian = [0,3];


for i=1:iteration
    [u,seg_vert,seg] = compute_u(static,temp_moving,vert,op,times,gaussian,eta,k1,k2);
    Fx = scatteredInterpolant(vert,seg_vert(:,1));
    Fy = scatteredInterpolant(vert,seg_vert(:,2));
    map = [Fx(map),Fy(map)];
    
    temp_mu = bc_metric(face,vert,map,2);
    temp_mu = Tools.mu_chop(temp_mu,upper_bound);
    smooth_mu = smoothing(temp_mu,0,op,alpha,beta,lambda,delta);
    smooth_mu = Tools.mu_chop(smooth_mu,upper_bound);

    map = lsqc_solver(face,vert,smooth_mu,landmark,vert(landmark,:));
%     temp_moving = Tools.move_pixels(temp_moving,vert,smooth_vert);
%     temp_moving = Tools.move_pixels(temp_moving,vert,smooth_vert);
    temp_moving = Tools.move_pixels(moving,vert,map);

    mid = (c1+c2)/2;
    tg = temp_moving >= mid;
    bg = temp_moving < mid;
    c1 = mean(static(tg));
    c2 = mean(static(bg));
    temp_moving = c1*tg + c2*bg;
%     temp_moving2 = c1*(temp_moving2>=mid)+c2*(temp_moving2<mid);

    subplot(2,2,1);
    imshow(abs(temp_moving-static));
    subplot(2,2,2);
%     hold on;
    imshow(temp_moving);
%     Plot.pri_scatter(map(idx,:));
%     hold off;
    subplot(2,2,3);
    hold on;
    imshow(temp_moving);
    Plot.pri_scatter(map(idx,:));
    hold off;
    subplot(2,2,4);
%     hold on;
    imshow(seg);
%     Plot.pri_scatter(map(idx,:));
%     hold off;
    drawnow;

    fprintf('%d %f %f\n', i, c1, c2);
end