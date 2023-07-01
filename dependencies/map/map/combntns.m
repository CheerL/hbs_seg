function c = combntns(choicevec,choose)
% COMBNTNS has been removed. Use NCHOOSEK instead. 

% Copyright 1996-2022 The MathWorks, Inc.

ric = matlab.lang.correction.ReplaceIdentifierCorrection("combntns","nchoosek");
error(ric,message("map:removed:combntns","COMBNTNS","NCHOOSEK"))
