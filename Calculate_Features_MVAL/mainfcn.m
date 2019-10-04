function featuretab = mainfcn(param)
%For each patient-image, get features
%Export cohort feature table to file


%--- Script Template Parameters
data_root   = param.data_root;%"C:\Users\Jurgen\Documents\PROJECT ESOTEXTURES\Data_Eso";
outprefix   = param.fileprefix; %'mval';
Nfeature    = 52; %undocumented by original source

Process_cohort()
%---
function Process_cohort()
    %--- Get list of patient folders and preallocate output
    cohort      = getPatients(data_root); %.imgfolder .roifolder
    Npatient    = length(cohort);
    featuretab  = table('Size',[Npatient Nfeature],'VariableTypes',repmat({'double'},1,Nfeature)); %awkward syntax to preallocate table...
    [~, patientID] = cellfun(@fileparts,{cohort.imgfolder},'UniformOutput',false);
    namelist    = [];
    %--- Iteratively get features for each patient, save final result in pwd
    for idx = 1:Npatient 
        disp(['loading patient: ' patientID{idx} ' (' num2str(idx) ' of ' num2str(Npatient) ')']);
        try
            [img, mask]     = load_patient(cohort(idx));      
            [names, featuretab(idx,:)] = mvalFeatures(img, mask); %Main function
            namelist = [namelist; names]; %Rows should be constant
        catch err
            handleError(err)
        end
    end
    sanityCheck();
    disp('Completed analysis, saving output');
    saveOut([outprefix '_features_complete']);
    
    function sanityCheck()
        for feat = 1:Nfeature
            assert(isequal(namelist{:,feat}),['Feature ' feat ' is not constant']);
        end
    end
    
    function handleError(e)
        if strcmpi(e.identifier,'CUSTOM:loadfail')
            warning(e.message);
            disp('skipping patient...');
        else
            if idx > 1
                disp('An error occured, saving partial results');
                timestamp = [date '_' datestr(now,'HH-MM-SS')];
                saveOut([outprefix '_features_partial_' timestamp]);
            end
            rethrow(e)
        end
    end
    
    function saveOut(outName)
        if logical(exist('names','var'))
            featuretab = [patientID(:) featuretab];
            featuretab.Properties.VariableNames(1:end) = ['PatientID' names];
            outNamexlsx = [outName '.xlsx'];
            if exist(outNamexlsx, 'file')==2
                warning("Overwriting existing xlsx file");
                try delete(outNamexlsx); catch, end
            end
            writetable(featuretab,outNamexlsx,'FileType','spreadsheet'); 
            save([outName '.mat'],'featuretab'); 
            disp(['Finished saving in ' pwd]);
        else
            disp('...Nothing to save, no output generated');
        end
    end
end
%---
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
            root = uigetdir('','Select Data root folder');
        end
        pets = getFolders(fullfile(root,'PET images'));
        rois = getFolders(fullfile(root,'LifeX ROIs')); 
    end
    
    disp("Using dataset under: " + root);
    assert(length(pets)==length(rois),"CUSTOM:loadfail", 'image set not equal to roi set?');
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

function [names, features] = mvalFeatures(I,M)
% features is a 1xN cell array of scalars
% names is a 1xN cell array of strings, formatted for table() compatibility
% Arguments are 3D image I and 3D contigous mask M.
% Assumes M is binary, I is type double (integer I might work too). 


%--- Return dummy data
%     load('mval_dummy_features'); warning('Using dummy data'); return


%--- Pre-processing
% Author states that volume should be isotropic, so scaling is done.
planeRes    = 1; %mm
sliceRes    = 1; %mm
tgtIsoRes   = 1; %mm

GROI = prepareVolume(I,M,'CT',planeRes,sliceRes,1,tgtIsoRes,'Global');
[ROIonly,levels] = prepareVolume(I,M,'CT',planeRes,sliceRes,1,tgtIsoRes,'Matrix','Uniform',64);
GLCM  = getGLCM(ROIonly,levels); 
GLRLM = getGLRLM(ROIonly,levels);
GLSZM = getGLSZM(ROIonly,levels); 
[NGTDM, countValid] = getNGTDM(ROIonly,levels); 

%--- Feature extraction
% Each category function returns a unique struct with features. 
% Would have been smarter to have a struct array with fname/value fields?
globalTextures = getGlobalTextures(GROI,64);
glcmTextures   = getGLCMtextures(GLCM);
glrlmTextures  = getGLRLMtextures(GLRLM);
glszmTextures  = getGLSZMtextures(GLSZM);
ngtdmTextures  = getNGTDMtextures(NGTDM, countValid);

nonTexture.AUCCSH = getAUCCSH(GROI);
nonTexture.Eccentricity = getEccentricity(GROI,planeRes,sliceRes);
[nonTexture.SUVmax, nonTexture.SUVpeak, nonTexture.SUVmean, ~] = getSUVmetrics(GROI);
nonTexture.Size = getSize(GROI,planeRes,sliceRes);
nonTexture.Solidity = getSolidity(GROI,planeRes,sliceRes);
nonTexture.Volume = getVolume(GROI,planeRes,sliceRes);
nonTexture.PecentInactive = getPercentInactive(GROI, 0.1);
%--- Convert structs to table-friendly output format
% Rules for valid variable names: 
% 1. Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% 2. Variable names have to start with a letter.
% 3. Variable names can be up to 63 characters long.
% 4. To avoid duplicate feature names: category name appended

names = [strcat('Nontexture_',fieldnames(nonTexture));...
    strcat('Global_',fieldnames(globalTextures));...
    strcat('GLCM_',fieldnames(glcmTextures));...
    strcat('GLRLM_',fieldnames(glrlmTextures));...
    strcat('GLSZM_',fieldnames(glszmTextures));...
    strcat('NGTDM_',fieldnames(ngtdmTextures))];

features = [struct2cell(nonTexture);...
    struct2cell(globalTextures);...
    struct2cell(glcmTextures);...
    struct2cell(glrlmTextures);...
    struct2cell(glszmTextures);...
    struct2cell(ngtdmTextures)];

names       = transpose(names);
features    = transpose(features);
assert(all(cellfun(@isscalar,features)),'Features has non-scalars?!'); %sanity check

%-----------------------------------------
%-----------------------------------------
    


end
