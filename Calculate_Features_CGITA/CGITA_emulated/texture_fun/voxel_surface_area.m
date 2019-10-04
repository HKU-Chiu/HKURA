function feature_output = voxel_surface_area(varargin)
global image_global;
global image_property;
global mask_for_TA;
global tumor_surface_area_CGITA;
% global image_global_ni;
% global mask_ni;
%%%% NOTE: I cannot gaurantee that this code is correct when the voxel
%%%% sizes on the x and y directions are not identical
%image_property.pixel_spacing = img_obj.pixel_spacing;

if exist('image_global')==1
    
    area_vec = [image_property.pixel_spacing(2)*image_property.pixel_spacing(3) image_property.pixel_spacing(2)*image_property.pixel_spacing(3) ...
        image_property.pixel_spacing(1)*image_property.pixel_spacing(3) image_property.pixel_spacing(1)*image_property.pixel_spacing(3) ...
        image_property.pixel_spacing(1)*image_property.pixel_spacing(2) image_property.pixel_spacing(1)*image_property.pixel_spacing(2)]' / 1e2; % convert to cm^2
    
    mask = varargin{4}.mask_vol_for_TA_extended{1}{1};
    area_sum = 0;
    for idx1 = 2:size(mask, 1)-1
        for idx2 = 2:size(mask, 2)-1
            for idx3 = 2:size(mask, 3)-1
                if mask(idx1, idx2, idx3)==1
                    area_sum = area_sum + (~[mask(idx1-1, idx2, idx3) mask(idx1+1, idx2, idx3) mask(idx1, idx2-1, idx3) mask(idx1, idx2+1, idx3) mask(idx1, idx2, idx3-1) mask(idx1, idx2, idx3+1)])*area_vec;
                end
            end
        end
    end
    
    feature_output = area_sum;
    tumor_surface_area_CGITA = feature_output;
else
    error('The parent image must be computed first');
end
% if exist('image_global')==1
%     temp1 = image_global(:);
%     nonzero_voxels = length(temp1(find(mask_for_TA)));
%     %nonzero_voxels = sum(mask_ni(:));
%     feature_output = nonzero_voxels  * prod(image_property.pixel_spacing) / 1e3; % convert to mL
%     
% else
%     error('The parent image must be computed first');
% end

return;