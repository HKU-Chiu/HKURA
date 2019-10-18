function ParentInfo=NeighborIntensityDifference3_Category(CDataSetInfo, Mode, Param)
%%%Doc Starts%%%
%-Description: 
%1.   This method is to compute neighborhood intensity difference matrix(NIDM) from image inside
%      the binary mask. The neighborhood is in 3D.  All the feature calculation is done the same as NeighborIntensityDifference25 does. 
%2.   NIDM is passed into NeighborIntensityDifference3_Feature.m to compute the related features.

%-Parameters:
%1.  NHood: The neighborhood matrix size in X dimension.
%2.  NHoodSym: 1==neighborhood matrix size in Y and Z are calculated to best match neighborhood physical length in X dimension.
%                       0==neighborhood matrx size are same in X, Y, and Z dimensions.
%3.   IncludeEdge: Include edge pixels for analysis (1) or not (0).
%4.   RangeMin:   Minimum intensity value for analysis.
%5.   RangeMax:   Maximum intensity value for analysis.
%6.   NBins:       The number of bins.
%RangeMin, RangeMax, NBins are used to reduce the number of interested intensity level.

%-References:
%1. Amadasun, M.; King, R. Textural features corresponding to textural properties.
%   IEEE Transactions on Systems, Man and Cybernetics,Volume 19 Issue 5, Page 1264-1274 

%-Revision:
%2014-05-22: The method is implemented.

%-Authors:
%Joy Zhang, lifzhang@mdanderson.org
%David Fried, DVFried@mdanderson.org
%%%Doc Ends%%%

%Code
NIDStruct=ComputeNIDM(CDataSetInfo, Param);

switch Mode
    case 'Review'
        ReviewInfo=CDataSetInfo.ROIImageInfo;
        ReviewInfo.NIDStruct=NIDStruct;        
        
        ClassName=class(CDataSetInfo.ROIImageInfo.MaskData);
        FuncH=str2func(ClassName);
        
        %DiffMat: Force the float difference to the current type
        ReviewInfo.MaskData=FuncH(NIDStruct.DiffMaskData);
        
        %Occurence Probability Histogram Curve
        ReviewInfo.CurvesInfo(1).Description='Occurence Probability Histogram (Prob. VS Intensity)';
        ReviewInfo.CurvesInfo(1).CurveData=[ReviewInfo.NIDStruct.HistBinLoc, ReviewInfo.NIDStruct.HistOccurPropability];
        
        %Diff. Sum Histogram Curve
        ReviewInfo.CurvesInfo(2).Description='Difference Sum. Histogram (Sum. VS Intensity)';
        ReviewInfo.CurvesInfo(2).CurveData=[ReviewInfo.NIDStruct.HistBinLoc, ReviewInfo.NIDStruct.HistDiffSum];
                
        ParentInfo=ReviewInfo;
        
    case 'Child'
        CDataSetInfo.ROIImageInfo.NIDStruct=NIDStruct;
        ParentInfo=CDataSetInfo;
end


function NIDStruct=ComputeNIDM(CDataSetInfo, Param)
ROIImageInfo=CDataSetInfo.ROIImageInfo;

%-----Step 1: Compute 3D Neighborhood Intensity Difference Matrix
%Scale to 0-4096
if ~isinteger(ROIImageInfo.MaskData)
   ROIImageInfo=ScaleDataSet2Int(ROIImageInfo);
end

%make sure the Odd number of neighborhood
NHoodX=Param.NHood;

if Param.NHoodSym > 0
    NHoodY=round(Param.NHood*ROIImageInfo.XPixDim/ROIImageInfo.YPixDim);
    NHoodZ=round(Param.NHood*ROIImageInfo.XPixDim/ROIImageInfo.ZPixDim);
else
    NHoodY=NHoodX;
    NHoodZ=NHoodX;    
end

NHoodX=OddNHood(NHoodX);
NHoodY=OddNHood(NHoodY);
NHoodZ=OddNHood(NHoodZ);

% %DEBUG
% NHoodX=3;
% NHoodY=3;
% NHoodZ=3;
% %DEBUG

%--DiffMat
%DiffMat is in float
DiffMat=zeros(size(ROIImageInfo.MaskData), 'single');

MaskData=permute(ROIImageInfo.MaskData, [2,1,3]);
DiffMat=permute(DiffMat, [2,1,3]);

ComputeSlideNeighDiff(MaskData, DiffMat, ...
    size(ROIImageInfo.MaskData, 2), size(ROIImageInfo.MaskData, 1),  size(ROIImageInfo.MaskData, 3), ...
    NHoodX, NHoodY, NHoodZ);

DiffMat=permute(DiffMat, [2,1,3]);
ROIImageInfo.MaskData=DiffMat;

