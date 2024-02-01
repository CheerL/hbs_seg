function [map,map_mu,Edge, vertex] = lbs_rect(mu, h, w)

% This function lbs restores the quasi-conformal map in rectangular domain 
% corresponding to the given Beltrami coefficients mu by minimizing the least 
% square energy from the Beltrami equation.
% Corners corresponding to the target rectangular domain can be chosen
% manually.
% Hard landmark (both interior / Dirichlet boundary) constraints can be
% added, where landmarks are the vertices index, target position is represented 
% by the 2-dimensional coordinates. 
%
% Inputs
% face : m x 3 triangulation connectivity
% vertex : n x 3 vertices coordinates
% mu : m x 1 Beltrami coefficients
% varargin :
% Corner : corner vertexi indexes in anti-clockwise order
% Landmark : vertices ID as landmarks in the form of k x 1 vector
% Target : corresponding target position in 2D in the form of k x 2 matrix
%
% Outputs
% map : corresponding quasi-conformal map f
% map_mu : The true, admissible Beltrami coefficients
% Edge : Divided edges
%
% Remarks on Corner input
%
% Defualt :
% 	4 extreme points are chosen.
%
% User input :
% 	Anti-clockwise location for the corners.
%   	P4 ---(Edge 3)--- P3
%   	|	       		   |
%	(Edge 4)			(Edge 2)
%   	|	               |
%   	P1 ---(Edge 1)--- P2
%
% Function is written by Jeffery Ka Chun Lam (2014)
% www.jefferykclam.com
% Reference : 
% K. C. Lam and L. M. Lui, 
% Landmark and intensity based registration with large deformations via Quasi-conformal maps.
% SIAM Journal on Imaging Sciences, 7(4):2364--2392, 2014.

width = 1;
height = 1;

[face,vertex] = image_meshgen(h, w);

landmark = [];
target = [];

targetlmX = [];
targetlmY = [];

[Ax,abc,area] = generalized_laplacian2D(face,vertex,mu, h, w); 
Ay = Ax;
bx = zeros(length(vertex),1);
by = bx;

corner = [h*w-w+1 ;h*w ;w ;1];

Edge1 = reshape([h*w-w+1: h*w], w, 1);
Edge2 = reshape([w:w:h*w], h, 1);
Edge3 = reshape([1:w], w, 1);
Edge4 = reshape([1: w: h*w-w+1], h, 1);
Edge = [Edge1; Edge2; Edge3; Edge4];

VBdyC = [Edge4;Edge2]; VBdy = [Edge4*0; Edge2*0 + width];
landmarkx = [VBdyC]; 
targetx = [VBdy];
bx(landmarkx) = targetx;
Ax(landmarkx,:) = 0; 
Ax(landmarkx,landmarkx) = diag(ones(length(landmarkx),1));
mapx = Ax\bx;

HBdyC = [Edge1;Edge3]; HBdy = [Edge1*0; Edge3*0 + height];
landmarky = [HBdyC]; 
targety = [HBdy];
by(landmarky) = targety;
Ay(landmarky,:) = 0; 
Ay(landmarky,landmarky) = diag(ones(length(landmarky),1));
mapy = Ay\by;

map = [mapx,mapy,0*vertex(:,1)+1];
map_mu = bc_metric(face,vertex,map,2);

end
