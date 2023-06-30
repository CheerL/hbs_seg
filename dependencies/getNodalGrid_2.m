function X = getNodalGrid_2(omega,m)

if nargin == 0, % help and minimal example
  help(mfilename); 
  omega = [0 2 0 1]; m = [6,3];
  xN = getNodalGrid(omega,m);
  xP = reshape(xN,[],2)';
  figure(1); clf; plotGrid(xN,omega,m); hold on; title(mfilename); 
  plot(xP(1,:),xP(2,:),'rs'); axis image
  return; 
end;

X  = []; x1 = []; x2 = []; x3 = [];
h   = (omega(2:2:end)-omega(1:2:end))./m; % voxel size for integration
nu = @(i) (omega(2*i-1)       :h(i):omega(2*i)       )'; % nodal
switch length(omega)/2,
  case 1, x1 = nu(1);
  case 2, [x1,x2] = ndgrid(nu(1),nu(2));
  case 3, [x1,x2,x3] = ndgrid(nu(1),nu(2),nu(3));
end;
X = [x1(:);x2(:);x3(:)];
