% Radiomics Case Study using "NSCLC-Radiomics" CT dataset from TCIA
% By J.T.J. van Lunenburg
% As part of the HKU Radiomics Archive platform, available on gitgub.com
%
% Purpose: 
% 1) Showcase the usage for automatic processing with multiple featuresets.
% 2) Evaluate codebase performace (record times per featureset per patient)
% 3) Analyze implementation differences between similar features.
% 4) Repeat the clinical phenotype clustering from literature with a larger featureset.

root = "C:\Users\Jurgen\Documents\PROJECT ESOTEXTURES\Data\Data_OpenLungAerts\NSCLC-Radiomics\";
csvname = "radiomics_test"; %gets appended with "complete" or "partial"
output = processCohort(root, csvname); 

function varargout = processCohort(root, csvname)

    %--- Parse dataset paths, read library settings, and predict output size
    disp("parsing data files and settings");
    cohort = load_lungradiomics(root, "roi");
    settings = loadSettings("cgita", [],...
        "mvalradiomics", [],...
        "pyradiomics", [],...
        "cerr", [],...
        "ibex", "default"); %nested struct with one toplvl field per library
    flat = struct2array(settings);
    Nlibraries = length(flat);
    Nfeature = sum([flat.Nvariables]);
    Npatient = numel(cohort);

    %--- Initialize a table for the total featureset, then iterate
    disp("starting cohort processing with " + Nlibraries + " supported featuresets");
    featuretable  = table('Size',[Npatient Nfeature],'VariableTypes',repmat({'double'},1,Nfeature)); %Can't initialize with variable names because they're complex to predict, i.e. generated in realtime by the original codebase.
    namelog = strings(size(featuretable)); %store the returned variable names for sanity checking
    cerrvars = 1:settings.cerr.Nvariables;
    ibexvars = (1 + max(cerrvars)):(settings.ibex.Nvariables + max(cerrvars));
    mvalvars = (1 + max(ibexvars)):(settings.mvalradiomics.Nvariables + max(ibexvars));
    cgitavars = (1 + max(mvalvars)):(settings.cgita.Nvariables + max(mvalvars));
    pyradvars = (1 + max(cgitavars)):(settings.pyradiomics.Nvariables + max(cgitavars));
    tictocs = zeros(Npatient, 5);
    
    for idx = 116:Npatient
        disp(['loading patient: ' cohort(idx).patientID ' (' num2str(idx) ' of ' num2str(Npatient) ')']);

        try
        [im, mask] = loadPatient(cohort(idx));
        
        disp("Calculating CERR features")
        tic; [namelog(idx, cerrvars), featuretable(idx, cerrvars)] = cerrFeatures(im, mask, settings.cerr);
        tictocs(idx, 1) = toc;
        
        disp("Calculating IBEX features")
        tic; [namelog(idx, ibexvars), featuretable(idx, ibexvars)] = ibexFeatures(im, mask, settings.ibex);
        tictocs(idx, 2) = toc;
        
        disp("Calculating RadiomicsToolbox features")
        tic; [namelog(idx, mvalvars), featuretable(idx, mvalvars)] = mvalFeatures(im, mask, settings.mvalradiomics);
        tictocs(idx, 3) = toc;
        
        disp("Calculating CGITA features")
        tic; [namelog(idx, cgitavars), featuretable(idx, cgitavars)] = cgitaFeatures(im, mask, settings.cgita);
        tictocs(idx, 4) = toc;
        
        disp("Calculating Pyradiomics features")
        tic; [namelog(idx, pyradvars), featuretable(idx, pyradvars)] = pyradFeatures(im, mask, settings.pyradiomics);
        tictocs(idx, 5) = toc;
        
        catch err
            handleError(err)
        end
    end
    
    %--- Update output file name. Then save results.
        csvname = csvname + "_features_completed";
        disp('Completed analysis, saving output...');
        saneSave();
    
    %--- Utility functions    
    function finalizeTable()
        varnames = namelog(1, :);
        prefixes = strings(1, Nfeature);
        prefixes(cerrvars) = "cerr_";
        prefixes(ibexvars) = "ibex_";
        prefixes(mvalvars) = "rad_";
        prefixes(cgitavars) = "cgita_";
        prefixes(pyradvars) = "pyrad_";
        
        varnames = prefixes + varnames;
        rulebreakers = arrayfun(@(X) length(char(X)), varnames) >  63;
        varnames(rulebreakers) = extractBefore(varnames(rulebreakers), 63);
        featuretable.Properties.VariableNames = varnames; 
        PatientID = cell2table(transpose({cohort.patientID}));
        featuretable = [PatientID, featuretable];
    end
    
    function saneSave()
        namelog(all(namelog == "", 2),:) = []; %remove empty rows (skipped patients)
        if(isempty(namelog))
            disp('Oops, no output was generated, skipping save');
        else    
            assert(size(unique(namelog, 'rows'), 1) == 1, 'CUSTOM:NamesVary', [namelog(:)]); %name rows should be constant
            outNamexlsx = strcat(csvname, '.xlsx');
            if exist(outNamexlsx, 'file')==2
                warning("Attmpting to overwrite existing xlsx file:" + outNamexlsx);
                try delete(outNamexlsx); catch, end
            end
            varargout{1} = tictocs;
            try
                finalizeTable();
                writetable(featuretable, outNamexlsx,'FileType','spreadsheet'); 
                save(strcat(csvname, '.mat'),'featuretable', 'tictocs', 'namelog', 'settings'); 
                disp(['Finished saving in ' pwd]);
            catch
                disp("A problem occurred during save, outputting features to return value")
                varargout{2} = featuretable;
                varargout{3} = settings;
                varargout{4} = namelog;
            end
            
        end
    end
    
    function handleError(e)
        if strcmpi(e.identifier,'CUSTOM:loadfail')
            warning(e.message);
            disp('Load error, skipping patient...');
        elseif strcmpi(e.identifier,'CUSTOM:NamesVary') %Corrupt output, throw
                disp('Feature is named inconsistently over iterations');
                disp(strsplit(e.message')); 
                rethrow(e);
        else %Valid output, save what we have before throwing. 
            if idx > 1
                timestamp = [date '_' datestr(now,'HH-MM-SS')];
                csvname = strcat(csvname, timestamp);
                disp('An error occured, saving partial results');
                saneSave();
            end
            rethrow(e);
        end
    end
end