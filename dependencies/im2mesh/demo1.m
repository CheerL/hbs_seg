function demo1()
% demo1 of im2mesh tool (convert 2d segmented image to FEM meshes)
%
% It consists of a few functions, like, im2Bounds (image to polygonal
% boundaries), getCtrlPnts (mark intersecting vertex between polygons,  
% serving as fixed/control point for polygon simplification and meshing),  
% simplifyBounds (simplify polygon), poly2mesh (polygon to triangular 
% meshes), printInp (export as Inp file). The Inp file can be imported into
% software Abaqus.
%
% This tool was originally written in March 2018 for particle material with
% air void. The code was rewritten in 2019 so it can work for multi-phase
% materials. Exactly reserve the contact detail between different phases.
%
% Key function: getCtrlPnts, dpsimplify, poly2mesh, getExactBounds
% Key parameter: tolerance
% Parameters that will affect mesh: tolerance, hmax, mesh_kind, grad_limit
% 
% Revision history:
%   Jiexian Ma, mjx0799@gmail.com, Oct 2020
% Cite As
%   Jiexian Ma (2020). Im2mesh (2D image to triangular meshes) (https://ww
%   w.mathworks.com/matlabcentral/fileexchange/71772-im2mesh-2d-image-to-t
%   riangular-meshes), MATLAB Central File Exchange. Retrieved May 21, 202
%   0.
%   

    % download MESH2D from www.mathworks.com/matlabcentral/fileexchange/25
    % 555-mesh2d-delaunay-based-unstructured-mesh-generation, and then add
    % the folder (mesh2d-master) to your path using addpath function
    addpath('mesh2d-master')    % for poly2mesh
    
    % ---------------------------------------------------------------------
    % Example 1
    % Demonstrate functions and parameters in im2mesh tool
    % ---------------------------------------------------------------------
    
    % import grayscale segmented image
    im = imread('images\kumamon.tif');
    
    % parameters
    tf_avoid_sharp_corner = false;  % For function getCtrlPnts
                                    % Whether to avoid sharp corner when 
                                    % simplifying polygon.
                                    % Value: true or false
                                    % If true, two extra control points
                                    % will be added around one original 
                                    % control point to avoid sharp corner 
                                    % when simplifying polygon.
                                    % Sharp corner in some cases will make 
                                    % poly2mesh not able to converge.
                        
    tolerance = 1.0;    % For funtion simplifyBounds
                        % Tolerance for polygon simplification.
                        % Check Douglas-Peucker algorithm.
                        % If u don't need to simplify, try tolerance = eps.
                        % If the value of tolerance is too large, some 
                        % polygons will become line segment after 
                        % simplification, and these polygons will be 
                        % deleted by function delZeroAreaPoly.
    
    hmax = 500;             % For funtion poly2mesh
                            % Maximum mesh-size
    
    mesh_kind = 'delaunay'; % For funtion poly2mesh
                            % Meshing algorithm
                            % Value: 'delaunay' or 'delfront' 
                            % "standard" Delaunay-refinement or "Frontal-Delaunay" technique
    
    grad_limit = +0.25;     % For funtion poly2mesh
                            % Scalar gradient-limit for mesh
    
    
    % image to polygon boundary
    bounds1 = im2Bounds( im );
    bounds2 = getCtrlPnts( bounds1, tf_avoid_sharp_corner );
    
    % simplify polygon boundary
    bounds3 = simplifyBounds( bounds2, tolerance );
    bounds3 = delZeroAreaPoly( bounds3 );

    % clear up redundant vertices
    % only control points and knick-points will remain
    bounds4 = getCtrlPnts( bounds3, false );
    bounds4 = simplifyBounds( bounds4, eps );
    
    % generate mesh
    [ node_cell, edge_cell ] = genNodeEdge( bounds4 );
    [ vert,tria,tnum ] = poly2mesh( node_cell, edge_cell, hmax, mesh_kind, grad_limit );
    % plotMeshes( vert, tria, tnum );
    
    % show result
    imshow( im,'InitialMagnification','fit' );
    plotBounds( bounds2 );
    plotBounds( bounds4 );
    plotMeshes( vert, tria, tnum );
    drawnow;
    set(figure(1),'units','normalized', ...
        'position',[.05,.50,.30,.35]);
    set(figure(2),'units','normalized', ...
        'position',[.35,.50,.30,.35]);
    set(figure(3),'units','normalized', ...
        'position',[.05,.05,.30,.35]);
    set(figure(4),'units','normalized', ...
        'position',[.35,.05,.30,.35]);
    % ---------------------------------------------------------------------

end