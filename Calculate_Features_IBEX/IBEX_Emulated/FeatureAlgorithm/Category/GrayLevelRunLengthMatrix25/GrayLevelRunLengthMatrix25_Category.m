function ParentInfo=GrayLevelRunLengthMatrix25_Category(CDataSetInfo, Mode, Param)
%%%Doc Starts%%%
%-Description: 
%1.  This method is to compute gray-level run length matrix(GLRLM) from image inside
%    the binary mask in 2.5D in 0 and 90 degree. GLRLM summing occurence from all
%    directions is computed also.  2.5D means:  First, GLRLM is computed in 2D slice by slice. 
%    Then, sum the occurence of run length from all 2D image slices.
%2. GLRLM is passed into GrayLevelRunLengthMatrix25_Feature.m to compute the related features.

%-Parameters:
%1.  Direction:   Define the run length direction. 0 and 90 degree are supported.
%2.  GrayLimits:  Two-element vector that specifis how the grayscale values are linearly scaled into graylevels.
%3.  NumLevels:   Integer specifying hte number of gray-levels to use when scaling the grayscale values.


%-References:
%1.  M. M. Galloway. Texture analysis using gray level run lengths. 
%    Computer Graphics and Image Processing, 4:172–179, 1975.
%2.  Xiaoou Tang. Texture information in run-length matrices.
%    IEEE Transactions on Image Processing ,Volume 7 Issue 11, Page 1602-1609 

%-Revision:
%2014-05-22: The method is implemented.

%-Authors:
%Joy Zhang, lifzhang@mdanderson.org
%%%Doc Ends%%%

%Code
GLRLMStruct=ComputeGLRLM(CDataSetInfo, Param);

switch Mode
    case 'Review'
        ReviewInfo=CDataSetInfo.ROIImageInfo;
        ReviewInfo.GLRLMStruct25=GLRLMStruct;        
        ParentInfo=ReviewInfo;
        
    case 'Child'
        CDataSetInfo.ROIImageInfo.GLRLMStruct25=GLRLMStruct;
        ParentInfo=CDataSetInfo;
end

function GLRLMStruct25=ComputeGLRLM(CDataSetInfo, Param)

if ~(isfield(Param, 'Direction') && isfield(Param, 'GrayLimits') && isfield(Param, 'NumLevels') && isfield(Param, 'Offset') && isfield(Param, 'Symmetric'))
    GLCMStruct=[];
end

ROIImageData=CDataSetInfo.ROIImageInfo.MaskData;
ROIBWData=CDataSetInfo.ROIBWInfo.MaskData;


Count=1;
for i=1:length(Param.Direction)
    
    %Only support 0 and 90 angles
    if (Param.Direction(i) ~= 0) && (Param.Direction(i) ~= 90)
        continue;
    end
    
    CurrentData=ROIImageData;
    CurrentBWData=ROIBWData;
    
    [GLRLM, SI] = GrayRLMatrix25_Mask(double(CurrentData), CurrentBWData, ...
        'GrayLimits', Param.GrayLimits, 'Offset', Param.Direction(i), 'NumLevels', Param.NumLevels);
        
    GLRLMStruct25(Count).Direction=Param.Direction(i);    
    GLRLMStruct25(Count).GLRLM=GLRLM;
    GLRLMStruct25(Count).ScaleImage=SI;
    
    Count=Count+1;
end

%Sum all directions
SumGLCMStruct=GLRLMStruct25(1);
SumGLCMStruct.Direction=-333;

for i=2:length(GLRLMStruct25)
    SumGLCMStruct.GLRLM=SumGLCMStruct.GLRLM+GLRLMStruct25(i).GLRLM;
end
SumGLCMStruct.GLRLM=SumGLCMStruct.GLRLM./length(GLRLMStruct25);

GLRLMStruct25=[SumGLCMStruct, GLRLMStruct25];









