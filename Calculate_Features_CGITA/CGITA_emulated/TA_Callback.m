function handles = TA_Callback(handles)
% Creates cubic roi image (zero outside roi)
% Quantizes image
% Performs CGITA analysis with simplified version of "Perform_TA_in_GUI.m" that returns feature data
%
% Adds to handles: 
% image_vol_for_TA
% mask_vol_for_TA
% mask_vol_for_TA_extended
% resampled_image_vol_for_TA
% resampled_image_vol_for_TA_unmasked
% resampled_image_vol_for_TA_extended
% resampled_image_vol_for_TA_unmasked_extended
% range: cell array of length 3, with vector incides per dimension: Z Y X

assert(any(handles.mask_volume(:)),'Can not process empty VOI');
[range, extended_range] = determine_mask_range(handles.mask_volume);
handles.range{1} = range; %cell array of length 1, containing a cell array of length 3

%--- Get: image_vol_for_TA, mask_vol_for_TA (normal/extended), resampled image_vol (masked/unmasked)(normal/extended),
handles.image_vol_for_TA{1}{1}         = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1}) .* handles.mask_volume(range{3}, range{2}, range{1});
handles.mask_vol_for_TA{1}{1}          = handles.mask_volume(range{3}, range{2}, range{1});
handles.mask_vol_for_TA_extended{1}{1} = handles.mask_volume(extended_range{3}, extended_range{2}, extended_range{1});

% Perform the digitization
% First, determine the digitization parameters
switch handles.digitization_flag
    case 0 % 0 - use the min and max within the masked volume for digitization (default)
        tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1}) .* handles.mask_volume(range{3}, range{2}, range{1});
        digitization_min = min(tempimg(find(handles.mask_volume(range{3}, range{2}, range{1}))));
        digitization_max = max(tempimg(find(handles.mask_volume(range{3}, range{2}, range{1}))));
    case 1 % 1 - use the min and max within the rectangular cylinder volume
        tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1});
        digitization_min = min(tempimg(:));
        digitization_max = max(tempimg(:));
    case 2 % 2 - use 0 and max within the masked volume for digitization
        tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1}) .* handles.mask_volume(range{3}, range{2}, range{1});
        digitization_min = 0;
        digitization_max = max(tempimg(find(handles.mask_volume(range{3}, range{2}, range{1}))));
    case 3 % 3 - use 0 and max within the rectangular cylinder volume
        tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1});
        digitization_min = 0;
        digitization_max = max(tempimg(:));
    case 4 % 4 - use preset min and max values (needs to assign both values)
        digitization_min = handles.default_digitization_min;
        digitization_max = handles.default_digitization_max;
end

tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1}) .* handles.mask_volume(range{3}, range{2}, range{1});
tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
handles.resampled_image_vol_for_TA{1}{1} = tempimg;

tempimg = handles.Primary_image_obj.image_volume_data(range{3}, range{2}, range{1});
tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
handles.resampled_image_vol_for_TA_unmasked{1}{1} = tempimg;

switch handles.digitization_flag
    case 0 % 0 - use the min and max within the masked volume for digitization (default)
        tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1})  .* handles.mask_volume(extended_range{3}, extended_range{2}, extended_range{1});
        digitization_min = min(tempimg(find(handles.mask_volume(extended_range{3}, extended_range{2}, extended_range{1}))));
        digitization_max = max(tempimg(find(handles.mask_volume(extended_range{3}, extended_range{2}, extended_range{1}))));
    case 1 % 1 - use the min and max within the rectangular cylinder volume
        tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1});
        digitization_min = min(tempimg(:));
        digitization_max = max(tempimg(:));
    case 2 % 2 - use 0 and max within the masked volume for digitization
        tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1})  .* handles.mask_volume(extended_range{3}, extended_range{2}, extended_range{1});
        digitization_min = 0;
        digitization_max = max(tempimg(find(handles.mask_volume(extended_range{3}, extended_range{2}, extended_range{1}))));
    case 3 % 3 - use 0 and max within the rectangular cylinder volume
        tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1});
        digitization_min = 0;
        digitization_max = max(tempimg(:));
    case 4 % 4 - use preset min and max values (needs to assign both values)
        digitization_min = handles.default_digitization_min;
        digitization_max = handles.default_digitization_max;
end

tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1})  .* handles.mask_volume(extended_range{3}, extended_range{2}, extended_range{1});
tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
handles.resampled_image_vol_for_TA_extended{1}{1} = tempimg;

tempimg = handles.Primary_image_obj.image_volume_data(extended_range{3}, extended_range{2}, extended_range{1});
tempimg = digitize_img(tempimg, handles.digitization_type, 1, handles.digitization_bins, digitization_min, digitization_max);
handles.resampled_image_vol_for_TA_unmasked_extended{1}{1} = tempimg;

handles = Perform_TA_in_GUI(handles);