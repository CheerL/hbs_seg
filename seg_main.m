function [ map, smooth_mu, seg ] = seg_main(static,unit_disk,face,vert,init_map, hbs_mu,iteration)
%% Parameter settings
u_times = 20;
gaussian = [0,5];
eta = 1;
k1 = 0.1;
k2 = 15;
alpha = 1;  % similarity with mu_f 
beta = 0;   % similarity with HBS
delta = 0;    % grad of mu
lambda = 0.1;       % abs of mu
upper_bound = 0.9999;
% sigma = 1; % mu + grad mu (sigma)
% sigmaIncrease = 2; % Increase sigma within the process

%% Main Program

% Initialize parameters
warning('off','all')
c1 = 1;
c2 = 0;
stopcount = 0;
seg = Tools.move_pixels(unit_disk, vert, init_map);
inner_idx = unit_disk >= 0.5;
op = Mesh.mesh_operator(face,vert);
figure;

[m, n] = size(static);
outer_boundary_idx = any([vert(:, 1)==0, vert(:, 1) == (n-1), vert(:,2) == 0, vert(:,2)== (m-1)], 2);
landmark = find(outer_boundary_idx);
map = init_map;

% iterations
for k = 1:iteration
    % Compute modified demon descent and update the registration function (mu-subproblem)
    [temp_map,temp_seg] = compute_u(static,seg,vert,vert,op,u_times,gaussian,eta,k1,k2,c1,c2);
    Fx = scatteredInterpolant(vert,temp_map(:,1));
    Fy = scatteredInterpolant(vert,temp_map(:,2));
    temp_map = [Fx(map),Fy(map)];
    % temp_seg = Tools.move_pixels(unit_disk,vert,temp_map);
    % [u,map,seg] = compute_u(static,moving,vert,map,op,times,gaussian,eta,k1,k2,c1,c2);

    temp_mu = bc_metric(face,vert,temp_map,2);
    temp_mu = Tools.mu_chop(temp_mu,upper_bound);
    smooth_mu = smoothing(temp_mu,hbs_mu,op,alpha,beta,lambda,delta);
    smooth_mu = Tools.mu_chop(smooth_mu,upper_bound);
    map = lsqc_solver(face,vert,smooth_mu,landmark,temp_map(landmark,:));
    seg = Tools.move_pixels(unit_disk,vert,map);

    c1_old = c1;
    c2_old = c2;

    mid = (c1+c2)/2;
    tg = seg >= mid;
    bg = seg < mid;
    c1 = mean(static(tg));
    c2 = mean(static(bg));
    seg = c1*tg + c2*bg;

    if ((abs(c1-c1_old)<5e-4)&&(abs(c2-c2_old)<5e-4))
        stopcount = stopcount + 1;
    else
        stopcount = 0;
    end

    % Display intermediate results
    if mod(k,1)==0
        info = sprintf('Interation %i. C1: %f -(%f)-> %f, C2: %f -(%f)-> %f, stopcount %i',...
            k,c1_old,c1-c1_old,c1,c2_old,c2-c2_old,c2,stopcount);
        % subplot(1,4,1);
        % imshow(M);
        subplot(1,3,1);
        imshow(temp_seg);
        subplot(1,3,2);
        imshow(seg);
        hold on;
        Plot.pri_scatter(map(inner_idx,:)+[1,1]);
        hold off;
        xlabel(info);
        subplot(1,3,3);
        imshow(abs(static-seg));
        set(gcf,'unit','normalized','position',[0 0 1 1]);
        drawnow;
    end

    % Stopping criterion


    if stopcount==10 || k == iteration
        % imshow(abs(static - temp_moving))
        figure;
        imshow(seg)
        xlabel(['Iteration ',num2str(k),', stop'])
        set(gcf,'unit','normalized','position',[0 0 1 1]);
        drawnow;
        break
    end
end
end