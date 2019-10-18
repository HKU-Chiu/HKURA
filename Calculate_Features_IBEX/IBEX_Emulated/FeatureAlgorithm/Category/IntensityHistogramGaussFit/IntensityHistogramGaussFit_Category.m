function ParentInfo=IntensityHistogramGaussFit_Category(DataItemInfo, Mode, Param)
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

DebugFlag=0;

%Compute the hisogram
DataItemInfo= ComputeHistogram(DataItemInfo, Param, Mode);

%Upsample and smooth hisogram
HistData=DataItemInfo.ROIImageInfo.MaskData;

Rate=16;
HistData=UpsampleData(HistData, Rate);

XData=HistData(:, 1); 
YDataOri=HistData(:, 2);

YData= smooth(XData, YDataOri, 5,'moving', 0);

if Param.NumberOfGauss > 8
    Param.NumberOfGauss=8;
end

Param.NumberOfGaussOri=Param.NumberOfGauss;     

%Step 1: estimage model adding one each time and refine, and next
Param.NumberOfGauss=8;

CurveFit=EestimateModelOneByOne(Param, XData, YData);
if DebugFlag > 0
    DataItemInfo.ROIImageInfo=AddGaussCurveInfo(DataItemInfo.ROIImageInfo, CurveFit, XData, 'NoFit');
end

%Step 2: remove the refine peak, pick the distinguished peaks
CurveFitAll=CurveFit;

CurveFit=RemoveCloseModel(CurveFit);
if DebugFlag > 0
    DataItemInfo.ROIImageInfo=AddGaussCurveInfo(DataItemInfo.ROIImageInfo,CurveFit, XData, 'NoFit');
end

%Step 3: Fix number of gaussian
Param.NumberOfGauss=Param.NumberOfGaussOri;
if Param.NumGaussFix > 0
    %Auto Gauss # >= NumOfGauss
    Len=length(CurveFit);
    
    if Len >= Param.NumberOfGauss
        CurveFit=CurveFit(1:Param.NumberOfGauss);        
    else
        %Auto Gauss # < NumOfGauss
        CurveFit=AddMedianModel(CurveFit, CurveFitAll, Param.NumberOfGauss);
    end
end

if DebugFlag > 0
    DataItemInfo.ROIImageInfo=AddGaussCurveInfo(DataItemInfo.ROIImageInfo, CurveFit, XData, 'NoFit');
end

%Step 4: Refine A1(amplitude), B1(Mean), C1(Std)....
[CurveFit, CurveModel]=RefineModelGroup(CurveFit, XData, YData, 'Last');
DataItemInfo.ROIImageInfo=AddGaussCurveInfo(DataItemInfo.ROIImageInfo, CurveFit, XData);


DataItemInfo.ROIImageInfo.CurveModel=CurveModel;


DataItemInfo.ROIImageInfo.HistData=HistData;

switch Mode
    case 'Review'
        ReviewInfo=DataItemInfo.ROIImageInfo;
        ParentInfo=ReviewInfo;        
        
    case 'Child'
        ParentInfo=DataItemInfo;
end

function CurveFit=AddMedianModel(CurveFit, CurveFitAll, NumberOfGauss)
A1=[]; B1=[]; C1=[];
for i=1:length(CurveFit)    
    A1=[A1; CurveFit(i).CurveModel.a1];
    B1=[B1; CurveFit(i).CurveModel.b1];
    C1=[C1; CurveFit(i).CurveModel.c1];
end

A1T=[]; B1T=[]; C1T=[];
for i=1:length(CurveFitAll)    
    A1T=[A1T; CurveFitAll(i).CurveModel.a1];
    B1T=[B1T; CurveFitAll(i).CurveModel.b1];
    C1T=[C1T; CurveFitAll(i).CurveModel.c1];
end

CurveFitIndex=[];
for i=1:length(CurveFit)    
    TIndex=find(A1(i)==A1T & B1(i)==B1T & C1(i)==C1T);
    CurveFitIndex=[CurveFitIndex; TIndex];
end

%Add by distance
Dist=0;
for i=1:length(CurveFit)
    Dist=Dist+(B1T-B1(i)).^2;
