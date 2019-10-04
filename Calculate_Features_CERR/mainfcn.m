function featuretab = mainfcn(param)
%For each patient-image, get features
%Export cohort feature table to file

%--- Script Template Parameters
data_root   = param.data_root;%"C:\Users\Jurgen\Documents\PROJECT ESOTEXTURES\Data_Eso";
outprefix   = param.fileprefix; %


%--- Get list of patient folders and preallocate output
disp("Using data under " + data_root)
cohort      = getPatients(data_root); %.imgfolder .roifolder
Npatient    = length(cohort);
Nfeature    = 143;%63; %143, undocumented by CERR
featuretab  = table('Size',[Npatient Nfeature],'VariableTypes',repmat({'double'},1,Nfeature)); %awkward syntax to preallocate table...
[~, patientID] = cellfun(@fileparts,{cohort.imgfolder},'UniformOutput',false);


%--- Iteratively get features for each patient, save final result in pwd
for idx = 1:Npatient 
    disp(['loading patient: ' patientID{idx} ' (' num2str(idx) ' of ' num2str(Npatient) ')']);
    try
        [img, mask]     = load_patient(cohort(idx));      
        [names, featuretab(idx,:)] = cerrFeatures(img, mask);
    catch e
        if strcmp(e.identifier, "CUSTOM:loadfail")
            disp("Failed to load: " + e.message)
            continue;
        end
        if idx > 1
            disp('An error occured, saving partial results');
            timestamp = [date '_' datestr(now,'HH-MM-SS')];
            saveOut([outprefix '_features_partial_' timestamp]);
        end
        rethrow(e)
    end
end
disp('Completed analysis, saving output');
saveOut([outprefix '_features_complete']) 

%---
    function saveOut(outName)
        featuretab = [patientID(:) featuretab];
        featuretab.Properties.VariableNames(1:end) = ['PatientID' names];
        outNamexlsx = [outName '.xlsx'];
        if exist(outNamexlsx, 'file')==2
            warning("Overwriting existing xlsx file");
            delete(outNamexlsx);
        end
        writetable(featuretab,outNamexlsx,'FileType','spreadsheet'); 
        save([outName '.mat'],'featuretab'); 
        disp(['Finished saving in ' pwd]);
    end
end

function cohort =  getPatients(root)
%NB: Assumes a certain data folder structure, see main comments
%Assuming the two lists share the same natsorted ordering, depends on how the [patient] subdirectories are named though
    try assert(exist(root, 'dir')==7);    
    catch
        root = uigetdir('','Select Data root folder'); 
    end
    pets = getFolders(fullfile(root,'PET images'));
    rois = getFolders(fullfile(root,'LifeX ROIs'));
    assert(length(pets)==length(rois),'image set not equal to roi set?');
    cohort = cell2struct([pets(:),rois(:)],{'imgfolder','roifolder'},2); %Careful with argument order
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
assert(isequal(size(img),size(mask)), 'CUSTOM:loadfail', 'Mask size should match that of scan');
end
















% structNum   = getMatchingIndex(paramS.structuresC{1},strC,'exact');
% scanNum     = getStructureAssociatedScan(structNum,planC);
%--- Create planC object from I and M
% Shape features require gridS, which requires scanStruct.scanInfo.
%   - sizeOfDimension1/2/zValue/xOffset/grid2Units/yOffset/grid1Units
% [indexS, planC] = dummyPlanC();
% planC{indexS.scan}.scanArray = I;
% planC{indexS.scan}.scanInfo.CTOffset = 0;
% planC = quality_assure_planC(planC);
%planC{indexS.structures}(roinum).contour(slicenum).segments(segnum).points =
%slicewise polygon with 3D coordinates. multiple segments = multiple
%polygons in that slice.
