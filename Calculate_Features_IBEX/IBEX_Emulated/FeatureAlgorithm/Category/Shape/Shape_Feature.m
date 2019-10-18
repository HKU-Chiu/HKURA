function FeatureInfo=Shape_Feature(ParentInfo, FeatureInfo, Mode)

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
        FeatureInfo(i).FeatureValue=FeatureValue;
    end         
end


function [FeatureValue, FeatureReviewInfo]=GetFeatureValue(ParentInfo, CurrentFeatureInfo,  FeaturePrefix)
FeatureName=CurrentFeatureInfo.Name;

FuncName=[FeaturePrefix, '_', FeatureName];
FuncHandle=str2func(FuncName);

[FeatureValue, FeatureReviewInfo]=FuncHandle(ParentInfo, CurrentFeatureInfo.Value);

function [Value, ReviewInfo]=Shape_Feature_NumberOfVoxel(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. The number of voxels treating the edge voxels differently. 

%-Parameters:
%1. EdgeVoxelFraction: edge voxel is considered as EdgeVoxelFraction*Voxel.
%%%Doc Ends%%%
if isfield(Param, 'EdgeVoxelFraction')
    EdgeVoxelFraction=Param.EdgeVoxelFraction;
else
    EdgeVoxelFraction=0.5;
end

BWMatInfo=ParentInfo.ROIBWInfo;

TempIndex=find(BWMatInfo.MaskData);

NumVox=MKGetNumVoxBWMask(BWMatInfo.MaskData, EdgeVoxelFraction);

if ~isempty(TempIndex)
    Value=NumVox;
else
    Value=0;
end

ClassName=class(ParentInfo.ROIImageInfo.MaskData);
fhandle=str2func(ClassName);
MaskData=fhandle(double(BWMatInfo.MaskData)*double(max(ParentInfo.ROIImageInfo.MaskData(:))));

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.MaskData=MaskData;
ReviewInfo.Value=Value;

function [Value, ReviewInfo]=Shape_Feature_Volume(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. The physical volume treating the edge voxels differently. 

%-Parameters:
%1. EdgeVoxelFraction: edge voxel is considered as EdgeVoxelFraction*Voxel.
%%%Doc Ends%%%

if isfield(Param, 'EdgeVoxelFraction')
    EdgeVoxelFraction=Param.EdgeVoxelFraction;
else
    EdgeVoxelFraction=0.5;
end

BWMatInfo=ParentInfo.ROIBWInfo;

TempIndex=find(BWMatInfo.MaskData);

NumVox=MKGetNumVoxBWMask(BWMatInfo.MaskData, EdgeVoxelFraction);

if ~isempty(TempIndex)
    Value=NumVox*BWMatInfo.XPixDim*BWMatInfo.YPixDim*BWMatInfo.ZPixDim;
else
    Value=0;
end

ClassName=class(ParentInfo.ROIImageInfo.MaskData);
fhandle=str2func(ClassName);
MaskData=fhandle(double(BWMatInfo.MaskData)*double(max(ParentInfo.ROIImageInfo.MaskData(:))));

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.MaskData=MaskData;
ReviewInfo.Value=Value;


function [Value, ReviewInfo]=Shape_Feature_Mass(ParentInfo, Param)
%%%Doc Starts%%%
%Mass caculation is only meaningful to CT images.
%%%Doc Ends%%%

DensityCTNum=[0, 294, 898, 1000, 1056, 1198, 1644, 1872, 2470];
DensityValue=[0, 0.291, 0.927, 1, 1.047, 1.1, 1.337, 1.427, 1.75];

%Density Lookup Table
[DensityLookupCTNum, DensityLookupValue]=ComputeDensityLookup(DensityCTNum, DensityValue); 

BWMat=ParentInfo.ROIBWInfo.MaskData;
ImageMat=ParentInfo.ROIImageInfo.MaskData;

ROICT=ImageMat(logical(BWMat));

ROICT=double(ROICT);

TTTIndex=find(ROICT > length(DensityLookupValue));
ROICT(TTTIndex)=DensityCTNum(end);

TTTIndex=find(ROICT > 0);
ROICTNum=ROICT(TTTIndex);

try
    ROIDensity=DensityLookupValue(ROICTNum);
    ROICT(TTTIndex)=ROIDensity;
    
    Value=sum(ROICT(:))*ParentInfo.ROIBWInfo.XPixDim*ParentInfo.ROIBWInfo.YPixDim*ParentInfo.ROIBWInfo.ZPixDim;
catch
    Value=NaN;
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=Shape_Feature_Roundness(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. Measure how much the binary mask is close to circle in 2D. 
%2. Refer to MATLAB "regionprops(Mask, 'Eccentricity')" for details

%-Formula:
%1. First, compute roundness value  in 2D slice-by-slice. Roundness=1-regionprops(2DMask, 'Eccentricity')
%2. Then, compute the mean of roundness value among the slices.
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

Value=[];

for i=1:size(BWMat, 3)
    CurrentSlice=BWMat(:, :, i);
    TempIndex=find(CurrentSlice);
    
    if ~isempty(TempIndex)
        Stas=regionprops(CurrentSlice, 'Eccentricity');
        CurrentValue=1-Stas.Eccentricity;
        
        Value=[Value; CurrentValue];
    end    
end

if ~isempty(Value)
    Value=mean(Value);    
end

ReviewInfo.MaskData=Value;


function [Value, ReviewInfo]=Shape_Feature_Orientation(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. Measure the angle between the x-axis and the major axis of the ellipse in 2D. 
%2. Refer to MATLAB "regionprops(Mask, 'Orientation')" for details

%-Formula:
%1. First, compute orientation value  in 2D slice-by-slice. Orientation=regionprops(2DMask, 'Orientation')
%2. Then, compute the mean of orientation value among the slices.
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

Value=[];

for i=1:size(BWMat, 3)
    CurrentSlice=BWMat(:, :, i);
    TempIndex=find(CurrentSlice);
    
    if ~isempty(TempIndex)
        Stas=regionprops(CurrentSlice, 'Orientation');
        CurrentValue=Stas.Orientation;
        
        Value=[Value; CurrentValue];
    end    
end

if ~isempty(Value)
    Value=mean(Value);    
end

ReviewInfo.MaskData=Value;


function [Value, ReviewInfo]=Shape_Feature_Convex(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%1. Measure the proportion of the pixels in the convex hull that are also in the region. 
%2. Refer to MATLAB "regionprops(Mask, 'Solidity')" for details

%-Formula:
%1. First, compute convex value  in 2D slice-by-slice. Convex=regionprops(2DMask, 'Solidity')
%2. Then, compute the mean of convex value among the slices.
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

Value=[];

for i=1:size(BWMat, 3)
    CurrentSlice=BWMat(:, :, i);
    TempIndex=find(CurrentSlice);
    
    if ~isempty(TempIndex)
        Stas=regionprops(CurrentSlice, 'Solidity');
        CurrentValue=Stas.Solidity;
        
        Value=[Value; CurrentValue];
    end    
end

if ~isempty(Value)
    Value=mean(Value);    
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=Shape_Feature_NumberOfObjects(ParentInfo, Param)
BWMat=ParentInfo.ROIBWInfo.MaskData;

CC = bwconncomp(BWMat, 26);

Value=CC.NumObjects;

ReviewInfo.MaskData=CC.NumObjects;


function [Value, ReviewInfo]=Shape_Feature_ConvexHullVolume3D(ParentInfo, Param)
%%%Doc Starts%%%
%3D volume of the convex hull that is the convex envelope of binary mask. 
%%%Doc Ends%%%

BWMat=ParentInfo.ROIBWInfo.MaskData;

TempIndex=find(BWMat);
[RowIndex, ColIndex, PageIndex]=ind2sub(size(BWMat), TempIndex);

try 
    [ConvexHullRep, ConvexVolume] = convhull(ColIndex, RowIndex, PageIndex);
catch
    ConvexVolume=0; ConvexHullRep = [0,0,0];
end

Value=ConvexVolume*ParentInfo.ROIBWInfo.XPixDim*ParentInfo.ROIBWInfo.YPixDim*ParentInfo.ROIBWInfo.ZPixDim;

ReviewInfo.Value=Value;

ReviewInfo.MeshInfo(1).Description ='Convexl Hull';
ReviewInfo.MeshInfo(1).TriRep=ConvexHullRep;

XCor=(ColIndex-1)*ParentInfo.ROIBWInfo.XPixDim+ParentInfo.ROIBWInfo.XStart;
YCor=(ParentInfo.ROIBWInfo.YDim-RowIndex)*ParentInfo.ROIBWInfo.YPixDim+ParentInfo.ROIBWInfo.YStart;
ZCor=(PageIndex-1)*ParentInfo.ROIBWInfo.ZPixDim+ParentInfo.ROIBWInfo.ZStart;

ReviewInfo.MeshInfo(1).XCor=XCor;
ReviewInfo.MeshInfo(1).YCor=YCor;
ReviewInfo.MeshInfo(1).ZCor=ZCor;


function [Value, ReviewInfo]=Shape_Feature_ConvexHullVolume(ParentInfo, Param)
%%%Doc Starts%%%
%The mean volume of the 2D convex hulls that are the convex envelopes of each slice's binary mask. 
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

ConvexBWMat=zeros(size(BWMat), class(BWMat));

for i=1:size(BWMat, 3)
    CurrentSlice=BWMat(:, :, i);
    CurrentSlice=bwconvhull(CurrentSlice);    
    ConvexBWMat(:, :, i)=CurrentSlice;
end

TempIndex=find(ConvexBWMat);

NumVox=MKGetNumVoxBWMask(ConvexBWMat);

if ~isempty(TempIndex)
    Value=NumVox*ParentInfo.ROIBWInfo.XPixDim*ParentInfo.ROIBWInfo.YPixDim*ParentInfo.ROIBWInfo.ZPixDim;
else
    Value=0;
end

ClassName=class(ParentInfo.ROIImageInfo.MaskData);
fhandle=str2func(ClassName);
MaskData=fhandle(double(ConvexBWMat)*double(max(ParentInfo.ROIImageInfo.MaskData(:))));

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.MaskData=MaskData;
ReviewInfo.Value=Value;


function [Value, ReviewInfo]=Shape_Feature_SurfaceArea(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%The surface area of the binary mask. 

%-References:
%1.   Computation of Minkowski measures on 2D and 3D binary images". David Legland, Kien Kieu and Marie-Francoise Devaux (2007)
%      Image Analysis and Stereology, Vol 26(2), June 2007
%2.   web: http://www.ias-iss.org/ojs/IAS/article/view/811
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

TempIndex=find(BWMat);

if ~isempty(TempIndex)    
    if ParentInfo.ROIBWInfo.ZDim > 1
        %3D
        Value = imSurface(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim, ParentInfo.ROIBWInfo.ZPixDim]);
    else
        %2D
        Value = imPerimeter(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim]);
    end
else
    Value=[];
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=Shape_Feature_SurfaceAreaDensity(ParentInfo, Param)
%%%Doc Starts%%%
%-Description:
%SurfaceAreaDensity == SurfaceVolumeRation in Hugo's paper below.
%-Formula:
%SurfaceAreaDensity= (surface area of the binary mask)/(volume of the binary mask).

%-References:
%1.   Computation of Minkowski measures on 2D and 3D binary images". David Legland, Kien Kieu and Marie-Francoise Devaux (2007)
%      Image Analysis and Stereology, Vol 26(2), June 2007
%2.   web: http://www.ias-iss.org/ojs/IAS/article/view/811
%3.    Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%       Nat. Commun. 2014; 5: 4006.
%4.     http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

TempIndex=find(BWMat);

if ~isempty(TempIndex)
    Value = imSurfaceDensity(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim, ParentInfo.ROIBWInfo.ZPixDim]);  
else
    Value=[];
end

ReviewInfo.MaskData=Value;


function [Value, ReviewInfo]=Shape_Feature_MeanBreadth(ParentInfo, Param)
%%%Doc Starts%%%
%-Formula:
%MeanBreath=Integral of mean curvature

%-References:
%1.   Computation of Minkowski measures on 2D and 3D binary images". David Legland, Kien Kieu and Marie-Francoise Devaux (2007)
%      Image Analysis and Stereology, Vol 26(2), June 2007
%2.   web: http://www.ias-iss.org/ojs/IAS/article/view/811
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

TempIndex=find(BWMat);

if ~isempty(TempIndex)
    Value = imMeanBreadth(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim, ParentInfo.ROIBWInfo.ZPixDim]);
else
    Value=[];
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=Shape_Feature_VoxelSize(ParentInfo, Param)
%%%Doc Starts%%%
%The physical voxel size. 
%%%Doc Ends%%%
Value=ParentInfo.ROIBWInfo.YPixDim*ParentInfo.ROIBWInfo.XPixDim*ParentInfo.ROIBWInfo.ZPixDim;

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=Shape_Feature_Compactness1(ParentInfo, Param)
%%%Doc Starts%%%
%-Formula:
%Compactness1= (Volume)/(sqrt(pi)*(SurfaceArea)^(2/3)).

%-Reference:
%1.    Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%       Nat. Commun. 2014; 5: 4006.
%2.     http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

TempIndex=find(BWMat);

if ~isempty(TempIndex)    
    if ParentInfo.ROIBWInfo.ZDim > 1
        %3D
        SurefaceArea = imSurface(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim, ParentInfo.ROIBWInfo.ZPixDim]);
    else
        %2D
        SurefaceArea = imPerimeter(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim]);
    end
           
    NumVox=MKGetNumVoxBWMask(BWMat, 0.5);    
    Volume=NumVox*ParentInfo.ROIBWInfo.XPixDim*ParentInfo.ROIBWInfo.YPixDim*ParentInfo.ROIBWInfo.ZPixDim;
    
    Value=Volume/(sqrt(pi)*(SurefaceArea^(2/3)));    
