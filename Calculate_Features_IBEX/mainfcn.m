function featuretab = mainfcn(input)
%For each patient::image::roi, get scalar IBEX features
%Export cohort feature table to file

%--- Script Template Parameters
data_root     = input.data_root; %"C:\Users\Jurgen\Documents\PROJECT ESOTEXTURES\Data_Eso";
settings.file = input.settings.file; %'IBEX_Featureset.mat';
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

function settings = loadSettings(S)
    varname = "FeatureSetsInfo";
    if isempty(S.file) %Create a default
        defaultname = "IBEX_features_default.mat";
        S.file = defaultname;
        disp("No feature settings file specified. Generating default featureset and saving file...")
        settings.(varname) = generateIBEXsettings();
        settings.file = defaultname;
        save(defaultname, varname);
        disp("Saved " + defaultname + "to: " + pwd);
        %disp("To alter future defaults please read generateIBEXsettings.m ");
    else %check if valid file & load
        [~,~,ext] = fileparts(S.file);
        assert(ext == ".mat", "CUSTOM:nosettings", "Settings file invalid: doesn't have .mat extension");
        assert(logical(exist(S.file,'file')), "CUSTOM:nosettings", "Can't find file by the name: " + S.file);
        disp("Using feature settings from file: " + S.file);
        settings = load(S.file);
        assert(isfield(settings, varname), "CUSTOM:nosettings", "Settings file did not contain expected variable: " + varname)
        settings.file = S.file;
    end

    [settings.Nfeatures, settings.scalarOnly] = parseFeatureset(settings.(varname));
    assert(settings.Nfeatures > 0, "Empty or corrupted featureset?");
    disp("Predicted number of features: " + settings.Nfeatures)
    
end

function [N, scalarOnly] = parseFeatureset(mat)
%See generateIBEXsettings.m for more information on the IBEX featureset
%structure. It may help to load an example featureset and browse it in MATLAB.
    categories = string({mat.Category});
    featuresetList = {mat.Feature};
    featuresetSizes = cellfun(@length, featuresetList);
    scalarOnly = true; 
    
    %only 3 categories affect feature output count: 2, 3, 4
    NfeatFromA = 0;
    nonscalarA = (categories == "GrayLevelCooccurenceMatrix25") | (categories == "GrayLevelCooccurenceMatrix3") | (categories == "GrayLevelRunLengthMatrix25");
    if any(nonscalarA)
        scalarOnly = false;
        categorySettings = {mat.CategoryStore};
        multipliersA = cellfun(@getMultiplier, categorySettings(nonscalarA)); 
        NfeatFromA = sum(multipliersA .* featuresetSizes(nonscalarA));
    end
   
    %features with a percentile and quantile vectors also affect output count. Assuming these are
    %only in 3 **other** IBEX categories: 1, 5, 6 
    NfeatFromB = sum(featuresetSizes(~nonscalarA));
    extra = 0;
    nonscalarB = (categories == "GradientOrientHistogram") | (categories == "IntensityDirect") | (categories == "IntensityHistogram");
    if any(nonscalarB)
        scalarOnly = false;
        featuresetSettings = {mat.FeatureStore}; %cell array of struct arrays
        perc = cellfun(@(x) strcmp(x,"Percentile") | strcmp(x,"PercentileArea"), featuresetList(nonscalarB),'Uni', false);
        quant = cellfun(@(x) strcmp(x,"Quantile"), featuresetList(nonscalarB), 'Uni', false);
        if any(cellfun(@any, perc))
           extra = extra + sum(cellfun(@countP, featuresetSettings(nonscalarB), perc));
        end
        if any(cellfun(@any, quant))
            extra = extra + sum(cellfun(@countQ, featuresetSettings(nonscalarB), quant));
        end
        NfeatFromB = NfeatFromB + extra;
    end
    
    N = NfeatFromA + NfeatFromB;
    assert(isscalar(N), "Feature count is not a scalar");
    
    function C = countP(a, b) 
        percentileArrays = cellfun(@(x) getfield(x, "Percentile"),{a(b).Value}, 'Uni', false); %Get percentile vectors given an IBEX FeatureStore struct array and a logical index, assumes every percentile feature has at least one percentile Value
        C = sum(cellfun(@length, percentileArrays)) - length(percentileArrays);
    end

    function C = countQ(a, b) %similar to countP. Could combine quant and perc, however, their features appear to be redundant; quantile may be dropped in the future.
        qArrays = cellfun(@(x) getfield(x, "Quantile"),{a(b).Value}, 'Uni', false); 
        C = sum(cellfun(@length, qArrays)) - length(qArrays);
    end

    function C = getMultiplier(s)
        if isfield(s.Value, "Offset")
            B = numel(s.Value.Offset);
        else
            B = 1; %run-length
        end
        C = (1 + numel(s.Value.Direction)) * B; %the +1 is for rot. invariant (333)
    end

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

