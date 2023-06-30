function index = vertex_search(XYZ,v)
% --------------------------------------------------------
% Search vertex index for which the coordinates of the
% corresponding vertex are nearest to XY/XYZ.
% --------------------------------------------------------
% Input : 
% 	XYZ - (X,Y)/(X,Y,Z) coordinates of ponits (kx2 or kx3)
% 	v - vertex (3xn or 2xn)
%
% Output :
%	index - vertex index of the points (X,Y)/(X,Y,Z) (kx1) 
% --------------------------------------------------------

if size(XYZ,2) ~= 2 && size(XYZ,2) ~= 3
    error('Input feature points must be a kx2 or kx3 matrix');
end

if size(v,1)==2||size(v,2)==2
    if size(v,1)~=2
        v = v';
    end
elseif size(v,1)==3||size(v,2)==3
    if size(v,1)~=3
        v = v';
    end
else
    error('Input vertex must be a 2xn or 3xn matrix');
end
% if size(v,1)~=3
%     v=v';
%     if size(v,1)~=3
%         error('Input vertex must be a 3xn matrix');
%     end
% end

k = size(XYZ,1);
n = size(v,2);
index = zeros(k,1);

switch size(XYZ,2)
    case 2
		[~,index] = min(sqrt((repmat(v(1,:),k,1)-repmat(XYZ(:,1),1,n)).^2 +...
            (repmat(v(2,:),k,1)-repmat(XYZ(:,2),1,n)).^2),[],2);
    case 3
		[~,index] = min(sqrt((repmat(v(1,:),k,1)-repmat(XYZ(:,1),1,n)).^2 +...
            (repmat(v(2,:),k,1)-repmat(XYZ(:,2),1,n)).^2 +...
            (repmat(v(3,:),k,1)-repmat(XYZ(:,3),1,n)).^2),[],2);
end

if length(unique(index)) ~= length(index)
    warning('Some points are sharing the same vertex index found')
end   

end