function ParentInfo=Shape_Category(CDataSetInfo, Mode, Param)
%%%Doc Starts%%%
%-Description: 
%1.  This method is just a layer on Shape_Feature.m.
%2.  Image and binary mask are passed into Shape_Feature.m to compute the related features.

%-Parameters:
%No

%-Revision:
%2014-01-01: The method is implemented.
%2014-07-28: Feature SurfaceArea, SurfaceAreaDensity, MeanBreath, and VoxelSize are added.

%-Authors:
%Joy Zhang, lifzhang@mdanderson.org
%%%Doc Ends%%%

%Code
switch Mode
    case 'Review'
        ReviewInfo=CDataSetInfo.ROIImageInfo;
        ReviewInfo.MaskData=100;
        ParentInfo=ReviewInfo;
        
    case 'Child'
        ParentInfo=CDataSetInfo;
end