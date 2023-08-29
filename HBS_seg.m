function [map, mu, seg, moving] = HBS_seg(static, moving, P)
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
    

    bound_point_num = P.bound_point_num;
    circle_point_num = P.circle_point_num;
    hbs_mesh_density = P.hbs_mesh_density;
    smooth_eps = P.smooth_eps;
    mu_upper_bound = P.upper_bound;
    init_image_display = P.init_image_display;
    recounstruced_bound_display = P.recounstruced_bound_display;

    if isfield(P, 'distort_bound')
        distort_bound = P.distort_bound;
    else
        distort_bound = 0;
    end

    [m, n] = size(static);
    [face, vert] = Mesh.rect_mesh(m, n, 0);
    mesh_density = min([m, n] / 4);
    normal_vert = (vert - [n / 2, m / 2]) ./ mesh_density;
    unit_disk = zeros(m, n);
    unit_disk(Tools.norm(normal_vert) <= (1 + smooth_eps)) = 1;


    %% Compute HBS and initial map
    

    if size(moving, 2) ~= 1
        bound = Mesh.get_bound(moving, bound_point_num);
        [hbs, ~, ~, ~, disk_face, disk_vert, ~] = HBS(bound, circle_point_num, hbs_mesh_density);
    else
        hbs = moving;
        circle_interval = (2 / circle_point_num)*pi;
        [disk_face, disk_vert] = Mesh.unit_disk_mesh(hbs_mesh_density, circle_interval);
    end
    
    [reconstructed_bound, inner, outer, extend_vert, ~] = HBS_reconstruct(hbs, disk_face, disk_vert, m, n, mesh_density);
    extend_map = Tools.complex2real([reconstructed_bound; inner; outer]);

    interp_map_x = scatteredInterpolant(extend_vert, extend_map(:, 1));
    interp_map_y = scatteredInterpolant(extend_vert, extend_map(:, 2));
    normal_map = [interp_map_x(normal_vert), interp_map_y(normal_vert)];
        
    map = normal_map .* mesh_density + [n, m] / 2;
    hbs_mu = bc_metric(face, vert, map, 2);
    hbs_mu = Tools.mu_chop(hbs_mu, mu_upper_bound);
    reconstructed_bound = Tools.complex2real(reconstructed_bound) .* mesh_density + [n, m] / 2;
    init_moving = double(Tools.move_pixels(unit_disk, vert, map) >= 0.5);

    % Display init_moving, map and mu
    if init_image_display ~= "none"
        figure;
        sp1 = subplot(1, 3, 1);
        imshow(static);
        hold on;
        if size(moving, 2) ~= 1  
            % contour(moving,[0,1],'g','LineWidth',2);
            Plot.pri_scatter(bound);
            plot(real(bound), imag(bound), 'g', 'LineWidth', 1);
        else
            contour(init_moving, 1, 'g','LineWidth',2);
        end
        hold off;

        sp2 = subplot(1, 3, 2);
        imshow(init_moving)
        hold on;
        Plot.pri_scatter(reconstructed_bound+[1,1]);
        % plot(real(reconstructed_bound), imag(reconstructed_bound), 'g','LineWidth',1);
        % Plot.pri_plot_mesh(face, map);
        hold off;

        subplot(1, 3, 3);
        Plot.pri_plot_mu(hbs_mu, face, vert);
        colormap(sp1, "gray");
        colormap(sp2, "gray");
        set(gcf, 'unit', 'normalized', 'position', [0 0 1 1])
        drawnow();

        if init_image_display ~= "" && endsWith(init_image_display, '.png')

            if ~exist(fileparts(init_image_display), 'dir')
                mkdir(fileparts(init_image_display));
            end

            saveas(gcf, init_image_display);
            fprintf('Saved to %s', init_image_display);
        end

    end

    %% Transform initial moving
    if isempty(P.T_params)
        [scaling, rotation, a, b] = get_transformation_params(static, init_moving);
    else
        [scaling, rotation, a, b] = get_transformation_params(static, init_moving, P.T_params);
    end

    params_str = replace(num2str([scaling, rotation, a, b]), " ", "_");
    [~, static_str, ~] = fileparts(P.static);
    [~, moving_str, ~] = fileparts(P.moving);
    params_filename = join([static_str, moving_str, params_str, "mat"], ".");
    params_dir = "vars";

    if ~exist(params_dir, 'dir')
        mkdir(params_dir);
    end

    params_path = join([params_dir, params_filename], "/");

    if exist(params_path, 'file')
        load(params_path, 'updated_map')
        updated_moving = Tools.move_pixels(unit_disk, vert, updated_map) >= 0.5;
        hbs_mu = bc_metric(face, vert, updated_map, 2);
    else
        rotation_matrix = [cos(rotation), sin(rotation); -sin(rotation), cos(rotation)];
        updated_map = (map - [n, m] / 2) * rotation_matrix * scaling + [a, b] * max(m, n) / 2 + [n, m] / 2;
        updated_moving = Tools.move_pixels(unit_disk, vert, updated_map) >= 0.5;

        if distort_bound
            corner_idx = [n; m * n; m * n - n + 1; 1];
            corner_dis = Tools.norm(updated_map(1, :) - vert(corner_idx, :));
            [~, pos] = min(corner_dis);

            out_bound_idx = find(vert(:, 1) == 0 | vert(:, 1) == n - 1 | vert(:, 2) == 0 | vert(:, 2) == m - 1);
            out_bound_targets = Tools.complex2real(Tools.real2complex(vert(out_bound_idx, :) - [n - 1, m - 1] / 2) * exp(-1i * pos / 2 * pi)) + [n - 1, m - 1] / 2;

            unit_disk_bound = Mesh.get_bound2(unit_disk) - [1, 1];
            unit_disk_bound_idx = unit_disk_bound(:, 1) * m + unit_disk_bound(:, 2) + 1;
            unit_disk_bound_targets = updated_map(unit_disk_bound_idx, :);

            landmark = [out_bound_idx; unit_disk_bound_idx];
            targets = [out_bound_targets; unit_disk_bound_targets];

            deformed_map = lsqc_solver(face, vert, hbs_mu, landmark, targets);

            i = 0;
            while 1
                deformed_hbs_mu = bc_metric(face, vert, deformed_map, 2);
                fprintf('%f\n', max(abs(deformed_hbs_mu)));
                i = i + 1;
                if max(abs(deformed_hbs_mu)) < 0.9999 || i > 50
                    hbs_mu = deformed_hbs_mu;
                    updated_map = deformed_map;
                    updated_moving = Tools.move_pixels(unit_disk, vert, updated_map) >= 0.5;
                    break
                end

                deformed_hbs_mu = Tools.mu_chop(deformed_hbs_mu, 0.975, 0.95);
                deformed_map = lsqc_solver(face, vert, deformed_hbs_mu, landmark, targets);
            end
            save(params_path, 'updated_map')
        end
    end

    if recounstruced_bound_display ~= "none"
        figure;
        subplot(1, 3, 1)
        imshow(static);
        subplot(1, 3, 2);
        imshow(updated_moving);
        subplot(1, 3, 3);
        imshow(static);
        hold on;
        contour(updated_moving, 1, 'EdgeColor', 'g', 'LineWidth', 1);
        hold off;

        set(gcf, 'unit', 'normalized', 'position', [0 0 1 1])
        drawnow();

        if recounstruced_bound_display ~= "" && endsWith(recounstruced_bound_display, '.png')

            if ~exist(fileparts(recounstruced_bound_display), 'dir')
                mkdir(fileparts(recounstruced_bound_display));
            end

            saveas(gcf, recounstruced_bound_display);
            fprintf('Saved to %s', init_image_display);
        end

    end

    %% Compute the object boundary (Main Program)

    % 1st time computation
    [map, mu, seg] = seg_main(static, unit_disk, face, vert, updated_map, hbs_mu, P);
end

function [scaling, rotation, a, b] = get_transformation_params(static, moving, params)
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

        static = cast(static * 255, 'uint8');
        moving = cast(moving * 255, 'uint8');

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
