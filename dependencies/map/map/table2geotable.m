function GT = table2geotable(T,coordinateSystemType,varnames,namevalue)
% table2geotable - Convert table to geospatial table
% 
%   GT = table2geotable(T) converts the M-by-N table or timetable T to an
%   M-by-(N+1) geospatial table GT. The function creates the Shape table
%   variable using latitude and longitude variables or x and y variables.
% 
%   GT = table2geotable(T,coordinateSystemType,varnames) creates GT using
%   the specified coordinateSystemType ("geographic" or "planar") and
%   creates the Shape variable using the specified string scalar or vector
%   of table variables. If varnames is a string scalar, it represents a
%   variable name corresponding to a table variable containing well-known
%   text strings. If varnames is a string vector, it represents the
%   latitude and longitude coordinate table variables or x and y coordinate
%   table variables.
% 
%   GT = table2geotable(___,"CoordinateReferenceSystem",crs) specifies the
%   coordinate reference system object crs to assign to the Shape variable.
%   Specify crs as a projcrs object when coordinateSystemType is "planar"
%   and as a geocrs object when coordinateSystemType is "geographic".
% 
%   GT = table2geotable(___,"GeometryType",geom) specifies the geometry
%   type geom of the coordinate variables. geom is one of "point", "line",
%   or "polygon". By default, geom is "point" for coordinate variables.
% 
%   Example
%   -------
%   T = readtable("tsunamis.xlsx");
%   GT = table2geotable(T);
% 
%   See also geotable2table readgeotable readtable table2timetable

% Copyright 2021-2022 The MathWorks, Inc.
    
    arguments
        T {mustBeA(T,{'table','timetable'}), mustBeNonempty}
        coordinateSystemType (1,1) string = ""
        varnames string {mustBeVector} = ""
        namevalue.CoordinateReferenceSystem {mustBeScalarOrEmpty}
        namevalue.GeometryType (1,1) string
    end

    GT = T;
    if isfield(namevalue,"GeometryType")
        geomtype = namevalue.GeometryType;
        geomtype = validatestring(geomtype,["point","line","polygon"],"","GeometryType");
    else
        geomtype = "point";
    end
    
    if isfield(namevalue,"CoordinateReferenceSystem")
        crs = namevalue.CoordinateReferenceSystem;
        if ~(isa(crs,"projcrs") || isa(crs,"geocrs"))
            error(message("map:geotable:ExpectedCRS"))
        end
    else
        crs = [];
    end

    switch nargin % nargin does not factor in arguments block name-value pairs
        case 1
            % No dimension variable names specified. Guess them from from a
            % list of predetermined variable names.
            [coordinateVars, coordinateSystemType] = tableCoordinateVariables(T);
            shape = shapeFromCoordinateVectors(coordinateSystemType,...
                geomtype,crs,T.(coordinateVars(1)),T.(coordinateVars(2)));
            GT.Shape = shape;
            GT = movevars(GT,"Shape","Before",1);
        case 2
            % Not enough inputs if we don't guess the columns
            coordinateSystemType = validatestring(coordinateSystemType,...
                ["geographic","planar"],"","coordinateSystemType");
            
            [coordinateVars, detectedCST] = tableCoordinateVariables(T);
            if ~matches(coordinateSystemType, detectedCST)
                error(message("map:geotable:SpecifyCoordinateVariables"))
            end
            shape = shapeFromCoordinateVectors(coordinateSystemType,...
                geomtype,crs,T.(coordinateVars(1)),T.(coordinateVars(2)));
            GT.Shape = shape;
            GT = movevars(GT,"Shape","Before",1);
        case 3
            coordinateSystemType = validatestring(coordinateSystemType,...
                ["geographic","planar"],"","coordinateSystemType");
            
            % Use varnames for the columns
            if length(varnames) > 1
                % Two coordinate vectors
                shape = shapeFromCoordinateVectors(coordinateSystemType,...
                    geomtype,crs,T.(varnames(1)),T.(varnames(2)));
                GT.Shape = shape;
                GT = movevars(GT,"Shape","Before",1);
            else
                % One WKT string vector
                GT = geotableFromWKT(T,coordinateSystemType,varnames,crs);
                if isfield(namevalue,"GeometryType")
                    warning(message("map:geotable:GeometryTypeMixingWithWKT"))
                end
            end
    end
end


function T = geotableFromWKT(T,coordinateSystemType,varnames,crs)
    wktstrings = convertCharsToStrings(T.(varnames));
    if isstring(wktstrings)
        try
            S = map.shape.internal.shapesFromWKT(wktstrings);
            if coordinateSystemType == "geographic"
                shape = map.shape.GeographicShape.makeGeographicShape(S);
                shape.GeographicCRS = crs;
            else
                shape = map.shape.MapShape.makeMapShape(S);
                shape.ProjectedCRS = crs;
            end
        catch err
            error(message("map:geotable:UnableToCreateShapeFromWKT"))
        end
        if all(S.GeometryType == 0)
            error(message("map:geotable:InvalidWKT"))
        end
        T.Shape = shape;
        T = movevars(T,"Shape","Before",1);
    else
        error(message("map:geotable:WKTMustBeString"))
    end
end
