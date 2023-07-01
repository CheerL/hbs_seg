function shape = shapeFromCoordinateVectors(coordinateSystemType,geomtype,crs,var1,var2)
    % shapeFromCoordinateVectors - create shape from coordinate vectors
    
    % Copyright 2021 The MathWorks, Inc.
    
    if isa(crs,"geocrs") && matches(coordinateSystemType,"planar")
        % A planar coordinate system was requested, but the CRS is geographic.
        error(message('map:geotable:InconsistentCRS','planar'))
    elseif isa(crs,"projcrs") && matches(coordinateSystemType,"geographic")
        % A geographic coordinate system was requested, but the CRS is planar.
        error(message('map:geotable:InconsistentCRS','geographic'))
    end
    
    try
        switch geomtype
            case 'point'
                if coordinateSystemType == "geographic"
                    shape = geopointshape(var1,var2);
                    shape.GeographicCRS = crs;
                else
                    shape = mappointshape(var1,var2);
                    shape.ProjectedCRS = crs;
                end
            case 'line'
                if coordinateSystemType == "geographic"
                    shape = geolineshape(var1,var2);
                    shape.GeographicCRS = crs;
                else
                    shape = maplineshape(var1,var2);
                    shape.ProjectedCRS = crs;
                end
            case 'polygon'
                if coordinateSystemType == "geographic"
                    shape = geopolyshape(var1,var2);
                    shape.GeographicCRS = crs;
                else
                    shape = mappolyshape(var1,var2);
                    shape.ProjectedCRS = crs;
                end
        end
    catch e
        error(message("map:geotable:UnableToCreateShape", e.message))
    end
end