end

Dist(CurveFitIndex)=inf;
[Dist, SortIndex]=sort(Dist, 'ascend');

GaussNeed=NumberOfGauss-length(CurveFit);
IndexNeed=SortIndex(1:GaussNeed);

for i=1:GaussNeed
    CurveFit(end+1).CurveModel=CurveFitAll(IndexNeed(i)).CurveModel;
end


function CurveFitF=EestimateModelOneByOne(Param, XData, YData)
YDataOri=YData;
MaxXData=max(XData);
MinXData=min(XData);

FitType=fittype('gauss1');
FitOption=fitoptions('gauss1');


for i=1:Param.NumberOfGauss           
    
    [MeanEst, AmpEst, StdEst]=GetStartEst(XData, YData);
   
    StartPoint=[AmpEst, MeanEst, StdEst];
      
    if i < 2
%         UpperC=min(MaxXData-MeanEst, MeanEst);
        
        Lower=[0.9*AmpEst, 0.95*MeanEst, 0.9*StdEst];
        Upper=[1.1*AmpEst, 1.05*MeanEst, 1.1*StdEst];
%         Lower=[0.9*AmpEst, 0.95*MeanEst, 0];
%         Upper=[1.1*AmpEst, 1.05*MeanEst, UpperC];
    else        
        UpperC=min(MaxXData-MeanEst, MeanEst);
        
%         LowerB=max(MinXData, MeanEst-StdEst/2);
%         UpperB=min(MaxXData, MeanEst+StdEst/2);    

%         Lower=[0, LowerB, 0];
%         Upper=[inf, UpperB, UpperC];      
             
        Lower=[0.9*AmpEst, 0.95*MeanEst, 0];
        Upper=[1.1*AmpEst, 1.05*MeanEst, UpperC];
    end
    
    [Lower, Upper]=AssureBound(Lower, Upper);    
    set(FitOption, 'StartPoint', StartPoint, 'Lower', Lower, 'Upper', Upper);
        
    CurveModel = fit(XData,YData, FitType, FitOption);
    
    %Outliers
    YDataFit = feval(CurveModel, XData);           
   
    CurveFitF(i).CurveModel=CurveModel;
        
    if i > 1
        [CurveFit, CurveModelNew]=RefineModelGroup(CurveFitF, XData, YDataOri);
        YDataFit = feval(CurveModelNew, XData);
        
        CurveFitF(1).CurveModel=CurveFit(1).CurveModel;
    end
    
    %Next Iteration
    YData=YDataOri-YDataFit;    
    
    TempIndex=find(YData < 0);
    YData(TempIndex)=0;
end

function [CurveFit, CurveModel]=RefineModelGroup(CurveFit, XData, YData, Mode)
MaxXData=max(XData);
MinXData=min(XData);

NumberOfGauss=length(CurveFit);

FitType=fittype(['gauss', num2str(NumberOfGauss)]);
FitOption=fitoptions(['gauss', num2str(NumberOfGauss)]);

StartPoint=[]; 
for i=1:NumberOfGauss
    StartPoint=[StartPoint, CurveFit(i).CurveModel.a1, CurveFit(i).CurveModel.b1, CurveFit(i).CurveModel.c1];
end

Lower=[]; Upper=[];
for i=1:NumberOfGauss
    if nargin < 4
        %Refine when adding curve when one by one
        if i <2
            LowerB=max(MinXData, CurveFit(i).CurveModel.b1-CurveFit(i).CurveModel.c1/2);
            UpperB=min(MaxXData, CurveFit(i).CurveModel.b1+CurveFit(i).CurveModel.c1/2);
            
            Lower=[Lower, 1*CurveFit(i).CurveModel.a1,  LowerB, 0.5*CurveFit(i).CurveModel.c1];
            Upper=[Upper, 2*CurveFit(i).CurveModel.a1,  UpperB, 1.5*CurveFit(i).CurveModel.c1];
        else
            UpperC=min(MaxXData-CurveFit(i).CurveModel.b1, CurveFit(i).CurveModel.b1);
                      
            Lower=[Lower, 0,  0, 0];
            Upper=[Upper, inf,  MaxXData, UpperC];
        end
    else
        %Last refine
        LowerB=max(MinXData, CurveFit(i).CurveModel.b1-CurveFit(i).CurveModel.c1);
        UpperB=min(MaxXData, CurveFit(i).CurveModel.b1+CurveFit(i).CurveModel.c1);
        
        if i <2
            UpperC=min(MaxXData-CurveFit(i).CurveModel.b1, CurveFit(i).CurveModel.b1);
            
            Lower=[Lower,1*CurveFit(i).CurveModel.a1, LowerB, 0];
            Upper=[Upper, 2*CurveFit(i).CurveModel.a1,  UpperB, UpperC];
        else
            Lower=[Lower, 0, 0, 0];
            Upper=[Upper, inf, MaxXData, MaxXData/2];
            
