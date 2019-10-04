function ParentInfo=IntensityDirect_Category(CDataSetInfo, Mode, Param)
%%%Doc Starts%%%
%-Description: 
%1. This method is to preprocess the binary mask for the features derived directly from the image intensity.
%    The binary mask can be modified through the intensity thresholding, the binary erosion, 
%    and/or using only the binary slice with the maximum area.
%2.  Image and binary mask are passed into IntensityDirect_Feature.m to compute the related features.

%-Parameters:
%1. ThresholdLow:   Lower threshold of image intensity.
%2. ThresholdHigh:  Upper threshold of image intensity.
%3. ErosionDist:       Distance in mm for binary mask erosion.
%4. OnlyUseMaxSlice:  1==Binary mask only contains the binary slice with the maximum area. 0==Use the binary mask as it is.


%-Revision:
%2014-01-01: The method is implemented.

%-Authors:
%Joy Zhang, lifzhang@mdanderson.org
%%%Doc Ends%%%


%Code
%Threshod
if isfield(Param, 'Threshold') || isfield(Param, 'ThresholdLow')
   CDataSetInfo= ThresholdDataSet(CDataSetInfo, Param, Mode);      
end

%---Erosion Shrink
if ~isinteger(CDataSetInfo.ROIImageInfo.MaskData)
    CDataSetInfo.ROIImageInfo=ScaleDataSet2Int(CDataSetInfo.ROIImageInfo);
end

CDataSetInfo=ErodeDataSet(CDataSetInfo, Param, Mode);

if isfield(CDataSetInfo.ROIImageInfo, 'RescaleMinV')
    CDataSetInfo.ROIImageInfo=ScaleDataSet2Ori(CDataSetInfo.ROIImageInfo);
end

%Max Area Slice Only
if isfield(Param, 'OnlyUseMaxSlice') && Param.OnlyUseMaxSlice > 0    
    
    CDataSetInfo=ThresholdMaxSlice(CDataSetInfo, Param, Mode);   
end

switch Mode
    case 'Review'
        ReviewInfo=CDataSetInfo.ROIImageInfo;
        ParentInfo=ReviewInfo;
        
    case 'Child'
        ParentInfo=CDataSetInfo;
end

function CDataSetInfo=ThresholdMaxSlice(CDataSetInfo, Param, Mode)
BWInfo= CDataSetInfo.ROIBWInfo;

AreaSlice=sum(double(BWInfo.MaskData), 1);
AreaSlice=sum(AreaSlice, 2);
AreaSlice=squeeze(AreaSlice);

[MaxV, MaxIndex]=max(AreaSlice);
MaxIndex=MaxIndex(1);

MaskData=zeros(size(CDataSetInfo.ROIBWInfo.MaskData), 'uint8');
MaskData(:, :, MaxIndex)=CDataSetInfo.ROIBWInfo.MaskData(:, :, MaxIndex);

CDataSetInfo.ROIBWInfo.MaskData=MaskData;

if isequal(Mode, 'Review')
    TempImageData=CDataSetInfo.ROIImageInfo.MaskData;
    TempImageData(~MaskData)=0;
    
    CDataSetInfo.ROIImageInfo.MaskData=TempImageData;
end