%Scale back to original
if isfield(ROIImageInfo, 'RescaleMinV')
    ROIImageInfo.RescaleClass='single';
    ROIImageInfo=ScaleDataSet2Ori(ROIImageInfo);
end

DiffMaskData=ROIImageInfo.MaskData;

%--DiffMask BW
%Remove Edge
if isfield(Param, 'IncludeEdge') && Param.IncludeEdge < 1
    MaskShrinkBW=GetMaskShrinkBW(CDataSetInfo.ROIBWInfo.MaskData, NHoodX, NHoodY, NHoodZ);
else
    MaskShrinkBW=ones(size(ROIImageInfo.MaskData), 'uint8');
end

DiffMaskBW=GetDiffMatBWMask(size(ROIImageInfo.MaskData), NHoodX, NHoodY, NHoodZ);
DiffMaskBW=MaskShrinkBW& DiffMaskBW & CDataSetInfo.ROIBWInfo.MaskData;

NIDStruct.DiffMaskData=DiffMaskData;
NIDStruct.DiffMaskBW=DiffMaskBW;

%--Intensity Probability Histogram (Ocurrence Probability VS Intensity)
ValidImageData=CDataSetInfo.ROIImageInfo.MaskData(logical(DiffMaskBW));
ValidDiffData=DiffMaskData(logical(DiffMaskBW));

MaskImageMat=double(ValidImageData);

if isempty(MaskImageMat)
    NIDStruct.HistOccurPropability=NaN;
    NIDStruct.HistDiffSum=NaN;
    NIDStruct.HistBinLoc=NaN;
else
    InterVal=(Param.RangeMax-Param.RangeMin)/Param.NBins;
    BinLoc=double(Param.RangeMin:InterVal:Param.RangeMax);
    
    [ValuePropability, BinCenter] = hist(MaskImageMat, BinLoc);
    ValuePropability=ValuePropability./numel(MaskImageMat);
    
    %--Intensity Difference Sum  Histogram  (Differenct Sum VS Intensity)
    MaskDiffMat=double(ValidDiffData);
    
    [ValueSum, BinCenter]=GetValueSumHist(BinCenter, MaskImageMat, MaskDiffMat);
    
    NIDStruct.HistOccurPropability=ValuePropability';
    NIDStruct.HistDiffSum=ValueSum';
    NIDStruct.HistBinLoc=BinCenter';
end

function MaskShrinkBW=GetMaskShrinkBW(MaskData, NHoodX, NHoodY, NHoodZ)
SumMat=zeros(size(MaskData), 'single');
MaskShrinkBW=ones(size(MaskData), 'uint8');

MaskData=permute(uint16(MaskData), [2,1,3]);
SumMat=permute(SumMat, [2,1,3]);

ComputeSlideNeighSum(MaskData, SumMat, ...
    size(MaskData, 1), size(MaskData, 2),  size(MaskData, 3), ...
    NHoodX, NHoodY, NHoodZ);

SumMat=permute(SumMat, [2,1,3]);

SumV=NHoodX*NHoodY*NHoodZ;

TempIndex=find(SumMat < SumV);

MaskShrinkBW(TempIndex) = 0;





function [ValueSum, BinCenter2]=GetValueSumHist(BinCenter, MaskImageMat, MaskDiffMat)
y=MaskImageMat;

xx = BinCenter(:)';
binwidth = [diff(xx) 0];
xx = [xx(1)-binwidth(1)/2 xx+binwidth/2];

miny=min(y);
maxy=max(y);

xx(1) = min(xx(1),miny);
xx(end) = max(xx(end),maxy);

% Shift bins so the interval is ( ] instead of [ ).
xx = full(real(xx));
bins = xx + eps(xx);
edges = [-Inf bins];

nn = HistIntensitySum(y, edges, 1, MaskDiffMat);

edges(2:end) = xx;    % remove shift

% Combine first bin with 2nd bin and last bin with next to last bin
nn(2,:) = nn(2,:)+nn(1,:);
nn(end-1,:) = nn(end-1,:)+nn(end,:);
nn = nn(2:end-1,:);
edges(2) = [];
edges(end) = Inf;

ValueSum = nn';
BinCenter2 = BinCenter;


function DiffMaskBW=GetDiffMatBWMask(MatSize, NHoodX, NHoodY, NHoodZ)
DiffMaskBW=zeros(MatSize, 'uint8');

HalfWidthX=(NHoodX-1)/2;
HalfWidthY=(NHoodY-1)/2;
HalfWidthZ=(NHoodZ-1)/2;

DiffMaskBW(HalfWidthY+1:end-HalfWidthY, HalfWidthX+1:end-HalfWidthX, HalfWidthZ+1:end-HalfWidthZ)=uint8(1);


function NHood=OddNHood(NHood)
if rem(NHood, 2) < 0.5
    NHood=NHood+1;
end










