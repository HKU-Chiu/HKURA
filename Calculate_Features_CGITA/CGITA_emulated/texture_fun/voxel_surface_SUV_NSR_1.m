function feature_output = voxel_surface_SUV_NSR_1(varargin)
global image_global;
global image_property;
global mask_for_TA;
global tumor_surface_area_CGITA;
global tumor_asphericity_CGITA;
global tumor_volume_CGITA;
% global image_global_ni;
% global mask_ni;
%%%% NOTE: I cannot gaurantee that this code is correct when the voxel
%%%% sizes on the x and y directions are not identical
%image_property.pixel_spacing = img_obj.pixel_spacing;
img_in = varargin{2}; % Use the resampled image volume to compute the co-occurrence matrix

if exist('mask_for_TA')==1
        
    mask = mask_for_TA;
    mask_new = zeros(size(mask)+2); mask_new(2:end-1, 2:end-1, 2:end-1) = mask; mask = mask_new;
    image_global2 = zeros(size(image_global)+2); image_global2(2:end-1, 2:end-1, 2:end-1) = image_global;
    
    area_sum = 0;
    counter = 0;
    surf_act = [];
    area_vec = [image_property.pixel_spacing(2)*image_property.pixel_spacing(3) image_property.pixel_spacing(2)*image_property.pixel_spacing(3) ...
        image_property.pixel_spacing(1)*image_property.pixel_spacing(3) image_property.pixel_spacing(1)*image_property.pixel_spacing(3) ...
        image_property.pixel_spacing(1)*image_property.pixel_spacing(2) image_property.pixel_spacing(1)*image_property.pixel_spacing(2)]' / 1e2; % convert to cm^2

    for idx1 = 2:size(mask, 1)-1
        for idx2 = 2:size(mask, 2)-1
            for idx3 = 2:size(mask, 3)-1
                if mask(idx1, idx2, idx3)==1
                    if prod([mask(idx1-1, idx2, idx3) mask(idx1+1, idx2, idx3) mask(idx1, idx2-1, idx3) mask(idx1, idx2+1, idx3) mask(idx1, idx2, idx3-1) mask(idx1, idx2, idx3+1)])==1
                        % this voxel is not on the border
                    else
                        surf_act(end+1) = image_global2(idx1, idx2, idx3);
                        counter = counter+1;
                    end
                end
            end
        end
    end
    
    feature_output = std(surf_act) / mean(surf_act);

%     for idx = 1:max(surf_act(:))
%         p = length(find(surf_act==idx))/length(surf_act);
%         if p>0
%             feature_output = feature_output - p*log(p);
%         end
%     end
    
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