else
    Value=[];
end

ReviewInfo.MaskData=Value;


function [Value, ReviewInfo]=Shape_Feature_Compactness2(ParentInfo, Param)
%%%Doc Starts%%%
%-Formula:
%Compactness2= 36*pi*(Volume^2)/((SurfaceArea)^3).

%-Reference:
%1.    Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%       Nat. Commun. 2014; 5: 4006.
%2.     http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

TempIndex=find(BWMat);

if ~isempty(TempIndex)    
    if ParentInfo.ROIBWInfo.ZDim > 1
        %3D
        SurefaceArea = imSurface(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim, ParentInfo.ROIBWInfo.ZPixDim]);
    else
        %2D
        SurefaceArea = imPerimeter(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim]);
    end
           
    NumVox=MKGetNumVoxBWMask(BWMat, 0.5);    
    Volume=NumVox*ParentInfo.ROIBWInfo.XPixDim*ParentInfo.ROIBWInfo.YPixDim*ParentInfo.ROIBWInfo.ZPixDim;
    
    Value=36*pi*(Volume^2)/(SurefaceArea^3);    
else
    Value=[];
end

ReviewInfo.MaskData=Value;

function [Value, ReviewInfo]=Shape_Feature_Max3DDiameter(ParentInfo, Param)
%%%Doc Starts%%%
%-Description:
%Max3DDiameter= largest pairwise Euclidean distance between voxels on the surface of the tumor volume.

