function [ map, smooth_mu, seg ] = seg_main(static,unit_disk,face,vert,init_map, hbs_mu,iteration)
%% Parameter settings
u_times = 20;
gaussian_params = [1,1];
eta = 1;
k1 = 0.5;
k2 = 0.5;
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
seg = Tools.move_pixels(unit_disk, vert, init_map) >= 0.5;
op = Mesh.mesh_operator(face,vert);
figure;

[m, n] = size(static);
outer_boundary_idx = any([vert(:, 1)==0, vert(:, 1) == (n-1), vert(:,2) == 0, vert(:,2)== (m-1)], 2);
landmark = find(outer_boundary_idx);
map = init_map;

% iterations
for k = 1:iteration

    % Update the moving image
    c1_old = c1;
    c2_old = c2;
    mid = (c1+c2)/2;

    % Compute modified demon descent and update the registration function (mu-subproblem)

    % [M,Tx,Ty] = simple_demon(seg,static,demon_iteration,gaussian_size,method,sigma,eta_inside,eta_outside);
    local_moving = seg;
    local_map = vert;

    for i=1:u_times
        [ux,uy] = solve_u(static,local_moving,op,eta,k1,k2);
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
        uxs = Fx(local_map);
        uys = Fy(local_map);
        local_map = local_map + [uxs,uys];
        local_moving = Tools.move_pixels(local_moving, vert, local_map);
        local_moving = c1*(local_moving>=mid)+c2*(local_moving<mid);

        u = [Fx(map),Fy(map)];
        map = map + u;
        temp_seg = Tools.move_pixels(unit_disk, vert, map);
        temp_seg = c1*(temp_seg>=mid)+c2*(temp_seg<mid);
        
        subplot(1,2,1);
        imshow(local_moving);
        subplot(1,2,2);
        imshow(temp_seg);
        drawnow;
        % local_moving = temp_seg;
        % Tx = Tx+uxs;
        % Ty = Ty+uys;
        % moving = movepixels(init_moving,-Ty,-Tx);
    end
    % [~,map,temp_seg] = compute_u(static,seg,vert,map,op,u_times,gaussian_params,eta,k1,k2);
    % Fx = scatteredInterpolant(vert,ux(:));
    % Fy = scatteredInterpolant(vert,uy(:));
    % ux = Fx(map);
    % uy = Fy(map);
    % map = map(:,1:2) + [ux,uy];
    % temp_seg = Tools.move_pixels(unit_disk, vert, map);
    temp_mu = bc_metric(face,vert,map,2);

    % Smoothens the Beltrami coefficient (nu-subproblem)
    % delta = delta + sigmaIncrease;
    smooth_mu = Tools.mu_chop(temp_mu,upper_bound);
    smooth_mu = smoothing(smooth_mu,hbs_mu,op,alpha,beta,lambda,delta);
    smooth_mu = Tools.mu_chop(smooth_mu,upper_bound);
    map = lsqc_solver(face,vert,smooth_mu,landmark,map(landmark,:));

    % Update the template image
    seg = Tools.move_pixels(unit_disk, vert, map);

    % % Rebuild original template image
    % Bheight = (reshape(-inverse_vector(:,2),size(static)));
    % Bwidth  = (reshape(-inverse_vector(:,1),size(static)));
    % ori_moving = movepixels(temp_moving,Bheight,Bwidth);

    % Update c_1, c_2
    object = seg >= mid;
    background = seg < mid;
    c1 = mean(static(object), "all");
    c2 = mean(static(background), "all");
    seg = c1*object + c2*background;

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
        imshow(temp_seg > 0.5);
        subplot(1,3,2);
        imshow(seg);
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