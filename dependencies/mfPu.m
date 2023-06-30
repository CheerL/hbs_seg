% (c) Jan Modersitzki 2011/04/27, see FAIR.2 and FAIRcopyright.m.
% http://www.mic.uni-luebeck.de/people/jan-modersitzki.html
%
% function Pu = mfPu(uc,omega,m,flag);
%
% coarse <-> fine grid operator
%
% This function applies the prolongation operator (default, flag='Pu') or the adjoint 
% (flag='PTu') to uc for cell-centered, nodal and staggered grids.
% Step 1: us is divided into uk, k=1,2,...,d, and reshapes into a d-array
% Step 2: for each k, the j-th dimension of uk is either expanded (pu) or shrinked (PTu) 
%  depended on the grid in this direction being centered (C) or nodal (N).
%
% =======================================================================================
% changes 2011-04-21
%   q~=2*m is allowed now
% =======================================================================================
 
function Pu = mfPu(uc,omega,m,flag)

% default flag is Pu
if ~exist('flag','var'), flag = 'Pu';  end;
switch flag,
  case 'Pu',  q = 2*m;      % the operation expands: coarse to fine
  case 'PTu', q = m/2;      % the operation shrinks: fine to coarse
end;

q = round(q); % if q is no integer
m = round(m); % if m is no integer

% identify the grid and allocate memory
dim = length(omega)/2;
if numel(uc) == dim*prod(m),
  grid = 'cell-centered';
  uc   = reshape(uc,[],dim);
  Pu   = zeros(prod(q),dim);
elseif numel(uc) == dim*prod(m+1),
  grid = 'nodal';
  uc   = reshape(uc,[],dim);
  Pu   = zeros(prod(q+1),dim);
elseif numel(uc) == sum(prod(ones(dim,1)*m+eye(dim),2))
  grid = 'staggered';
  % ns, qs are used to identify u1, u2, u3 in the input uc and the output Pu
  ns = cumsum([0;prod(ones(dim,1)*m+eye(dim),2)]);
  qs = cumsum([0;prod(ones(dim,1)*q+eye(dim),2)]);
  Pu = zeros(qs(end),1);
else
  error('can not deal this grid')
end;

switch [flag,'-',grid],
  case 'Pu-cell-centered',          % coarse to fine cell-centered
    for k=1:dim,                    % run over all components uk of uc
      uk = reshape(uc(:,k),m);      % make uk a d-array and expand in all directions
      for j=1:dim, uk = cut(expandCj(uk,omega,m,j),j,q); end;
      Pu(:,k) = reshape(uk,[],1);   % collect the results
    end;
  case 'PTu-cell-centered',         % fine to coarse cell-centered
    for k=1:dim,                    % run over all components uk of uc
      uk = reshape(uc(:,k),m);      % make uk a d-array and expand in all directions
      for j=1:dim, uk = shrinkCj(uk,omega,m,j); end;
      Pu(:,k) = reshape(uk,[],1);   % collect the results
    end;
  case 'Pu-nodal',                  % coarse to fine nodal
    for k=1:dim,                    % run over all components uk of uc
      uk = reshape(uc(:,k),m+1);    % make uk a d-array and expand in all directions
      for j=1:dim, uk = cut(expandNj(uk,omega,m,j),j,q+1); end;
      Pu(:,k) = reshape(uk,[],1);   % collect the results
    end;
  case 'PTu-nodal',                 % fine to coarse nodal
    for k=1:dim,                    % run over all components uk of uc
      uk = reshape(uc(:,k),m+1);    % make uk a d-array and expand in all directions
      for j=1:dim, uk = shrinkNj(uk,omega,m,j); end;
      Pu(:,k) = reshape(uk,[],1);   % collect the results
    end;
  case 'Pu-staggered',              % coarse to fine staggered
    for k=1:dim,                    % run over all components uk of uc
                                    % ns(k)+1:ns(k+1) are the indices of uk in uc
                                    % m+(1:dim==k) gives the array dimesions of uk
      uk = reshape(uc(ns(k)+1:ns(k+1)),m+(1:dim==k));
      for j=1:dim,                  % run over all directions
        if j == k,                  % nodal or centered?
          uk = cut(expandNj(uk,omega,m,j),j,q+1);  % expand the nodal direction
        else
          uk = cut(expandCj(uk,omega,m,j),j,q);  % expand the cell-centered direction(s)
        end;
      end;
                                    % collect the results
      Pu(qs(k)+1:qs(k+1)) = reshape(uk,[],1);
    end;
  case 'PTu-staggered',             % fine to coarse staggered
    for k=1:dim,                    % run over all components uk of uc
                                    % ns(k)+1:ns(k+1) are the indices of uk in uc
                                    % m+(1:dim==k) gives the array dimesions of uk
      uk = reshape(uc(ns(k)+1:ns(k+1)),m+(1:dim==k));
      for j=1:dim,                  % run over all directions
        if j == k,                  % nodal or centered?
          uk = shrinkNj(uk,omega,m,j);   % shrink the nodal direction
        else
          uk = shrinkCj(uk,omega,m,j);   % shrink the cell-centered direction(s)
        end;
      end;         
                                    % collect the results
      Pu(qs(k)+1:qs(k+1)) = reshape(uk,[],1);
    end;
  otherwise, error(flag);