%-Reference:
%1.    Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%       Nat. Commun. 2014; 5: 4006.
%2.     http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

TempIndex=find(BWMat);

if ~isempty(TempIndex)    
    DistMethod=1;   
        
    switch DistMethod
        case 1
            Dist=BWDist_EucNeg(BWMat, BWMat, [ParentInfo.ROIBWInfo.XPixDim, ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.ZPixDim]); 
                        
        case 2
            BWEdge = bwperim(BWMat);
            EdgeIndex=find(BWEdge);
            [RowIndex, ColIndex, PageIndex]=ind2sub(size(BWMat), EdgeIndex);
            
            RowCor=(RowIndex(:)-1)*ParentInfo.ROIBWInfo.YPixDim;
            ColCor=(ColIndex(:)-1)*ParentInfo.ROIBWInfo.XPixDim;
            PageCor=(PageIndex(:)-1)*ParentInfo.ROIBWInfo.ZPixDim;
            
            Point=[ColCor, RowCor, PageCor];
            [TT, Dist]=dsearchn_Neg(Point, Point);          
            
        case 3
            BWEdge = bwperim(BWMat);
            EdgeIndex=find(BWEdge);
            [RowIndex, ColIndex, PageIndex]=ind2sub(size(BWMat), EdgeIndex);
            
            RowCor=(RowIndex(:)-1)*ParentInfo.ROIBWInfo.YPixDim;
            ColCor=(ColIndex(:)-1)*ParentInfo.ROIBWInfo.XPixDim;
            PageCor=(PageIndex(:)-1)*ParentInfo.ROIBWInfo.ZPixDim;
            
            Point=[ColCor, RowCor, PageCor];        
            
            [TT, Dist]=knnsearch(Point, Point, 'Distance', @NegDist);
            Dist=-Dist;
    end
        
    Value=max(Dist);
