function [Value, ReviewInfo]=IntensityDirect_Feature_GlobalIntensityUniformity(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%The intensity uniformity among all the voxels.

%-Parameters:
%1. NBins:          The number of bins.
%2. RangeMin:    Lower bound of bin location.
%3. RangeMax:   Upper bound of bin location.
%4. RangeFix:     1==The specified RangeMin and RangeMax specified are used. 0==Ignore the specified RangeMin and RangeMax, and 
%                    RangeMin and RangeMax are dynamically determined by min and max of the current image.
%%%Doc Ends%%%
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;

MaskImageMat=ImageInfo.MaskData(logical(BWInfo.MaskData));
MaskImageMat=double(MaskImageMat(:));

if isempty(MaskImageMat)    
    Value=NaN;
    ReviewInfo.Value=NaN;
    ReviewInfo.Description='Histogram';
    return;
end

MaxV=max(MaskImageMat);
MinV=min(MaskImageMat);

%Dynamic Range
if isfield(Param, 'RangeFix') && Param.RangeFix < 1
    Param.RangeMin=MinV;
    Param.RangeMax=MaxV;    
end

InterVal=(Param.RangeMax-Param.RangeMin)/Param.NBins;
BinLoc=double(Param.RangeMin:InterVal:Param.RangeMax);

[p, BinCenter] = hist(MaskImageMat, BinLoc);

%Remove the bondary bin to remove the extrapolation from Matlab hist
if BinCenter(1) > MinV
    BinCenter(1)=[];
    p(1)=[];
end

if BinCenter(end) < MaxV
    BinCenter(end)=[];
    p(end)=[];
end

%Method 1
% InputRange=[Param.RangeMin, Param.RangeMax];
% 
% FinalRange=[0,255];
% MaskImageMat=(MaskImageMat-InputRange(1))*(FinalRange(2)-FinalRange(1))/(InputRange(2)-InputRange(1))+FinalRange(1);
% MaskImageMat=uint8(MaskImageMat);
% 
% [p, BinCenter] = imhist(MaskImageMat, Param.NBins);
% 
% BinCenter=(BinCenter-FinalRange(1))*(InputRange(2)-InputRange(1))/(FinalRange(2)-FinalRange(1))+InputRange(1);
% 
% ReviewInfo.MaskData=[BinCenter, p];

% normalize p so that sum(p) is one.
p = p ./ numel(MaskImageMat);

ReviewInfo.MaskData=[BinCenter', p'];

% remove zero entries in p 
p(p==0) = [];

Value= sum(p.^2);

ReviewInfo.Value=Value;
ReviewInfo.Description='Histogram';
