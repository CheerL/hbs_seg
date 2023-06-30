

function v = computeTridiagonalM(T,v,c)

v = reshape(c*v,[],2);
s = sum(T.*v,2);
v = [T(:,1).*s;T(:,2).*s];