else
    Value=[];
end

ReviewInfo.MaskData=Value;

function D2 = NegDist(ZI, ZJ)
Dim=size(ZJ, 2);

for i=1:Dim
    if i < 2
        Tot=(ZI(i)-ZJ(:, i)).^2;
    else
        Tot=Tot+(ZI(i)-ZJ(:, i)).^2;
    end    
end

D2=-sqrt(Tot);


function [Value, ReviewInfo]=Shape_Feature_SphericalDisproportion(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1.    Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%       Nat. Commun. 2014; 5: 4006.
%2.     http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

TempIndex=find(BWMat);

if ~isempty(TempIndex)    
    if ParentInfo.ROIBWInfo.ZDim > 1
        %3D
        SurefaceArea = imSurface(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim, ParentInfo.ROIBWInfo.ZPixDim]);
    else
        %2D
        SurefaceArea = imPerimeter(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim]);
    end
           
    NumVox=MKGetNumVoxBWMask(BWMat, 0.5);    
    Volume=NumVox*ParentInfo.ROIBWInfo.XPixDim*ParentInfo.ROIBWInfo.YPixDim*ParentInfo.ROIBWInfo.ZPixDim;
    
    Radius=(Volume*3/4/pi)^(1/3);
    
    Value=SurefaceArea/((4*pi)*(Radius^2));    
