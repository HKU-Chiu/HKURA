function ParentInfo=IntensityHistGaussFitOrgan_Category(DataItemInfo, Mode, Param)
%%%Doc Starts%%%
%-Description: 
%1.   This method is to fit histogram with gaussian curves.
%2.   Gaussian curve information is passed into IntensityHistogram_Feature.m to compute the related features.

%-Parameters:
%1. NBins:          The number of bins.
%2. RangeMin:    Lower bound of bin location.
%3. RangeMax:   Upper bound of bin location.
%4. RangeFix:     1==The specified RangeMin and RangeMax specified are used. 0==Ignore the specified RangeMin and RangeMax, and 
%                    RangeMin and RangeMax are dynamically determined by min and max of the current image.
%5. OnlyUseMaxSlice:  1: Binary mask only contains the binary slice with the maximum area. 0: Use the binary mask as it is.
%6. NumberOfGauss: The number of gaussian curves to be fitted.

%-Revision:
%2014-10-17: The method is implemented.

%-Algorithm:
%1. First set NumberOfGauss to 1, detect the maximum occurence position,
%    use this position to set gaussian mean, gaussian amplitude, and then fit
%    the gaussian curve.
%2. Get the residual curve=Original curve-Gaussian curve
%3. Repeat step 1 and step 2, until NumberOfGauss is reached.


%-Authors:
%Joy Zhang, lifzhang@mdanderson.org
%%%Doc Ends%%%


%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%
%%-----------Implement your code starting from here---------%
warning off;

DebugFlag=1;

%Compute the hisogram
DataItemInfo= ComputeHistogram(DataItemInfo, Param, Mode);

%Upsample and smooth hisogram
HistData=DataItemInfo.ROIImageInfo.MaskData;

Rate=16;
HistData=UpsampleData(HistData, Rate);

XData=HistData(:, 1); 
YDataOri=HistData(:, 2);

YData= smooth(XData, YDataOri, 5,'moving', 0);

Param.NumberOfGauss=length(Param.OrganMean);


Param.NumberOfGaussOri=Param.NumberOfGauss;     

%Step 1: estimage model adding one each time and refine, and next
[CurveFit, CurveModel]=EestimateModel(Param, XData, YData);
if DebugFlag > 0
    DataItemInfo.ROIImageInfo=AddGaussCurveInfo(DataItemInfo.ROIImageInfo, CurveFit, XData);
end

DataItemInfo.ROIImageInfo.CurveModel=CurveModel;

switch Mode
    case 'Review'
        ReviewInfo=DataItemInfo.ROIImageInfo;
        ParentInfo=ReviewInfo;        
        
    case 'Child'
        ParentInfo=DataItemInfo;
end


function [CurveFit, CurveModel]=EestimateModel(Param, XData, YData)

NumGauss=length(Param.OrganMean);

FitType=fittype(['gauss', num2str(NumGauss)]);
FitOption=fitoptions(['gauss', num2str(NumGauss)]);
        
StartPoint=[];
Lower=[];
Upper=[];

MinX=min(XData(:));
MaxX=max(XData(:));

[MeanEst, AmpEst, StdEst]=GetStartEst(XData, YData);     

for i=1:NumGauss
    
    switch i
        case 1
            StartPoint=[StartPoint, AmpEst, MeanEst,StdEst];
            
            Lower=[Lower, 0.9*AmpEst, 0.95*MeanEst, 0.9*StdEst];
            Upper=[Upper, 1.1*AmpEst, 1.05*MeanEst, 1.1*StdEst];
        case 2
            PosMean=MeanEst-20;
            
            StartPoint=[StartPoint, Param.OrganAmp(i), PosMean, Param.OrganStd(i)];
                        
            Lower=[Lower, 0, PosMean-5, 0];
            Upper=[Upper, AmpEst,  PosMean+5, StdEst];
        case 3
            StartPoint=[StartPoint, Param.OrganAmp(i), Param.OrganMean(i), Param.OrganStd(i)];
            
            Lower=[Lower, 0, Param.OrganMean(i)-50, 0];
            Upper=[Upper, AmpEst,  Param.OrganMean(i)+50, (MeanEst-MinX)/2];
            
        case 4
            StartPoint=[StartPoint, Param.OrganAmp(i), Param.OrganMean(i), Param.OrganStd(i)];
            
            Lower=[Lower, 0, Param.OrganMean(i)-50, 0];
            Upper=[Upper, inf,  Param.OrganMean(i)+50, inf];
            
        otherwise
            StartPoint=[StartPoint, Param.OrganAmp(i), Param.OrganMean(i), Param.OrganStd(i)];
            
            Lower=[Lower, 0, Param.OrganMean(i)-100, 0];
            Upper=[Upper, inf,  Param.OrganMean(i)+100, inf];
    end           
end

[Lower, Upper]=AssureBound(Lower, Upper);
set(FitOption, 'StartPoint', StartPoint, 'Lower', Lower, 'Upper', Upper);

