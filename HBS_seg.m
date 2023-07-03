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
    [m, n] = size(static);
    bound_point_num = P.bound_point_num;%500;
    circle_point_num = P.circle_point_num;%1000;
    hbs_mesh_density = P.hbs_mesh_density;%50;
    smooth_eps = P.smooth_eps;%0;
    mu_upper_bound = P.upper_bound;
    

    init_image_display = P.init_image_display; %"img/hbs_seg/output/init.png";
    recounstruced_bound_display = P.recounstruced_bound_display; %"img/hbs_seg/output/reconstructed.png";
    % seg_display = "img/hbs_seg/output/seg_display.png";
    mesh_density = min([m, n] / 4);

    %% Compute HBS and initial map
    bound = Mesh.get_bound(moving, bound_point_num);

    [face, vert] = Mesh.rect_mesh(m, n, 0);
    normal_vert = (vert - [n / 2, m / 2]) ./ mesh_density;

    [hbs, ~, ~, ~, disk_face, disk_vert, ~] = HBS(bound, circle_point_num, hbs_mesh_density);
    [reconstructed_bound, inner, outer, extend_vert, ~] = HBS_reconstruct(hbs, disk_face, disk_vert, m, n, mesh_density);
    extend_map = Tools.complex2real([reconstructed_bound; inner; outer]);

    interp_map_x = scatteredInterpolant(extend_vert, extend_map(:, 1));
    interp_map_y = scatteredInterpolant(extend_vert, extend_map(:, 2));
    normal_map = [interp_map_x(normal_vert), interp_map_y(normal_vert)];
    hbs_mu = bc_metric(face, normal_vert, normal_map, 2);
    hbs_mu = Tools.mu_chop(hbs_mu, mu_upper_bound);

    unit_disk = zeros(m, n);
    unit_disk(Tools.norm(normal_vert) <= (1 + smooth_eps)) = 1;

    map = normal_map .* mesh_density + [n, m] / 2;
    reconstructed_bound = Tools.complex2real(reconstructed_bound) .* mesh_density + [n, m] / 2;
    init_moving = Tools.move_pixels(unit_disk, vert, map) >= 0.5;

    % Display init_moving, map and mu
    if init_image_display ~= "none"
        figure;
        sp1 = subplot(1, 3, 1);
        imshow(static)
        hold on;
        % contour(moving,[0,1],'g','LineWidth',2);
        Plot.pri_scatter(bound);
        plot(real(bound), imag(bound), 'g', 'LineWidth', 1);
        hold off;

        sp2 = subplot(1, 3, 2);
        imshow(init_moving)
        hold on;
        Plot.pri_scatter(reconstructed_bound);
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
            saveas(gcf, init_image_display);
        end

    end

    %% Transform initial moving
    if isempty(P.T_params)
        [scaling, rotation, a, b] = get_transformation_params(static, init_moving);
    else
        [scaling, rotation, a, b] = get_transformation_params(static, init_moving, P.T_params);
    end
    rotation_matrix = [cos(rotation), sin(rotation); -sin(rotation), cos(rotation)];
    updated_map = (map - [n, m] / 2) * rotation_matrix * scaling + [a, b] * max(m, n) / 2 + [n, m] / 2;
    updated_moving = Tools.move_pixels(unit_disk, vert, updated_map) >= 0.5;

    if recounstruced_bound_display ~= "none"
        figure;
        subplot(1, 3, 1)
        imshow(static);
        subplot(1, 3, 2);
        imshow(updated_moving);
        subplot(1, 3, 3);
        imshow(abs(static - updated_moving));
        set(gcf, 'unit', 'normalized', 'position', [0 0 1 1])
        drawnow();

        if recounstruced_bound_display ~= "" && endsWith(recounstruced_bound_display, '.png')
            saveas(gcf, recounstruced_bound_display);
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
