function ParentInfo=GrayLevelCooccurenceMatrix25_Category(CDataSetInfo, Mode, Param)
%%%Doc Starts%%%
%-Description: 
%1.  This method is to compute gray-level co-ccorrence matrix(GLCM) from image inside
%    the binary mask in 2.5D in 4 directions. GLCM summing occurence from all
%    directions is computed also.  2.5D means:  First the occurence of individual
%    intensity pair is computed in 2D slice by slice. Then, sum the occurence of individual intensity pair from all 2D image slices.
%    All the feature calculation is done the same as GrayLevelCooccurenceMatrix3 does.
%2.  GLCM is passed into GrayLevelCooccurenceMatrix25_Feature.m to compute the related features.

%-Parameters:
%1.  Direction: Define the angle of intensity pair, 4 directions (45, 90, 180, 270).
%2.  AdaptLimitLevel: If AdaptLimitLevel=1, ignore parameter GrayLimits and NumLevels. GrayLimits set to the minimum(MinValue) and
%     maximum(MaxValue) of the masked image. NumLevels is length(MinValue:MaxValue).
%3.   GrayLimits: Two-element vector that specifis how the grayscale values are linearly scaled into graylevels.
%4.   NumLevels: Integer specifying hte number of gray-levels to use when scaling the grayscale values.
%5.   Offset: The distance between the intensity pair
%6.   Symmetric: 0==The pixel order in the pair matters. 1==The pixel order in the pair doesn't matter.


%-References:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%     IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. Haralick, R.M., and L.G. Shapiro. Computer and Robot Vision: Vol. 1, Addison-Wesley, 1992, p. 459.
%3. MATLAB built-in functions: graycomatrix, graycoprops.

%-Revision:
%2014-03-06: The method is implemented.
%2014-07-26: AdaptLimitLevel is added.


%-Authors:
%Joy Zhang, lifzhang@mdanderson.org
%David Fried, DVFried@mdanderson.org
%Xenia Fave, XJFave@mdanderson.org
%Dennis Mackin, DSMackin@mdanderson.org
%%%Doc Ends%%%

%Code
GLCMStruct=ComputeGLCM(CDataSetInfo, Param);

switch Mode
    case 'Review'
        ReviewInfo=CDataSetInfo.ROIImageInfo;
        ReviewInfo.GLCMStruct25=GLCMStruct;        
        ParentInfo=ReviewInfo;
        
    case 'Child'
        CDataSetInfo.ROIImageInfo.GLCMStruct25=GLCMStruct;
        ParentInfo=CDataSetInfo;
end

function GLCMStruct25=ComputeGLCM(CDataSetInfo, Param)

if ~(isfield(Param, 'Direction') && isfield(Param, 'GrayLimits') && isfield(Param, 'NumLevels') && isfield(Param, 'Offset') && isfield(Param, 'Symmetric'))
    GLCMStruct=[];
end

ROIImageData=CDataSetInfo.ROIImageInfo.MaskData;
ROIBWData=CDataSetInfo.ROIBWInfo.MaskData;


for i=1:length(Param.Direction)
    
    OffsetMat=Param.Offset';
    switch Param.Direction(i)
        case 0
            Offset=[0*OffsetMat, 1*OffsetMat];
         case 180
            Offset=[0*OffsetMat, -1*OffsetMat];
        case 45
            Offset=[-1*OffsetMat, 1*OffsetMat];
        case 225
            Offset=[1*OffsetMat, -1*OffsetMat];    
        case 90
            Offset=[-1*OffsetMat, 0*OffsetMat];
        case 270
            Offset=[1*OffsetMat, 0*OffsetMat];            
        case 135
            Offset=[-1*OffsetMat, -1*OffsetMat];
        case 315
            Offset=[1*OffsetMat, 1*OffsetMat];            
    end
        
    CurrentData=ROIImageData;
    CurrentBWData=ROIBWData;
    
    %Adaptive GrayLimits and NumberLevel
    if Param.AdaptLimitLevel > 0
        MaskData=CurrentData(logical(CurrentBWData));
        
        if ~isempty(MaskData)            
            LimitLow=min(nonzeros(MaskData(:)));
            LimitHigh=max(MaskData(:));
            
            if ~(LimitHigh > LimitLow)
                LimitHigh=LimitHigh+1;
            end
        else
            LimitLow=0;
            LimitHigh=1;
        end
        
        Param.GrayLimits = [LimitLow,  LimitHigh];
        if(isfield(CDataSetInfo.ROIImageInfo,'Round'))
            Param.NumLevels = length(Param.GrayLimits(1): CDataSetInfo.ROIImageInfo.Round:Param.GrayLimits(2));
        else
            Param.NumLevels = length(Param.GrayLimits(1):Param.GrayLimits(2));
        end
    end
    
    [GLCMs, SI] = GrayCoMatrix25_Mask(double(CurrentData), CurrentBWData, ...
        'GrayLimits', Param.GrayLimits, 'Offset', Offset, 'NumLevels', Param.NumLevels, 'Symmetric', logical(Param.Symmetric));
        
    GLCMStruct25(i).Direction=Param.Direction(i);
    GLCMStruct25(i).Offset=OffsetMat;
    GLCMStruct25(i).GLCM=GLCMs;
    GLCMStruct25(i).ScaleImage=SI;
end

%Sum all directions
SumGLCMStruct=GLCMStruct25(1);
SumGLCMStruct.Direction=-333;

for i=2:length(GLCMStruct25)
    SumGLCMStruct.GLCM=SumGLCMStruct.GLCM+GLCMStruct25(i).GLCM;
end

GLCMStruct25=[SumGLCMStruct, GLCMStruct25];








