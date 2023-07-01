function T = geotable2table(GT,varnames)
%

% geotable2table - Convert geospatial table to table
% 
%   T = geotable2table(GT) converts the M-by-N geospatial table GT to an
%   M-by-N table T. The Shape variable is replaced with a well-known text
%   string representation.
% 
%   T = geotable2table(GT,varnames) replaces the Shape variable with the
%   specified table variable names. Replace the Shape variable with a table
%   variable containing well-known text strings by specifying varnames as a
%   string scalar. Replace the Shape variable with two table variables
%   containing latitude and longitude coordinates or x and y coordinates by
%   specifying varnames as a string vector.
% 
%   Example 1
%   ---------
%   GT = readgeotable("worldcities.shp");
%   T = geotable2table(GT,["Latitude","Longitude"]);
% 
%   Example 2
%   ---------
%   % View the well-known text string for a specific street line.
%   GT = readgeotable("boston_roads.shp");
%   T = geotable2table(GT);
%   wkt = T.Shape(T.STREETNAME == "C STREET")
% 
%   See also isgeotable readgeotable table2geotable table2timetable

% Copyright 2021-2022 The MathWorks, Inc.
    
    arguments
        GT {mustBeA(GT,{'table','timetable'})}
        varnames string {mustBeVector} = "Shape"
    end
    
    if ~isgeotable(GT)
        error(message('map:validate:expectedGeospatialTable'))
    end
    
    T = GT;
    if length(varnames) > 1
        T = tableWithCoordinateVectors(T,varnames);
    else
        T = tableWithWKT(T,varnames);
    end
    
    if ~any(matches(varnames,"Shape"))
        T = removevars(T,"Shape");
    end
end


function T = tableWithCoordinateVectors(T,varnames)
    % Take variable names from the shapes and translate them to the
    % varnames specified for table variables
    shape = T.Shape;
    if shape.CoordinateSystemType == "geographic"
        shapeVariableNames = ["Latitude","Longitude"];
    else
        shapeVariableNames = ["X","Y"];
    end
    
    S = shapeToStructure(shape);
    T.(varnames(1)) = S.(shapeVariableNames(1));
    T.(varnames(2)) = S.(shapeVariableNames(2));
end


function T = tableWithWKT(T,wktvar)
    % Create a WKT representation of the shape geometry
    S = exportShapeData(T.Shape);
    try
        wktstrings = map.shape.internal.shapesToWKT(S);
    catch err
        throw(err)
    end
    T.(wktvar) = wktstrings;
end
