function [xi, yi] = firstPolygonIntersection(polygon, xs, ys, vx, vy)
% For each element of xs, ys, vx, and vy, find the first polygon boundary
% intersection with the the ray originating at (xs(k), ys(k)) and going in the
% direction indicated by (vx(k), vy(k)). Return NaNs if there is no
% intersection. Inputs xs, ys, vx, and vy must match in size, and outputs xi and
% yi will have that size also.

% Copyright 2022 The MathWorks, Inc.

    arguments
        polygon (1,1) polyshape
        xs double
        ys double
        vx double
        vy double
    end

    % Length of hypotenuse of bounding rectangle
    [xlimits, ylimits] = boundingbox(polygon);
    diagonal = hypot(diff(xlimits), diff(ylimits));

    % Choose end points along rays guaranteed to be exterior to polygon.
    vnorm = hypot(vx, vy);
    xe = xs + diagonal * vx ./ vnorm;
    ye = ys + diagonal * vy ./ vnorm;

    % Computations have been fully vectorized up to this point. But now we need
    % to iterate over the elements of xs, ys, xe, and ye while analyzing their
    % intersections separately.
    xi = NaN(size(xs));
    yi = xi;
    for k = 1:numel(xs)
        [xi(k), yi(k)] = intersectLineSegmentWithPolygon(polygon, xs(k), ys(k), xe(k), ye(k));
    end
end


function [xi, yi] = intersectLineSegmentWithPolygon(polygon, xs, ys, xe, ye)
% Find the first intersection of the line segment connecting (xs,ys) to (xe,ye)
% with the boundary of the polygon, returning NaNs if there is no intersection
% or if the intersection falls entirely within the polygon without touching its
% boundary. In any case, the ouputs (xi,yi) are always scalar.

    arguments
        polygon (1,1) polyshape
        xs (1,1) double
        ys (1,1) double
        xe (1,1) double
        ye (1,1) double
    end

    if isinterior(polygon, xs, ys)
        % From the help for polyshape/intersect: The second input to
        % intersect below "is a 2-column matrix whose first column
        % defines the x-coordinates of the input line segments and the
        % second column defines the y-coordinates."
        [inside, ~] = intersect(polygon, [xs, ys; xe, ye]);
        if height(inside) >= 2
            % There is at least one intersection
            %   In the following (because isinterior is true),
            %   inside(I(1),:) == [xs ys] and offset(1) == 0
            %   and the closest point that is not [xs ys] itself
            %   is therefore inside(I(2),:).
            offset = hypot(inside(:,1) - xs, inside(:,2) - ys);
            [~,I] = sort(offset);
            xi = inside(I(2),1);
            yi = inside(I(2),2);
        else
            xi = xs;
            yi = ys;
        end
    else
        xi = NaN;
        yi = NaN;
    end
end
