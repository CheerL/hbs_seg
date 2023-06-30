classdef Zipper
    %ZIPPER �˴���ʾ�йش����ժ҄1�7
    %   �˴���ʾ��ϸ˵��
    methods(Static)
        function [bound, others, params] = zipper(bound, others)
            if nargin <2
                others = [];
            end

            n = length(bound);
            params = zeros(n+1, 1);
            params(1:2) = bound(1:2);
            points = Zipper.f_pre([bound;others], params(1), params(2));
            for j=3:n
%                 if abs(imag(points(j))/real(points(j))) > 200
%                     a = real(points(j));
%                     b = imag(points(j));
%                     k = mean(abs(imag(params(1:j-1))./real(params(1:j-1))));
%                     k = sqrt(abs(a*k/b));
%                     points(j) = a/k+1i*b*k;
%                     points(j) = points(j+1)/2;
%                 end
%                 if real(points(j)) == 0
%                     continue
%                 end
                params(j) = points(j);
                points = Zipper.f(points, params(j));
            end
            params(n+1) = points(1);
            points = Zipper.f_end(points, params(n+1));
            points = Zipper.f_final(points);

            bound = points(1:n);
            others = points(n+1:end);
        end
        
        function w = f_pre(z, p, q)
            % q -> 0
            % p -> inf
            % inf -> 1
            % then map to right half plane
            w = (z-q)./(z-p);
            w(isinf(z)) = 1;
            w(z==p)=inf;
            w = sqrt(w);
        end
        
        function w = f1(z, p)
            c = real(p)/abs(p)^2;
            d = imag(p)/abs(p)^2;
            w = c*z./(1+1i*d*z);
            w(isinf(z)) = -c / d * 1i;
            w(z==1i/d) = inf;
        end
        
        function w = f2(z)
%             k = real(z)<=1 & abs(imag(z))<5e-5;
%             imag_mean = mean(imag(z(k)));
%             imag_mean_sign = imag_mean / abs(imag_mean);
%             z(k) = real(z(k)) + abs(imag(z(k))) * imag_mean_sign * 1i;
            w = sqrt(z.^2 - 1);
            k = imag(w) .* imag(z) < 0;
            w(k) = -w(k);
            w(z == 0) = 1i;
            w(isinf(z)) = inf;
        end
        
        function w = f(z, p)
            w = Zipper.f1(z, p);
            w = Zipper.f2(w);
            w(Tools.near(z, p)) = 0;
        end

        function w = f_end(z, p)
            % 0 -> 0
            % p -> inf
            % inf -> p
            % then right half plane to upper half plane
            w = (z./(1-z/p)).^2;
            w(isinf(z)) = p^2;
            w(z==p) = inf;
