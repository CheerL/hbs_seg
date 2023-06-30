addpath('./dependencies');
addpath('./dependencies/im2mesh');
addpath('./dependencies/mfile');
addpath('./dependencies/aco-v1.1/aco');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
boundary_point_num = 200;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('bc_dict','var')
    bc_dict = struct();
end

for d={'camel' 'deer' 'dog' 'elephant' 'giraffe' 'gorilla' 'rabit'}
% for d={'camel'}
imgs = dir(['img/' d{1} '/*.png']);
for k=1:length(imgs)

fname = ['img/' d{1} '/' imgs(k).name];
disp(fname);
% fname = 'img/fish/3.png';
dname = strsplit(fname, '.');
dname = strsplit(dname{1}, '/');
dname = strcat(dname{2:end});
im = Mesh.read(fname);
bound = Mesh.get_bound(im, boundary_point_num);
try
[hbs, he, xq, yq, face, vert, face_center] = HBS(bound, 1000);
bc_dict.(dname)=struct('bc',hbs,'x',xq,'y',yq,'bound',bound,'im',im,'name',fname);
catch
end

% trans = @(z, k) (1-k).*z;
% p2shape_dis = @(p, s) min(abs(s-p));
% shape2shape_dis = @(s1, s2) max(arrayfun(@ (p) p2shape_dis(p, s2), s1));
% shape_dis = @(s1, s2) mean([shape2shape_dis(s1, s2), shape2shape_dis(s2, s1)]);
% hbs1 = hbs;
% rb1 = HBS_reconstruct(hbs, face,vert);
% dhbs = [];
% doo = [];
% for k=0:0.01:0.1
% hbs = trans(hbs1,k);
% [rbound, map, map_mu] = HBS_reconstruct(hbs, face,vert);
% d1 = max(abs(hbs-hbs1));
% d2 = shape_dis(rb1, rbound);
% if ~isnan(d1) && ~isnan(d2)
% dhbs = [dhbs,d1];
% doo = [doo,d2];
% end

% sprintf('k=%d, HBS dis=%f, Shape dis=%f', k,d1,d2)
%%%%%%%%%%%%%%%% show
if 0
    Plot.plotall(bound, xq, yq, face_center, hbs, fname); 
% figure;
% hold on;
% subplot(1,2,1);
% Plot.pri_plotBC(face_center, hbs);
% box on;
% subplot(1,2,2);
% Plot.pri_complex_show(rbound);
% box on;
% set(gcf, 'color','w')
% hold off;
%     try
%         if abs(hbs1)
%             figure;
%             histogram(abs(hbs1-hbs));set(gcf, 'color','w');box on;
%             sqrt(mean(abs(hbs1-hbs).^2))
%         end
%     catch
%     end
end
% end
end
end
