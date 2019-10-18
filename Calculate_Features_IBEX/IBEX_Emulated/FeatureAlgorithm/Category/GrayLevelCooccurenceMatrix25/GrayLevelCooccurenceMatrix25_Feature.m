function FeatureInfo=GrayLevelCooccurenceMatrix25_Feature(ParentInfo, FeatureInfo, Mode)

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
        
        if length(FeatureValue) > 1
            FeatureInfo(i).FeatureValueParam=FeatureValue(1, 2:end);
            FeatureInfo(i).FeatureValue=FeatureValue(2:end, :);
        else
            FeatureInfo(i).FeatureValue=FeatureValue;
        end
    end         
end


function [FeatureValue, FeatureReviewInfo]=GetFeatureValue(ParentInfo, CurrentFeatureInfo,  FeaturePrefix)
FeatureName=CurrentFeatureInfo.Name;

FuncName=[FeaturePrefix, '_', FeatureName];
FuncHandle=str2func(FuncName);

[FeatureValue, FeatureReviewInfo]=FuncHandle(ParentInfo, CurrentFeatureInfo.Value);

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_Contrast(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
% For the feature description, refer to the documentation on MATLAB function "graycoprops".

%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2.  Haralick, R.M., and L.G. Shapiro. Computer and Robot Vision: Vol. 1, Addison-Wesley, 1992, p. 459.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'Contrast');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_Correlation(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
% For the feature description, refer to the documentation on MATLAB function "graycoprops".

%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2.  Haralick, R.M., and L.G. Shapiro. Computer and Robot Vision: Vol. 1, Addison-Wesley, 1992, p. 459.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'Correlation');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_Energy(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
% For the feature description, refer to the documentation on MATLAB function "graycoprops".

%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2.  Haralick, R.M., and L.G. Shapiro. Computer and Robot Vision: Vol. 1, Addison-Wesley, 1992, p. 459.
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'Energy');


function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_Homogeneity(ParentInfo, Param)
%%%Doc Starts%%%
%-Description: 
% 1.   This feature is equivalent to Homogeneity1 in Hugo's paper.
% 2.  For the feature description, refer to the documentation on MATLAB function "graycoprops".

%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2.  Haralick, R.M., and L.G. Shapiro. Computer and Robot Vision: Vol. 1, Addison-Wesley, 1992, p. 459.
%3. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%4. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'Homogeneity');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_Entropy(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. L. Soh and C. Tsatsoulis. Texture analysis of sar sea ice imagery using gray level co-occurances matrices.
%    IEEE Trans. on Geoscience and Remote Sensing, 37(2):780–795, 1999
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'Entropy');


function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_AutoCorrelation(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. L. Soh and C. Tsatsoulis. Texture analysis of sar sea ice imagery using gray level co-occurances matrices.
%    IEEE Trans. on Geoscience and Remote Sensing, 37(2):780–795, 1999
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'AutoCorrelation');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_Dissimilarity(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. L. Soh and C. Tsatsoulis. Texture analysis of sar sea ice imagery using gray level co-occurances matrices.
%    IEEE Trans. on Geoscience and Remote Sensing, 37(2):780–795, 1999
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'Dissimilarity');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_ClusterShade(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. L. Soh and C. Tsatsoulis. Texture analysis of sar sea ice imagery using gray level co-occurances matrices.
%    IEEE Trans. on Geoscience and Remote Sensing, 37(2):780–795, 1999
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'ClusterShade');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_ClusterProminence(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. L. Soh and C. Tsatsoulis. Texture analysis of sar sea ice imagery using gray level co-occurances matrices.
%    IEEE Trans. on Geoscience and Remote Sensing, 37(2):780–795, 1999
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'ClusterProminence');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_ClusterTendendcy(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. L. Soh and C. Tsatsoulis. Texture analysis of sar sea ice imagery using gray level co-occurances matrices.
%    IEEE Trans. on Geoscience and Remote Sensing, 37(2):780–795, 1999
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'ClusterTendency');


function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_MaxProbability(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. L. Soh and C. Tsatsoulis. Texture analysis of sar sea ice imagery using gray level co-occurances matrices.
%    IEEE Trans. on Geoscience and Remote Sensing, 37(2):780–795, 1999
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'MaxProbability');


