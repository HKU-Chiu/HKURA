for voi_idx = 1:length(list_idx)
    [handles.contour_volume handles.mask_volume first_slice last_slice] = return_volume_contour_mask(handles.VOI_obj(list_idx(voi_idx)).contour, handles);
    mask = handles.mask_volume;
    if sum(mask(:)) > 1
        [range extended_range] = determine_mask_range(mask);
        handles.range{1} = range;
        handles.image_vol_for_TA{1}{voi_idx} = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1}) .* mask(range{3}, range{2}, range{1});
                        
        handles.mask_vol_for_TA{1}{voi_idx} = mask(range{3}, range{2}, range{1});
        handles.mask_vol_for_TA_extended{1}{voi_idx} = mask(extended_range{3}, extended_range{2}, extended_range{1});
        
        % Perform the digitization
        % First, determine the digitization parameters
        switch handles.digitization_flag
            case 0 % 0 - use the min and max within the masked volume for digitization (default)
                tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1}) .* mask(range{3}, range{2}, range{1});
                digitization_min = min(tempimg(find(mask(range{3}, range{2}, range{1}))));
                digitization_max = max(tempimg(find(mask(range{3}, range{2}, range{1}))));
            case 1 % 1 - use the min and max within the rectangular cylinder volume
                tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1});
                digitization_min = min(tempimg(:));
                digitization_max = max(tempimg(:));
            case 2 % 2 - use 0 and max within the masked volume for digitization
                tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1}) .* mask(range{3}, range{2}, range{1});
                digitization_min = 0;
                digitization_max = max(tempimg(find(mask(range{3}, range{2}, range{1}))));
            case 3 % 3 - use 0 and max within the rectangular cylinder volume
                tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1});
                digitization_min = 0;
                digitization_max = max(tempimg(:));
            case 4 % 4 - use preset min and max values (needs to assign both values)
                digitization_min = handles.default_digitization_min;
                digitization_max = handles.default_digitization_max;
        end
        
        tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1}) .* mask(range{3}, range{2}, range{1});
        tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
        handles.resampled_image_vol_for_TA{1}{voi_idx} = tempimg;
        
        tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1});
        tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
        handles.resampled_image_vol_for_TA_unmasked{1}{voi_idx} = tempimg;
        
        switch handles.digitization_flag
            case 0 % 0 - use the min and max within the masked volume for digitization (default)
                tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1})  .* mask(extended_range{3}, extended_range{2}, extended_range{1});
                digitization_min = min(tempimg(find(mask(extended_range{3}, extended_range{2}, extended_range{1}))));
                digitization_max = max(tempimg(find(mask(extended_range{3}, extended_range{2}, extended_range{1}))));
            case 1 % 1 - use the min and max within the rectangular cylinder volume
                tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1});
                digitization_min = min(tempimg(:));
                digitization_max = max(tempimg(:));
            case 2 % 2 - use 0 and max within the masked volume for digitization
                tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1})  .* mask(extended_range{3}, extended_range{2}, extended_range{1});
                digitization_min = 0;
                digitization_max = max(tempimg(find(mask(extended_range{3}, extended_range{2}, extended_range{1}))));
            case 3 % 3 - use 0 and max within the rectangular cylinder volume
                tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1});
                digitization_min = 0;
                digitization_max = max(tempimg(:));
            case 4 % 4 - use preset min and max values (needs to assign both values)
                digitization_min = handles.default_digitization_min;
                digitization_max = handles.default_digitization_max;
        end
        
        tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1})  .* mask(extended_range{3}, extended_range{2}, extended_range{1});
        tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
        handles.resampled_image_vol_for_TA_extended{1}{voi_idx} = tempimg;
        
        tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1});
        tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
        handles.resampled_image_vol_for_TA_unmasked_extended{1}{voi_idx} = tempimg;
        
        if handles.Fusion_images_loaded
            [handles.fusion_contour_volume handles.fusion_mask_volume] = return_volume_contour_mask_Fusion_image(handles.VOI_obj(list_idx(voi_idx)).contour, handles);
            % Second, get the masked voxels
            fusion_mask = handles.fusion_mask_volume;
            % Third, send the masked voxels for texturare analysis
            [fusion_range fusion_extended_range] = determine_mask_range(fusion_mask);
            handles.range{2} = fusion_range;
            
            handles.image_vol_for_TA{2}{voi_idx} = handles.Fusion_image_obj.image_volume_data(fusion_range{3}, fusion_range{2},fusion_range{1}) .* ...
                fusion_mask(fusion_range{3}, fusion_range{2}, fusion_range{1});
            
            handles.mask_vol_for_TA{2}{voi_idx} = fusion_mask(fusion_range{3}, fusion_range{2}, fusion_range{1});
            handles.mask_vol_for_TA_extended{2}{voi_idx} = fusion_mask(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1});
            
            switch handles.digitization_flag
                case 0 % 0 - use the min and max within the masked volume for digitization (default)
                    tempimg = handles.Fusion_image_obj.image_volume_data(fusion_range{3}, fusion_range{2}, fusion_range{1}) .* fusion_mask(fusion_range{3}, fusion_range{2}, fusion_range{1});
                    digitization_min = min(tempimg(:));
                    digitization_max = max(tempimg(:));
                case 1 % 1 - use the min and max within the rectangular cylinder volume
                    tempimg = handles.Fusion_image_obj.image_volume_data(fusion_range{3}, fusion_range{2}, fusion_range{1});
                    digitization_min = min(tempimg(:));
                    digitization_max = max(tempimg(:));
                case 2 % 2 - use 0 and max within the masked volume for digitization
                    tempimg = handles.Fusion_image_obj.image_volume_data(fusion_range{3}, fusion_range{2}, fusion_range{1}) .* fusion_mask(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1});
                    digitization_min = 0;
                    digitization_max = max(tempimg(:));
                case 3 % 3 - use 0 and max within the rectangular cylinder volume
                    tempimg = handles.Fusion_image_obj.image_volume_data(fusion_range{3}, fusion_range{2}, fusion_range{1});
                    digitization_min = 0;
                    digitization_max = max(tempimg(:));
                case 4 % 4 - use preset min and max values (needs to assign both values)
                    digitization_min = handles.default_digitization_min;
                    digitization_max = handles.default_digitization_max;
            end
            
            tempimg = handles.Fusion_image_obj.image_volume_data(fusion_range{3}, fusion_range{2}, fusion_range{1}) .* fusion_mask(fusion_range{3}, fusion_range{2}, fusion_range{1});
            tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
            handles.resampled_image_vol_for_TA{2}{voi_idx} = tempimg;
            
            tempimg = handles.Fusion_image_obj.image_volume_data(fusion_range{3}, fusion_range{2}, fusion_range{1});
            tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
            handles.resampled_image_vol_for_TA_unmasked{2}{voi_idx} = tempimg;
            
            switch handles.digitization_flag
                case 0 % 0 - use the min and max within the masked volume for digitization (default)
                    tempimg = handles.Fusion_image_obj.image_volume_data(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1}) .* fusion_mask(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1});
                    digitization_min = min(tempimg(find(fusion_mask(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1}))));
                    digitization_max = max(tempimg(find(fusion_mask(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1}))));
                case 1 % 1 - use the min and max within the rectangular cylinder volume
                    tempimg = handles.Fusion_image_obj.image_volume_data(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1});
                    digitization_min = min(tempimg(:));
                    digitization_max = max(tempimg(:));
                case 2 % 2 - use 0 and max within the masked volume for digitization
                    tempimg = handles.Fusion_image_obj.image_volume_data(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1}) .* fusion_mask(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1});
                    digitization_min = 0;
                    digitization_max = max(tempimg(find(fusion_mask(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1}))));
                case 3 % 3 - use 0 and max within the rectangular cylinder volume
                    tempimg = handles.Fusion_image_obj.image_volume_data(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1});
                    digitization_min = 0;
                    digitization_max = max(tempimg(:));
                case 4 % 4 - use preset min and max values (needs to assign both values)
                    digitization_min = handles.default_digitization_min;
                    digitization_max = handles.default_digitization_max;
            end
            
            tempimg = handles.Fusion_image_obj.image_volume_data(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1}) ...
                .* fusion_mask(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1});
            tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
            handles.resampled_image_vol_for_TA_extended{2}{voi_idx} = tempimg;
            
            tempimg = handles.Fusion_image_obj.image_volume_data(fusion_extended_range{3}, fusion_extended_range{2}, fusion_extended_range{1});
            tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
            handles.resampled_image_vol_for_TA_unmasked_extended{2}{voi_idx} = tempimg;
            
        end
    end
end