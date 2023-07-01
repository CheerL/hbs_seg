function moments = get_boundary_moments(bound)
%UNTITLED 此处显示有关此函数的摘要
%   此处显示详细说明
x_mean = mean(bound(:, 1));
y_mean = mean(bound(:, 2));
z = sqrt((bound(:, 1) - x_mean).^2+(bound(:,2)-y_mean).^2);

m1 = m_r(z, 1);
mu2 = mu_r(z, 2);
mu3 = mu_r(z, 3);
mu4 = mu_r(z, 4);
mu5 = mu_r(z, 5);

F1 = sqrt(mu2)/m1;
F2 = mu3 / mu2^1.5;
F3 = mu4 / mu2^2;
F4 = mu5 / mu2^2.5;
moments = [F1, F2, F3, F4];
end

function m = m_r(z, r)
m = mean(z.^r);
end

function mu = mu_r(z, r)
m1 = m_r(z, 1);
mu = mean((z-m1).^r);
end

