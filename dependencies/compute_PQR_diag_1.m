function result = compute_PQR_diag_1(pp,pq,qq,m,K11,K22,K12)

pp = reshape(pp,[m,2]);
pq = reshape(pq,[m,2]);
qq = reshape(qq,[m,2]);


result = convn(pp(:,:,1),K11(:,:,1),'valid')...
       + convn(pp(:,:,2),K11(:,:,2),'valid');
      
result = result+convn(pq(:,:,1),K12(:,:,1),'valid')...
       + convn(pq(:,:,2),K12(:,:,2),'valid');
      
result = result+convn(qq(:,:,1),K22(:,:,1),'valid')...
       + convn(qq(:,:,2),K22(:,:,2),'valid');
      

result = result(:);