function [map, smooth_mu, seg] = seg_main(static, unit_disk, face, vert, init_map, hbs_mu, P)
    %% Parameter settings
    seg_display = P.seg_display;
    iteration = P.iteration;
    gaussian = P.gaussian;
    eta = P.eta;
    seta = P.seta;
    k1 = P.k1;
    k2 = P.k2;
    alpha = P.alpha;                % similarity with mu_f
    beta = P.beta;                  % similarity with HBS
    delta = P.delta;                % grad of mu
    lambda = P.lambda;              % abs of mu
    upper_bound = P.upper_bound;
    contour_width = P.contour_width;
    smooth_x_window = P.smooth_window(1);
    smooth_y_window = P.smooth_window(2);
    before_nu = P.force_before_nu;

    if isfield(P, 'compare')
        compare = double(imresize(Mesh.imread(P.compare), [256,256]));
    else
        compare = static;
    end

    if isfield(P, 'show_mu')
        show_mu = P.show_mu;
    else
        show_mu = 0;
    end

    if isfield(P, 'reverse_image') && P.reverse_image
        show_static = 1 - static;
        compare = 1 - compare;
    else
        show_static = static;
    end

    % Initialize parameters
    warning('off', 'all')
    stopcount = 0;
    [m, n] = size(static);

    op = Mesh.mesh_operator(face, vert);
    inner_idx = unit_disk >= 0.5;
    landmark = vert(:, 1) == 0 | vert(:, 1) == n - 1 | vert(:, 2) == 0 | vert(:, 2) == m - 1;

    global best_loss;
    global best_map;

    if isempty(best_loss)
        best_loss = 1e9;
        best_map = init_map;
    end

    map = best_map;
    hbs_mu = op.f2v * hbs_mu;

    [seg, target_color, background_color] = Tools.move_seg(unit_disk,vert,map,static);
    % seg = Tools.move_pixels(unit_disk, vert, map);
    % target_color = mean(static(seg >= mid));
    % background_color = mean(static(seg < mid));
    % seg = target_color * (seg >= mid) + background_color * (seg < mid);
    loss_list = [];

    f1 = figure;
    set(f1, 'unit', 'normalized', 'position', [0 0 1 1]);

    f2 = figure;

    % iterations
    for k = 1:iteration
        % Compute modified demon descent and update the registration function (mu-subproblem)
        temp_map = map;
        temp_seg = seg;
        for kk = 1:P.u_times
        
        u = compute_u( ...
            static, temp_seg, unit_disk, vert, temp_map, landmark, ...
            op, gaussian, eta, k1, k2, target_color, background_color ...
        );
        temp_map_x_intp = scatteredInterpolant(u, vert(:,1));
        temp_map_y_intp = scatteredInterpolant(u, vert(:,2));
        temp_map = [temp_map_x_intp(temp_map),temp_map_y_intp(temp_map)];
        temp_seg = Tools.move_seg(unit_disk,vert,temp_map,static);
        end
        % temp_f_map_intp_x = scatteredInterpolant(temp_map, vert(:, 1));
        % temp_f_map_intp_y = scatteredInterpolant(temp_map, vert(:, 2));
        % temp_f_map = [temp_f_map_intp_x(vert), temp_f_map_intp_y(vert)];

        % temp_mu = bc_metric(face, vert, temp_map, 2);
        [gx_temp_map, gy_temp_map] = gradient(reshape(Tools.real2complex(temp_map),m,n));
        temp_mu = (gx_temp_map + 1i * gy_temp_map) ./ (gx_temp_map - 1i * gy_temp_map + 1e-10);
        temp_mu = Tools.mu_chop(temp_mu, upper_bound);
        if k < 5
            smooth_mu = smoothing(temp_mu, hbs_mu, op, inner_idx, alpha, beta, lambda, delta,0);
        else
            smooth_mu = smoothing(temp_mu, hbs_mu, op, inner_idx, alpha, beta, lambda, delta,seta);
        end
        smooth_mu = Tools.mu_chop(smooth_mu, upper_bound);
        map = lsqc_solver(face, vert, op.v2f * smooth_mu, find(landmark), init_map(landmark, :));
        % map = lsqc_solver(face, vert, op.v2f * smooth_mu, [zero_pos;one_pos], temp_map([zero_pos;one_pos], :));
        
        % map_intp_x = scatteredInterpolant(f_map, vert(:, 1));
        % map_intp_y = scatteredInterpolant(f_map, vert(:, 2));
        % map = [map_intp_x(vert), map_intp_y(vert)];

        target_color_old = target_color;
        background_color_old = background_color;
        % [seg, target_color, background_color] = Tools.move_seg_inv(unit_disk,vert,map,static);
        [seg, target_color, background_color] = Tools.move_seg(unit_disk,vert,map,static);

        if ((abs(target_color - target_color_old) < 1e-4) && (abs(background_color - background_color_old) < 1e-4))
            stopcount = stopcount + 1;
        else
            stopcount = 0;
        end

        % Display intermediate results
        loss = norm(compare - seg, 'fro');
        loss_list = cat(2, loss_list, loss);
        info_fmt = 'Interation %i of %s \n C1: %.4f -> %.4f, C2: %.4f -> %.4f\n loss: %.3f, stopcount %i\n';
        info = sprintf(info_fmt, k, P.config_name, target_color_old, target_color, background_color_old, background_color, loss, stopcount);
        fprintf(info);

        if loss < best_loss
            best_loss = loss;
            best_map = map;
        end
        
        if mod(k, 1) == 0
            if seg_display ~= "none"
                figure(f1);
                sp1 = subplot(2, 3, 1);
                colormap("gray");
                plot(loss_list);
                axis square;

                sp2 = subplot(2, 3, 2);
                imshow(temp_seg);   
                hold off;
                
                xlabel(info);

                sp3 = subplot(2, 3, 3);
                imshow(show_static);
                hold on;
                contour(seg, 1, 'EdgeColor', 'r', 'LineWidth', 1);
                contour(temp_seg, 1, 'EdgeColor', 'g', 'LineWidth', 1);
                hold off;

                sp4 = subplot(2, 3, 4);
                imshow(seg);
                hold on;
                Plot.pri_scatter(map(unit_disk == 1, :) + [1, 1], 2);
                Plot.pri_scatter(map(unit_disk == 0, :) + [1, 1], 2);
                hold off;

                if show_mu
                    subplot(2, 3, 5);
                    Plot.pri_plot_mu(op.v2f * temp_mu(:), face, vert);
                    subplot(2, 3, 6);
                    Plot.pri_plot_mu(op.v2f * smooth_mu(:), face, vert);
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
                    if (before_nu || P.beta == 0)
                    Plot.pri_smooth_contour(temp_seg,smooth_x_window,smooth_y_window,'g',contour_width);
                    else
                    Plot.pri_smooth_contour(seg,smooth_x_window,smooth_y_window,'g',contour_width);
                    end
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
                        % saveas(f1, best_result_path);
                        % saveas(f2, best_result_seg_path);
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
                Plot.pri_smooth_contour(temp_seg,smooth_x_window,smooth_y_window,'g',contour_width);
                % contour(temp_seg, 1, 'EdgeColor', 'g', 'LineWidth', contour_width);
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
