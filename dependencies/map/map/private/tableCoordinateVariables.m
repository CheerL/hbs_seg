function [coordinateVars, coordinateSystemType] = tableCoordinateVariables(T)
    % Try to automatically detect coordinate variables from a table.
    
    % Copyright 2021 The MathWorks, Inc.
    
    vnames = string(T.Properties.VariableNames);
    if length(vnames) < 2
        error(message("map:geotable:SpecifyCoordinateVariables"))
    end

    % Coordinate columns must be numeric (or cell).
    mightBeCoordinate = @(v) isnumeric(v) || iscell(v);
    coordinateCandidates = varfun(mightBeCoordinate,T,'OutputFormat','uniform');

    % Check the table for geographic latitude and longitude columns.
    coordinateSystemType = "geographic";
    latNames = matches(vnames,["lat","latitude"],"IgnoreCase",true);
    dimvar1 = find(coordinateCandidates & latNames,1);
    lonNames = matches(vnames,["lon","longitude","long"],"IgnoreCase",true);
    dimvar2 = find(coordinateCandidates & lonNames,1);

    % No latitude and/or longitude columns automatically detected.
    % Check the table for planar X and Y columns.
    if isempty(dimvar1) || isempty(dimvar2)
        coordinateSystemType = "planar";
        xNames = matches(vnames,"x","IgnoreCase",true);
        dimvar1 = find(coordinateCandidates & xNames,1);
        yNames = matches(vnames,"y","IgnoreCase",true);
        dimvar2 = find(coordinateCandidates & yNames,1);
    end

    % No latitude, longitude, X, or Y columns automatically detected.
    if isempty(dimvar1) || isempty(dimvar2)
        error(message("map:geotable:NoCoordinateVarsFound"))
    end

    coordinateVars = [dimvar1, dimvar2];
end