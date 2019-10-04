function featuretab = mainfcn(param)
%For each patient-image, get features
%Export cohort feature table to file


%--- Script Template Parameters
data_root   = param.data_root;%"C:\Users\Jurgen\Documents\PROJECT ESOTEXTURES\Data_Eso";
outprefix   = param.fileprefix; %'pyradiomics';
Nfeature    = 107; 

Process_cohort()
%---
function Process_cohort()
    %--- Get list of patient folders and preallocate output
    cohort      = getPatients(data_root); %.imgfolder .roifolder
    Npatient    = length(cohort);
    featuretab  = array2table(zeros(Npatient, Nfeature)); %awkward syntax to preallocate table...
    [~, patientID] = cellfun(@fileparts,{cohort.imgfolder},'UniformOutput',false); %fileparts might take a string array in future MATLAB versions
    namelog    = strings(size(featuretab));
    
    %--- Iteratively get features for each patient, save final result in pwd
    for idx = 1:Npatient 
        disp(['loading patient: ' patientID{idx} ' (' num2str(idx) ' of ' num2str(Npatient) ')']);
        try
            [img, mask]     = load_patient(cohort(idx));      
            [namelog(idx, :), featuretab(idx,:)] = pyradiomicsFeatures(img, mask);
        catch err
            handleError(err)
        end
    end
    saneSave(outprefix + "_features_complete", 'Completed analysis, saving output...');

    
    function saneSave(outName, msg)
        namelog(all(namelog == "", 2),:) = []; %remove empty rows
        if(isempty(namelog))
            disp('Oops, no output was generated, skipping save');
        else    %rows should be constant
                assert(size(unique(namelog, 'rows'), 1) == 1,'CUSTOM:NamesVary', namelog);
        end
            featuretab = [patientID(:), featuretab]; %add patient col
            namelist   = ['PatientID', namelog(1,:)];
            featuretab.Properties.VariableNames(1:end) = namelist; %add headers
            disp(msg);
            saveOut(outName, featuretab);
            disp(['Finished saving in ' pwd]);
    end
    
    
    function handleError(e)
        if strcmpi(e.identifier,'CUSTOM:loadfail')
            warning(e.message);
            disp('skipping patient...');
        elseif strcmpi(e.identifier,'CUSTOM:NamesVary') %Corrupt output, throw
                disp('Feature is named inconsistently over iterations');
                disp(strsplit(e.message')); 
                rethrow(e);
        else %Valid output, save then throw. 
            if idx > 1
                timestamp = [date '_' datestr(now,'HH-MM-SS')];
                saneSave([outprefix '_features_partial_' timestamp], 'An error occured, saving partial results');
            end
            rethrow(e);
        end
    end
    
    
end
%---
end

function saveOut(outName, tbl)
        outNamexlsx = outName + '.xlsx';
        if exist(outNamexlsx, 'file')==2
            warning("Attempting to overwrite existing xlsx file");
            try delete(outNamexlsx); catch, end
        end
        writetable(tbl, outNamexlsx, 'FileType', 'spreadsheet'); 
        save(outName + '.mat','tbl'); 
end

function cohort =  getPatients(root)
%Assumption: Patient input data consists of single scan and a single roi
% -> Has implications for the output table/general loop

%Assumption: Data folder/file structure: 
% -> Has implications for the patientdata loading functions
% [Root]
% - "PET images"
% -- [Patient]
% ---- [multiple .dcm]
% - "LifeX ROIs"
% -- [Patient]
% ---- "RoiVolume"
% ------[roifile.nii.gz]
% Note: The dicom loader prefers previously created VOLUME_IMAGE.mat, if available

%Assuming the two lists share the same natsorted ordering, depends on how the [patient] subdirectories are named though
    try 
        pets = getFolders(fullfile(root,'PET images'));
        rois = getFolders(fullfile(root,'LifeX ROIs'));    
    catch err
        if strcmpi("CUSTOM:patherror", err.identifier)
            root = uigetdir('','Select Scan Data Root Folder');
        end
        pets = getFolders(fullfile(root,'PET images'));
        rois = getFolders(fullfile(root,'LifeX ROIs')); 
    end
    
    assert(length(pets)==length(rois),"CUSTOM:loadfail", 'image set not equal to roi set?');
    assert(~isempty(pets), "CUSTOM:loadfail", "No data entries found in pet folder");
    disp("Using dataset under: " + root);
    cohort = cell2struct([pets(:), rois(:)],{'imgfolder','roifolder'},2); %Careful with argument order
end

function [img, mask] = load_patient(patient)
%NB: Assumes a certain data folder structure, see main comments
%The .dcm study & series UIDs are messed up (due to anonimization method?): can't use matlab dicom loader
% Niftiread takes a file, while dicomread takes a folder as argument
% ROI files are voxel-wise bitmasks (instead of commonly used polygon sets)

roiFilePaths = getFullFiles(fullfile(patient.roifolder,'RoiVolume'));
try
    assert(numel(roiFilePaths)==1,['Can not determine roi file in ' patient.roifolder]);
catch
    assert(~isempty(roiFilePaths),'No ROI available');
    roiFilePaths = roiFilePaths(1);
    warning('Multiple ROIs detected for this patient, using first one found');
end
roiinfo = niftiinfo(char(roiFilePaths));
mask    = logical(niftiread(roiinfo));
assert(any(mask(:)),'CUSTOM:loadfail', 'Empty mask not expected');
img     = dicom23D(patient.imgfolder); %saves VOLUME_IMAGE.mat after first run
assert(isequal(size(img),size(mask)),'CUSTOM:loadfail','Mask size should match that of scan');
end

function [names, values] = pyradiomicsFeatures(im, mask)
% features is a 1xN cell array of scalars
% names is a 1xN cell array of strings, formatted for table() compatibility
% Arguments are 3D image I and 3D contigous mask M.
% Assumes M is binary, I is type double (integer I might work too). 


%--- save im and mask to simpleITK compatible filetypes.  
%avoid DICOM. Try nifti.or nrrd
imageName = fullfile(pwd, "tempimg.nii");
maskName = fullfile(pwd, "tempmask.nii");
niftiwrite(im, imageName);
niftiwrite(uint8(mask), maskName); %must be numeric
% imageName = 'C:\\Users\\Jurgen\\AppData\\Local\\Temp\\pyradiomics\\data\\brain1_image.nrrd';
% maskName = 'C:\\Users\\Jurgen\\AppData\\Local\\Temp\\pyradiomics\\data\\brain1_label.nrrd';

%--- Create extractor and execute with filenames
kwa = pyargs('binCount', uint8(64));
extractor = py.radiomics.featureextractor.RadiomicsFeatureExtractor(kwa);
featureVector = extractor.execute(imageName, maskName); 

%--- Parse output dictionary
firstidx = 23; %fixed? or does preamble change, relative to input?

allvalues = cell(py.list(featureVector.values));
values = allvalues(firstidx:end);
values = cellfun(@(x) double(py.array.array('d', py.numpy.nditer(x))), values, 'Uni', false); %convert to matlab doubles

% Rules for valid variable names: 
% 1. Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% 2. Variable names have to start with a letter.
% 3. Variable names can be up to 63 characters long.
allnames = string(cell(py.list(featureVector.keys))); %may contain hyphens, spaces and dots?
names = allnames(firstidx:end); 
names = replace(names, [" ","-","."], ["_", "", ""]);

assert(all(cellfun(@isscalar, values)),'Features has non-scalars?!'); %sanity check


end