else
    Value=[];
end

ReviewInfo.MaskData=Value;



function [Value, ReviewInfo]=Shape_Feature_Sphericity(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1.    Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%       Nat. Commun. 2014; 5: 4006.
%2.     http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
BWMat=ParentInfo.ROIBWInfo.MaskData;

TempIndex=find(BWMat);

if ~isempty(TempIndex)    
    if ParentInfo.ROIBWInfo.ZDim > 1
        %3D
        SurefaceArea = imSurface(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim, ParentInfo.ROIBWInfo.ZPixDim]);
    else
        %2D
        SurefaceArea = imPerimeter(BWMat, [ParentInfo.ROIBWInfo.YPixDim, ParentInfo.ROIBWInfo.XPixDim]);
    end
           
    NumVox=MKGetNumVoxBWMask(BWMat, 0.5);    
    Volume=NumVox*ParentInfo.ROIBWInfo.XPixDim*ParentInfo.ROIBWInfo.YPixDim*ParentInfo.ROIBWInfo.ZPixDim;
    
        
    Value=(pi^(1/3))*((6*Volume)^(2/3))/SurefaceArea;     
else
    Value=[];
end

ReviewInfo.MaskData=Value;

%-------------------------------------------------------------Helper----------------------------------------------%
function [DensityLookupCTNum, DensityLookupValue]=ComputeDensityLookup(DensityCTNum, DensityValue)
% DensityCTNum=[0, 294, 898, 1000, 1056, 1198, 1644, 1872, 2470];
% DensityValue=[0, 0.291, 0.927, 1, 1.047, 1.1, 1.337, 1.427, 1.75];

DensityLookupCTNum=[];
DensityLookupValue=[];

for i=1:length(DensityCTNum)-1
    CurrentCTNum=DensityCTNum(i)+1:DensityCTNum(i+1);
    CurrentValue=DensityValue(i)+(CurrentCTNum-DensityCTNum(i))*(DensityValue(i+1)-DensityValue(i))/(DensityCTNum(i+1)-DensityCTNum(i));
    
    DensityLookupCTNum=[DensityLookupCTNum, CurrentCTNum];
    DensityLookupValue=[DensityLookupValue, CurrentValue];
end