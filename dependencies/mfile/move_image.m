function deform = move_image(moving,vertex,map,view)

[height,width] = size(moving);
temp = scatteredInterpolant(map(:,1),map(:,2),moving(:));
deform = flipud(reshape(temp(vertex(:,1),vertex(:,2)),height,width));

if view
    figure
    imshow(deform);
end

end