CurveModel = fit(XData,YData, FitType, FitOption);

FitType=fittype(['gauss', num2str(1)]);
FitOption=fitoptions(['gauss', num2str(1)]);
CurveModelFake = fit(XData,YData, FitType, FitOption);

for i=1:NumGauss
    CurveFit(i).CurveModel=CurveModelFake;
    CurveFit(i).CurveModel.a1=CurveModel.(['a', num2str(i)]);
    CurveFit(i).CurveModel.b1=CurveModel.(['b', num2str(i)]);
    CurveFit(i).CurveModel.c1=CurveModel.(['c', num2str(i)]);
end

function [Lower, Upper]=AssureBound(Lower, Upper)
Diff=Upper-Lower;
TempIndex=find(Diff <= 0);
Upper(TempIndex)=inf;


function ROIImageInfo=AddGaussCurveInfo(ROIImageInfo, CurveFit, XData, Mode)
if isfield(ROIImageInfo, 'CurvesInfo')
    CurvesInfo=ROIImageInfo.CurvesInfo;
else
    CurvesInfo=[];
end

Len=length(CurvesInfo);

NumberOfGauss=length(CurveFit);

CurvesInfo(Len+1).CurveData=ROIImageInfo.MaskData;
CurvesInfo(Len+1).Description='Histogram';
CurvesInfo(Len+1).LineStyle='b';
CurvesInfo(Len+1).LineWidth=1;

%Each Gaussian Curve
YData=[]; LineStyleT={'-'; '--'; ':'; '-.'};
for i=1:NumberOfGauss
    YDataFit = feval(CurveFit(i).CurveModel, XData);
    YData=[YData, YDataFit];
    
    CurvesInfo(Len+i+1).CurveData=[XData, YDataFit];
    CurvesInfo(Len+i+1).Description=['Gauss ', num2str(i)];
    
    LineIndex=rem(i, 4);
    if LineIndex < 1
        LineIndex=4;
    end
    CurvesInfo(Len+i+1).LineStyle=['r', LineStyleT{LineIndex}];
    
    CurvesInfo(Len+i+1).LineWidth=1;
end

%Fitted Curve
if nargin < 4
    YData=sum(YData, 2);
    CurvesInfo(Len+NumberOfGauss+2).CurveData=[XData, YData];
    CurvesInfo(Len+NumberOfGauss+2).Description=['Fitted Curve '];
    CurvesInfo(Len+NumberOfGauss+2).LineStyle='g-';
    CurvesInfo(Len+NumberOfGauss+2).LineWidth=2;
    CurvePlot=zeros(1, NumberOfGauss+2);   
else
    CurvePlot=zeros(1, NumberOfGauss+1);   
end

ROIImageInfo.CurvesInfo=CurvesInfo;
CurvePlot(1)=1;

if isfield(ROIImageInfo, 'CurvesPlot')
    ROIImageInfo.CurvesPlot=[ROIImageInfo.CurvesPlot, CurvePlot];
else
    ROIImageInfo.CurvesPlot=CurvePlot;
end


function HistData=UpsampleData(HistData, Rate)

XData=HistData(:, 1);
YData=HistData(:, 2);

XMin=min(XData);
XMax=max(XData);

LenOri=length(XData);
LenFinal=Rate*LenOri;

Interval=(XMax-XMin)/LenFinal;

XDataFinal=XMin+(0:LenFinal)'*Interval;

YDataFinal=interp1(XData, YData, XDataFinal);

HistData=[XDataFinal, YDataFinal];


function [MeanEst, AmpEst, StdEst]=GetStartEst(XData, YData)
[MaxY, MaxIndex]=max(YData);

%Maxium probability position for Mean and amplitude estimation
MeanEst=XData(MaxIndex);
AmpEst=MaxY;

%Std estimation through X(0.05*AmpEst)-MeanEst
MaxXData=max(XData);
MinXData=min(XData);
BaseStd=min([MaxXData/2, MaxXData-MeanEst, MeanEst-MinXData]);
% BaseStd=MaxXData/(2*2*Param.NumberOfGauss);

MaxYStd=MaxY*0.05;
TempIndexLeft=find(YData<MaxYStd & XData < MeanEst);
TempIndexRight=find(YData<MaxYStd & XData > MeanEst);

if ~isempty(TempIndexLeft) || ~isempty(TempIndexRight)

    if ~isempty(TempIndexLeft)
        XDataT=XData(TempIndexLeft);
        StdEstLeft=MeanEst-max(XDataT);
        
        BaseStd=min(BaseStd, StdEstLeft);
    end
    
    if ~isempty(TempIndexRight)
        XDataT=XData(TempIndexRight);
        StdEstRight=min(XDataT)-MeanEst;
        
        BaseStd=min(BaseStd, StdEstRight);
    end    
end

StdEst=BaseStd;
