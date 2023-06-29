classdef Poisson
    %POISSON 此处显示有关此类的摘要
    %   此处显示详细说明
    methods(Static)
        function w = kernel(z, x)
           w = z ./ x.';
           w = real((1+w)./(1-w));
        end
        
        function w = integral(z, x, y)
            theta = angle(x);
            dth = diff(theta);
            dth(end+1) = theta(1) - theta(end);
            dth(dth<0) = dth(dth<0) + 2*pi;
            kernel = Poisson.kernel(z, x);
            w = (kernel * (y .* dth)) / (2*pi);
        end
    end
end




