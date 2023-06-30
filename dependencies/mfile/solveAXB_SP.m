function X = solveAXB_SP(A,B)
%used for solving AX = B, X is [row*col,1];
%only works for squire matrix.
%by ys.

%additional A is sparse.

iteration = 100;

%get parameter

%row = sqrt(row);
%col = row;
x0 = sparse(size(A,1),1);
x = x0;

r = B-A*x;
p=r;
rsold = r'*r;

for i =1:iteration

    Ap = A*p;
    alpha = rsold/(p'*Ap+eps);
    dx = alpha * p;
    dr = alpha * Ap;
    dx_norm = norm(dx);
    if dx_norm < 1e-10
        break
    end
    x=x+dx;
    r=r-dr;
    rsnew = r'*r;
                   
    p = r+(rsnew/(rsold+eps))*p;
    rsold=rsnew;
end
X=x;

