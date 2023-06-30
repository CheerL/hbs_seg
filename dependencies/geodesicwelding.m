function [a, b] = geodesicwelding(a, b, s, t)
% 
%  GEODESICWELDING Geodesic Welding Algorithm
%     [a, b] = GEODESICWELDING(a, b, s, t) gives conformal map to unit disk
%        a: interior points of polygon s
%        b: exterior points of polygon t
%        (s, t): welding correspondence
%        a, b, s, t: complex numbers
% 
%  For example, w = GEODESICWELDING(s, [], s, t) welds two shapes according
%  to correspondence of s and t. If (s, t) is a shape fingerprint, the
%  algorithm reconstructs the shape (up to Mobius ambiguity). The algorithm
%  runs in O( #s * (#a + #b + #s) ) with #s = #t. No dependence. Idea comes
%  from Donald E. Marshall, thank you Donald.
% 
%  Reference:
%     @article{marshall2009lens,
%       title={Lens chains and the geodesic algorithm for conformal mapping},
%       author={Marshall, Donald E},
%       journal={preprint},
%       year={2009}
%     }
% 
n = length(s);
z = [s; a; 0];
w = [t; b; inf];
z = step0(z, z(1), z(2));
w = step0(w, w(1), w(2));
for i = 3 : n
  z = step1(z, z(i), 1i);
  w = step1(w, w(i), -1i);
end
z = step2(z, z(1));
w = step2(w, w(1));
for i = n-1:-1:2
  c1 = z(i); c2 = w(i);
  z = step3(z, c1, c2);
  w = step3(w, c1, c2);
end
z = step4(z, z(1));
w = step4(w, w(1));
a = step5(z(n+1:end-1), z(end), w(end));
b = step5(w(n+1:end-1), z(end), w(end));

function w = step0(z, p, q)
w = sqrt((z-q)./(z-p));
w(isinf(z)) = 1;

function w = step1(z, p, m)
c = real(p) / abs(p)^2;
d = imag(p) / abs(p)^2;
t = c * z ./ (1 + 1i*d*z);
t(isinf(z)) = c / (1i*d);
w = sqrt(t.^2-1);
k = imag(w).*imag(t) < 0;
w(k) = -w(k);
w(z == 0) = m;
w(z == p) = 0;

function w = step2(z, p)
w = z./(1-z/p);
w(isinf(z)) = -p;

function w = step3(z, p, q)
p = imag(p);
q = imag(q);
if p == 0
    p = eps;
end
if q == 0
    q = eps;
end
a = -2*p*q/(p-q);
b = (p+q)/(p-q);
r = z./(a-1i*b*z);
r(isnan(z)) = 1i/b; %
r(isinf(z)) = 1i/b;
w = sqrt(r.^2+1);
s = imag(r).*imag(w)<0;
w(s) = -w(s);

function w = step4(z, p)
w = (z./(1-z/p)).^2;
w(isinf(z)) = p^2;

function w = step5(z, p, q)
w = (z-p)./(z-q);
w(isinf(z)) = 1;