function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_DifferenceEntropy(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
%3. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%4. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'DifferenceEntropy');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_Homogeneity2(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
%3. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%4. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'Homogeneity2');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_InformationMeasureCorr1(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
%3. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%4. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'InformationMeasureCorr1');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_InformationMeasureCorr2(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
%3. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%4. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'InformationMeasureCorr2');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_InverseDiffMomentNorm(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
%3. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%4. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'InverseDiffMomentNorm');


function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_InverseDiffNorm(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
%3. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%4. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'InverseDiffNorm');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_InverseVariance(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%2. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'InverseVariance');

function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_SumAverage(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
%3. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%4. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'SumAverage');


function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_SumEntropy(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
%3. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%4. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'SumEntropy');


function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_SumVariance(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Haralick, R.M., K. Shanmugan, and I. Dinstein, "Textural Features for Image Classification", 
%    IEEE Transactions on Systems, Man, and Cybernetics, Vol. SMC-3, 1973, pp. 610-621.
%2. http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
%3. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%4. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'SumVariance');


function [Value, ReviewInfo]=GrayLevelCooccurenceMatrix25_Feature_Variance(ParentInfo, Param)
%%%Doc Starts%%%
%-Reference:
%1. Hugo J. W, Sara Cavalho, et al. Decoding tumour phenotype by noninvasive imaging using a quantitative radiomics approach.
%   Nat. Commun. 2014; 5: 4006.
%2. http://www.nature.com/ncomms/2014/140603/ncomms5006/extref/ncomms5006-s1.pdf
%%%Doc Ends%%%
[Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, 'Variance');



function [Value, ReviewInfo]=ComputeGLCMFeature(ParentInfo, Mode)
DirectionNum=length(ParentInfo.ROIImageInfo.GLCMStruct25);
Offset=ParentInfo.ROIImageInfo.GLCMStruct25(1).Offset;

FeatureValue=zeros(DirectionNum, length(Offset));

for i=1:DirectionNum
    CurrentItem=ParentInfo.ROIImageInfo.GLCMStruct25(i);
    
    GLCM=CurrentItem.GLCM;
        
    if isequal(Mode, 'Homogeneity') ||  isequal(Mode, 'Energy') || isequal(Mode, 'Correlation') || isequal(Mode, 'Contrast')
        %Use Matlab Implementation
        GLCMProp=graycoprops(GLCM, Mode);
        FinalValue=GLCMProp.(Mode);
        
        FeatureValue(i, :)=FinalValue;
    else
        CValue=[];
          
        for j=1:size(GLCM, 3)
            CGLCM=GLCM(:, :, j);
            CGLCM=NormalizeGLCM(CGLCM);
            
            s = size(CGLCM);
            [c, r] = meshgrid(1:s(1),1:s(2));
            r = r(:);
            c = c(:);
            
            switch Mode
                case 'Entropy'
                    TValue = CalculateEntropy(CGLCM);
                case 'AutoCorrelation'
                    TValue = CalculateAutoCorr(CGLCM, r, c);
                case 'Dissimilarity'
                    TValue = CalculateDissim(CGLCM, r, c);
                case 'ClusterShade'
                    TValue = CalculateCluterShade(CGLCM, r, c);
                case 'ClusterProminence'
                    TValue = CalculateCluterP(CGLCM, r, c);
                case 'ClusterTendency'
                    TValue = CalculateCluterT(CGLCM, r, c);
                case 'MaxProbability'
                    TValue = CalculateMaxP(CGLCM);
                case 'DifferenceEntropy'
                    TValue = CalculateDiffEntropy(CGLCM, r, c);
                case 'Homogeneity2'
                    TValue = CalculateHomogeneity2(CGLCM, r, c);
                case 'InformationMeasureCorr1'
                    TValue = CalculateIMC1(CGLCM);
                case 'InformationMeasureCorr2'
                    TValue = CalculateIMC2(CGLCM);
                case 'InverseDiffMomentNorm'
                    TValue = CalculateIDMN(CGLCM, r, c);
                case 'InverseDiffNorm'
                    TValue = CalculateIDN(CGLCM, r, c);
                case 'InverseVariance'
                    TValue = CalculateInverseVariance(CGLCM, r, c);
                case 'SumAverage'
                    TValue = CalculateSumAverage(CGLCM, r, c);
                case 'SumEntropy'
                    TValue = CalculateSumEntropy(CGLCM, r, c);
                case 'SumVariance'
                    TValue = CalculateSumVariance(CGLCM, r, c);
                case 'Variance'
                    TValue = CalculateVariance(CGLCM, r, c);               
            end
            
            CValue=[CValue, TValue];
        end
        FeatureValue(i, :)=CValue; 
    end
        
