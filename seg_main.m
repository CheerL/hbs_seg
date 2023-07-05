function [map, smooth_mu, seg] = seg_main(static, unit_disk, face, vert, init_map, hbs_mu, P)

    %% Parameter settings
    seg_display = P.seg_display; %'';
    iteration = P.iteration; %100;
    u_times = P.u_times; %20;
    gaussian = P.gaussian; %[0, 5];
    eta = P.eta; %1;
    k1 = P.k1; %0.01;
    k2 = P.k2; %100;
    alpha = P.alpha; %1; % similarity with mu_f
    beta = P.beta; %0; % similarity with HBS
    delta = P.delta; %0; % grad of mu
    lambda = P.lambda; %0.1; % abs of mu
    upper_bound = P.upper_bound; %0.9999;
    % sigma = 1; % mu + grad mu (sigma)
    % sigmaIncrease = 2; % Increase sigma within the process

    %% Main Program

    % Initialize parameters
    warning('off', 'all')
    stopcount = 0;
    mid = 0.5;
    [m, n] = size(static);

    op = Mesh.mesh_operator(face, vert);
    inner_idx = unit_disk >= 0.5;
    outer_boundary_idx = any([vert == [0 0], vert == [n - 1,0], vert == [0,m-1], vert == [n-1, m - 1]], 2);
    % outer_boundary_idx = any([vert(:, 1) == 0, vert(:, 1) == (n - 1), vert(:, 2) == 0, vert(:, 2) == (m - 1)], 2);
    landmark = find(outer_boundary_idx);

    global best_loss;
    global best_map;

    if isempty(best_loss)
        best_loss = 1e9;
        best_map = init_map;
    end

    map = best_map;
    seg = Tools.move_pixels(unit_disk, vert, map);
    c1 = mean(static(seg >= mid));
    c2 = mean(static(seg < mid));
    seg = c1 * (seg >= mid) + c2 * (seg < mid);
    loss_list = [];

    figure;
    % iterations
    for k = 1:iteration
        % Compute modified demon descent and update the registration function (mu-subproblem)
        [temp_map, temp_seg] = compute_u(static, seg, vert, vert, op, u_times, gaussian, eta, k1, k2, c1, c2);
        Fx = scatteredInterpolant(vert, temp_map(:, 1));
        Fy = scatteredInterpolant(vert, temp_map(:, 2));
        temp_map = [Fx(map), Fy(map)];
        % temp_seg = Tools.move_pixels(unit_disk,vert,temp_map);
        % [u,map,seg] = compute_u(static,moving,vert,map,op,times,gaussian,eta,k1,k2,c1,c2);

        temp_mu = bc_metric(face, vert, temp_map, 2);
        temp_mu = Tools.mu_chop(temp_mu, upper_bound);
        smooth_mu = smoothing(temp_mu, hbs_mu, op, alpha, beta, lambda, delta);
        smooth_mu = Tools.mu_chop(smooth_mu, upper_bound);
        map = lsqc_solver(face, vert, smooth_mu, landmark, temp_map(landmark, :));
        seg = Tools.move_pixels(unit_disk, vert, map);

        c1_old = c1;
        c2_old = c2;

        mid = (c1 + c2) / 2;
        tg = seg >= mid;
        bg = seg < mid;
        c1 = mean(static(tg));
        c2 = mean(static(bg));
        seg = c1 * tg + c2 * bg;

        if ((abs(c1 - c1_old) < 1e-4) && (abs(c2 - c2_old) < 1e-4))
            stopcount = stopcount + 1;
        else
            stopcount = 0;
        end

        % Display intermediate results
        loss = norm(static - seg, 'fro');
        loss_list = cat(2, loss_list, loss);
        info_fmt = 'Interation %i\n C1: %.4f -> %.4f, C2: %.4f -> %.4f\n loss: %.3f, stopcount %i\n';
        info = sprintf(info_fmt, k, c1_old, c1, c2_old, c2, loss, stopcount);
        fprintf(info);

        if loss < best_loss
            best_loss = loss;
            best_map = map;
        end

        if mod(k, 1) == 0

            if seg_display ~= "none"
                % subplot(1,4,1);
                % imshow(M);
                subplot(1, 3, 1);
                % imshow(temp_seg);
                plot(loss_list);
                axis square;
                subplot(1, 3, 2);
                imshow(seg);
                hold on;
                Plot.pri_scatter(map(inner_idx, :) + [1, 1]);
                hold off;
                % imshow(temp_seg)
                xlabel(info);
                subplot(1, 3, 3);
                imshow(abs(static - seg));
                set(gcf, 'unit', 'normalized', 'position', [0 0 1 1]);
                drawnow;

                if seg_display ~= "" && endsWith(seg_display, '.png')
                    split_path = split(seg_display, '/');
                    seg_filename = split_path(end);
                    seg_detail_dir = replace(seg_display, seg_filename, 'detail');
                    if exist(seg_detail_dir, 'dir') == 0
                        mkdir(seg_detail_dir);
                    end
                    detail_filename = replace(seg_filename, '.png', ['_', num2str(k), '.png']);
                    seg_detail_path = join([seg_detail_dir, detail_filename], '/');
                    saveas(gcf, seg_detail_path);
                    saveas(gcf, seg_display);
                    Plot.plot_mesh(face, map)
                    saveas(gcf, replace(seg_display, '.png', '_mesh.png'));
                end

            end

        end

        % Stopping criterion
        if stopcount == 10 || k == iteration
            % imshow(abs(static - temp_moving))
            if seg_display ~= "none"
                figure;
                imshow(seg)
                xlabel(['Iteration ', num2str(k), ', stop'])
                set(gcf, 'unit', 'normalized', 'position', [0 0 1 1]);
                drawnow;

                if seg_display ~= "" && endsWith(seg_display, '.png')
                    seg_path = replace(seg_display, '.png', ['_final.png']);
                    saveas(gcf, seg_path);
                end

            end

            break
        end

    end

end
