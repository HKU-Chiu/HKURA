function FeatureInfo=IntensityDirect_Feature(ParentInfo, FeatureInfo, Mode)

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
        
        %handle buffer data or not
        if ~isstruct(FeatureValue)                    
            if length(FeatureValue) > 1
                FeatureInfo(i).FeatureValueParam=FeatureValue(:, 1);
                FeatureInfo(i).FeatureValue=FeatureValue(:, 2);
            else
                FeatureInfo(i).FeatureValue=FeatureValue;
            end
        else
            %Handle a group of feature
             FeatureInfo(i).FeatureValue=FeatureValue.Value;
             ParentInfo.BufferData=FeatureValue.BufferData;
             ParentInfo.BufferType=FeatureValue.BufferType;
        end               
    end         
end


function [FeatureValue, FeatureReviewInfo]=GetFeatureValue(ParentInfo, CurrentFeatureInfo,  FeaturePrefix)
FeatureName=CurrentFeatureInfo.Name;

FuncName=[FeaturePrefix, '_', FeatureName];
FuncHandle=str2func(FuncName);

[FeatureValue, FeatureReviewInfo]=FuncHandle(ParentInfo, CurrentFeatureInfo.Value);



%Global features
function [Value, ReviewInfo]=IntensityDirect_Feature_GlobalMax(ParentInfo, Param)
%%%Doc Starts%%%
%The intensity maximum among all the voxels.
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value= max(double(MaskImageMat));
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;


function [Value, ReviewInfo]=IntensityDirect_Feature_GlobalMin(ParentInfo, Param)
%%%Doc Starts%%%
%The intensity minimum among all the voxels.
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value= min(double(MaskImageMat));
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=IntensityDirect_Feature_GlobalMedian(ParentInfo, Param)
%%%Doc Starts%%%
%The intensity median among all the voxels.
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value= median(double(MaskImageMat));
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=IntensityDirect_Feature_GlobalMean(ParentInfo, Param)
%%%Doc Starts%%%
%The intensity mean among all the voxels.
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value= mean(double(MaskImageMat));
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=IntensityDirect_Feature_Range(ParentInfo, Param)
%%%Doc Starts%%%
%The intensity range(MaxValue-MinValue) among all the voxels.
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value= max(double(MaskImageMat))-min(double(MaskImageMat));
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;



function [Value, ReviewInfo]=IntensityDirect_Feature_Kurtosis(ParentInfo, Param)
%%%Doc Starts%%%
%Measure the peakedness of all the voxels' intensity.
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value=kurtosis(double(MaskImageMat));
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=IntensityDirect_Feature_Skewness(ParentInfo, Param)
%%%Doc Starts%%%
%Measure the  asymmetry of all the voxels' intensity.
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value=skewness(double(MaskImageMat));
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=IntensityDirect_Feature_GlobalStd(ParentInfo, Param)
%%%Doc Starts%%%
%The intensity standard deviation among all the voxels.
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value=std(double(MaskImageMat));
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;


function [Value, ReviewInfo]=NoUseIntensityDirect_Feature_GlobalMeanVolumeWeighted(ParentInfo, Param)
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

%Total number of voxel
NumVox=sum(double(BWInfo.MaskData(:)));

ImageData=ImageInfo.MaskData;
ImageData(~BWInfo.MaskData)=0;

SumImageSlice=sum(ImageData, 1);
SumImageSlice=sum(SumImageSlice, 2);
SumImageSlice=squeeze(SumImageSlice);

SumBWSlice=sum(double(BWInfo.MaskData), 1);
SumBWSlice=sum(SumBWSlice, 2);
SumBWSlice=squeeze(SumBWSlice);

TempIndex=find(SumBWSlice == 0);
if ~isempty(TempIndex)
    SumImageSlice(TempIndex)=[];
    SumBWSlice(TempIndex)=[];    
end

if ~isempty(SumImageSlice)
    MeanImageSlice=SumImageSlice./SumBWSlice;    
    MeanAll=sum(MeanImageSlice.*SumBWSlice/NumVox);
    
    Value=MeanAll;
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;


function [Value, ReviewInfo]=NoUseIntensityDirect_Feature_VolumeThres(ParentInfo, Param)
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

Value=length(MaskImageMat)*ImageInfo.XPixDim*ImageInfo.YPixDim*ImageInfo.ZPixDim;

ReviewInfo.MaskData=Value;

