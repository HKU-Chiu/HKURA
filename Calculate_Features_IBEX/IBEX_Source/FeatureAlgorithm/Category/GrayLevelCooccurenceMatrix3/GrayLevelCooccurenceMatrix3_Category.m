function ParentInfo=GrayLevelCooccurenceMatrix3_Category(CDataSetInfo, Mode, Param)
%%%Doc Starts%%%
%-Description: 
%1.  This method is to compute gray-level co-ccorrence matrix(GLCM) from image inside
%     the binary mask in 3D in 13 unique directions. GLCM summing occurence from all directions is computed also.
%    All the feature calculation is done the same as GrayLevelCooccurenceMatrix25 does.
%2.  GLCM is passed into GrayLevelCooccurenceMatrix3_Feature.m to compute the related features.

%-Parameters:
%1.  %Direction: Define the angle of intensity pair (phi/theta).
%   0: 0/90, 1: 90/90, 2: 0/0, 3: 45/90, 4: 135/90, 5: 90/45, 6: 90/135, 
%   7: 0/45, 8: 0/135, 9: 45/54.7, 10: 135/54.7, 11: 45/125.3, 12: 135/125.3
%2. GrayLimits: Two-element vector that specifis how the grayscale values are linearly scaled into graylevels.
%3. NumLevels: Integer specifying hte number of gray-levels to use when scaling the grayscale values.
%4. Offset: The distance between the intensity pair
%5. Symmetric: 0==The pixel order in the pair matters. 1==The pixel order in the pair doesn't matter.


%-References:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%     IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. Haralick, R.M., and L.G. Shapiro. Computer and Robot Vision: Vol. 1, Addison-Wesley, 1992, p. 459.
%3. MATLAB built-in functions: graycomatrix, graycoprops.

%-Revision:
%2014-03-05: The method is implemented.

%-Authors:
%Joy Zhang, lifzhang@mdanderson.org
%David Fried, DVFried@mdanderson.org
%Xenia Fave, XJFave@mdanderson.org
%Dennis Mackin, DSMackin@mdanderson.org
%Slade Klawikowski, slade@uwalumni.com
%%%Doc Ends%%%

%Code
GLCMStruct=ComputeGLCM(CDataSetInfo, Param);

switch Mode
    case 'Review'
        ReviewInfo=CDataSetInfo.ROIImageInfo;
        ReviewInfo.GLCMStruct3=GLCMStruct;        
        ParentInfo=ReviewInfo;
        
    case 'Child'
        CDataSetInfo.ROIImageInfo.GLCMStruct3=GLCMStruct;
        ParentInfo=CDataSetInfo;
end

function GLCMStruct3=ComputeGLCM(CDataSetInfo, Param)

if ~(isfield(Param, 'Direction') && isfield(Param, 'GrayLimits') && isfield(Param, 'NumLevels') && isfield(Param, 'Offset') && isfield(Param, 'Symmetric'))
    GLCMStruct=[];
end

ROIImageData=CDataSetInfo.ROIImageInfo.MaskData;
ROIBWData=CDataSetInfo.ROIBWInfo.MaskData;


for i=1:length(Param.Direction)
    
    OffsetMat=Param.Offset';
    switch Param.Direction(i)
        case 0 %'0/90'        
            Offset=[1*OffsetMat, 0*OffsetMat, 0*OffsetMat];
        case 1 %'90/90'        
            Offset=[0*OffsetMat, 1*OffsetMat, 0*OffsetMat];
        case 2 % '0/0'     
            Offset=[0*OffsetMat, 0*OffsetMat, 1*OffsetMat];
        case 3 %'45/90'        
            Offset=[1*OffsetMat, 1*OffsetMat, 0*OffsetMat];
        case 4 % '135/90'        
            Offset=[-1*OffsetMat, 1*OffsetMat, 0*OffsetMat];
        case 5 %'90/45'        
            Offset=[0*OffsetMat, 1*OffsetMat, 1*OffsetMat];
        case 6 %'90/135'        
            Offset=[0*OffsetMat, 1*OffsetMat, -1*OffsetMat];
        case 7 %'0/45'        
            Offset=[1*OffsetMat, 0*OffsetMat, 1*OffsetMat];
        case 8 %'0/135'        
            Offset=[1*OffsetMat, 0*OffsetMat, -1*OffsetMat];
        case 9 %'45/54.7'        
            Offset=[1*OffsetMat, 1*OffsetMat, 1*OffsetMat];
        case 10 %'135/54.7'        
            Offset=[-1*OffsetMat, 1*OffsetMat, 1*OffsetMat];
        case 11 %'45/125.3'
            Offset=[1*OffsetMat, 1*OffsetMat, -1*OffsetMat];
        case 12 %'135/125.3'
            Offset=[-1*OffsetMat, 1*OffsetMat, -1*OffsetMat];        
    end
        
    CurrentData=ROIImageData;
    CurrentBWData=ROIBWData;
    
    [GLCMs, SI] = GrayCoMatrix3_Mask(double(CurrentData), CurrentBWData, ...
        'GrayLimits', Param.GrayLimits, 'Offset', Offset, 'NumLevels', Param.NumLevels, 'Symmetric', logical(Param.Symmetric));
        
    GLCMStruct3(i).Direction=Param.Direction(i);
    GLCMStruct3(i).Offset=OffsetMat;
    GLCMStruct3(i).GLCM=GLCMs;
    GLCMStruct3(i).ScaleImage=SI;
end

%Sum all directions
SumGLCMStruct=GLCMStruct3(1);
SumGLCMStruct.Direction=-333;

for i=2:length(GLCMStruct3)
    SumGLCMStruct.GLCM=SumGLCMStruct.GLCM+GLCMStruct3(i).GLCM;
end

GLCMStruct3=[SumGLCMStruct, GLCMStruct3];