end;
Pu = Pu(:); % vectorize output
%------------------------------------------------------------------------------
function u=shrinkCj(u,omega,m,j)
% permutes the array, such that the interesting direction becomes first direction
% use interpolation 
%
% [ 1 3 3 1        ]
% [     1 3 3 1    ]  /4
%
% (conv + downsample) and undo permutation
dim = length(omega); C = zeros(4,1,1); C(:,1,1) = [1 3 3 1]/4; %% 4
J = [j,setdiff(1:dim,j)];
u = permute(u,J);
u = convn(u([1,1:end,end],:,:),C,'same');
u = ipermute(u(2:2:end-1,:,:),J);
%------------------------------------------------------------------------------
function u=expandCj(u,omega,m,j)
% permutes the array, such that the interesting direction becomes first direction
% use interpolation values 
%
% [ 1 3 3 1        ]'
% [     1 3 3 1    ]  /4
%
% and undo permutation

dim = length(omega);
J = [j,setdiff(1:dim,j)];
u = permute(u,J);
U = zeros(2*size(u,1),size(u,2),size(u,3));
U([1,end],:,:)   = u([1,end],:,:);
U(2:2:end-2,:,:) = .75*u(1:end-1,:,:)+.25*u(2:end,:,:);
U(3:2:end-1,:,:) = .25*u(1:end-1,:,:)+.75*u(2:end,:,:);   
u = ipermute(U,J);
%------------------------------------------------------------------------------
function u=shrinkNj(u,omega,m,j)
% permutes the array, such that the interesting direction becomes first direction
% use interpolation 
%
% [ 1 2 1        ]
% [     1 2 1    ]  /2
%
% and undo permutation
dim = length(omega)/2; C = zeros(3,1,1); C(:,1,1) = [1 2 1]/2; %% 2
J = [j,setdiff(1:dim,j)];
u = permute(u,J);
u = convn(u,C,'same');
u = ipermute(u(1:2:end,:,:),J);
%------------------------------------------------------------------------------
function u=expandNj(u,omega,m,j)
% permutes the array, such that the interesting direction becomes first direction
% use interpolation 
%
% [ 1 2 1        ]'
% [     1 2 1    ]  /2
%
% (conv + downsample) and undo permutation
dim = length(omega)/2;
J = [j,setdiff(1:dim,j)];
u = permute(u,J);
U = zeros(2*size(u,1)-1,size(u,2),size(u,3));
U(1:2:end,:,:)   = u;
U(2:2:end-1,:,:) = .5*(u(1:end-1,:,:)+u(2:end,:,:));
u = ipermute(U,J);

%------------------------------------------------------------------------------
function uk = cut(uk,j,q)
% Cut grid in case of q~=2*m
switch j
    case 1
        uk = uk(1:q(1),:,:);
    case 2
        uk = uk(:,1:q(2),:);
    case 3
        uk = uk(:,:,1:q(3));
end

%{ 
	=======================================================================================
	FAIR: Flexible Algorithms for Image Registration, Version 2011
	Copyright (c): Jan Modersitzki
	Maria-Goeppert-Str. 1a, D-23562 Luebeck, Germany
	Email: jan.modersitzki@mic.uni-luebeck.de
	URL:   http://www.mic.uni-luebeck.de/people/jan-modersitzki.html
	=======================================================================================
	No part of this code may be reproduced, stored in a retrieval system,
	translated, transcribed, transmitted, or distributed in any form
	or by any means, means, manual, electric, electronic, electro-magnetic,
	mechanical, chemical, optical, photocopying, recording, or otherwise,
	without the prior explicit written permission of the authors or their
	designated proxies. In no event shall the above copyright notice be
	removed or altered in any way.

	This code is provided "as is", without any warranty of any kind, either
	expressed or implied, including but not limited to, any implied warranty
	of merchantibility or fitness for any purpose. In no event will any party
	who distributed the code be liable for damages or for any claim(s) by
	any other party, including but not limited to, any lost profits, lost
	monies, lost data or data rendered inaccurate, losses sustained by
	third parties, or any other special, incidental or consequential damages
	arrising out of the use or inability to use the program, even if the
	possibility of such damages has been advised against. The entire risk
	as to the quality, the performace, and the fitness of the program for any
	particular purpose lies with the party using the code.
	=======================================================================================
	Any use of this code constitutes acceptance of the terms of the above statements
	=======================================================================================
%}