%Local features---Entropy
function [Value, ReviewInfo]=IntensityDirect_Feature_LocalEntropyMax(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute entropy in its neighborhood region.
%2. Then, compute the maximum among all the voxel's entropy caculated from 1.

%-Parameters:
%1. NHood:        Size of the neighborhood
%2. RangeMin:    Lower bound of bin location.
%3. RangeMax:   Upper bound of bin location.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalEntropyFeature(ParentInfo, Param, 'Max');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalEntropyMedian(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute entropy in its neighborhood region.
%2. Then, compute the median among all the voxel's entropy caculated from 1.

%-Parameters:
%1. NHood:        Size of the neighborhood
%2. RangeMin:    Lower bound of bin location.
%3. RangeMax:   Upper bound of bin location.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalEntropyFeature(ParentInfo, Param, 'Median');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalEntropyMin(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute entropy in its neighborhood region.
%2. Then, compute the minimum among all the voxel's entropy caculated from 1.

%-Parameters:
%1. NHood:        Size of the neighborhood
%2. RangeMin:    Lower bound of bin location.
%3. RangeMax:   Upper bound of bin location.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalEntropyFeature(ParentInfo, Param, 'Min');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalEntropyMean(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute entropy in its neighborhood region.
%2. Then, compute the mean among all the voxel's entropy caculated from 1.

%-Parameters:
%1. NHood:        Size of the neighborhood
%2. RangeMin:    Lower bound of bin location.
%3. RangeMax:   Upper bound of bin location.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalEntropyFeature(ParentInfo, Param, 'Mean');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalEntropyStd(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute entropy in its neighborhood region.
%2. Then, compute the standard deviation among all the voxel's entropy caculated from 1.

%-Parameters:
%1. NHood:        Size of the neighborhood
%2. RangeMin:    Lower bound of bin location.
%3. RangeMax:   Upper bound of bin location.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalEntropyFeature(ParentInfo, Param, 'Std');

%Local features---Range
function [Value, ReviewInfo]=IntensityDirect_Feature_LocalRangeMax(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute range value(MaxValue-MinValue) in its neighborhood region.
%2. Then, compute the median among all the voxel's range value caculated from 1.

%-Parameters:
%1. NHood:    Size of the neighborhood
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalRangeFeature(ParentInfo, Param, 'Max');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalRangeMedian(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute range value(MaxValue-MinValue) in its neighborhood region.
%2. Then, compute the median among all the voxel's range value caculated from 1.

%-Parameters:
%1. NHood:    Size of the neighborhood
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalRangeFeature(ParentInfo, Param, 'Median');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalRangeMin(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute range value(MaxValue-MinValue) in its neighborhood region.
%2. Then, compute the minimum among all the voxel's range value caculated from 1.

%-Parameters:
%1. NHood:    Size of the neighborhood
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalRangeFeature(ParentInfo, Param, 'Min');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalRangeMean(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute range value(MaxValue-MinValue) in its neighborhood region.
%2. Then, compute the mean among all the voxel's range value caculated from 1.

%-Parameters:
%1. NHood:    Size of the neighborhood
%%%Doc Ends%%%

[Value, ReviewInfo]=ComputeLocalRangeFeature(ParentInfo, Param, 'Mean');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalRangeStd(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute range value(MaxValue-MinValue) in its neighborhood region.
%2. Then, compute the standard deviation among all the voxel's range value caculated from 1.

%-Parameters:
%1. NHood:    Size of the neighborhood
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalRangeFeature(ParentInfo, Param, 'Std');

%Local features---Std
function [Value, ReviewInfo]=IntensityDirect_Feature_LocalStdMax(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute standard deviation in its neighborhood region.
%2. Then, compute the maximum among all the voxel's standard deviation value caculated from 1.

%-Parameters:
%1. NHood:    Size of the neighborhood
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalStdFeature(ParentInfo, Param, 'Max');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalStdMin(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute standard deviation in its neighborhood region.
%2. Then, compute the mimimum among all the voxel's standard deviation value caculated from 1.

%-Parameters:
%1. NHood:    Size of the neighborhood
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalStdFeature(ParentInfo, Param, 'Min');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalStdMedian(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute standard deviation in its neighborhood region.
%2. Then, compute the median among all the voxel's standard deviation value caculated from 1.

%-Parameters:
%1. NHood:    Size of the neighborhood
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalStdFeature(ParentInfo, Param, 'Median');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalStdMean(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute standard deviation in its neighborhood region.
%2. Then, compute the mean among all the voxel's standard deviation value caculated from 1.

%-Parameters:
%1. NHood:    Size of the neighborhood
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalStdFeature(ParentInfo, Param, 'Mean');

function [Value, ReviewInfo]=IntensityDirect_Feature_LocalStdStd(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. First, at each voxel, compute standard deviation in its neighborhood region.
%2. Then, compute the standard deviation all the voxel's standard deviation value caculated from 1.

%-Parameters:
%1. NHood:    Size of the neighborhood
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeLocalStdFeature(ParentInfo, Param, 'Std');

function [Value, ReviewInfo]=IntensityDirect_Feature_MeanAbsoluteDeviation(ParentInfo, Param)
%%%Doc Starts%%%
%The mean absolute deviation of the intensity values among all the voxels.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeStatFeature(ParentInfo, Param, 'MeanAbsoluteDeviation');

function [Value, ReviewInfo]=IntensityDirect_Feature_MedianAbsoluteDeviation(ParentInfo, Param)
%%%Doc Starts%%%
%The median absolute deviation of the intensity values among all the voxels.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeStatFeature(ParentInfo, Param, 'MedianAbsoluteDeviation');

function [Value, ReviewInfo]=IntensityDirect_Feature_InterQuartileRange(ParentInfo, Param)
%%%Doc Starts%%%
%The interquartile range of the intensity values among all the voxels.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeStatFeature(ParentInfo, Param, 'InterQuartileRange');

function [Value, ReviewInfo]=IntensityDirect_Feature_Percentile(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Percentiles of the intensity values among all the voxels.

%-Parameters:
%1.  Percentile: Percent values.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeStatFeature(ParentInfo, Param, 'Percentile');

function [Value, ReviewInfo]=IntensityDirect_Feature_Quantile(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Quantiles of the intensity values among all the voxels.

%-Parameters:
%1.  Quantile: Cumulative probability values.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeStatFeature(ParentInfo, Param, 'Quantile');

function [Value, ReviewInfo]=ComputeStatFeature(ParentInfo, Param, Mode)
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=double(MaskImageMat(:));

ReviewInfo=ParentInfo.ROIImageInfo;

switch Mode
    case  'Skewness'
        Value = skewness(MaskImageMat);
        ReviewInfo.Value=Value;
    case 'Kurtosis'
        Value = kurtosis(MaskImageMat);
        ReviewInfo.Value=Value;
    case 'Range'
        Value = range(MaskImageMat);
        ReviewInfo.Value=Value;
    case 'MeanAbsoluteDeviation'
        Value = mad(MaskImageMat, 0);
        ReviewInfo.Value=Value;
    case 'MedianAbsoluteDeviation'
        Value = mad(MaskImageMat, 1);
        ReviewInfo.Value=Value;
    case 'InterQuartileRange'
        Value = iqr(MaskImageMat);
        ReviewInfo.Value=Value;
    case 'Percentile'        
        Value = prctile(MaskImageMat, Param.Percentile');        
        ReviewInfo.MaskData=[Param.Percentile', Value];
        ReviewInfo.Description='Intensity Percentile';        
        
        Value=[Param.Percentile', Value];
        ReviewInfo.Value=[];         
    case 'Quantile'
        Value = quantile(MaskImageMat, Param.Quantile');        
        ReviewInfo.MaskData=[Param.Quantile', Value];
        ReviewInfo.Description='Intensity Quantile';   
        
        Value=[Param.Quantile', Value];
        ReviewInfo.Value=[];
end       

function [Value, ReviewInfo]=IntensityDirect_Feature_Energy(ParentInfo, Param)
%%%Doc Starts%%%
%--Reference:
%1. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%2. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%3. Fave, X. et al. Impact of image preprocessing on the volume dependence and prognostic potential of radiomics features in non-small cell lung cancer. Translational Cancer Research 5, 349-363 (2016).
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value= sum((double(MaskImageMat)).^2); %%the orig (voldep form)
    %Value=  sum((double(MaskImageMat)).^2)/sum(BWInfo.MaskData(:)); %% XF volindep version(dividing by num of vox)
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=IntensityDirect_Feature_EnergyNorm(ParentInfo, Param)
%%%Doc Starts%%%
%--Reference:
%1. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%2. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%3. Fave, X. et al. Impact of image preprocessing on the volume dependence and prognostic potential of radiomics features in non-small cell lung cancer. Translational Cancer Research 5, 349-363 (2016).
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    %Value= sum((double(MaskImageMat)).^2); %%the orig (voldep form)
    Value=  sum((double(MaskImageMat)).^2)/sum(BWInfo.MaskData(:)); %% XF volindep version(dividing by num of vox)
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=IntensityDirect_Feature_RootMeanSquare(ParentInfo, Param)
%%%Doc Starts%%%
%--Reference:
%1. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%2. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value= sqrt(mean((double(MaskImageMat)).^2));
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;


function [Value, ReviewInfo]=IntensityDirect_Feature_Variance(ParentInfo, Param)
%%%Doc Starts%%%
%--Reference:
%1. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%2. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=MaskImageMat(:);

if ~isempty(MaskImageMat)    
    Value= var(double(MaskImageMat));
else
    Value=NaN;
end

ReviewInfo.MaskData=Value;



%Local features---Uniformity
function [Value, ReviewInfo]=NoIntensityDirect_Feature_LocalUniformityMax(ParentInfo, Param)
[Value, ReviewInfo]=ComputeLocalUniformityFeature(ParentInfo, Param, 'Max');

function [Value, ReviewInfo]=NoIntensityDirect_Feature_LocalUniformityMedian(ParentInfo, Param)
[Value, ReviewInfo]=ComputeLocalUniformityFeature(ParentInfo, Param, 'Median');

function [Value, ReviewInfo]=NoIntensityDirect_Feature_LocalUniformityMin(ParentInfo, Param)
[Value, ReviewInfo]=ComputeLocalUniformityFeature(ParentInfo, Param, 'Min');

function [Value, ReviewInfo]=NoIntensityDirect_Feature_LocalUniformityMean(ParentInfo, Param)
[Value, ReviewInfo]=ComputeLocalUniformityFeature(ParentInfo, Param, 'Mean');

function [Value, ReviewInfo]=NoIntensityDirect_Feature_LocalUniformityStd(ParentInfo, Param)
[Value, ReviewInfo]=ComputeLocalUniformityFeature(ParentInfo, Param, 'Std');

function [Value, ReviewInfo]=ComputeLocalEntropyFeature(ParentInfo, Param, Mode)
ImageData=ParentInfo.ROIImageInfo.MaskData;
BWData= ParentInfo.ROIBWInfo.MaskData;

%Method 1
InputRange=[Param.RangeMin, Param.RangeMax];
FinalRange=[0,255];
ImageData=double(ImageData);
ImageData=(ImageData-InputRange(1))*(FinalRange(2)-FinalRange(1))/(InputRange(2)-InputRange(1))+FinalRange(1);
ImageData=uint8(ImageData);

%Buffer exists
BufferFlag=0;
BufferType='LocalEntropy';

if isfield(ParentInfo, 'BufferData') && isequal(BufferType, ParentInfo.BufferType)
    BufferFlag=1;
    LocalEntropyMat=ParentInfo.BufferData;
end

if BufferFlag < 1
    LocalEntropyMat=entropyfilt(ImageData, true(Param.NHood));
end

MaskImageMat=LocalEntropyMat(logical(BWData));
MaskImageMat=MaskImageMat(:);

switch Mode
    case 'Max'
        TValue= max(double(MaskImageMat));
    case 'Median'
        TValue= median(double(MaskImageMat));
    case 'Min'
        TValue= min(double(MaskImageMat));
    case 'Mean'
        TValue= mean(double(MaskImageMat));
    case 'Std'
        TValue= std(double(MaskImageMat));        
end

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.Value=TValue;
ReviewInfo.LocalEntropyMat=LocalEntropyMat;

[LocalEntropyMat, ScaleRatio, ScaleMin]=Scale2CTRange(LocalEntropyMat);
ReviewInfo.MaskData=LocalEntropyMat;

ReviewInfo.ScaleRatio=ScaleRatio;
ReviewInfo.ScaleMin=ScaleMin;

Value.Value=ReviewInfo.Value;
Value.BufferData=ReviewInfo.LocalEntropyMat;
Value.BufferType=BufferType;


function [Value, ReviewInfo]=ComputeLocalUniformityFeature(ParentInfo, Param, Mode)
ImageData=ParentInfo.ROIImageInfo.MaskData;
BWData= ParentInfo.ROIBWInfo.MaskData;

%Method 1
InputRange=[Param.RangeMin, Param.RangeMax];
FinalRange=[0,255];
ImageData=double(ImageData);
ImageData=(ImageData-InputRange(1))*(FinalRange(2)-FinalRange(1))/(InputRange(2)-InputRange(1))+FinalRange(1);
ImageData=uint8(ImageData);

%Buffer exists
BufferFlag=0;
BufferType='LocalUniformity';

if isfield(ParentInfo, 'BufferData') && isequal(BufferType, ParentInfo.BufferType)
    BufferFlag=1;
    LocalEntropyMat=ParentInfo.BufferData;
end

if BufferFlag < 1
    LocalEntropyMat=UniformityFilt(ImageData, true(Param.NHood));
end

MaskImageMat=LocalEntropyMat(logical(BWData));
MaskImageMat=MaskImageMat(:);

switch Mode
    case 'Max'
        TValue= max(double(MaskImageMat));
    case 'Median'
        TValue= median(double(MaskImageMat));
    case 'Min'
        TValue= min(double(MaskImageMat));
    case 'Mean'
        TValue= mean(double(MaskImageMat));
    case 'Std'
        TValue= std(double(MaskImageMat));        
end

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.Value=TValue;
ReviewInfo.LocalUniformityMat=LocalEntropyMat;

[LocalEntropyMat, ScaleRatio, ScaleMin]=Scale2CTRange(LocalEntropyMat);
ReviewInfo.MaskData=LocalEntropyMat;

ReviewInfo.ScaleRatio=ScaleRatio;
ReviewInfo.ScaleMin=ScaleMin;

Value.Value=ReviewInfo.Value;
Value.BufferData=ReviewInfo.LocalUniformityMat;
Value.BufferType=BufferType;


function [Value, ReviewInfo]=ComputeLocalRangeFeature(ParentInfo, Param, Mode)
ImageData=ParentInfo.ROIImageInfo.MaskData;
BWData= ParentInfo.ROIBWInfo.MaskData;

% Bin Location
NHood=true(Param.NHood);

%Buffer exists
BufferFlag=0;
BufferType='LocalRange';

if isfield(ParentInfo, 'BufferData') && isequal(BufferType, ParentInfo.BufferType)
    BufferFlag=1;
    LocalRangeMat=ParentInfo.BufferData;
end

if BufferFlag < 1
    LocalRangeMat=rangefilt(ImageData, NHood);
end

MaskImageMat=LocalRangeMat(logical(BWData));
MaskImageMat=MaskImageMat(:);

switch Mode
    case 'Max'
        TValue= max(double(MaskImageMat));
    case 'Median'
        TValue= median(double(MaskImageMat));
    case 'Min'
        TValue= min(double(MaskImageMat));
    case 'Mean'
        TValue= mean(double(MaskImageMat));
    case 'Std'
        TValue= std(double(MaskImageMat));
end

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.Value=TValue;
ReviewInfo.MaskData=LocalRangeMat;

Value.Value=ReviewInfo.Value;
Value.BufferData=LocalRangeMat;
Value.BufferType=BufferType;

function [Value, ReviewInfo]=ComputeLocalStdFeature(ParentInfo, Param, Mode)
ImageData=ParentInfo.ROIImageInfo.MaskData;
BWData= ParentInfo.ROIBWInfo.MaskData;

% Bin Location
NHood=true(Param.NHood);

%Buffer exists
BufferFlag=0;
BufferType='LocalStd';

if isfield(ParentInfo, 'BufferData') && isequal(BufferType, ParentInfo.BufferType)
    BufferFlag=1;
    LocalStdMat=ParentInfo.BufferData;
end

if BufferFlag < 1
    LocalStdMat=stdfilt(ImageData, NHood);
end

MaskImageMat=LocalStdMat(logical(BWData));
MaskImageMat=MaskImageMat(:);

switch Mode
    case 'Max'
        TValue= max(double(MaskImageMat));
    case 'Median'
        TValue= median(double(MaskImageMat));
    case 'Min'
        TValue= min(double(MaskImageMat));
    case 'Mean'
        TValue= mean(double(MaskImageMat));
    case 'Std'
        TValue= std(double(MaskImageMat));
end

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.Value=TValue;
ReviewInfo.MaskData=LocalStdMat;

Value.Value=ReviewInfo.Value;
Value.BufferData=LocalStdMat;
Value.BufferType=BufferType;








