function X = solvingAXB_SP(A,B,k1,k2,varargin)
%used for solving AX = B, {[N,N]+k1*I+k2*laplace}*[N,N] = [N,N]
%only works for squire matrix.
%by ys.

%additional, A, B is sparse.
numm = numel(B);

%adding I part
dt1 = ones(numm,1);
dt1 = dt1.*k1(:);
dt1 = spdiags(dt1,0,numm,numm);

if nargin<=4
    %try adding laplace part.
    t1 = ones(numm,1)*(-4);
    t1(1) = -2;
    t1(end) = -2;
    t2 = ones(numm,1);

    %Laplace = spdiags(t1) + spdiags(t2,1) + spdiags(t2,-1);

    Laplace = spdiags([t2 t2 t1 t2 t2],[-size(A,1) -1 0 1 size(A,1)],numm,numm);
    
else
    Laplace = varargin{1};
end


LEFT = dt1+k2.*Laplace;
if ~isempty(A)
    AN1 = sparse(numm,numm);

    if sum(abs(A(:)))>0
        for i=1:size(A,1)
            AN1(size(A,1)*(i-1)+1:size(A,1)*(i),size(A,1)*(i-1)+1:size(A,1)*(i)) = A;
        end
    end
    LEFT = AN1 + LEFT;
end
%LEFT = sparse(LEFT);
%XN1 = LEFT\BN1;


%Exleft = LEFT'*LEFT;
%Exright = LEFT'*BN1;
XN1 = solveAXB_SP(LEFT,B(:));
% XN1 = LEFT\B(:);
% XN1 = mldivide(LEFT,B(:));

%XN1 = Exleft\Exright;

X = reshape(XN1,[size(B,1),size(B,2)]);
