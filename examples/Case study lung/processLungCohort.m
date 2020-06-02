% Radiomics Case Study using "NSCLC-Radiomics" CT dataset from TCIA
% By J.T.J. van Lunenburg
% As part of the HKU Radiomics Archive platform, available on gitgub.com
%
% Purpose: 
% 1) Showcase the usage for automated extraction of multiple featuresets.
% 2) Evaluate codebase performace (record times per featureset per patient)
% 3) Analyze implementation differences between similar features.
% 4) Repeat the clinical phenotype clustering from literature with a larger featureset.

root = "C:\Path\to\folder\NSLC-Radiomics";
csvnamebase = "radiomics_test"; 
output = processCohort(root, csvnamebase); 

function varargout = processCohort(root, csvnamebase)

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
    
    for idx = 1:Npatient
        disp(['loading patient: ' cohort(idx).patientID ' (' num2str(idx) ' of ' num2str(Npatient) ')']);
        try
        [im, mask] = loadPatient(cohort(idx));
        catch e
            if strcmpi(e.identifier,'CUSTOM:loadfail')
                warning(e.message);
            else
                warning("Unknown load error occurred: " + e.message);
            end 
            disp('Load error, skipping patient...');
            continue;
        end
        
        try
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
        csvname = csvnamebase + "_features_completed";
        disp('Completed analysis, saving output...');
        saneSave()
        
    %--- Utility functions    
    function finalizeTable()
        prefixes = strings(1, Nfeature);
        prefixes(cerrvars) = "cerr_";
        prefixes(ibexvars) = "ibex_";
        prefixes(mvalvars) = "rad_";
        prefixes(cgitavars) = "cgita_";
        prefixes(pyradvars) = "pyrad_";
        
        varnames = prefixes + namelog(1, :);
        
        rulebreakers = arrayfun(@(X) length(char(X)), varnames) >  63;
        varnames(rulebreakers) = extractBefore(varnames(rulebreakers), 63); %need some way to ensure uniqueness post-crop
        featuretable.Properties.VariableNames = varnames; 
        PatientID = cell2table(transpose({cohort.patientID}));
        featuretable = [PatientID, featuretable];
    end
    
    function saneSave()
        %--- Dont save if all patients skipped, or if output seems corrupt.
        namelog(all(namelog == "", 2),:) = []; %remove empty rows (skipped patients)
        if(isempty(namelog))
            disp('Oops, no output was generated, skipping save');
        else    
            varargout{1} = tictocs;
            if size(unique(namelog, 'rows'), 1) ~= 1 %Corrupt output, throw
                %disp(strsplit([namelog(:)]')); 
                throw(MException('CUSTOM:NamesVary', 'Feature is named inconsistently over iterations'));
            end
            try
                outNamexlsx = strcat(csvname, '.xlsx');
                if exist(outNamexlsx, 'file')==2
                    warning("Attempting to overwrite existing xlsx file:" + outNamexlsx);
                    try delete(outNamexlsx); catch, end
                end
                finalizeTable();
                writetable(featuretable, outNamexlsx,'FileType','spreadsheet'); 
                save(strcat(csvname, '.mat'),'featuretable', 'tictocs', 'namelog', 'settings'); 
                disp(['Finished saving in ' pwd]);
            catch
                disp("A problem occurred during save, outputting features as return value")
                varargout{2} = featuretable;
                varargout{3} = settings;
                varargout{4} = namelog;
            end
            
        end
    end
    
    function handleError(e)
            if idx > 1 %save what we have before throwing.
                timestamp = [date '_' datestr(now,'HH-MM-SS')];
                csvname = strcat(csvnamebase, timestamp);
                disp('An error occured, saving partial results');
                saneSave();
            end
            rethrow(e);
    end
end