function FeatureInfo=IntensityHistogram_Feature(ParentInfo, FeatureInfo, Mode)

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

%Global features
function [Value, ReviewInfo]=IntensityHistogram_Feature_Skewness(ParentInfo, Param)
%%%Doc Starts%%%
%Measure the asymmetry of the occurence probability values in the histogram.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeHistFeature(ParentInfo, Param, 'Skewness');

function [Value, ReviewInfo]=IntensityHistogram_Feature_Kurtosis(ParentInfo, Param)
%%%Doc Starts%%%
%Measure the peakedness of the occurence probability values in the histogram.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeHistFeature(ParentInfo, Param, 'Kurtosis');

function [Value, ReviewInfo]=IntensityHistogram_Feature_Range(ParentInfo, Param)
%%%Doc Starts%%%
%Measure  the range(MaxValue-MinValue) of the occurence probability values in the histogram.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeHistFeature(ParentInfo, Param, 'Range');

function [Value, ReviewInfo]=IntensityHistogram_Feature_MeanAbsoluteDeviation(ParentInfo, Param)
%%%Doc Starts%%%
%The mean absolute deviation of the occurence probability values in the histogram.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeHistFeature(ParentInfo, Param, 'MeanAbsoluteDeviation');

function [Value, ReviewInfo]=IntensityHistogram_Feature_MedianAbsoluteDeviation(ParentInfo, Param)
%%%Doc Starts%%%
%The median absolute deviation of the occurence probability values in the histogram.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeHistFeature(ParentInfo, Param, 'MedianAbsoluteDeviation');

function [Value, ReviewInfo]=IntensityHistogram_Feature_InterQuartileRange(ParentInfo, Param)
%%%Doc Starts%%%
%The interquartile range of the occurence probability values in the histogram.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeHistFeature(ParentInfo, Param, 'InterQuartileRange');

function [Value, ReviewInfo]=IntensityHistogram_Feature_Percentile(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Percentiles of the occurence probability values in the histogram.

%-Parameters:
%1.  Percentile: Percent values.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeHistFeature(ParentInfo, Param, 'Percentile');

function [Value, ReviewInfo]=IntensityHistogram_Feature_PercentileArea(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Percentiles of values in the accumulative histogram.

%-Parameters:
%1.  Percentile: Percent values.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeHistFeature(ParentInfo, Param, 'PercentileArea');

function [Value, ReviewInfo]=IntensityHistogram_Feature_Quantile(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Quantiles of the occurence probability values in the histogram.

%-Parameters:
%1.  Quantile: Cumulative probability values.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeHistFeature(ParentInfo, Param, 'Quantile');



function [Value, ReviewInfo]=ComputeHistFeature(ParentInfo, Param, Mode)
HistData=ParentInfo.ROIImageInfo.MaskData;

ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskDataOri(logical(BWInfo.MaskData));
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
    case  'PercentileArea'    
        Value = PrctileArea(HistData, Param.Percentile');        
        ReviewInfo.MaskData=[Param.Percentile', Value];
        ReviewInfo.Description='Histogram Area Percentile';        
        
        Value=[Param.Percentile', Value];
        ReviewInfo.Value=[];        
    case 'Quantile'
        Value = quantile(MaskImageMat, Param.Quantile');        
        ReviewInfo.MaskData=[Param.Quantile', Value];
        ReviewInfo.Description='Intensity Quantile';   
        
        Value=[Param.Quantile', Value];
        ReviewInfo.Value=[];
end       


function Value = PrctileArea(HistData, Percentile)

HistBin=HistData(:, 1);
HistCount=HistData(:, 2);

HistCountCum=cumsum(HistCount, 1);
HistCountCum=HistCountCum*100/HistCountCum(end);

[HistCountCumUnique, TIndex]=unique(HistCountCum, 'first');
HistBinUnique=HistBin(TIndex);

try
    Value=interp1(HistCountCumUnique, HistBinUnique, Percentile);
catch
    Value=repmat(NaN, length(Percentile), 1);
end










