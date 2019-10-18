function [names, features] = cgitaFeatures(I,M)
% features is a 1xN cell array of scalars
% names is a 1xN cell array of strings, formatted for table() compatibility
% Arguments are 3D image I and 3D contigous mask M.
% Assumes M is binary, I is type double (integer I might work too). 

%--- Emulate callback with loaded data
CGITA_struct = shim_TA_Callback(I,M);   %.Feature_table not used

%--- Parse resulting Feature_display_cell 
features = transpose(CGITA_struct.Feature_display_cell(:,3)); 
names = join(CGITA_struct.Feature_display_cell(:,1:2),'_');
names = strrep(names,' ','_');
names = strrep(names,'-','');
names = strrep(names,'.','');
names = transpose(names);
% 3 rules for valid variable names: 
% Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% Variable names have to start with a letter.
% Variable names can be up to 63 characters long.
end

function fake_handles = shim_TA_Callback(img, mask)
%--- emulate callback from GUI button: apply analysis on current VOI
% Simplified version of a local function in CGITA_GUI.m 
% orignal implementation: "TA_Callback(handles)"
% 
% Depends directly on handles containing:
% VOI_obj: an array of structs with field 'contour', assuming not used
% Primary_image_obj: a struct with field 'image_volume_data'
% digitization_flag: an integer
% default_digitization_min: a scalar, not definitely used
% default_digitization_max: a scalar, not definitely used
% digitization_type: a string
% digitization_bins: an integer

% Newly added and/or indirect handles depends:
% contour_volume: originally computed within, assuming not used
% mask_volume: originally computed within, assuming equal to mask
% Primary_image_obj.pixel_spacing: for Prepare_SUV
% Primary_image_obj.patient_LBM_ratio: for Prepare_SUV
% Primary_image_obj.metadata
sz = size(img);
fake_handles.mask_volume = mask; 
fake_handles.contour_volume = [];
fake_handles.VOI_obj = [];

fake_handles.Primary_image_obj.image_volume_data = img;
fake_handles.Primary_image_obj.pixel_spacing = [1,1,1];
fake_handles.Primary_image_obj.patient_LBM_ratio = 1;
fake_handles.Primary_image_obj.metadata.ManufacturerModelName = 'Fakename';
fake_handles.Primary_image_obj.metadata.Modality = 'Generic';
fake_handles.Primary_image_obj.metadata.Slices = sz(3);
fake_handles.Primary_image_obj.metadata.Width = sz(1);
fake_handles.Primary_image_obj.metadata.Height = sz(2);
fake_handles.Primary_image_obj.metadata.PixelSpacing = [1,1,1]; %[2.7344 2.7344 3.2700]
fake_handles.Primary_image_obj.metadata.SliceThickness = 1;
fake_handles.Primary_image_obj.metadata.StudyDate = date;
fake_handles.Primary_image_obj.metadata.StudyTime = [];

fake_handles.digitization_flag = 1; %local min and max
fake_handles.default_digitization_min = []; %not used
fake_handles.default_digitization_max = []; %not used
fake_handles.digitization_type = 'uint16';
fake_handles.digitization_bins = 64;

fake_handles = TA_Callback(fake_handles); 



end