function [names, features] = ibexFeatures(I,M,S)
% features is a 1xN cell array of scalars
% names is a 1xN cell array of strings, formatted for table() compatibility
% Arguments are 3D image I and 3D contigous mask M.
% Assumes M is binary, I is floating point or integer data type. 

%--- Return dummy data
%     load('ibex_dummy_features'); warning('Using dummy data'); return


%--- Preprocessing
%Emulate ridiculously convoluted datastructures
FeatureSetsInfo = S.FeatureSetsInfo; %getFeatureset(S.file);
DataSetsInfo    = getDataset(I,M); %contains cropped image & cropped mask

%Result Header, 2 rows: top = category, bottom = meta + feat
 HeaderCell=[{' '}, {' '}, {' '}, {' '}; {'Index'}, {'Image'}, {'ROI '}, {'MRN '}];
 for Feat = FeatureSetsInfo'
     CategoryName=Feat.Category{1};
     
     FeatureName=(Feat.Feature)';   

     CategoryNameStr=repmat({CategoryName}, 1, length(FeatureName));
     
     TempM=[CategoryNameStr; FeatureName];
     HeaderCell=[HeaderCell, TempM];
 end
 
 %--- Feature extraction
% ResultCell is a cell array, each row an image/roi calculation of length Nfeat, prepended with extra 4 metadata variables 

 ResultCCell=[{'D 1'}, {DataSetsInfo.DBName}, {DataSetsInfo.ROIName}];
 ResultCCell=[ResultCCell, {DataSetsInfo.MRN}];
 NCategories = length(FeatureSetsInfo);
 warning off
 for idx=1:NCategories
     current = " (" + string(idx) + " of " + string(NCategories) +")";
      disp("Calculating features for: " + FeatureSetsInfo(idx).Category + current)
     %Preprocess
     TestStruct=FeatureSetsInfo(idx).PreprocessStore;

     if ~isempty(TestStruct)
         DataSetsInfo=PreprocessImage(TestStruct, DataSetsInfo);
     end

     %Category
     TestStruct=FeatureSetsInfo(idx).CategoryStore;

     CategoryFuncH=str2func([TestStruct.Name, '_Category']);
     %nnz(DataSetsInfo.ROIBWInfo.MaskData(:))
     ParentInfo=CategoryFuncH(DataSetsInfo, 'Child', TestStruct.Value);


     %Feature
     TestStructF=FeatureSetsInfo(idx).FeatureStore;

     FeatureFuncH=str2func([TestStruct.Name, '_Feature']);
     FeatureInfo=FeatureFuncH(ParentInfo, TestStructF, 'NoReview');

     FeatureValue={FeatureInfo.FeatureValue};
     EmptyIndex=cellfun('isempty', FeatureValue);
     FeatureValue(EmptyIndex)={NaN};         

     for kkk=1:length(FeatureValue)
         CurrentFeatureValue=FeatureValue{kkk};

         %Single Value return
         if size(CurrentFeatureValue, 1) == 1 && size(CurrentFeatureValue, 2) == 1
             ResultCCell=[ResultCCell, num2cell(CurrentFeatureValue)];
         end

         if isfield(FeatureInfo, 'FeatureValueParam') && ~isempty(FeatureInfo(kkk).FeatureValueParam)
             % 1 column return: Histogram Percentile return [M1, M2; N1, N2]
             if size(CurrentFeatureValue, 1) >= 1 && size(CurrentFeatureValue, 2) == 1
                HeaderCell=ExtendResultHeaderCell(FeatureInfo, kkk, '1Column', HeaderCell, ResultCCell);
                ResultCCell=[ResultCCell, num2cell(CurrentFeatureValue')];
             end

             % 2 or more column return: GLCM Feature Value return [M1, M2, M3...; N1, N2, N3....]
             if size(CurrentFeatureValue, 1) >= 1 && size(CurrentFeatureValue, 2) > 1
                     HeaderCell=ExtendResultHeaderCell(FeatureInfo, kkk, '2MoreColumn', HeaderCell, ResultCCell);
                 for iii=2:size(CurrentFeatureValue, 2)
                     ResultCCell=[ResultCCell, num2cell(CurrentFeatureValue(:, iii)')];
                 end
             end
         end

     end       

 end

warning on



%--- Convert output format
% Rules for valid variable names: 
% 1. Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% 2. Variable names have to start with a letter.
% 3. Variable names can be up to 63 characters long.
% 4. To avoid duplicate feature names: category name appended

names    = join(HeaderCell(:,5:end), '_', 1);
names = strrep(names,' ','_');
names = strrep(names,'-','');
names = strrep(names,'.','');
features = ResultCCell(5:end);

%-----------------------------------------
%-----------------------------------------
    


end

function dsInfo = getDataset(im, mask)
    %ImageInfo = emulate_getImageDataInfo();
    %MaskInfo = emulate_GenerateROIBinaryMask();

    %Basic information
%     dsInfo.Modality     = 'PET'; % handles.ImageInfo.Modality;
     dsInfo.MRN          = 11111; %handles.PatInfo.MRN;
     dsInfo.DBName      = '';% handles.ImageInfo.DBName;
     dsInfo.ROIName     = '';
%     dsInfo.Comment      = '';% handles.ImageInfo.Comment;
%     dsInfo.ScanTime     = '';% handles.ImageInfo.ScanTime;
%     dsInfo.Slices       = size(im,3); %handles.ImageInfo.Slices;
%     dsInfo.SeriesInfo   = ''; %handles.ImageInfo.SeriesInfo;
%     dsInfo.ImageID      = ''; %handles.ImageInfo.ImageID;
%     dsInfo.SrcPath      = []; %handles.PatPath;
    bbox = regionprops3(mask, 'BoundingBox');
    if size(bbox, 1) > 1
        bbox = regionprops3(imclose(mask, strel('square', 4)), 'BoundingBox');
        if size(bbox, 1) > 1
            volumes = prod(bbox.BoundingBox(:,4:end), 2); %'size' of each bbox
            bbox = bbox(volumes == max(volumes), :); %assuming a single max
        end
    end
    bbox = ceil(bbox.BoundingBox);
    crop = @(x) x(bbox(2)+ (0:bbox(5)),bbox(1)+ (0:bbox(4)),bbox(3)+ (0:bbox(6))); %Swapped 1st and 2nd dims?
    dsInfo.ROIBWInfo.MaskData    = crop(mask);
    dsInfo.ROIImageInfo.MaskData = crop(im);
    
    [dsInfo.ROIBWInfo.XDim, dsInfo.ROIBWInfo.YDim, dsInfo.ROIBWInfo.ZDim] = size(dsInfo.ROIBWInfo.MaskData);
    dsInfo.ROIBWInfo.XPixDim = 1;
    dsInfo.ROIBWInfo.YPixDim = 1;
    dsInfo.ROIBWInfo.ZPixDim = 1;
    
    dsInfo.ROIImageInfo.XPixDim = 1;
    dsInfo.ROIImageInfo.YPixDim = 1;
    dsInfo.ROIImageInfo.ZPixDim = 1;
    
    dsInfo.ROIBWInfo.XStart = 0;
    dsInfo.ROIBWInfo.YStart = 0;
    dsInfo.ROIBWInfo.ZStart = 0;
    %dsInfo = emulate_GetDateSetROIInfo(dsInfo,MaskInfo);  
    %dsInfo = emulate_GetStructAxialROI(dsInfo);

end

function BWInfo = emulate_GenerateROIBinaryMask()
    ROIName = 'ROI';
    PlanIndex = 1; %{'fake plan';'User'}
    BWMatInfoT = emulate_BWFillROI();
    BWMatInfoT.ROINamePlanIndex = [deblank(ROIName), num2str(PlanIndex)];
end

function BWMatInfo = emulate_BWFillROI()
BWMatInfo.XStart=[];
BWMatInfo.YStart=[];
BWMatInfo.ZStart=[];

BWMatInfo.XDim=[];
BWMatInfo.YDim=[];
BWMatInfo.ZDim=[];

BWMatInfo.XPixDim=[];
BWMatInfo.YPixDim=[];
BWMatInfo.ZPixDim=[];

BWMatInfo.MaskData=[];

 %Preprocess--resample
if isfield(handles, 'ZStart')
    ResampleFlag=1;
else
    ResampleFlag=0;
end

if ResampleFlag <1
    %SpecifyData, ROIEditor, ROIEditorDataSet
    ImageDataInfoAxial=GetImageDataInfo(handles, 'Axial');
else
    %Preprocess--resample
    ImageDataInfoAxial=handles;
    ImageDataInfoAxial.TablePos=handles.ZStart+((1:handles.ZDim)-1)*handles.ZPixDim;
    structViewROI=handles.structAxialROI;    
end

switch nargin
    case 3
        if ~isempty(PlanIndex)
            structViewROI=handles.PlansInfo.structAxialROI{PlanIndex};
        end
        
        ContourNum=length(structViewROI(ROIIndex).CurvesCor);        
        ContourZLoc=structViewROI(ROIIndex).ZLocation;                
    case 4       
        structViewROI=handles.PlansInfo.structAxialROI{PlanIndex};     
        structViewROI=structViewROI(ROIIndex);
        ContourZLoc=structViewROI.ZLocation;
        
        TempIndex=find(abs(ContourZLoc-ZLocation) < ImageDataInfoAxial.ZPixDim/3);
        if isempty(TempIndex)
            return;
        end
        
        structViewROI.ZLocation=structViewROI.ZLocation(TempIndex);
        structViewROI.CurvesCor=structViewROI.CurvesCor(TempIndex);
        
        ContourNum=length(structViewROI.CurvesCor);
        ContourZLoc=structViewROI.ZLocation;
        
        ROIIndex=1;
    case 6        
        structViewROI.CurvesCor(1)={[LineX', LineY']};
        ContourNum=length(structViewROI.CurvesCor);
        ContourZLoc=ZLocation;
        
        ROIIndex=1;
end

if isempty(ContourZLoc)
    return;
end

%Get Limit box
if ResampleFlag <1
    MinZ=min(ContourZLoc);
    MaxZ=max(ContourZLoc);

    MinX=9999999;
    MinY=9999999;
    MaxX=-9999999;
    MaxY=-9999999;
    
    for i=1:ContourNum
        ContourData=structViewROI(ROIIndex).CurvesCor{i};
        
        if ~isempty(ContourData)
            MinX=min(MinX, min(ContourData(:, 1)));
            MaxX=max(MaxX, max(ContourData(:, 1)));
            
            MinY=min(MinY, min(ContourData(:, 2)));
            MaxY=max(MaxY, max(ContourData(:, 2)));
        end
    end
else
    %Preprocess--resample
    MinX=ImageDataInfoAxial.XStart;
    MaxX=ImageDataInfoAxial.XStart+(ImageDataInfoAxial.XDim-1)*ImageDataInfoAxial.XPixDim;
    
    MinY=ImageDataInfoAxial.YStart;
    MaxY=ImageDataInfoAxial.YStart+(ImageDataInfoAxial.YDim-1)*ImageDataInfoAxial.YPixDim;
    
    MinZ=ImageDataInfoAxial.ZStart;
    MaxZ=ImageDataInfoAxial.ZStart+(ImageDataInfoAxial.ZDim-1)*ImageDataInfoAxial.ZPixDim;
end

MinPage=round((MinZ-ImageDataInfoAxial.ZStart)/ImageDataInfoAxial.ZPixDim+1);
MaxPage=round((MaxZ-ImageDataInfoAxial.ZStart)/ImageDataInfoAxial.ZPixDim+1);

if MinPage > ImageDataInfoAxial.ZDim || MaxPage < 1
    return;
end

if MinPage < 1
    MinPage=1;
end

if MaxPage > ImageDataInfoAxial.ZDim
    MaxPage=ImageDataInfoAxial.ZDim;
end

MinCol=round((MinX-ImageDataInfoAxial.XStart)/ImageDataInfoAxial.XPixDim+1);
MaxCol=round((MaxX-ImageDataInfoAxial.XStart)/ImageDataInfoAxial.XPixDim+1);

MaxRow=round(ImageDataInfoAxial.YDim-(MinY-ImageDataInfoAxial.YStart)/ImageDataInfoAxial.YPixDim);
MinRow=round(ImageDataInfoAxial.YDim-(MaxY-ImageDataInfoAxial.YStart)/ImageDataInfoAxial.YPixDim);

%Refine MinX, MinY, MinZ
MinX=(MinCol-1)*ImageDataInfoAxial.XPixDim+ImageDataInfoAxial.XStart;
MinY=(ImageDataInfoAxial.YDim-MaxRow)*ImageDataInfoAxial.XPixDim+ImageDataInfoAxial.YStart;
MinZ=ImageDataInfoAxial.TablePos(MinPage);

%Fill
RowNum=MaxRow-MinRow+1;
ColNum=MaxCol-MinCol+1;
PageNum=MaxPage-MinPage+1;

TablePos=ImageDataInfoAxial.TablePos(MinPage:MaxPage);

BWMat=zeros(RowNum, ColNum, PageNum, 'uint8');

%Square Len for MKroipoly
SquareLen=max(RowNum, ColNum);

for i=1:ContourNum
    
    TempZLocation=ContourZLoc(i)  ;    %ZLocation
    ContourData=structViewROI(ROIIndex).CurvesCor{i};
           
    if  min(abs(TablePos-TempZLocation)) <= (ImageDataInfoAxial.ZPixDim/3)      %if curve is in image domain
        
        BWC=ContourData(:,2); BWR=ContourData(:,1);
        
        CIndex=round((BWC-MinY)/ImageDataInfoAxial.YPixDim)+1;
        RIndex=round((BWR-MinX)/ImageDataInfoAxial.XPixDim)+1;
        
        %Method 1---MATLAB
%         TempImage=uint8(zeros(RowNum, ColNum, 'uint8'));
%         BWSlice=roipoly(TempImage, RIndex, CIndex);        
        
        %Method 2---MKRoipoly
        TempImage=uint8(zeros(SquareLen, SquareLen, 'uint8'));
        
        x=BWR-single(MinX); x=(x/single(ImageDataInfoAxial.XPixDim))+1;
        y=BWC-single(MinY); y=(y/single(ImageDataInfoAxial.YPixDim))+1;
        BWSlice=MKroipoly(TempImage, x, y);
        BWSlice=BWSlice(1:RowNum, 1:ColNum);
                       
        [MinT, ZIndex]=min(abs(TablePos-TempZLocation));
        
        BWMat(:,:,ZIndex)=xor(BWMat(:,:,ZIndex), BWSlice);
    end        
end
       
BWMat=flipdim(BWMat, 1);


BWMatInfo.XStart=MinX;
BWMatInfo.YStart=MinY;
BWMatInfo.ZStart=MinZ;

BWMatInfo.XDim=size(BWMat, 2);
BWMatInfo.YDim=size(BWMat, 1);
BWMatInfo.ZDim=size(BWMat, 3);

BWMatInfo.XPixDim=ImageDataInfoAxial.XPixDim;
BWMatInfo.YPixDim=ImageDataInfoAxial.YPixDim;
BWMatInfo.ZPixDim=ImageDataInfoAxial.ZPixDim;

BWMatInfo.MaskData=BWMat;
end

function FeatureSetsInfo = getFeatureset(fname)
    load(fname, 'FeatureSetsInfo'); 
end