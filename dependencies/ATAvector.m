

function p = ATAvector(p,m,K1_1,K2_1)

p = reshape(p,[m-1,2]);
p = convn(p,K1_1,'same')+convn(p,K2_1,'same');
p = p(:);


