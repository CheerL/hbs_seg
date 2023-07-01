%

%MAPCLIP Clip shape to X-Y limits in planar coordinates
%
%   CLIPPED = MAPCLIP(SHAPE,XLIMITS,YLIMITS) clips a mappointshape,
%   maplineshape, or mappolyshape object or array to the X-Y limits
%   specified by the 1-by-2 vectors XLIMITS and YLIMITS. CLIPPED is the
%   same type and size as SHAPE. If an element of SHAPE lies completely
%   outside the specified limits, then the corresponding element of CLIPPED
%   does not contain coordinate data.
%
%   Example 1
%   ---------
%   places = readgeotable("boston_placenames.shp");
%   xlimits = [235226 237174];
%   ylimits = [900179 901059];
%   clipped = mapclip(places.Shape,xlimits,ylimits);
%   figure
%   mapshow(places,'MarkerEdgeColor','k')
%   mapshow(table(clipped,'VariableNames',{'Shape'}))
%   mapshow(xlimits([1 1 2 2 1]),ylimits([1 2 2 1 1]))
%
%   Example 2
%   ---------
%   hydro_lines = readgeotable("concord_hydro_line.shp");
%   hydro_areas = readgeotable("concord_hydro_area.shp");
%   xlimits = [206600 208700];
%   ylimits = [910500 912100];
%   lclip = mapclip(hydro_lines.Shape,xlimits,ylimits);
%   aclip = mapclip(hydro_areas.Shape,xlimits,ylimits);
%   figure
%   mapshow(table(aclip,'VariableNames',{'Shape'}))
%   mapshow(table(lclip,'VariableNames',{'Shape'}))
%   mapshow(xlimits([1 1 2 2 1]),ylimits([1 2 2 1 1]),'Color','k')
%
%   See also GEOCLIP, MAPCROP

% Copyright 2021-2022 The MathWorks, Inc.

function clipped = mapclip(obj, xlimits, ylimits) %#ok<*STOUT> 
    arguments
        obj map.shape.MapShape %#ok<*INUSA> 
        xlimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
        ylimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
    end
    % No function body is needed here because if obj is actually a
    % MapShape, execution will dispatch to the mapclip method of
    % class(obj).
end
