
names = sort(fieldnames(bc_dict));
n = length(names);
cw_dis = zeros(n,n);
hbs_dis = zeros(n,n);
sc_dis = zeros(n,n);
bm_dis = zeros(n,n);
tic
for i=1:n
    for j=i+1:n
        i_data = getfield(bc_dict, names{i});
        j_data = getfield(bc_dict, names{j});
        i_bound = Tools.complex2real(i_data.bound);
        j_bound = Tools.complex2real(j_data.bound);
        cw = sqrt(mean(abs(i_data.y-j_data.y).^2));
        hbs = sqrt(mean(abs(abs(i_data.bc)-abs(j_data.bc)).^2));
%         [~,~,sc]=shape_matching(i_bound, j_bound);
%         bm = norm(get_boundary_moments(i_bound)-get_boundary_moments(j_bound));

        cw_dis(i,j) = cw;
        cw_dis(j,i) = cw;
        hbs_dis(i,j) = hbs;
        hbs_dis(j,i) = hbs;
%         sc_dis(i,j) = sc;
%         sc_dis(j,i) = sc;
%         bm_dis(i,j) = bm;
%         bm_dis(j,i) = bm;
    end
end
toc
figure;
heatmap(cw_dis, 'XDisplayLabels', names,'YDisplayLabels', names);
set(gcf, 'color','w')

figure;
heatmap(hbs_dis, 'XDisplayLabels', names,'YDisplayLabels', names);
set(gcf, 'color','w')

% figure;
% heatmap(sc_dis, 'XDisplayLabels', names,'YDisplayLabels', names);
% set(gcf, 'color','w')
% 
% figure;
% heatmap(bm_dis, 'XDisplayLabels', names,'YDisplayLabels', names);
% set(gcf, 'color','w')