%             k = abs(imag(w))<1e-10;
%             w(k) = real(w(k));
        end
        
        function w = f_final(z)
            w = (z -1i)./(z+1i);
            w(isinf(z)) = 1;
            w(z==-1i) = inf;
        end
        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %         
        % diff
        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
        function d = zipper_d(points, params)
            n = length(params) - 1;          
            d = Zipper.f_pre_d(points, params(1), params(2));
            points = Zipper.f_pre(points, params(1), params(2));
            for j=3:n
                d = d .* Zipper.f_d(points, params(j));
                points = Zipper.f(points, params(j));
            end
            d = d .* Zipper.f_end_d(points, params(n+1));
            points = Zipper.f_end(points, params(n+1));
            d = d .* Zipper.f_final_d(points);
        end

        function d = f_pre_d(z, p, q)
            t = Zipper.f_pre(z, p, q);
            d = (q-p)./(2 * ((z-p).^2) .* t);
            d(isinf(z)) = 0;
            d(z == p) = inf;
            d(z == q) = inf;
        end
        
        function w = f1_d(z, p)
            pc = real(p)/abs(p)^2;
            pd = imag(p)/abs(p)^2;
            w = pc./(1+1i*pd*z).^2;
            w(isinf(z)) = 0;
            w(z==1i/pd) = inf;
        end
        
        function d = f2_d(z)
            d = z./Zipper.f2(z);
            d(isinf(z)) = 1;
        end
        
        function d = f_d(z, p)
            t = Zipper.f1(z, p);
            d1 = Zipper.f1_d(z, p);
            d2 = Zipper.f2_d(t);
            d = d1 .* d2;
        end
        
        function d = f_end_d(z, p)
            d = 2 * z ./(1-z/p).^3;
            d(isinf(z)) = 0;
            d(z==p) = inf;
        end
        
        function d = f_final_d(z)
            d = 2i./(z+1i).^2;
            d(isinf(z)) = 0;
            d(z==-1i) = inf;
        end
        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %         
        % inverse
        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
        function points = zipper_inv(points, params)
            n = length(params) - 1;
            points = Zipper.f_final_inv(points);
            points = Zipper.f_end_inv(points, params(n+1));
            for j=n:-1:3
                points = Zipper.f_inv(points, params(j));
            end
            points = Zipper.f_pre_inv(points, params(1), params(2));
        end
        
        function z = f_pre_inv(w, p, q)
            % q -> 0
            % p -> inf
            % inf -> 1
            % then map to right half plane
            z = (p*w.^2-q)./(w.^2-1);
            z(isinf(w)) = p;
            z(w==1)=inf;
        end
        
        function z = f1_inv(w, p)
            pc = real(p)/abs(p)^2;
            pd = imag(p)/abs(p)^2;
            z = w./(pc-1i*pd*w);
            z(isinf(w)) = 1i/pd;
            z(w==-1i*pc/pd) = inf;
        end
        
        function z = f2_inv(w)
            z = sqrt(w.^2+1);
            k = imag(w) .* imag(z) < 0;
            z(k) = -z(k);
            z(w == 1i) = 0;
            z(isinf(w)) = inf;
        end
        
        function z = f_inv(w, p)
            z = Zipper.f2_inv(w);
            z = Zipper.f1_inv(z, p);
        end

        function z = f_end_inv(w, p)
            % 0 -> 0
            % p -> inf
            % inf -> p
            % then right half plane to upper half plane
            z = sqrt(w);
            z = z./(1 + z/p);
            z(isinf(w)) = p;
            % z(w==p^2) = inf;
        end
        
        function z = f_final_inv(w)
            z = (w + 1) * 1i ./ (1 - w);
            k = abs(imag(z))<1e-10;
            z(k) = real(z(k));
            z(isinf(w)) = -1i;
            z(w==1) = inf;
        end
        % % % % % % % % % % % % % % % % % % % % % % % % %         
        % params
        % % % % % % % % % % % % % % % % % % % % % % % % % % 
        function points = zipper_params(points, params)
            n = length(params) - 1;
            points = Zipper.f_pre(points, params(1), params(2));
            for j=3:n
                points = Zipper.f(points, params(j));
            end
            points = Zipper.f_end(points, params(n+1));
            points = Zipper.f_final(points);
        end
        % % % % % % % % % % % % % % % % % % % % % % % % % % % %         
        % inverse_diff
        % % % % % % % % % % % % % % % % % % % % % % % % % % % %
        function d = zipper_inv_d(points, params)
            n = length(params) - 1;
            dl = zeros(n+1, 1);
            d = Zipper.f_final_inv_d(points);
            dl(n+1) = angle(d);
            points = Zipper.f_final_inv(points);
            d0 = Zipper.f_end_inv_d(points, params(n+1));
            d = d .* d0;
            dl(n) = angle(d);
            points = Zipper.f_end_inv(points, params(n+1));
            for j=n:-1:3
                d0 = Zipper.f_inv_d(points, params(j));
                d = d .* d0;
                dl(j-1) = angle(d);
                points = Zipper.f_inv(points, params(j));
            end
            d0 = Zipper.f_pre_inv_d(points, params(1), params(2));
            dl(1) = angle(d);
            d = d .* d0;
%             d(ori_points==1) = 0;
        end

        function d = f_pre_inv_d(w, p, q)
            d = (q-p)*2*w ./ (w.^2 - 1) .^ 2;
            d(w.^2==1) = inf;
            d(isinf(w)) = 0;
        end

        function d = f1_inv_d(w, p)
            pc = real(p)/abs(p)^2;
            pd = imag(p)/abs(p)^2;
            d = pc./(pc-1i*pd*w).^2;
            d(isinf(w)) = 0;
            d(w==1i*pc/pd) = inf;
        end

        function d = f2_inv_d(w)
            d = w./Zipper.f2_inv(w);
            d(isinf(w)) = 1;
        end

        function d = f_inv_d(w, p)
            t = Zipper.f2_inv(w);
            d1 = Zipper.f1_inv_d(t, p);
            d2 = Zipper.f2_inv_d(w);
            d = d1 .* d2;
        end
        function d = f_end_inv_d(w, p)
            q = sqrt(w);
            d = 1./(2 * q .* (1 + q/p) .^ 2);
            d(isinf(w)) = 0;
            d(q==0) = inf;
            d(q==-p) = inf;
        end

        function d = f_final_inv_d(w)
            d = 2i ./ (1 - w) .^ 2;
            d(isinf(w)) = -2i;
            d(w==1) = inf;
        end
    end
end

