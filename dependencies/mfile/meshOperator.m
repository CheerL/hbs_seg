function Operator = meshOperator(v,f)
% -------------------------------------------------------
% Create common discrete operators
% -------------------------------------------------------
% Input : 
% 	v - vertex
% 	f - connection
%
% Output :
% 	f2v - Face to vertex operator
%		  (Face-valued to vertex-valued function)
%	v2f - Vertex to face operator
%		  (Vertex-valued to face-valued function)
%	laplacian - Laplace-Beltrami Operator
%	Diff - Differential operator
% -------------------------------------------------------

if size(v,1)>size(v,2)
    v=v';
end
if (size(f,2)==3)&&(size(f,1)~=3)
    f=f';
end

Operator.f2v = F2V(v,f);
Operator.v2f = V2F(v,f);
Operator.laplacian = laplacebeltrami(v,f);
Operator.Diff = diff_operator(v,f);
Operator.Diff.Dxv = Operator.f2v * Operator.Diff.Dx;
Operator.Diff.Dyv = Operator.f2v * Operator.Diff.Dy;
Operator.Diff.Dzv = Operator.f2v * Operator.Diff.Dz;
Operator.double_laplacian = Operator.laplacian * Operator.laplacian;
end




% -------------------------------------------------------
function S = F2V(v,f)
    ring = vertexAttachments(TriRep(f',v'));
    nv = size(v,2); nf = size(f,2);
    II = cellfun(@times,ring,num2cell(zeros(nv,1)),'UniformOutput',0);
    II = cell2mat(cellfun(@plus,II,num2cell(1:nv)','UniformOutput',0)')';
    JJ = cell2mat(ring')';
    avg = cellfun(@length,ring);
    S = sparse(II,JJ,ones(length(JJ),1),nv,nf);
    S = sparse(1:nv,1:nv,1./avg)*S;
end


% -------------------------------------------------------
function S = V2F(v,f)
    nv = size(v,2); nf = size(f,2);
    II = reshape(repmat(1:nf,3,1),3*nf,1);
    JJ = f(:);
    S = sparse(II,JJ,ones(length(JJ),1),nf,nv)./3;
end


% -------------------------------------------------------
function L = laplacebeltrami(v,f)
l = [sqrt(sum((v(:,f(2,:)) - v(:,f(3,:))).^2,1));
    sqrt(sum((v(:,f(3,:)) - v(:,f(1,:))).^2,1));
    sqrt(sum((v(:,f(1,:)) - v(:,f(2,:))).^2,1))];
f1 = f(1,:); f2 = f(2,:); f3 = f(3,:);
l1 = l(1,:); l2 = l(2,:); l3 = l(3,:);
s = (l1 + l2 + l3)*0.5;
area = sqrt( s.*(s-l1).*(s-l2).*(s-l3));
area(area<1e-5)=1e-5;
cot12 = (l1.^2 + l2.^2 - l3.^2)./area/4;
cot23 = (l2.^2 + l3.^2 - l1.^2)./area/4; 
cot31 = (l1.^2 + l3.^2 - l2.^2)./area/4; 
diag1 = -cot12-cot31; diag2 = -cot12-cot23; diag3 = -cot31-cot23;
II = [f1 f2 f2 f3 f3 f1 f1 f2 f3];
JJ = [f2 f1 f3 f2 f1 f3 f1 f2 f3];
V = [cot12' cot12' cot23' cot23' cot31' cot31' diag1' diag2' diag3'];
cot = sparse(II,JJ,V,size(v,2),size(v,2));

% face_num = size(f,2);
% vertex_num = size(v,2);
% face_idx = repmat((1:face_num),3,1);
% vf_matrix = sparse(f(:),face_idx(:), ones(1, 3*face_num), vertex_num, face_num);
% v_area = vf_matrix * area' / 3;
% v_area_matrix = spdiags(0.5 ./v_area, 0, vertex_num, vertex_num);
% 
% L = v_area_matrix * cot;
L = cot / 2;

end


% -------------------------------------------------------
function MyDifferential = diff_operator(vertex, face)
    n = size(face, 2);
    Mi = reshape([1:n;1:n;1:n], [1,3*n]);
    Mj = reshape(face, [1,3*n]);
    [e1,e2,e3]= GetEdge(vertex,face);
    area = GetSignedArea_edge(e1, e2);
    area = [area;area;area];
    Mx = reshape([e1(2,:);e2(2,:);e3(2,:)]./area /2 , [1, 3*n]);
    My = -reshape([e1(1,:);e2(1,:);e3(1,:)]./area /2 , [1, 3*n]);
    Dx = sparse(Mi,Mj,Mx);
    Dy = sparse(Mi,Mj,My);
    Dz = (Dx - 1i*Dy) / 2; 
    Dc = (Dx + 1i*Dy) / 2;
    MyDifferential = struct('Dx', Dx, 'Dy', Dy, 'Dz', Dz, 'Dc', Dc);
end
function [e1, e2, e3] = GetEdge(vertex,face)
    e1 = vertex(1:2,face(3,:)) - vertex(1:2,face(2,:));
    e2 = vertex(1:2,face(1,:)) - vertex(1:2,face(3,:));
    e3 = vertex(1:2,face(2,:)) - vertex(1:2,face(1,:));
end
function area = GetSignedArea_edge(e1, e2)
    xb = -e1(1,:);
    yb = -e1(2,:);
    xa = e2(1,:);
    ya = e2(2,:);
    area = ( xa.*yb - xb.*ya )/2;
end