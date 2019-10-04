function ParentInfo=GradientOrientHistogram_Category(CDataSetInfo, Mode, Param)
%%%Doc Starts%%%
%-Description: 
% Implementation of Histogram of gradient orientations.

%-Parameters:
%nBins: number of bins for histogram

%-Revision:
%V1: 20151012

%-Reference
%1.  T. Pallavi, et al. Texture Descriptors to distinguish Radiation Necrosis 
%     from Recurrent Brain Tumors on multi-parametric MRI. Proc SPIE. 2014; 
%     9035: 90352B. http://www.ncbi.nlm.nih.gov/pmc/articles/PMC4045619/

%-Author:
%Jinzhong Yang, JYang4@mdanderson.org
%%%Doc Ends%%%

%Purpose:       To implement a feature, two files are needed. 
%*CategoryName*_Category.m: to calculate the ParentInfo from DateItemInfo to be used in *CategoryName*_Feature.m.
%*CategoryName*_Feature.m:   to calcuate the features using the same ParentInfo that is output from *CategoryName*_Category.m. 
%Feature names are describled in the declaration of feature caculation function in *CategoryName*_Feature.m.
%Naming Convention of feaure caculation functions:  *CategoryName*_Feature_*FeatureName*
%Architecture: All the feature-relevant files are under \IBEXCodePath\FeatureAlgorithm\Category\*CategoryName*\.
%Files:            *CategoryName*_Category.m, *CategoryName*_Category.INI

%%---------------Input Parameters Passed In By IBEX-------------%
%DataItemInfo:  a structure containing information on the entire image, image-inside-ROIBoundingBox and binary-mask-inside-ROIBoundingBox
%Param:            The entry used for IBEX to accept the parameters from GUI. Use .INI to define the default parameters
%Mode:             Two Statuses.
%'Child':  The output ParentInfo is the derived data that is used for feature caculation in  *CategoryName*_Feature.m
%'Review': The output ParentInfo is the
%ReviewInfo to be reviewed when press "Test" button.
%%--------------Output Parameters------------%
%ParentInfo:    %If Mode == 'Child',  it is the derived data that is used for feature caculation in  *CategoryName*_Feature.m
%If Mode == 'Review', it is the ReviewInfo to be reviewed when press "Test" button.                                               

%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%
%-----------------------------DO_NOT_CHANGE_STARTS--------------------------%
%Empty
%-----------------------------DO_NOT_CHANGE_ENDS------------------------------%
%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%



%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%
%%-----------Implement your code starting from here---------%
%****The skeleton category adds 0 to image data****%

ImageData=CDataSetInfo.ROIImageInfo.MaskData;
MaskData=CDataSetInfo.ROIBWInfo.MaskData;

[FData, BinLoc, OrientImg]=HoG2DIBEX(ImageData, MaskData, Param.nBins);

CDataSetInfo.ROIImageInfo.MaskDataOri=OrientImg;
CDataSetInfo.ROIImageInfo.MaskData=[BinLoc', FData'];
CDataSetInfo.ROIImageInfo.Description='HoGHistogram (Probability VS Value)';

switch Mode
    case 'Review'
        ReviewInfo=CDataSetInfo.ROIImageInfo;
        ParentInfo=ReviewInfo;
        
    case 'Child'
        ParentInfo=CDataSetInfo;
end








