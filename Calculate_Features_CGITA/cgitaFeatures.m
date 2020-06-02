function [names, features] = cgitaFeatures(I, M, S)
% features is a 1xN cell array of scalars
% names is a 1xN cell array of strings
% Arguments are 3D image I and 3D contigous mask M.
% Assumes M is binary, I has integer values. 

%--- Check input
if nargin == 2
    S = getfield(loadSettings("cgita",[]), "cgita");
end
negatives = I < 0;
assert(~any(negatives(:)), "Input image may not contain negative values");

if ~isinteger(I)
    %check if the float has only integer values
    mismatches = ~(I == uint16(I)); %assuming integers in I don't exceed 2^16 - 1
    if any(mismatches(:))
        warning("cgita: Input image seems to contain non-integers, converting to uint16 range..."); 
        I = double(im2uint16(I));
    end
end

%--- Emulate callback with loaded data
CGITA_struct = shim_TA_Callback(I,M,S); %contains "Feature_display_cell"

%--- Parse resulting Feature_display_cell 
% 3 rules for valid variable names: 
% Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% Variable names have to start with a letter.
% Variable names can be up to 63 characters long.
features = transpose(CGITA_struct.Feature_display_cell(:,3)); 
names = join(CGITA_struct.Feature_display_cell(:,1:2),'_');
names = transpose(names);

end

function fake_handles = shim_TA_Callback(img, mask, settings)
%--- emulate callback from GUI button: apply analysis on current VOI
% Simplified version of a local function in CGITA_GUI.m 
% orignal implementation: "TA_Callback(handles)"
% 

sz = size(img);
if isfield(settings.parameters, "pixelspacing")
    PixelSpacing = settings.parameters.pixelspacing;
else
    warning("Assuming isotropic 1mm pixel spacing. Use the settings to specify otherwise."); %affects some shape features
    PixelSpacing = [1, 1, 1];
end

if isfield(settings.parameters, "lbm")
    LBM = settings.parameters.lbm;
else
    warning("Assuming patient LBM ratio of 1. Use the settings to specify otherwise."); %affects one or two features.
    LBM = 1;
end

%add fields
fake_handles = settings.parameters; %"digitization" stuff
fake_handles.mask_volume = mask; 
fake_handles.contour_volume = [];
fake_handles.VOI_obj = [];

%add Primary_image_obj field
metadata.ManufacturerModelName = 'Fakename';
metadata.Modality = 'ModalityAgnostic';
metadata.Slices = sz(3);
metadata.Width = sz(1);
metadata.Height = sz(2);
metadata.PixelSpacing = PixelSpacing;
metadata.SliceThickness = PixelSpacing(3);
metadata.StudyDate = '12345';
metadata.StudyTime = [];
Primary_image_obj.metadata = metadata;
Primary_image_obj.image_volume_data = img;
Primary_image_obj.patient_LBM_ratio = LBM;
Primary_image_obj.pixel_spacing = PixelSpacing;
fake_handles.Primary_image_obj = Primary_image_obj;

% fake_handles.digitization_flag = settings.parameters.digitization_flag  ; %local min and max
% fake_handles.default_digitization_min = settings.parameters.default_digitization_min; %not used
% fake_handles.default_digitization_max = settings.parameters.default_digitization_max; %not used
% fake_handles.digitization_type = settings.parameters.digitization_type ;
% fake_handles.digitization_bins = settings.parameters.digitization_bins ;


fake_handles = TA_Callback(fake_handles); 



end