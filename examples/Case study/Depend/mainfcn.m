function featuretab = mainfcn(input)
%For each patient::image::roi, get scalar IBEX features
%Export cohort feature table to file

%--- Script Template Parameters
data_root     = input.data_root; %"C:\Users\Jurgen\Documents\PROJECT ESOTEXTURES\Data_Eso";
settings.file = input.settings.file; 
outprefix     = input.fileprefix;%'ibex'; %csv name prefix
Process_cohort()
%---

function Process_cohort()
    %--- Load settings from file, if applicable:
    settings = loadSettings(settings); %main field: FeatureSetsInfo
    Nfeature = settings.Nfeatures;
    
    %--- Parse patient data paths and preallocate table for output
    cohort      = getPatients(data_root); %.imgfolder .roifolder
    Npatient    = length(cohort);
    featuretab  = table('Size',[Npatient Nfeature],'VariableTypes',repmat({'double'},1,Nfeature)); %awkward syntax to preallocate table...
    [~, patientID] = cellfun(@fileparts,{cohort.imgfolder},'UniformOutput',false); 
    namelog    = cell(size(featuretab));
    
    
    %--- Iteratively get features for each patient, save final result in pwd
    for idx = 1:Npatient 
        disp(['loading patient: ' patientID{idx} ' (' num2str(idx) ' of ' num2str(Npatient) ')']);
        try
            [img, mask]     = loadPatient(cohort(idx));      
            [namelog(idx,:), featuretab(idx,:)] = ibexFeatures(img, mask, settings);
        catch err
            handleError(err)
        end
    end
    saneSave([outprefix '_features_complete'], 'Completed analysis, saving output...');

    
    
    function saneSave(outName, msg)
        namelog(all(cellfun(@isempty,namelog),2),:) = []; %remove empty rows
        if(isempty(namelog))
            disp('Oops, no output was generated, skipping save');
        else    %rows should be constant
            for col = namelog
                assert(isequal(col{:}),'CUSTOM:NamesVary',strjoin(col)); %unique(...,'rows') doesn't work for cells
            end
            featuretab = [patientID(:), featuretab];
            namelist   = ['PatientID', namelog(1,:)];
            featuretab.Properties.VariableNames(1:end) = namelist;
            disp(msg);
            saveOut(outName, featuretab);
            disp(['Finished saving in ' pwd]);
        end
    end
    
    function handleError(e)
        if strcmpi(e.identifier,'CUSTOM:loadfail') %Just continue, skip bad patient loads
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
        outNamexlsx = [outName '.xlsx'];
        if exist(outNamexlsx, 'file')==2
            warning("Overwriting existing xlsx file");
            try delete(outNamexlsx); catch, end
        end
        writetable(tbl,outNamexlsx,'FileType','spreadsheet'); 
        save([outName '.mat'],'tbl'); 
end

function cohort = getPatients(root)
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

function [img, mask] = loadPatient(patient)
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

