function feature_output = voxel_peak_SUL(varargin)
global image_global;
global image_property;
global mask_for_TA;
global tumor_surface_area_CGITA;
global tumor_asphericity_CGITA;
global tumor_volume_CGITA;
%image_property.pixel_spacing = img_obj.pixel_spacing;

if (varargin{5} == 1)
    img_original = varargin{4}.Primary_image_obj.image_volume_data;
    mask = varargin{4}.mask_volume;
else
    img_original = varargin{4}.Fusion_image_obj.image_volume_data;
    mask = varargin{4}.fusion_mask_volume;
end

vox_peak = [];
sample_size = 0.01;
if exist('image_global')==1
    [cubic_n, mat2] = calculate_SUV_peak_kernel(image_property.pixel_spacing(1)/10, image_property.pixel_spacing(2)/10, image_property.pixel_spacing(3)/10, sample_size);
    cubic_s = (cubic_n-1)/2;
    %temp1 = image_global(:);
    %nonzero_voxels = temp1(find(mask_for_TA));
    for idx1 = cubic_s+1:size(img_original,1)-cubic_s-1
        for idx2 = cubic_s+1:size(img_original,2)-cubic_s-1
            for idx3 = cubic_s+1:size(img_original,3)-cubic_s-1
                if mask(idx1,idx2,idx3)==1
                    sub_img = img_original(idx1-cubic_s:idx1+cubic_s, idx2-cubic_s:idx2+cubic_s, idx3-cubic_s:idx3+cubic_s);
                    vox_peak(end+1) = sub_img(:)' * mat2;
                end
            end
        end
    end
    
    if length(vox_peak)>0
        feature_output = max(vox_peak) * image_property.patient_LBM_ratio;
    else
        feature_output = NaN;
    end
    
    feature_output = feature_output*tumor_surface_area_CGITA;
else
    error('The parent image must be computed first');
end

return;