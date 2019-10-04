function FeatureInfo=GrayLevelRunLengthMatrix25_Feature(ParentInfo, FeatureInfo, Mode)

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
        
        if size(FeatureValue, 2) > 1
            FeatureInfo(i).FeatureValueParam=FeatureValue(:, 1);
            FeatureInfo(i).FeatureValue=FeatureValue(:, 2);
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

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_ShortRunEmphasis(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Xiaoou Tang. Texture information in run-length matrices.
%  IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609."
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'ShortRunEmphasis');

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_LongRunEmphasis(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Xiaoou Tang. Texture information in run-length matrices.
%  IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609."
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'LongRunEmphasis');

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_GrayLevelNonuniformity(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
% 1. Xiaoou Tang. Texture information in run-length matrices. IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609.
% 2. Fave, X. et al. Impact of image preprocessing on the volume dependence and prognostic potential of radiomics features in non-small cell lung cancer. Translational Cancer Research 5, 349-363 (2016).
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'GrayLevelNonuniformity');

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_RunLengthNonuniformity(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
% 1. Xiaoou Tang. Texture information in run-length matrices. IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609.
% 2. Fave, X. et al. Impact of image preprocessing on the volume dependence and prognostic potential of radiomics features in non-small cell lung cancer. Translational Cancer Research 5, 349-363 (2016).
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'RunLengthNonuniformity');

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_RunPercentage(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Xiaoou Tang. Texture information in run-length matrices.
%  IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609."
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'RunPercentage');

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_LowGrayLevelRunEmpha(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Xiaoou Tang. Texture information in run-length matrices.
%  IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609."
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'LowGrayLevelRunEmphasis');

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_HighGrayLevelRunEmpha(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Xiaoou Tang. Texture information in run-length matrices.
%  IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609."
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'HighGrayLevelRunEmphasis');

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_ShortRunLowGrayLevelEmpha(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Xiaoou Tang. Texture information in run-length matrices.
%  IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609."
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'ShortRunLowGrayLevelEmphasis');

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_ShortRunHighGrayLevelEmpha(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Xiaoou Tang. Texture information in run-length matrices.
%  IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609."
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'ShortRunHighGrayLevelEmphasis');

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_LongRunLowGrayLevelEmpha(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Xiaoou Tang. Texture information in run-length matrices.
%  IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609."
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'LongRunLowGrayLevelEmphasis');

function [Value, ReviewInfo]=GrayLevelRunLengthMatrix25_Feature_LongRunHighGrayLevelEmpha(ParentInfo, Param)
%%%Doc Starts%%%
%For the feature description, refer to the paper below.
%  "Xiaoou Tang. Texture information in run-length matrices.
%  IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609."
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, 'LongRunHighGrayLevelEmphasis');



function [Value, ReviewInfo]=ComputeGLRLMFeature(ParentInfo, Mode)
DirectionNum=length(ParentInfo.ROIImageInfo.GLRLMStruct25);

FeatureValue=zeros(DirectionNum, 1);

for i=1:DirectionNum
    CurrentItem=ParentInfo.ROIImageInfo.GLRLMStruct25(i);
    
    GLRLM=CurrentItem.GLRLM;        
    [GrayLevelNum, RunLenLevelNum]= size(GLRLM);
    
    RunLenVec2=(1:RunLenLevelNum).^2;    
    GrayVec2=(1:GrayLevelNum)'.^2;
        
    switch Mode
        case 'ShortRunEmphasis'
            TempMat=repmat(RunLenVec2, GrayLevelNum, 1);            
            TempMat=GLRLM./TempMat;
            
            FinalValue=sum(TempMat(:))/sum(GLRLM(:));            
            
        case 'LongRunEmphasis'
            TempMat=repmat(RunLenVec2, GrayLevelNum, 1);            
            TempMat=GLRLM.*TempMat;
            
            FinalValue=sum(TempMat(:))/sum(GLRLM(:));
            
        case 'LowGrayLevelRunEmphasis'
            TempMat=repmat(GrayVec2, 1, RunLenLevelNum);
            TempMat=GLRLM./TempMat;
            
            FinalValue=sum(TempMat(:))/sum(GLRLM(:));
            
        case 'HighGrayLevelRunEmphasis'                        
            TempMat=repmat(GrayVec2, 1, RunLenLevelNum);
            TempMat=GLRLM.*TempMat;
            
            FinalValue=sum(TempMat(:))/sum(GLRLM(:));
            
        case 'ShortRunLowGrayLevelEmphasis'           
            TempMatRun=repmat(RunLenVec2, GrayLevelNum, 1);  
            TempMatGray=repmat(GrayVec2, 1, RunLenLevelNum);
            
            TempMat=GLRLM./TempMatRun./TempMatGray;
            
            FinalValue=sum(TempMat(:))/sum(GLRLM(:));            
            
        case 'ShortRunHighGrayLevelEmphasis'          
            TempMatRun=repmat(RunLenVec2, GrayLevelNum, 1);     
            TempMatGray=repmat(GrayVec2, 1, RunLenLevelNum);
            
            TempMat=GLRLM.*TempMatGray./TempMatRun;
            
            FinalValue=sum(TempMat(:))/sum(GLRLM(:));            
            
        case 'LongRunLowGrayLevelEmphasis'           
            TempMatRun=repmat(RunLenVec2, GrayLevelNum, 1);        
            TempMatGray=repmat(GrayVec2, 1, RunLenLevelNum);
            
            TempMat=GLRLM.*TempMatRun./TempMatGray;
            
            FinalValue=sum(TempMat(:))/sum(GLRLM(:));            
            
        case 'LongRunHighGrayLevelEmphasis'
            TempMatRun=repmat(RunLenVec2, GrayLevelNum, 1);        
            TempMatGray=repmat(GrayVec2, 1, RunLenLevelNum);
            
            TempMat=GLRLM.*TempMatRun.*TempMatGray;
            
            FinalValue=sum(TempMat(:))/sum(GLRLM(:));  
            
        case 'GrayLevelNonuniformity'
            TempMat=sum(GLRLM, 2).^2;
            FinalValueA=sum(TempMat(:))/sum(GLRLM(:));  
            FinalValue=FinalValueA/sum(ParentInfo.ROIBWInfo.MaskData(:));
            %FinalValue=FinalValueA; %uncomment if want the orig (vol-dep version back)
           
        case 'RunLengthNonuniformity'     
            TempMat=sum(GLRLM, 1).^2;
            FinalValueA=sum(TempMat(:))/sum(GLRLM(:));   
            FinalValue=FinalValueA/sum(ParentInfo.ROIBWInfo.MaskData(:));
            %FinalValue=FinalValueA; %uncomment if want the orig (vol-dep version back)
             
        case 'RunPercentage'
            TempIndex=find(ParentInfo.ROIBWInfo.MaskData);
            FinalValue=sum(GLRLM(:))/length(TempIndex);
    end           
        
    FeatureValue(i)=FinalValue;
end

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.Description=['GLRLM Feature', ' (Direction VS ', Mode, ')'];

Direction=cell2mat({ParentInfo.ROIImageInfo.GLRLMStruct25.Direction});

Value=[Direction', FeatureValue];
ReviewInfo.MaskData=Value;




