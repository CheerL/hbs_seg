function Result = computeTriPreconditioner(s1,s2,s3,c1,c2,b)

B = b;
b = reshape(b(1:end-2),[],2);
b1 = b(:,1);
b2 = b(:,2);

s1 = sqrt(s1);
s2 = s2./s1;
s3 = sqrt(s3-s2.^2);

b1 = b1./s1;
b2 = (b2-s2.*b1)./s3;

b2 = b2./s3;
b1 = (b1-s2.*b2)./s1;

Result = [b1;b2;B(end-1)/c1;B(end)/c2];