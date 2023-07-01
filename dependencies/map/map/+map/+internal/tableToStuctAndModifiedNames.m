function [TS,modifiedVarnames] = tableToStuctAndModifiedNames(T)
%tableToStuctAndModifiedNames Convert table to structure array
%
%   [TS, modifiedVarnames] = tableToStuctAndModifiedNames(T) converts the
%   table T to a structure array TS. modifiedVarnames is a scalar structure
%   containing the modified and original table variable names. If table
%   variables names are valid MATLAB identifiers, modifiedVarnames is an
%   empty structure. Warning for modified variable names is temporarily
%   disabled.

% Copyright 2021 The MathWorks, Inc.

    origVarnames = T.Properties.VariableNames(:);
    wstate = warning('off', 'MATLAB:table:ModifiedVarnames');
    warnObj = onCleanup(@()warning(wstate));
    
    TS = table2struct(T);
    
    newVarnames = fieldnames(TS);
    orig_diff = setdiff(origVarnames, newVarnames);
    if ~isempty(orig_diff)
        new_diff = setdiff(newVarnames, origVarnames);
        modifiedVarnames = cell2struct(orig_diff, new_diff);
    else
        modifiedVarnames = struct.empty;
    end
end
