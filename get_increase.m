function idx = get_increase(x)
%UNTITLED 此处显示有关此函数的摘要
%   此处显示详细说明
start_pos = [1;find(diff(x)<=0)+1];
end_pos = [find(diff(x)<=0);size(x,1)];
num = size(start_pos,1);
idx = start_pos(1):end_pos(1);

for i=2:num
    idx = sub_get_increase(x, idx, start_pos(i),end_pos(i));
end
end

function idx = sub_get_increase(x, idx, s, e)
    length1 = size(idx,2);
    length2 = e-s+1;
    if x(idx(length1)) < x(s)
        idx = [idx,s:e];
        return
    end
    if length1 < length2
        idx = sub_get_increase(x, idx, s, s+length1-1);
        idx = sub_get_increase(x, idx, s+length1, e);
    else
        if length1 == 1
            idx = s:e;
            return
        elseif x(idx(length1-1)) < x(s)
            idx = [idx(1:length1-1),s:e];
            return
        elseif length2 == 1
            return
        elseif x(idx(length1)) < x(s+1)
            idx = [idx(1:length1),s+1:e];
            return
        elseif x(idx(length1-1)) < x(s+1)
            idx = [idx(1:length1-1),s+1:e];
            return
        end
        idx = sub_get_increase(x, idx(1:length1-1), s+1, e);
        return
    end
end
