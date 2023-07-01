function tf = isgeotable(T)
    %

    %ISGEOTABLE Determine if input is geospatial table
    %
    % tf = isgeotable(A) returns logical 1 (true) if A is a geospatial
    % table and logical 0 (false) otherwise.
    %
    % Example:
    % --------
    % T = readgeotable('concord_roads.shp');
    % tf = isgeotable(T);
    %
    % See also istable readgeotable
    
    % Copyright 2021-2022 The MathWorks, Inc.
    
    tf = isa(T,'tabular') ... % Must be tabular (table or timetable)
        && ~isempty(T.Properties.VariableNames) ... % The variable name array must not be empty
        && strcmp(T.Properties.VariableNames(1),'Shape') ... % The first variable must be 'Shape'
        && isa(T.Shape,'map.shape.Shape') ... % The 'Shape' variable must be a shape class instance
        && iscolumn(T.Shape); % The Shape variable must be a column vector
end
