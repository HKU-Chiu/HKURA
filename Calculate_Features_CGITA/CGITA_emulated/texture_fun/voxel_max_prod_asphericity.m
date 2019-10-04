function feature_output = voxel_min(varargin)
global image_global;
global image_property;
global mask_for_TA;
global tumor_surface_area_CGITA;
global tumor_asphericity_CGITA;
global tumor_volume_CGITA;
%image_property.pixel_spacing = img_obj.pixel_spacing;


if exist('image_global')==1
    temp1 = image_global(:);
    nonzero_voxels = temp1(find(mask_for_TA));
    
    feature_output = max(nonzero_voxels) * tumor_asphericity_CGITA;
    
else
    error('The parent image must be computed first');
end

return;