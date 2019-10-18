function FeatureInfo=NeighborIntensityDifference25_Feature(ParentInfo, FeatureInfo, Mode)

[MFilePath, MFileName]=fileparts(mfilename('fullpath'));

%Parse Feature Names and Params
if isempty(FeatureInfo)
    FeatureName=ParseFeatureName(MFilePath, MFileName(1:end-8));
    
    if isempty(FeatureName)
        FeatureInfo=[];
        return;
    end
    
    for i=1:length(FeatureName)
        FeatureInfo(i).Name=FeatureName{i};
        
        ConfigFile=[MFilePath, '\', MFileName, '_', FeatureName{i}, '.INI'];
        Param=GetParamFromINI(ConfigFile);
        FeatureInfo(i).Value=Param;
    end
    
    %For passing the feature name
    if isequal(Mode, 'ParseFeature')
        return;
    end
end

%Parent Information
FeaturePrefix=MFileName;

for i=1:length(FeatureInfo)
    if isequal(Mode, 'Review')
        [FeatureValue, FeatureReviewInfo]=GetFeatureValue(ParentInfo, FeatureInfo(i), FeaturePrefix);
        FeatureInfo(i).FeatureValue=FeatureValue;
        FeatureInfo(i).FeatureReviewInfo=FeatureReviewInfo;
    else
        FeatureValue=GetFeatureValue(ParentInfo, FeatureInfo(i), FeaturePrefix);
        
        if length(FeatureValue) > 1
            FeatureInfo(i).FeatureValueParam=FeatureValue(1, 2:end);
            FeatureInfo(i).FeatureValue=FeatureValue(2:end, :);
        else
            FeatureInfo(i).FeatureValue=FeatureValue;
        end
    end         
end


function [FeatureValue, FeatureReviewInfo]=GetFeatureValue(ParentInfo, CurrentFeatureInfo,  FeaturePrefix)
FeatureName=CurrentFeatureInfo.Name;

FuncName=[FeaturePrefix, '_', FeatureName];
FuncHandle=str2func(FuncName);

[FeatureValue, FeatureReviewInfo]=FuncHandle(ParentInfo, CurrentFeatureInfo.Value);


function [Value, ReviewInfo]=NeighborIntensityDifference25_Feature_Coarseness(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Amadasun, M.; King, R. Textural features corresponding to textural properties.
%   IEEE Transactions on Systems, Man and Cybernetics,Volume 19 Issue 5, Page 1264-1274 "
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeNIDFeature(ParentInfo, 'Coarseness');

function [Value, ReviewInfo]=NeighborIntensityDifference25_Feature_Contrast(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Amadasun, M.; King, R. Textural features corresponding to textural properties.
%   IEEE Transactions on Systems, Man and Cybernetics,Volume 19 Issue 5, Page 1264-1274 "
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeNIDFeature(ParentInfo, 'Contrast');

function [Value, ReviewInfo]=NeighborIntensityDifference25_Feature_Busyness(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Amadasun, M.; King, R. Textural features corresponding to textural properties.
%   IEEE Transactions on Systems, Man and Cybernetics,Volume 19 Issue 5, Page 1264-1274 "
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeNIDFeature(ParentInfo, 'Busyness');

function [Value, ReviewInfo]=NeighborIntensityDifference25_Feature_Complexity(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Amadasun, M.; King, R. Textural features corresponding to textural properties.
%   IEEE Transactions on Systems, Man and Cybernetics,Volume 19 Issue 5, Page 1264-1274 "
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeNIDFeature(ParentInfo, 'Complexity');

function [Value, ReviewInfo]=NeighborIntensityDifference25_Feature_TextureStrength(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Amadasun, M.; King, R. Textural features corresponding to textural properties.
%   IEEE Transactions on Systems, Man and Cybernetics,Volume 19 Issue 5, Page 1264-1274 "
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeNIDFeature(ParentInfo, 'TextureStrength');


function [Value, ReviewInfo]=ComputeNIDFeature(ParentInfo, Mode)
Epsilon= 1e-10;
NIDStruct=ParentInfo.ROIImageInfo.NIDStruct;

if isnan(NIDStruct.HistOccurPropability)
    Value=NaN;
    ReviewInfo.MaskData=Value;

    return;
end

switch Mode
    case 'Coarseness'
        ValidNumVoxel=length(find(NIDStruct.DiffMaskBW));%Remove the tumor size impact
        Value=1/(Epsilon+sum(NIDStruct.HistDiffSum./ValidNumVoxel));
       %Value=1/(Epsilon+sum(NIDStruct.HistDiffSum)); %uncomment if want orig (voldep one)
        
    case 'Contrast'
        ValidNumVoxel=length(find(NIDStruct.DiffMaskBW));
        AveDiff1D=sum(NIDStruct.HistDiffSum)/ValidNumVoxel;
        
        AveDiff2D=ComputeAverageCrossDiff(NIDStruct);
        
        Value=AveDiff1D*AveDiff2D;
        
    case 'Busyness'
        ValidNumVoxel=length(find(NIDStruct.DiffMaskBW));%Remove the tumor size impact
        WeightDiff=NIDStruct.HistDiffSum./ValidNumVoxel;
        %WeightDiff=NIDStruct.HistDiffSum; %uncomment if want orig (voldep one)
        
        SumDiff1D=sum(WeightDiff);        
        SumDiff2D=ComputeSumCrossDiff(NIDStruct);
        
        Value=SumDiff1D/(Epsilon+SumDiff2D);
        
    case 'Complexity'
        Value=ComputeComplex(NIDStruct);
        
    case 'TextureStrength'
        SumDiff=sum(NIDStruct.HistDiffSum);
        
        SumWeightDiff2D=ComputeSumCrossWeightDiff(NIDStruct);
        
        Value=SumWeightDiff2D/(Epsilon+SumDiff);
        
end

ReviewInfo.MaskData=Value;
ReviewInfo.NIDTable = NIDStruct;

% NID = figure('Position',[1500 500 400 400]);
% uitable('Parent',NID,'Data',[NIDStruct.HistBinLoc,NIDStruct.HistDiffSum,NIDStruct.HistOccurPropability],'ColumnName',{'Values','Difference','Probability'},'Position',[0 0 350 400])


function SumComplex=ComputeComplex(NIDStruct)
ValidNumVoxel=length(find(NIDStruct.DiffMaskBW));

Prop=NIDStruct.HistOccurPropability;
DiffSum=NIDStruct.HistDiffSum;
BinLoc=NIDStruct.HistBinLoc;

%Remove empty entries
TempIndex=find(Prop == 0);
if ~isempty(TempIndex)
    Prop(TempIndex)=[];
    DiffSum(TempIndex)=[];
    BinLoc(TempIndex)=[];
end

%Cross part
IntensityMat1=repmat(BinLoc, 1, length(BinLoc));
IntensityMat2=IntensityMat1';

Occur=Prop*ValidNumVoxel;

OccurMat1=repmat(Occur, 1, length(BinLoc));
OccurMat2=OccurMat1';

NormIntensityCrossDiff=abs(IntensityMat1-IntensityMat2)./(OccurMat1+OccurMat2);

%Self part
PropMat1=repmat(Prop, 1, length(BinLoc));
PropMat2=PropMat1';

DiffSumMat1=repmat(DiffSum, 1, length(BinLoc));
DiffSumMat2=DiffSumMat1';

IntensityDiff=PropMat1.*DiffSumMat1+PropMat2.*DiffSumMat2;

Result=NormIntensityCrossDiff.*IntensityDiff;

SumComplex=sum(Result(:));


function SumDiff2D=ComputeSumCrossWeightDiff(NIDStruct)
Prop=NIDStruct.HistOccurPropability;
BinLoc=NIDStruct.HistBinLoc;

%Remove empty entries
TempIndex=find(Prop == 0);
if ~isempty(TempIndex)
    Prop(TempIndex)=[];
    BinLoc(TempIndex)=[];
end

IntensityMat1=repmat(BinLoc, 1, length(BinLoc));
IntensityMat2=IntensityMat1';

PropMat1=repmat(Prop, 1, length(BinLoc));
PropMat2=PropMat1';

Result=(PropMat1+PropMat2).*(IntensityMat1-IntensityMat2).*(IntensityMat1-IntensityMat2);

SumDiff2D=sum(Result(:));


function SumDiff2D=ComputeSumCrossDiff(NIDStruct)
Prop=NIDStruct.HistOccurPropability;
BinLoc=NIDStruct.HistBinLoc;

%Remove empty entries
TempIndex=find(Prop == 0);
if ~isempty(TempIndex)
    Prop(TempIndex)=[];
    BinLoc(TempIndex)=[];
end

WeightBinLoc=BinLoc.*Prop;

DiffMat1=repmat(WeightBinLoc, 1, length(BinLoc));
DiffMat2=DiffMat1';

TempMat=abs(DiffMat1-DiffMat2);

SumDiff2D=sum(TempMat(:));


function AveDiff2D=ComputeAverageCrossDiff(NIDStruct)
Prop=NIDStruct.HistOccurPropability;
BinLoc=NIDStruct.HistBinLoc;

%Remove empty entries
TempIndex=find(Prop == 0);
if ~isempty(TempIndex)
    Prop(TempIndex)=[];
    BinLoc(TempIndex)=[];
end

IntensityMat1=repmat(BinLoc, 1, length(BinLoc));
IntensityMat2=repmat(BinLoc', length(BinLoc), 1);

PropMat1=repmat(Prop, 1, length(BinLoc));
PropMat2=repmat(Prop', length(BinLoc), 1);

SqrtDiff2D=(IntensityMat1-IntensityMat2).^2;
Prop2D=PropMat1.*PropMat2;

SumDiff2D=SqrtDiff2D.*Prop2D;
AveDiff2D=mean(SumDiff2D(:));

    
    
    
    
    
    
    
    
    
    
    
    







