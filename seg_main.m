function [map, smooth_mu, seg] = seg_main(static, unit_disk, face, vert, init_map, hbs_mu, P)

    %% Parameter settings
    seg_display = P.seg_display;
    iteration = P.iteration;
    u_times = P.u_times;
    gaussian = P.gaussian;
    eta = P.eta;
    k1 = P.k1;
    k2 = P.k2;
    k3 = P.k3;
    alpha = P.alpha;                % similarity with mu_f
    beta = P.beta;                  % similarity with HBS
    delta = P.delta;                % grad of mu
    lambda = P.lambda;              % abs of mu
    upper_bound = P.upper_bound;

    if isfield(P, 'show_mu')
        show_mu = P.show_mu;
    else
        show_mu = 0;
    end

    if isfield(P, 'reverse_image') && P.reverse_image
        show_static = 1 - static;
    else
        show_static = static;
    end

    % Initialize parameters
    warning('off', 'all')
    stopcount = 0;
    mid = 0.5;
    [m, n] = size(static);

    op = Mesh.mesh_operator(face, vert);
    inner_idx = unit_disk >= 0.5;
    landmark = find(vert(:, 1) == 0 | vert(:, 1) == n - 1 | vert(:, 2) == 0 | vert(:, 2) == m - 1);
    % landmark = find((vert(:, 1) == 0 & vert(:, 2) == 0) ...
    %               | (vert(:, 1) == 0 & vert(:, 2) == m-1) ...
    %               | (vert(:, 1) == n-1 & vert(:, 2) == 0) ...
    %               | (vert(:, 1) == n-1 & vert(:, 2) == m-1));
    % landmark = find((vert(:, 1) == round(n/2) & vert(:, 2) == round(m/2)) ...
    %                |(vert(:, 1) == round(n/2+mesh_density) & vert(:, 2) == round(m/2)));
    % targets = [0, 0; n-1, 0; 0, m-1; n-1, m-1];

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

    f1 = figure;
    set(f1, 'unit', 'normalized', 'position', [0 0 1 1]);

    f2 = figure;
    % iterations
    for k = 1:iteration
        % Compute modified demon descent and update the registration function (mu-subproblem)
        [temp_map, temp_seg] = compute_u(static, seg, vert, vert, op, u_times, gaussian, eta, k1, k2, k3, c1, c2);
        Fx = scatteredInterpolant(vert, temp_map(:, 1));
        Fy = scatteredInterpolant(vert, temp_map(:, 2));
        temp_map = [Fx(map), Fy(map)];
        % temp_seg = Tools.move_pixels(unit_disk,vert,temp_map);
        % [u,map,seg] = compute_u(static,moving,vert,map,op,times,gaussian,eta,k1,k2,c1,c2);

        temp_mu = bc_metric(face, vert, temp_map, 2);
        temp_mu = Tools.mu_chop(temp_mu, upper_bound);
        smooth_mu = smoothing(temp_mu, hbs_mu, op, inner_idx, alpha, beta, lambda, delta);
        smooth_mu = Tools.mu_chop(smooth_mu, upper_bound);
        map = lsqc_solver(face, vert, smooth_mu, landmark, init_map(landmark, :));
        % map = lsqc_solver(face, vert, smooth_mu, landmark, targets);
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
        info_fmt = 'Interation %i of %s \n C1: %.4f -> %.4f, C2: %.4f -> %.4f\n loss: %.3f, stopcount %i\n';
        info = sprintf(info_fmt, k, P.config_name, c1_old, c1, c2_old, c2, loss, stopcount);
        fprintf(info);

        if loss < best_loss
            best_loss = loss;
            best_map = map;
        end

        if mod(k, 1) == 0
            if seg_display ~= "none"
                figure(f1);
                sp1 = subplot(2, 3, 1);
                % imshow(temp_seg);
                colormap("gray");
                plot(loss_list);
                axis square;

                sp2 = subplot(2, 3, 2);
                imshow(seg);
                % imshow(temp_seg)
                xlabel(info);

                sp3 = subplot(2, 3, 3);
                % imshow(abs(static - seg));
                imshow(show_static);
                hold on;
                contour(seg, 1, 'EdgeColor', 'g', 'LineWidth', 1);
                contour(temp_seg, 1, 'EdgeColor', 'r', 'LineWidth', 1);
                hold off;

                sp4 = subplot(2, 3, 4);
                imshow(seg);
                hold on;
                Plot.pri_scatter(map + [1, 1], 2);
                hold off;

                if show_mu
                    subplot(2, 3, 5);
                    Plot.pri_plot_mu(temp_mu, face, vert);
                    subplot(2, 3, 6);
                    Plot.pri_plot_mu(smooth_mu, face, vert);
                end

                colormap(sp1, 'gray');
                colormap(sp2, 'gray');
                colormap(sp3, 'gray');
                colormap(sp4, 'gray');
                drawnow;

                if seg_display ~= "" && endsWith(seg_display, '.png')
                    figure(f2);
                    imshow(show_static);
                    hold on;
                    contour(temp_seg, 1, 'EdgeColor', 'g', 'LineWidth', 1);
                    hold off;

                    result_path = seg_display;
                    result_seg_path = replace(result_path, '.png', '.seg.png');

                    splited_result_path_list = split(result_path, '/');
                    result_filename = splited_result_path_list(end);
                    iter_result_dir = replace(result_path, result_filename, 'detail');
                    if ~exist(iter_result_dir, 'dir')
                        mkdir(iter_result_dir);
                    end
                    
                    iter_result_path = join([iter_result_dir, result_filename], '/');
                    iter_result_path = replace(iter_result_path, '.png', ['_', num2str(k), '.png']);
                    iter_result_seg_path = replace(iter_result_path, '.png', '.seg.png');

                    saveas(f1, result_path);
                    saveas(f2, result_seg_path);
                    copyfile(result_path, iter_result_path);
                    copyfile(result_seg_path, iter_result_seg_path);

                    if loss <= best_loss
                        best_result_path = replace(result_path, '.png', '.best.png');
                        best_result_seg_path = replace(result_seg_path, '.png', '.best.png');
                        copyfile(result_path, best_result_path);
                        copyfile(result_seg_path, best_result_seg_path);
                    end
                end

            end

        end

        % Stopping criterion
        if stopcount == 10 || k == iteration
            if seg_display ~= "none"
                Plot.imshow(show_static);
                hold on;
                contour(seg, 1, 'EdgeColor', 'g', 'LineWidth', 1);
                hold off;
                drawnow;

                if seg_display ~= "" && endsWith(seg_display, '.png')
                    saveas(gcf, replace(seg_display, '.png', '_final.png'));
                end

            end

            break
        end

    end

end