end

Value=[Offset, FeatureValue'];

ReviewInfo=ParentInfo.ROIImageInfo;
ReviewInfo.MaskData=Value;
ReviewInfo.Description=['GLCM ', Mode];

Direction=cell2mat({ParentInfo.ROIImageInfo.GLCMStruct25.Direction});
Direction=[0, Direction];

Value=[Direction; Value];




%------------Utillites-----------------------------------------------------------------
function glcm = NormalizeGLCM(glcm)  
% Normalize glcm so that sum(glcm(:)) is one.
if any(glcm(:))
  glcm = glcm ./ sum(glcm(:));
end

function M = meanIndex(index,glcm)

M = index .* glcm(:);
M = sum(M);

  
  
function E = CalculateEntropy(glcm)
glcm=glcm(:);

InvalidIndex=find(glcm == 0);
glcm(InvalidIndex)=[];

if ~isempty(glcm)
    E = glcm.*log2(glcm);
    
    E = -sum(E(:));
else
    E=NaN;
end


function E = CalculateAutoCorr(glcm, r, c)
term1 = r.*c;
term2 = glcm;
  
term = term1 .* term2(:);

E = sum(term);

function E = CalculateDissim(glcm, r, c)
term1 = abs(r-c);
term2 = glcm;
  
term = term1 .* term2(:);

E = sum(term);

function E = CalculateCluterShade(glcm, r, c)
mr = meanIndex(r,glcm);
mc = meanIndex(c,glcm);

term1 = (r - mr +c - mc).^3 .* glcm(:);
E = sum(term1);

function E = CalculateCluterP(glcm, r, c)
mr = meanIndex(r,glcm);
mc = meanIndex(c,glcm);

term1 = (r - mr +c - mc).^4 .* glcm(:);
E = sum(term1);

function E = CalculateCluterT(glcm, r, c)
mr = meanIndex(r,glcm);
mc = meanIndex(c,glcm);

term1 = (r - mr +c - mc).^2 .* glcm(:);
E = sum(term1);


function E = CalculateMaxP(glcm)
E=max(glcm(:));

function E=CalculateDiffEntropy(glcm, r, c)
PMat=glcm(:);

DMat=abs(r-c);
[SortDMat, SortIndex]=sort(DMat);

%Cum sum of p(i, j)
SortPMat=PMat(SortIndex);
CumSumP=cumsum(SortPMat);

%X-Y
XMinusY=diff(SortDMat);
XMinusY=[XMinusY; 1];

%P_XMinusY
TempIndex=find(XMinusY > 0);
P_XMinusY=CumSumP(TempIndex);

P_XMinusY=[0;P_XMinusY];
P_XMinusY=diff(P_XMinusY);

%Entropy
P_XMinusY(P_XMinusY==0) = [];

if ~isempty(P_XMinusY)
    E= -sum(P_XMinusY.*log2(P_XMinusY));
else
    E=NaN;
end

function H = CalculateHomogeneity2(glcm,r,c)  
term1 = (1 + (r - c).^2);
term = glcm(:) ./ term1;
H = sum(term);

%InformationMeasureCorr1
function Value = CalculateIMC1(glcm)
%HXY
HXY = CalculateEntropy(glcm);

%HX, HY
PX=sum(glcm, 2);
PY=sum(glcm, 1);
HX = CalculateEntropy(PX);
HY = CalculateEntropy(PY);

%HXY1
PX=repmat(PX, 1, size(glcm, 2));
PY=repmat(PY, size(glcm, 1), 1);

E=glcm.*log2(PX.*PY);

InvalidIndex=find(PX==0 | PY==0);
E(InvalidIndex)=[];

if ~isempty(E) && ~isnan(HX) && ~isnan(HY) && ~isnan(HXY)
    HXY1=-sum(E(:));
    Value=(HXY-HXY1)/max(HX, HY);
else
    Value=NaN;
end


%InformationMeasureCorr2
function Value = CalculateIMC2(glcm)
%HXY
HXY = CalculateEntropy(glcm);

%HXY2
PX=sum(glcm, 2);
PY=sum(glcm, 1);

PX=repmat(PX, 1, size(glcm, 2));
PY=repmat(PY, size(glcm, 1), 1);

E=PX.*PY.*log2(PX.*PY);

InvalidIndex=find(PX==0 | PY==0);
E(InvalidIndex)=[];

if ~isempty(E) &&  ~isnan(HXY)
    HXY2=-sum(E(:));
    Value=sqrt(1-exp(-2*(HXY2-HXY)));
else
    Value=NaN;
end

%InverseDiffMomentNorm
function Value = CalculateIDMN(glcm, r, c)
term1 = 1 + (r - c).^2/(size(glcm, 1)^2);
term = glcm(:) ./ term1;
Value = sum(term);

%InverseDiffNorm
function Value = CalculateIDN(glcm, r, c)
term1 = 1 + abs(r - c)/size(glcm, 1);
term = glcm(:) ./ term1;
Value = sum(term);

%InverseVariance
function Value = CalculateInverseVariance(glcm, r, c)
term1 = (r - c).^2;
term = glcm(:);

InvalidIndex=find(term1 == 0);
term1(InvalidIndex)=[];
term(InvalidIndex)=[];

term=term./term1;

Value = sum(term);

%SumAverage
function Value = CalculateSumAverage(glcm, r, c)
PMat=glcm(:);

SMat=r+c;
[SortSMat, SortIndex]=sort(SMat);

%Cum sum of p(i, j)
SortPMat=PMat(SortIndex);
CumSumP=cumsum(SortPMat);

%X+Y
DXPlusY=diff(SortSMat);
DXPlusY=[DXPlusY; 1];

%P_XPlusY
TempIndex=find(DXPlusY > 0);
XPlusY=SortSMat(TempIndex);

P_XPlusY=CumSumP(TempIndex);
P_XPlusY=[0;P_XPlusY];
P_XPlusY=diff(P_XPlusY);

%Return value
Value=sum(XPlusY.*P_XPlusY);


%SumEntropy
function Value = CalculateSumEntropy(glcm, r, c)
PMat=glcm(:);

SMat=abs(r+c);
[SortSMat, SortIndex]=sort(SMat);

%Cum sum of p(i, j)
SortPMat=PMat(SortIndex);
CumSumP=cumsum(SortPMat);

%X+Y
DXPlusY=diff(SortSMat);
DXPlusY=[DXPlusY; 1];

%P_XPlusY
TempIndex=find(DXPlusY > 0);
P_XPlusY=CumSumP(TempIndex);
P_XPlusY=[0;P_XPlusY];
P_XPlusY=diff(P_XPlusY);

%Entropy
P_XPlusY(P_XPlusY==0) = [];

if ~isempty(P_XPlusY)
    Value= -sum(P_XPlusY.*log2(P_XPlusY));
else
    Value=NaN;
end

%SumVariance
function Value = CalculateSumVariance(glcm, r, c)
PMat=glcm(:);

SMat=abs(r+c);
[SortSMat, SortIndex]=sort(SMat);

%Cum sum of p(i, j)
SortPMat=PMat(SortIndex);
CumSumP=cumsum(SortPMat);

%X+Y
DXPlusY=diff(SortSMat);
DXPlusY=[DXPlusY; 1];

%P_XPlusY
TempIndex=find(DXPlusY > 0);
XPlusY=SortSMat(TempIndex);

P_XPlusY=CumSumP(TempIndex);
P_XPlusY=[0;P_XPlusY];
P_XPlusY=diff(P_XPlusY);

%Entropy
TempIndex=find(P_XPlusY==0);
P_XPlusY(TempIndex) = [];
XPlusY(TempIndex) = [];

if ~isempty(P_XPlusY)
    SE= -sum(P_XPlusY.*log2(P_XPlusY));
        
    term=((XPlusY-SE).^2).*P_XPlusY;    
    Value=sum(term);
else
    Value=NaN;
end

%Variance
function Value = CalculateVariance(glcm, r, c)
Value = CalculateCluterT(glcm, r, c);

