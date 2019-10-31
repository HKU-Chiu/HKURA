function [N, scalarOnly] = parseFeatureset(mat)
%See generateIBEXsettings.m for more information on the IBEX featureset
%structure. It may help to load an example featureset and browse it in MATLAB.
    categories = string({mat.Category});
    featuresetList = {mat.Feature};
    featuresetSizes = cellfun(@length, featuresetList);
    scalarOnly = true; 
    
    %only 3 categories affect feature output count: 2, 3, 4
    NfeatFromA = 0;
    nonscalarA = (categories == "GrayLevelCooccurenceMatrix25") | (categories == "GrayLevelCooccurenceMatrix3") | (categories == "GrayLevelRunLengthMatrix25");
    if any(nonscalarA)
        scalarOnly = false;
        categorySettings = {mat.CategoryStore};
        multipliersA = cellfun(@getMultiplier, categorySettings(nonscalarA)); 
        NfeatFromA = sum(multipliersA .* featuresetSizes(nonscalarA));
    end
   
    %features with a percentile and quantile vectors also affect output count. Assuming these are
    %only in 3 **other** IBEX categories: 1, 5, 6 
    NfeatFromB = sum(featuresetSizes(~nonscalarA));
    extra = 0;
    nonscalarB = (categories == "GradientOrientHistogram") | (categories == "IntensityDirect") | (categories == "IntensityHistogram");
    if any(nonscalarB)
        scalarOnly = false;
        featuresetSettings = {mat.FeatureStore}; %cell array of struct arrays
        perc = cellfun(@(x) strcmp(x,"Percentile") | strcmp(x,"PercentileArea"), featuresetList(nonscalarB),'Uni', false);
        quant = cellfun(@(x) strcmp(x,"Quantile"), featuresetList(nonscalarB), 'Uni', false);
        if any(cellfun(@any, perc))
           extra = extra + sum(cellfun(@countP, featuresetSettings(nonscalarB), perc));
        end
        if any(cellfun(@any, quant))
            extra = extra + sum(cellfun(@countQ, featuresetSettings(nonscalarB), quant));
        end
        NfeatFromB = NfeatFromB + extra;
    end
    
    N = NfeatFromA + NfeatFromB;
    assert(isscalar(N), "Feature count is not a scalar");
    
    function C = countP(a, b) 
        percentileArrays = cellfun(@(x) getfield(x, "Percentile"),{a(b).Value}, 'Uni', false); %Get percentile vectors given an IBEX FeatureStore struct array and a logical index, assumes every percentile feature has at least one percentile Value
        C = sum(cellfun(@length, percentileArrays)) - length(percentileArrays);
    end

    function C = countQ(a, b) %similar to countP. Could combine quant and perc, however, their features appear to be redundant; quantile may be dropped in the future.
        qArrays = cellfun(@(x) getfield(x, "Quantile"),{a(b).Value}, 'Uni', false); 
        C = sum(cellfun(@length, qArrays)) - length(qArrays);
    end

    function C = getMultiplier(s)
        if isfield(s.Value, "Offset")
            B = numel(s.Value.Offset);
        else
            B = 1; %run-length
        end
        C = (1 + numel(s.Value.Direction)) * B; %the +1 is for rot. invariant (333)
    end

end