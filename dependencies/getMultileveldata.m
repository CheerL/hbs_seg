
function MLdata = getMultileveldata(dataT,m,omega,MinLevel,MaxLevel)

     
xc = getCellCenteredGrid(omega,m);

T = linearInter(dataT,omega,xc);
T = reshape(T,m);

Singledata.T = T;
Singledata.m = m;

MLdata{MaxLevel} = Singledata;


for Level = MaxLevel-1:-1:MinLevel
    mLevel = m/(2^(MaxLevel-Level));
    
    T = MLdata{Level+1}.T;
    T = (T(1:2:end-1,1:2:end-1)+T(1:2:end-1,2:2:end)+T(2:2:end,1:2:end-1)+T(2:2:end,2:2:end))/4; 

    Singledata.T = T;
    Singledata.m = mLevel;
    
    MLdata{Level} = Singledata;

end
