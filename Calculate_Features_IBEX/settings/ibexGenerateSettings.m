function FeatureSetsInfo = generateIBEXsettings(saveflag)
%Generate a feature settings strucutre compatible with IBEX
%   settings = ibexGenerateSettings(saveflag)
% 
%  saveflag is boolean, if true will save it as "IBEX_features_default.mat"
%  that contains the field FeatureSetsInfo
%
% Under construction, currently only suitable for predicting featureset
% size.


fields =     [  "Preprocess"
                "PreprocessStore"
                "Category"
                "CategoryStore"
                "Feature"
                "FeatureStore"
                "Comment"
                "CreationDate"];

categories = [  "GradientOrientHistogram"
                "GrayLevelCooccurenceMatrix25"
                "GrayLevelCooccurenceMatrix3"
                "GrayLevelRunLengthMatrix25"
                "IntensityDirect"
                "IntensityHistogram"
                "IntensityHistogramGaussFit"
                "NeighborIntensityDifference25"
                "NeighborIntensityDifference3"
                "Shape"];

% counts = tabulate(selectCategory);
% Nfeat = nonscalarLUT(counts(:,1)) .* counts(:,2);          
%--- Default featureset            
selectCategoryID = 1:10;
selectCategoryID(7) = [];

selectCategory = categories(selectCategoryID);
N = length(selectCategory);

selectCategoryStore = {struct("nBins", 64)...%1
                            ,...
                            struct("Symmetric", true,... %2
                            "AdaptLimitLevel", false,...
                            "NumLevels", 64,...
                            "GrayLimits", [],...
                            "Direction", [0, 45, 90, 135],...
                            "Offset", [1])... 
                            ,...
                            struct("Symmetric", true,... %3
                            "AdaptLimitLevel", false,...
                            "NumLevels", 64,...
                            "GrayLimits", [],...
                            "Direction", [0:12],...
                            "Offset", [1])... 
                            ,...
                            struct("AdaptLimitLevel", false,...%4
                            "NumLevels", 64,...
                            "GrayLimits", [],...
                            "Direction", [0, 90],...
                            "Offset", [1])... 
                            ,...
                            struct(... %5
                            )... 
                            ,...
                            struct(... %6
                            )...
                            ,...
                            struct(...%7
                            )...
                            ,...
                            struct(...%8
                            )...
                            ,...
                            struct(...%9
                            )...
                            ,...
                        };
assert(N == length(selectCategoryStore), "Number of settings doesn't match the number of categories")


featuresetList = {{'InterQuartileRange';'Kurtosis';'MeanAbsoluteDeviation';'MedianAbsoluteDeviation';'Percentile';'PercentileArea';'Range';'Skewness'},...%1
        {'AutoCorrelation';'ClusterProminence';'ClusterShade';'ClusterTendendcy';'Contrast';'Correlation';'DifferenceEntropy';'Dissimilarity';'Energy';'Entropy';'Homogeneity';'Homogeneity2';'InformationMeasureCorr1';'InformationMeasureCorr2';'InverseDiffMomentNorm';'InverseDiffNorm';'InverseVariance';'MaxProbability';'SumAverage';'SumEntropy';'SumVariance';'Variance'},...%2
        {'AutoCorrelation';'ClusterProminence';'ClusterShade';'ClusterTendendcy';'Contrast';'Correlation';'DifferenceEntropy';'Dissimilarity';'Energy';'Entropy';'Homogeneity';'Homogeneity2';'InformationMeasureCorr1';'InformationMeasureCorr2';'InverseDiffMomentNorm';'InverseDiffNorm';'InverseVariance';'MaxProbability';'SumAverage';'SumEntropy';'SumVariance';'Variance'},...%3
        {'GrayLevelNonuniformity';'HighGrayLevelRunEmpha';'LongRunEmphasis';'LongRunHighGrayLevelEmpha';'LongRunLowGrayLevelEmpha';'LowGrayLevelRunEmpha';'RunLengthNonuniformity';'RunPercentage';'ShortRunEmphasis';'ShortRunHighGrayLevelEmpha';'ShortRunLowGrayLevelEmpha'},...%4
        {'Energy';'EnergyNorm';'GlobalEntropy';'GlobalMax';'GlobalMean';'GlobalMedian';'GlobalMin';'GlobalStd';'GlobalUniformity';'InterQuartileRange';'Kurtosis';'LocalEntropyMax';'LocalEntropyMean';'LocalEntropyMedian';'LocalEntropyMin';'LocalEntropyStd';'LocalRangeMax';'LocalRangeMean';'LocalRangeMedian';'LocalRangeMin';'LocalRangeStd';'LocalStdMax';'LocalStdMean';'LocalStdMedian';'LocalStdMin';'LocalStdStd';'MeanAbsoluteDeviation';'MedianAbsoluteDeviation';'Percentile';'Range';'RootMeanSquare';'Skewness';'Variance'},...%5
        {'InterQuartileRange';'Kurtosis';'MeanAbsoluteDeviation';'MedianAbsoluteDeviation';'Percentile';'PercentileArea';'Range';'Skewness'},...%6
        {'Busyness';'Coarseness';'Complexity';'Contrast';'TextureStrength'},...%7
        {'Busyness';'Coarseness';'Complexity';'Contrast';'TextureStrength'},...%8
        {'Compactness1';'Compactness2';'Convex';'ConvexHullVolume';'ConvexHullVolume3D';'Mass';'Max3DDiameter';'MeanBreadth';'NumberOfObjects';'NumberOfVoxel';'Orientation';'SphericalDisproportion';'Sphericity';'SurfaceArea';'SurfaceAreaDensity';'Volume';'VoxelSize'},...%9
        };
featurelistSizes = cellfun(@length, featuresetList);
assert(N == length(featuresetList), "Number of featuresets doesn't match the number of categories")


featuresetOptions = cell(1,N);
fso = struct('Name',"",'Value',"");
percentile = struct('Percentile', [5:5:95]);
for idx = 1:N
    %initialize struct array
    featureset = featuresetList{idx};
    Nopt = length(featureset);
    clear sa;
    sa(1, Nopt) = fso; 
    %Populate Name & Value fields
    empty = repmat({[]},1,Nopt);
    if ((selectCategoryID(idx) == 1) | (selectCategoryID(idx) == 5) | (selectCategoryID(idx) == 6))
        perc = cellfun(@(x) strcmp('Percentile',x), featureset);
        percarea = cellfun(@(x) strcmp('PercentileArea',x), featureset);
        if any(perc)
            empty{perc} = percentile;
        end
        if any(percarea)
            empty{percarea} = percentile;
        end
    end
    [sa.Value] = empty{:};
    [sa.Name] = featureset{:};
    featuresetOptions{idx} = sa;
end
                    
nvpairs = [cellstr(fields)'; repmat("", 1, length(fields))];
input = struct(nvpairs{:});
FeatureSetsInfo(N, 1) = input;
for idx = 1:N
    FeatureSetsInfo(idx).Category = selectCategory(idx); %, CS, F, FS, Comment, Date);
    FeatureSetsInfo(idx).CategoryStore = struct('Name', char(selectCategory(idx)), 'Value', selectCategoryStore{idx});
    FeatureSetsInfo(idx).Feature = featuresetList{idx};
    FeatureSetsInfo(idx).FeatureStore = featuresetOptions{idx};
end

if saveflag
    save("IBEX_features_default.mat", "FeatureSetsInfo");
end

end