function features = mainfcn(param)
%For each patient-image, get features
%Export feature table out to file
%May have hardcoded settings

%--- Script Template Parameters
data_root   = param.data_root;%"C:\Users\Jurgen\Documents\PROJECT ESOTEXTURES\Data_Eso";
%outprefix   = param.fileprefix; 

disp("Using data under " + data_root)

settings = {'Quantization_level', 64;...
    'Quantization_algorithm', 'Global min/max';...
    'Segmentation_method', 'import';...
    'Patient_LBM_ratio', 1;...
    'Pixelspacing', [1,1,1];...
    'Nfeatures', 108;}; %72 according to doc (v1.0?), but 108 in loaded property matrix
settings = cell2struct(settings(:,2),settings(:,1));

%--- Get 2 lists: img path & matching roi path and preallocate output
[imgpfolders, roipfolders] = getPatients(data_root);
Npatient = length(imgpfolders);
Nfeature = settings.Nfeatures; 
features = table('Size', [Npatient Nfeature], 'VariableTypes', repmat({'double'}, 1, Nfeature));
[~, patientID] = cellfun(@fileparts,imgpfolders,'UniformOutput',false);



%--- Iteratively get features for each patient, save result in pwd
for idx = 1:Npatient 
    disp(['loading patient: ' patientID{idx} ' (' num2str(idx) ' of ' num2str(Npatient) ')']);
    try
        [img, mask]     = load_patient(imgpfolders{idx}, roipfolders{idx});      
        [names, features(idx,:)] = cgitaFeatures(img, mask);
    catch e
        if strcmp(e.identifier, "CUSTOM:loadfail")
            disp("Failed to load: " + e.message)
            continue;
        end
        partialSave(idx)
        rethrow(e)
    end
end
completedSave()


%---
    function completedSave()
        disp("Completed analysis, saving output to: " + pwd);
        saveOut('cgita_features_complete') 
    end
    function saveOut(outName)
        features = [patientID(:) features];
        features.Properties.VariableNames(1:end) = ['PatientID' names];
        outNamexlsx = [outName '.xlsx'];
        if exist(outNamexlsx, 'file')==2
            warning("Overwriting existing xlsx file");
            delete(outNamexlsx);
        end
        try
        writetable(features,outNamexlsx,'FileType','spreadsheet'); 
        writetable(cell2table([fieldnames(settings), struct2cell(settings)]),outNamexlsx,'Sheet',2,'WriteVariableNames',false); %use writecell in 2019a
        save([outName '.mat'],'features','settings'); 
        catch e
            disp("Error saving to folder, writing to global variable instead, type ""global OUTPUT"" in the base workspace to access result")
            global OUTPUT
            OUTPUT.features = features;
            OUTPUT.settings = settings;
            rethrow(e);
        end
    end

    function partialSave(idx)
        if idx > 1
            disp("An error occured, saving partial results to: " + pwd);
            timestamp = [date '_' datestr(now,'HH-MM-SS')];
            saveOut(['cgita_features_partial_' timestamp]);
        end
    end

end

function [pets, rois] =  getPatients(root)
%Assuming the two lists share the same natsorted ordering, depends on how the [patient] subdirectories are named though
    pets = getFolders(fullfile(root,'PET images'));
    rois = getFolders(fullfile(root,'LifeX ROIs'));
    assert(length(pets)==length(rois),'image set not equal to roi set?');
end

function [img, mask] = load_patient(petPath, roiPath)
%NB: Assumes a certain data folder structure, see main comments
%The .dcm study & series UIDs are messed up (due to anonimization method?): can't use matlab dicom loader
% Niftread takes a file-, dicomread takes a folder as argument

roiFilePaths = getFullFiles(fullfile(roiPath,'RoiVolume'));
try
    assert(numel(roiFilePaths)==1,['Can not determine roi file in ' roiPath]);
catch
    assert(~isempty(roiFilePaths),'No ROI available');
    roiFilePaths = roiFilePaths(1);
    warning('Multiple ROIs detected for this patient, using first one found');
end
roiinfo = niftiinfo(char(roiFilePaths));
mask    = logical(niftiread(roiinfo));
assert(any(mask(:)),'CUSTOM:loadfail', 'Empty mask not expected');
img     = dicom23D(petPath); %saves VOLUME_IMAGE.mat after first run
assert(isequal(size(img),size(mask)), 'CUSTOM:loadfail', 'Mask size should match that of scan');
end

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