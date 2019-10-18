function ParentInfo=IntensityHistogram_Category(CDataSetInfo, Mode, Param)
%%%Doc Starts%%%
%-Description: 
%1.   This method is to compute histogram from image inside the binary mask.
%2.   Histogram is passed into IntensityHistogram_Feature.m to compute the related features.

%-Parameters:
%1. NBins:          The number of bins.
%2. RangeMin:    Lower bound of bin location.
%3. RangeMax:   Upper bound of bin location.
%4. RangeFix:     1==The specified RangeMin and RangeMax specified are used. 0==Ignore the specified RangeMin and RangeMax, and 
%                    RangeMin and RangeMax are dynamically determined by min and max of the current image.
%5. OnlyUseMaxSlice:  1: Binary mask only contains the binary slice with the maximum area. 0: Use the binary mask as it is.

%-Revision:
%2014-02-06: The method is implemented.

%-Authors:
%Joy Zhang, lifzhang@mdanderson.org
%%%Doc Ends%%%


%Code
%Histogram
CDataSetInfo= ComputeHistogram(CDataSetInfo, Param, Mode);

switch Mode
    case 'Review'
        ReviewInfo=CDataSetInfo.ROIImageInfo;
        %ReviewInfo.CallBackFunc='Test_ReviewFunc';
        ParentInfo=ReviewInfo;
        
    case 'Child'
        ParentInfo=CDataSetInfo;
end








