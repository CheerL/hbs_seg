function demo2()
% demo2 of im2mesh tool (convert 2d segmented image to FEM meshes)
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
    % Example 2
    % Demonstrate function im2mesh, and export mesh as inp file (Abaqus), 
    % bdf file (Nastran bulk data), and .node/.ele file.
    % ---------------------------------------------------------------------
    % part 1: obtain mesh
    
    % import grayscale segmented image
    im = imread('images\kumamon.tif');
    
    % parameters
    tf_avoid_sharp_corner = false;  % Whether to avoid sharp corner
    tolerance = 1.;                 % Tolerance for polygon simplification
    hmax = 500;                     % Maximum mesh-size
    mesh_kind = 'delaunay';         % Meshing algorithm
    grad_limit = +0.25;             % Scalar gradient-limit for mesh
    
    select_phase = [];  % Parameter type: vector
                        % If 'select_phase' is [], all the phases will be
                        % chosen.
                        % 'select_phase' is an index vector for sorted 
                        % grayscales (ascending order) in an image.
                        % For example, an image with grayscales of 40, 90,
                        % 200, 240, 255. If u're interested in 40, 200, and
                        % 240, then set 'select_phase' as [1 3 4]. Those 
                        % phases corresponding to grayscales of 40, 200, 
                        % and 240 will be chosen to perform meshing.
                        
    
    % function im2mesh includes the operations shown in demo1.m
    [ vert,tria,tnum ] = im2mesh( im, select_phase, tf_avoid_sharp_corner, tolerance, hmax, mesh_kind, grad_limit );
    plotMeshes( vert, tria, tnum );
    
    % ---------------------------------------------------------------------
    % part 2: write inp, bdf, and .node/.ele file 
    
    % parameters for mesh export
    dx = 1; dy = 1;     % scale of your imgage
                        % dx - column direction, dy - row direction
                        % e.g. scale of your imgage is 0.11 mm/pixel, try
                        %      dx = 0.11; and dy = 0.11;
                        
    ele_order = 1;      % for getNodeEle, this variable is either 1 or 2
                        % 1 - linear / first-order element
                        % 2 - quadratic / second-order element
                        % note: printBdf only support linear element
                        
    ele_type = 'CPS3';  % element type, for printInp
    
    precision_nodecoor = 8; % precision of node coordinates, for printInp
                            % e.g. precision_nodecoor=4, dx=1 -> 0.5000 
                            %      precision_nodecoor=3, dx=0.111, -> 0.055
    
    % scale node coordinates
    vert( :, 1 ) = vert( :, 1 ) * dx;
    vert( :, 2 ) = vert( :, 2 ) * dy;
    
    % get node coordinares and elements from mesh
    [ nodecoor_list, nodecoor_cell, ele_cell ] = getNodeEle( vert, tria, ...
                                                        tnum, ele_order );
    
    % write file
    % inp file (Abaqus)
    % print as multiple parts
    printInp_multiPart( nodecoor_cell, ele_cell, ele_type, precision_nodecoor );
    % print as multiple sections
    printInp_multiSect( nodecoor_list, ele_cell, ele_type, precision_nodecoor );
    
    % bdf file (Nastran bulk data)
    printBdf( nodecoor_list, ele_cell, precision_nodecoor );
    
    % .node/.ele file 
    % haven't been tested
    printTria( vert, tria, tnum, precision_nodecoor );  
    
    % ---------------------------------------------------------------------
    
end