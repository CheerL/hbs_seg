classdef Normalization
    %NORMALIZATION 
    methods(Static)
        % function [bound, vert, center, max_dis, rms_center] = prenorm(bounds, mesh)
        %     %PRENORM 
        %     delta1 = 1e-3;
        %     vert = mesh{1};
        %     bound = bounds{1}{1}(1:end-1, :);
        % 
        %     bound = Tools.real2complex(bound);
        %     vert = Tools.real2complex(vert);
        %     center = mean(bound);
        %     max_dis = max(abs(bound - center)) + delta1;
        % 
        %     bound = (bound - center) / max_dis;
        %     vert = (vert - center) / max_dis;
        % 
        %     rms_center = Tools.rms(bound);
        %     if sum(abs(bound - rms_center ) - abs(bound + rms_center)) <=0
        %         rotation = exp(-angle(rms_center)*1i);
        %     else
        %         rotation = exp(-angle(-rms_center)*1i);
        %     end
        %     bound = bound * rotation;
        %     vert = vert * rotation;
        % 
        %     [~, min_pos] = min(angle(bound));
        %     bound = circshift(bound, 1-min_pos);
        % end

        function [w, a, theta] = postnorm_inner(w)
            id = 1:length(w);
            p = w;
            p(end+1:end+2) = [0;1];
            while true  
                center = mean(p(id));
                if abs(center) <= eps
                    break
                end
                p = Tools.mobius(p, center);
            end
            p0 = p(end-1);
            p1 = p(end);
            k = (p1-p0)/(1-p1*conj(p0));
            a = -p0/k;
            theta = angle(k);
            % w = Tools.mobius(w, a, theta);
            w = p(1:length(w));
        end
        
        
        function [w, a, theta] = postnorm_outer(z, params)
            zinf = Zipper.zipper_params(inf, params);
            a = -1/ conj(zinf);
            theta = 0;
            w = Tools.mobius_inv(z, a, theta);         
        end
    end
end