%             Lower=[Lower, 1*CurveFit(i).CurveModel.a1, LowerB, 0.5*CurveFit(i).CurveModel.c1];
%             Upper=[Upper, inf, UpperB, 2*CurveFit(i).CurveModel.c1];
        end
    end
end


[Lower, Upper]=AssureBound(Lower, Upper);
set(FitOption, 'StartPoint', StartPoint, 'Lower', Lower, 'Upper', Upper);

CurveModel = fit(XData,YData, FitType, FitOption);

for i=1:NumberOfGauss
    CurveFit(i).CurveModel.a1=CurveModel.(['a', num2str(i)]);
    CurveFit(i).CurveModel.b1=CurveModel.(['b', num2str(i)]);
    CurveFit(i).CurveModel.c1=CurveModel.(['c', num2str(i)]);
end
    
function FinalCurveFit=RemoveCloseModel(CurveFit)
%Peak distance
Threshold=2.5;
ThresholdStdFirst=4;
ThresholdAmpFirst=1/10;

FinalCurveFit(1)=CurveFit(1);
CurveFit(1)=[];

while 1==1  
    Len=length(FinalCurveFit);
    %Remove by peak distance
    CurveFit=RemoveByPeakDistance(FinalCurveFit, Threshold, CurveFit);
    
    %Remove by peak distance and amplitude
    if Len < 2
        CurveFit=RemoveByPeakDistance(FinalCurveFit, ThresholdStdFirst, CurveFit, ThresholdAmpFirst);
    end
        
   if ~isempty(CurveFit)    
       Method=2;
       switch Method
           case 1
               A1=[];
               for i=1:length(CurveFit)
                   A1=[A1; CurveFit(i).CurveModel.a1];
               end
               [TempV, TempIndex]=max(A1);
                              
           case 2
               TempIndex=1;
       end
       
       FinalCurveFit(Len+1)=CurveFit(TempIndex(1));               
       CurveFit(TempIndex(1))=[];
   end   
   
   if size(CurveFit, 2) < 1
       break;
   end
end


 function CurveFit=RemoveByPeakDistance(FinalCurveFit, Threshold, CurveFit, ThresholdAmp)
 Len=length(FinalCurveFit);
 
 InitStd=FinalCurveFit(Len).CurveModel.c1/sqrt(2);
 InitMean=FinalCurveFit(Len).CurveModel.b1;
 InitAmp=FinalCurveFit(Len).CurveModel.a1;
 
 MeanMin=InitMean-Threshold*InitStd;
 MeanMax=InitMean+Threshold*InitStd;
 
 B1=[]; A1=[]; C1=[];
 for i=1:length(CurveFit)
     B1=[B1; CurveFit(i).CurveModel.b1];
     A1=[A1; CurveFit(i).CurveModel.a1];
     C1=[C1; CurveFit(i).CurveModel.c1];
 end
  
 if nargin < 4
     RemoveIndex=find(B1 > MeanMin & B1 <MeanMax);
 else
     RemoveIndex=find(B1 > MeanMin & B1 <MeanMax & A1<InitAmp*ThresholdAmp);
 end
 
 if ~isempty(RemoveIndex)
     CurveFit(RemoveIndex)=[];
 end
 

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

function [Lower, Upper]=AssureBound(Lower, Upper)
Diff=Upper-Lower;
TempIndex=find(Diff <= 0);
Upper(TempIndex)=inf;





