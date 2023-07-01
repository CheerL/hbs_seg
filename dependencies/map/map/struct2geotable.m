function GT = struct2geotable(S,coordinateSystemType,varnames,namevalue)
%

% struct2geotable - Convert structure array to geospatial table
% 
%   GT = struct2geotable(S) converts the structure array S to a geospatial
%   table GT. The function creates the Shape table variable using latitude
%   and longitude fields or x and y fields. When S is a non-scalar
%   structure array with M elements and N fields, then GT is M-by-(N+1).
% 
%   GT = struct2geotable(S,coordinateSystemType,fnames) creates GT using
%   the specified coordinateSystemType ("geographic" or "planar") and
%   creates the Shape variable using the specified string vector of struct
%   field names fnames. fnames represents the latitude and longitude
%   coordinate variable field names or x and y coordinate variable field
%   names.
% 
%   GT = struct2geotable(___,"CoordinateReferenceSystem",crs) specifies the
%   coordinate reference system object crs to assign to the Shape variable.
%   Specify crs as a projcrs object when coordinateSystemType is "planar"
%   and as a geocrs object when coordinateSystemType is "geographic".
% 
%   GT = struct2geotable(___,"GeometryType",geom) specifies the geometry
%   type geom of the coordinate variables. geom is one of "point", "line",
%   or "polygon". By default, geom is "point".
% 
%   Example
%   -------
%   S = shaperead("tsunamis.shp","UseGeoCoords",true);
%   GT = struct2geotable(S);
% 
%   See also readgeotable table2geotable

% Copyright 2021-2022 The MathWorks, Inc.
    
    arguments
        S {mustBeA(S,{'struct'}), mustBeVector}
        coordinateSystemType (1,1) string = ""
        varnames string {mustBeVector} = ""
        namevalue.CoordinateReferenceSystem {mustBeScalarOrEmpty}
        namevalue.GeometryType (1,1) string
    end

    GT = struct2table(S,"AsArray",true);
    if isfield(namevalue,"GeometryType")
        geomtype = replace(lower(namevalue.GeometryType),"multipoint","point");
        geomtype = validatestring(geomtype,["point","line","polygon"],"","GeometryType");
    elseif isfield(S,"Geometry")
        % Try to use the Geometry field to automatically detect geometry
        % type if the struct is a geostruct or mapstruct. The struct cannot
        % be assumed to be a mapstruct or geostruct, so this needs to be
        % checked.
        geomtype = S(1).Geometry;
        if any(strcmp(geomtype,["Point","Line","Polygon"]))
            geomtype = lower(geomtype);
        else
            geomtype = "point";
        end
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
    
    % Get the coordinate variables
    switch nargin % nargin does not factor in arguments block name-value pairs
        case 1
            % No dimension variable names specified. Guess them from from a
            % list of predetermined variable names.
            [coordinateVars, coordinateSystemType] = tableCoordinateVariables(GT);
            var1 = GT.(coordinateVars(1));
            var2 = GT.(coordinateVars(2));
        case 2
            coordinateSystemType = validatestring(coordinateSystemType,...
                ["geographic","planar"],"","coordinateSystemType");
            
            % Not enough inputs if we don't guess the columns
            [coordinateVars, detectedCST] = tableCoordinateVariables(GT);
            if ~matches(coordinateSystemType, detectedCST)
                error(message("map:geotable:SpecifyCoordinateVariables"))
            end
            var1 = GT.(coordinateVars(1));
            var2 = GT.(coordinateVars(2));
        case 3
            coordinateSystemType = validatestring(coordinateSystemType,...
                ["geographic","planar"],"","coordinateSystemType");
            
            % Use varnames for the columns
            if length(varnames) > 1
                % Two coordinate vectors
                var1 = GT.(varnames(1));
                var2 = GT.(varnames(2));
            else
                error(message("map:geotable:SpecifyCoordinateVariables"))
            end
    end
    
    if width(var1) > 1
        var1 = num2cell(var1,2);
        var2 = num2cell(var2,2);
    end
    shape = shapeFromCoordinateVectors(coordinateSystemType,...
        geomtype,crs,var1,var2);

    % Ensure empty coordinate vectors create an empty shape, rather
    % than a non-empty shape with no coordinates. Use repmat to
    % maintain the CRS property value.
    if isempty(var1)
        shape = repmat(shape, numel(S), 1);
    end
    
    GT.Shape = shape;
    GT = movevars(GT,"Shape","Before",1);
end
