function FeatureInfo=IntensityHistogramGaussFit_Feature(ParentInfo, FeatureInfo, Mode)

%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%
%-----------------------------DO_NOT_CHANGE_STARTS--------------------------%
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

ParentInfo.Mode=Mode;

for i=1:length(FeatureInfo)
    if isequal(Mode, 'Review')
        [FeatureValue, FeatureReviewInfo]=GetFeatureValue(ParentInfo, FeatureInfo(i), FeaturePrefix);
        
        FeatureInfo(i).FeatureValue=FeatureValue;
        FeatureInfo(i).FeatureReviewInfo=FeatureReviewInfo;
    else
        FeatureValue=GetFeatureValue(ParentInfo, FeatureInfo(i), FeaturePrefix);
        
        if ~isstruct(FeatureValue)
            if length(FeatureValue) > 1
                FeatureInfo(i).FeatureValueParam=FeatureValue(:, 1);
                FeatureInfo(i).FeatureValue=FeatureValue(:, 2);
            else
                FeatureInfo(i).FeatureValue=FeatureValue;
            end
        else
            %Handle a group of feature caculated for the same buffer data
            FeatureInfo(i).FeatureValue=FeatureValue.Value;
            ParentInfo.BufferData=FeatureValue.BufferData;
            ParentInfo.BufferType=FeatureValue.BufferType;
        end
    end
end



function [FeatureValue, FeatureReviewInfo]=GetFeatureValue(ParentInfo, CurrentFeatureInfo,  FeaturePrefix)
FeatureName=CurrentFeatureInfo.Name;

FuncName=[FeaturePrefix, '_', FeatureName];
FuncHandle=str2func(FuncName);

[FeatureValue, FeatureReviewInfo]=FuncHandle(ParentInfo, CurrentFeatureInfo.Value);
%-----------------------------DO_NOT_CHANGE_ENDS------------------------------%
%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%


%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%
%%------------------------Implement your code starting from here--------------------%
%Feature: NumberOfGauss
function [Value, ReviewInfo]=IntensityHistogramGaussFit_Feature_NumberOfGauss(ParentInfo, Param)
%%%Doc Starts%%%
%The number of gaussian curve that are used to approximate the curve.
%%%Doc Ends%%%

Value=numcoeffs(ParentInfo.ROIImageInfo.CurveModel)/3;

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.MaskData=Value;


%Feature: GaussAmplitude
function [Value, ReviewInfo]=IntensityHistogramGaussFit_Feature_GaussAmplitude(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Amplitude of each gaussian curve

%-Reference:
%http://www.mathworks.com/help/curvefit/gaussian.html
%%%Doc Ends%%%

NumGauss=numcoeffs(ParentInfo.ROIImageInfo.CurveModel)/3;

Value=[];
for i=1:NumGauss
    FieldName=['a', num2str(i)];
    Value=[Value; ParentInfo.ROIImageInfo.CurveModel.(FieldName)];
end

%Force to 8 gaussian, extra guass set to NaN
InvalidGaussLen=8-NumGauss;
Value=[Value; NaN*ones(InvalidGaussLen, 1)];
Value=[(1:8)', Value];

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.MaskData=Value;
ReviewInfo.Description='Gauss Amplitude';
ReviewInfo.LineStyle='r*';

%Feature: GaussMean
function [Value, ReviewInfo]=IntensityHistogramGaussFit_Feature_GaussMean(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Mean of each gaussian curve

%-Reference:
%http://www.mathworks.com/help/curvefit/gaussian.html
%%%Doc Ends%%%

NumGauss=numcoeffs(ParentInfo.ROIImageInfo.CurveModel)/3;

Value=[];
for i=1:NumGauss
    FieldName=['b', num2str(i)];
    Value=[Value; ParentInfo.ROIImageInfo.CurveModel.(FieldName)];
end

%Force to 8 gaussian, extra guass set to NaN
InvalidGaussLen=8-NumGauss;
Value=[Value; NaN*ones(InvalidGaussLen, 1)];
Value=[(1:8)', Value];

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.MaskData=Value;
ReviewInfo.Description='Gauss Mean';
ReviewInfo.LineStyle='r*';

%Feature: GaussStd
function [Value, ReviewInfo]=IntensityHistogramGaussFit_Feature_GaussStd(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Standard deviation of each gaussian curve

%-Reference:
%http://www.mathworks.com/help/curvefit/gaussian.html
%%%Doc Ends%%%

NumGauss=numcoeffs(ParentInfo.ROIImageInfo.CurveModel)/3;

Value=[];
for i=1:NumGauss
    FieldName=['c', num2str(i)];
    Value=[Value; ParentInfo.ROIImageInfo.CurveModel.(FieldName)/sqrt(2)];
end

%Force to 8 gaussian, extra guass set to NaN
InvalidGaussLen=8-NumGauss;
Value=[Value; NaN*ones(InvalidGaussLen, 1)];
Value=[(1:8)', Value];


ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.MaskData=Value;
ReviewInfo.Description='Gauss Standard Deviation';
ReviewInfo.LineStyle='r*';

%Feature: GaussArea
function [Value, ReviewInfo]=IntensityHistogramGaussFit_Feature_GaussArea(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Area of each gaussian curve

%-Reference:
%1.   http://www.mathworks.com/help/curvefit/gaussian.html
%2.   http://en.wikipedia.org/wiki/Gaussian_function
%%%Doc Ends%%%

NumGauss=numcoeffs(ParentInfo.ROIImageInfo.CurveModel)/3;

MethodFlag=1;    %1: wikipedia definition  %2: sampling numeric integral

Value=[];
for i=1:NumGauss
    A=ParentInfo.ROIImageInfo.CurveModel.(['a', num2str(i)]);
    C=ParentInfo.ROIImageInfo.CurveModel.(['c', num2str(i)])/sqrt(2);
    
    switch MethodFlag
        case 1
            TValue=A*C*sqrt(2*pi);
        case 2
            TValue=GetGaussArea(ParentInfo.ROIImageInfo.CurveModel, i, ParentInfo.ROIImageInfo.HistData);
    end
    
    Value=[Value; TValue];
end

%Force to 8 gaussian, extra guass set to NaN
InvalidGaussLen=8-NumGauss;
Value=[Value; NaN*ones(InvalidGaussLen, 1)];
Value=[(1:8)', Value];

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.MaskData=Value;
ReviewInfo.Description='Gauss Area';
ReviewInfo.LineStyle='r*';


%Feature: GaussArea
function [Value, ReviewInfo]=IntensityHistogramGaussFit_Feature_HistArea(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Area of each gaussian curve

%-Reference:
%1.   http://www.mathworks.com/help/curvefit/gaussian.html
%2.   http://en.wikipedia.org/wiki/Gaussian_function
%%%Doc Ends%%%

YData=ParentInfo.ROIImageInfo.HistData(:, 2);
Value=sum(YData);

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.MaskData=Value;


function Area=GetGaussArea(CurveModel, Index, HistData)

FitType=fittype('gauss1');
FitOption=fitoptions('gauss1');

XData=HistData(:, 1);
YData=HistData(:, 2);

TCurveModel = fit(XData,YData, FitType, FitOption);

TCurveModel.a1=CurveModel.(['a', num2str(Index)]);
TCurveModel.b1=CurveModel.(['b', num2str(Index)]);
TCurveModel.c1=CurveModel.(['c', num2str(Index)]);

%Outliers
YDataFit = feval(TCurveModel, XData);

Area=sum(YDataFit);




