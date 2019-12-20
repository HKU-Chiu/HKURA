root = "C:\Users\Jurgen\Documents\PROJECT ESOTEXTURES\Data\Data_OpenLungAerts\NSCLC-Radiomics\";
csvname = "radiomics_test"; %gets appended with "complete" or "partial"
stopwatch = processCohort(root, csvname); 

function tictocs = processCohort(root, csvname)

    %--- Parse dataset paths, library settings, and predict output size
    disp("parsing data files and settings");
    cohort = load_lungradiomics(root, "roi");
    Npatient = numel(cohort);
    settings = loadSettings("cgita", [], "mvalradiomics", [], "pyradiomics", [], "cerr", [], "ibex", "default"); %struct with one field per library
    flat = struct2array(settings);
    Nlibraries = length(flat);
    Nfeature = sum([flat.Nvariables]);

    %--- Initialize a table for each featureset, then iterate
    disp("starting cohort processing with " + Nlibraries + " supported featuresets");
    featuretable  = table('Size',[Npatient Nfeature],'VariableTypes',repmat({'double'},1,Nfeature)); %Can't initialize with variable names because they're complex to predict, i.e. generated in realtime by the original codebase.
    namelog = strings(size(featuretable));
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
    
    %--- Update table names and save results
        names = namelog(idx, :);
        prefixes = strings(1, Nfeature);
        prefixes(cerrvars) = "cerr_";
        prefixes(ibexvars) = "ibex_";
        prefixes(mvalvars) = "rad_";
        prefixes(cgitavars) = "cgita_";
        prefixes(pyradvars) = "pyrad_";
        names = prefixes + names;
        %names = "V" + string(1:Nfeature);
        %names(cerrvars) = "V" + string(cerrvars);
        featuretable.Properties.VariableNames = names; 
        csvname = csvname + "_features_completed";
        disp('Completed analysis, saving output...');
        saneSave();
    
    %--- Utility functions    
    function saneSave()
        namelog(all(namelog == "", 2),:) = []; %remove empty rows
        if(isempty(namelog))
            disp('Oops, no output was generated, skipping save');
        else    %rows should be constant
            assert(size(unique(namelog, 'rows'), 1) == 1, 'CUSTOM:NamesVary', namelog);
            outNamexlsx = strcat(csvname, '.xlsx');
            if exist(outNamexlsx, 'file')==2
                warning("Overwriting existing xlsx file");
                try delete(outNamexlsx); catch, end
            end
            writetable(featuretable, outNamexlsx,'FileType','spreadsheet'); 
            save(strcat(csvname, '.mat'),'featuretable', 'tictocs', 'namelog', 'settings'); 
            disp(['Finished saving in ' pwd]);
        end
    end
    
    function handleError(e)
        if strcmpi(e.identifier,'CUSTOM:loadfail')
            warning(e.message);
            disp('skipping patient...');
        elseif strcmpi(e.identifier,'CUSTOM:NamesVary') %Corrupt output, throw
                disp('Feature is named inconsistently over iterations');
                disp(strsplit(e.message')); 
                rethrow(e);
        else %Valid output, save what we have before throwing. 
            if idx > 1
                timestamp = [date '_' datestr(now,'HH-MM-SS')];
                csvname = csvname + timestamp;
                disp('An error occured, saving partial results');
                saneSave();
            end
            rethrow(e);
        end
    end
end