function [names, features] = cgitaFeatures(I, M, S)
% features is a 1xN cell array of scalars
% names is a 1xN cell array of strings, formatted for table() compatibility
% Arguments are 3D image I and 3D contigous mask M.
% Assumes M is binary, I is type double (integer I might work too). 

%--- Emulate callback with loaded data
CGITA_struct = shim_TA_Callback(I,M,S);   %.Feature_table not used

%--- Parse resulting Feature_display_cell 
% 3 rules for valid variable names: 
% Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% Variable names have to start with a letter.
% Variable names can be up to 63 characters long.
features = transpose(CGITA_struct.Feature_display_cell(:,3)); 
names = join(CGITA_struct.Feature_display_cell(:,1:2),'_');
names = strrep(names,' ','_');
names = strrep(names,'-','');
names = strrep(names,'.','');
names = transpose(names);

end

function fake_handles = shim_TA_Callback(img, mask, settings)
%--- emulate callback from GUI button: apply analysis on current VOI
% Simplified version of a local function in CGITA_GUI.m 
% orignal implementation: "TA_Callback(handles)"
% 

sz = size(img);

%add fields
fake_handles = settings.parameters;
fake_handles.mask_volume = mask; 
fake_handles.contour_volume = [];
fake_handles.VOI_obj = [];

%add Primary_image_obj field
metadata.ManufacturerModelName = 'Fakename';
metadata.Modality = 'ModalityAgnostic';
metadata.Slices = sz(3);
metadata.Width = sz(1);
metadata.Height = sz(2);
metadata.PixelSpacing = [1, 1, 1];
metadata.SliceThickness = 1;
metadata.StudyDate = '12345';
metadata.StudyTime = [];
Primary_image_obj.metadata = metadata;
Primary_image_obj.image_volume_data = img;
Primary_image_obj.patient_LBM_ratio = 1;
Primary_image_obj.pixel_spacing = [1, 1, 1];
fake_handles.Primary_image_obj = Primary_image_obj;

% fake_handles.digitization_flag = settings.parameters.digitization_flag  ; %local min and max
% fake_handles.default_digitization_min = settings.parameters.default_digitization_min; %not used
% fake_handles.default_digitization_max = settings.parameters.default_digitization_max; %not used
% fake_handles.digitization_type = settings.parameters.digitization_type ;
% fake_handles.digitization_bins = settings.parameters.digitization_bins ;


fake_handles = TA_Callback(fake_handles); 



end