function result = compute_PQRTv_2(p,q,m,KT1,KT2)

p =reshape(p,[m,2]);
q =reshape(q,[m,2]);


result = convn(p(:,:,1),KT1(:,:,1),'valid')...
       + convn(p(:,:,2),KT1(:,:,2),'valid');     


result = result + convn(q(:,:,1),KT2(:,:,1),'valid')...
       + convn(q(:,:,2),KT2(:,:,2),'valid');
     
result = result(:);

