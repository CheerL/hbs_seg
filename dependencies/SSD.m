
function [Dc,rc,dD,dr,d2psi,dc1,dc2,d2c1,d2c2] = SSD(Tc,Rc,hd,doDerivative,in,out,c1,c2)

dD = []; dr = []; d2psi = []; dc1=[]; dc2=[]; d2c1=[]; d2c2=[];

rc = Tc - Rc;              		% the residual
Dc = 0.5*hd * (rc'*rc);       	% the SSD
if ~doDerivative, return; end
dr = 1; 						% or speye(length(rc),length(rc)); 
dD = hd * rc'*dr; 
d2psi = hd;

dc1 = hd*(c1*length(in)-sum(Tc(in)));
dc2 = hd*(c2*length(out)-sum(Tc(out)));

d2c1= hd*length(in);
d2c2= hd*length(out);