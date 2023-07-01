function [bound, inner, outer, nvert, nface] = HBS_reconstruct(hbs, face, vert, mesh_height, mesh_width, mesh_density)
if nargin < 6
    mesh_density = 50;
end
if nargin == 3
    mesh_height = mesh_density * 4;
    mesh_width = mesh_height;
elseif nargin == 4
    mesh_width = mesh_height;
end


circle_point_num = length(vert(abs(Tools.norm(vert) - 1) < 1e-4,:));
[nface, nvert, ~, outer_vert] = Mesh.rect_mesh_from_disk(face, vert, mesh_height, mesh_width, mesh_density);

zero_pos = find(all([vert(:,1)==0, vert(:,2)==0], 2));
one_pos = find(all([vert(:,1)==1, vert(:,2)==0], 2));
landmark = [one_pos;zero_pos];
target = [1 0;0 0];

map = lsqc_solver(face, vert, hbs, landmark, target);
map = Tools.real2complex(map);
ori_bound = Tools.real2complex(vert(1:circle_point_num, :));
map_bound = map(1:circle_point_num);
[map, ~] = geodesicwelding(map, [], map_bound, ori_bound);
bound = map(1:circle_point_num);
inner = map(circle_point_num+1:end);

[zipper_bound, ~ ,params] = Zipper.zipper(flipud(bound));
[~, a, theta] = Normalization.postnorm_outer(zipper_bound, params);
normal_zipper_bound = Zipper.zipper_inv(Tools.mobius(ori_bound, a, theta), params);
[~, pos] = min(abs(angle(normal_zipper_bound)));
rotation = exp((pos-1)/circle_point_num*2*pi*1i);
outer = Zipper.zipper_inv(Tools.mobius(Tools.real2complex(outer_vert) * rotation, a, theta), params);

end

