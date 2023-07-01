classdef Plot
    %PLOT 此处显示有关此类的摘要
    %   此处显示详细说明
    methods(Static)
        function imshow(im)
            figure;
            imshow(im);
        end
        
        function scatter(varargin)
        % scatter the INPUT points.
        % INPUT should be one of following: 
        %   x: n x 1 complex number 
        %   x: n x 2 real number
        %   x: n x 1 real number, y: n x 1 real number
            figure;
            Plot.pri_scatter(varargin{:});
        end
        
        function pri_scatter(x, y)
            if nargin == 1 && ~isreal(x)
                y = imag(x);
                x = real(x);
            elseif nargin == 1 && isreal(x) && size(x, 2) == 2
                y = x(:, 2);
                x = x(:, 1);
            elseif nargin == 2 && isreal(x) && isreal(y) && size(x, 2) == 1 && size(y, 2) == 1
                
            else
                error('Type Error, not suitable input');
            end

            scatter(x, y, 20, 'filled');
%             axis([-1.2 1.2 -1 1])
            axis equal tight;
            box on;
        end
        
        function scatter_with_center(varargin)
        % scatter the INPUT points and highlight the center of points.
        % INPUT should be one of following: 
        %   x: n x 1 complex number 
        %   x: n x 2 real number
        %   x: n x 1 real number, y: n x 1 real number
            figure;
            Plot.pri_scatter_with_center(varargin{:});
        end
        
        function pri_scatter_with_center(x, y)
            if nargin == 1 && ~isreal(x)
                y = imag(x);
                x = real(x);
            elseif nargin == 1 && isreal(x) && size(x, 2) == 2
                y = x(:, 2);
                x = x(:, 1);
            elseif nargin == 2 && isreal(x) && isreal(y) && size(x, 2) == 1 && size(y, 2) == 1
                
            else
                error('Type Error, not suitable input');
            end

            s = length(x);
            x(end+1) = mean(x);
            y(end+1) = mean(y);
            color = zeros(s+1, 3);
            color(1:s, 3) = 1;
            color(end, 1) = 1;
%             scatter(x, y, 20, 'filled');
            scatter(x, y, 20, color, 'filled');
            axis equal tight;
            box on;
        end
        
        function plot_mesh(face, vert)
            figure;
            Plot.pri_plot_mesh(face, vert);
        end

        function pri_plot_mesh(face, vert)
            patch('Faces',face,'Vertices',vert,'FaceColor',[0.6,1,1],'LineWidth',0.5);
            axis equal tight off
            ax = gca; ax.Clipping = 'off';
        end
        
        function [x, y] = welding(outer_points, inner_points)
            figure;
            [x, y] = Plot.pri_welding(outer_points, inner_points);
        end
        
        function [x, y] = pri_welding(outer_points, inner_points)
            % outside as x, inside as y.
            complex2arg = @(z) mod(angle(z), 2*pi);
            x = complex2arg(outer_points);
            y = complex2arg(inner_points);
            x(x<0) = x(x<0)+2*pi;
            y(y<0) = y(y<0)+2*pi;
            Plot.pri_scatter(x, y);
            axis([0 2*pi 0 2*pi]);
            axis equal tight;
            box on;
        end
        
        function [x, y] = welding_filled(outer_points, inner_points)
            figure;
            [x, y] = Plot.pri_welding_filled(outer_points, inner_points);
        end
        
        function [x, y] = pri_welding_filled(outer_points, inner_points)
            % outside as x, inside as y.
            complex2arg = @(z) mod(angle(z/z(1)), 2*pi);
            x = complex2arg(outer_points);
            y = complex2arg(inner_points);
            xq = (0:1e-4:2*pi).';
            yq = interp1(x, y, xq, 'pchip');
            Plot.pri_scatter(xq, yq);
            axis([0 2*pi 0 2*pi]);
            axis equal tight;
        end
        
        function plot_mu(mu, varargin)
            figure;
            Plot.pri_plot_mu(mu, varargin{:});

        end
        
        function pri_plot_mu(mu, varargin)
            if length(varargin) == 2
                face = varargin{1};
                vert = varargin{2};
                face_center = Mesh.get_face_center(face, vert);
            elseif length(varargin) == 1
                face_center = varargin{1};
            end

            scatter3(face_center(:, 1), face_center(:, 2), abs(mu), 10, abs(mu), 'filled');
            axis equal;
            box on;
            % axis([-1 1 -1 1 0 1]);
            % xticks(-1:0.5:1);
            % yticks(-1:0.5:1);
            colormap jet;
            view([0 90]);
            % axis equal;
        end
        
        function plot_map(map,vert)
            figure;
            Plot.pri_plot_map(map, vert);
        end
        
        function pri_plot_map(map, vert)
            scatter3(vert(:, 1), vert(:, 2), abs(map), 10, abs(map), 'filled');
%             axis([-1 1 -1 1 0 1]);
%             axis equal
            colormap jet;
            box on;
        end
        
%         function plot_all(bound, x, y, face_center, mu, fname)
%             figure;
%             hold on;
%             subplot(1,3,1);
%             Plot.pri_scatter(bound);
%             set(gca,'position',[0.05,0.55,0.35,0.35]);
%             subplot(1,3,2);
%             Plot.pri_welding_filled(x, y); 
%             set(gca,'position',[0.05,0.1,0.35,0.35]);
%             subplot(1,3,3);
%             Plot.pri_plot_mu(face_center, mu);
%             set(gca,'position',[0.55,0.1,0.4,0.8]);
%             subtitle(fname);
%             set(gcf, 'color','w')
%             hold off;
%         end
%         
%         function plotall_dict(data, center, name)
%             if nargin == 3
%                 dname = strrep(strrep(name, '/','_'),'.','_');
%                 data = data.(dname);
%             end
%             Plot.plotall(data.bound, data.x, data.y, center, data.bc, data.name);
%         end
    end
end

