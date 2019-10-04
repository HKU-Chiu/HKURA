function FeatureInfo=cumIntensityHistogram_Feature(ParentInfo, FeatureInfo, Mode)

%Purpose:       To implement a feature, two files are needed. 
%*CategoryName*_Category.m: to calculate the ParentInfo from DateItemInfo to be used in *CategoryName*_Feature.m.
%*CategoryName*_Feature.m:   to calcuate the features using the same ParentInfo that is output from *CategoryName*_Category.m. 
%Feature names are describled in the declaration of feature caculation function in *CategoryName*_Feature.m.
%Naming Convention of feaure caculation functions:  *CategoryName*_Feature_*FeatureName*
%Architecture: All the feature-relevant files are under \IBEXCodePath\FeatureAlgorithm\Category\*CategoryName*\.
%Files:            *CategoryName*_Feature.m, *CategoryName*_Feature.INI

%%---------------Input Parameters Passed In By IBEX-------------%
%ParentInfo:      The structure from *CategoryName*_Category.m and all features are caculated from this ParentInfo.
%FeatureInfo:    The structure containing the feature info.
%length(FeatureInfo): the number of features
%FeatureInfo.Name: Feature Name  
%FeatureInfo.Value:  Parameters from GUI or from *CategoryName*_Feature_*FeatureName*.INI                         
%Mode:             Three Statuses.                          
%'ParseFeature': FeatureInfo is the feature name list.
%'Review':         FeatureInfo is the ReviewInfo to be reviewed when press "Test" button.
%'NoReview':    FeatureInfo contains the value of the features

%%--------------Output Parameters------------%
%FeatureInfo:    The structure containing the feature info.
%length(FeatureInfo): the number of features
%FeatureInfo.Name: Feature Name  
%FeatureInfo.Value:  Parameters from GUI or from *CategoryName*_Feature_*FeatureName*.INI
%FeatureInfo.FeatureValue: value of the features( for Mode == 'Review' or Mode == 'NoReview')

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
            FeatureInfo(i).FeatureValue=FeatureValue;
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
%Feature: cumHistogram
function [Value, ReviewInfo]=cumIntensityHistogram_Feature_cumHistogram(ParentInfo, Param)
%****The skeleton feature returns intensity maximum of ROI image data****%
disp_img = 1;
ImageInfo=ParentInfo.ROIImageInfo;
BWInfo= ParentInfo.ROIBWInfo;
Mod = ParentInfo.Modality;
Image = double(ImageInfo.MaskData);

Mask = double(BWInfo.MaskData);

use = Image.*Mask;
per_Volumef = zeros(101,1);
%per_Volumeb = per_Volumef;
Max = max(use(:));
iter=0;
for i = 0:100
    iter = iter+1;
    per_Volumef(iter)=sum(nonzeros(use) > (Max*i/100))/length(nonzeros(use));
    %per_Volumeb(iter)=sum(nonzeros(use) < (Max*i/100))/length(nonzeros(use));
end

if max(use(:))==0
    Valuef = NaN;
    %Valueb = NaN;
else
    Valuef = trapz(0:100,per_Volumef);
    %Valueb = trapz(0:100,per_Volumeb);
end

if(strcmp(Mod,'PT')&&disp_img == 1) && isequal(ParentInfo.Mode, 'Review')
    figure;
    subplot(1,2,1); plot(0:100,per_Volumef,'LineWidth',3); xlabel('Percent of SUVmax'); ylabel('Percent Volume');title([sprintf('Forward\n'),'AUC = ',num2str(Valuef)])
    %subplot(1,2,2); plot(0:100,per_Volumeb,'LineWidth',3); xlabel('Percent of SUVmax'); ylabel('Percent Volume');title([sprintf('Backward\n'),'AUC = ',num2str(Valueb)])
end

Value = Valuef;
%mean([Valuef,Valueb]);



% unique_vals = unique(nonzeros(use));
% if(strcmp(Mod,'PT'))
%     unique_vals = [0; unique_vals];
% else 
% end
% 
% iter = 0;
% per_Volume = zeros(length(unique_vals),1);
% for i = 1:length(unique_vals)
%     iter = iter+1;
%     per_Volume(iter)=sum(nonzeros(use) > unique_vals(i))/length(nonzeros(use));
% end
% 
% if(strcmp(Mod,'PT'))
%     per_unique_vals = unique_vals./max(unique_vals(:));
% else
%     per_unique_vals = 1/(max(unique_vals(:))-min(unique_vals(:)))*unique_vals-min(unique_vals(:))/(max(unique_vals(:))-min(unique_vals(:)));
% end
% 
% if max(use(:))==0
%     Value = NaN;
% else
% Value = trapz(per_unique_vals,per_Volume);
% end
% 
% if(strcmp(Mod,'PT')&&disp_img == 1)
% figure;
% subplot(1,2,1); plot(per_unique_vals,per_Volume,'LineWidth',3); xlabel('Percent of SUVmax'); ylabel('Percent Volume');title(['AUC = ',num2str(Value)])
% subplot(1,2,2); plot(unique_vals,per_Volume,'LineWidth',3); xlabel('SUV value'); ylabel('Percent Volume');title(['AUC = ',num2str(Value)])
% else
%     figure;
%     h1=subplot(1,2,1); plot(per_unique_vals,per_Volume,'LineWidth',3); xlabel('Percent of HUmax'); ylabel('Percent Volume');title(['AUC = ',num2str(Value)])
%     h2=subplot(1,2,2); plot(unique_vals,per_Volume,'LineWidth',3); xlabel('HU value'); ylabel('Percent Volume');title(['AUC = ',num2str(Value)])
%     axis([h1 h2],'tight')
% end

ReviewInfo.Value=Value;
 
 
