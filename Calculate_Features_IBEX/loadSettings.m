function settings = loadSettings(fname)
    varname = "FeatureSetsInfo";
    if isempty(fname) %Create a default, To alter future defaults please read generateIBEXsettings.m
        defaultname = "IBEX_features_default.mat";
        fname = defaultname;
	else
		[~,~,ext] = fileparts(fname);
		assert(ext == ".mat", "CUSTOM:nosettings", "Settings file invalid: doesn't have .mat extension");
		assert(logical(exist(fname,'file')), "CUSTOM:nosettings", "Can't find the non-default file with the name: " + fname);
	end
 
	if logical(exist(fname,'file'))
	settings = load(fname);
	assert(isfield(settings, varname), "CUSTOM:nosettings", "Settings file did not contain expected variable: " + varname)
	settings.file = fname;
	else
	warning("No feature settings file detected. Generating default featureset and saving file...")
		settings.(varname) = generateIBEXsettings();
		try 
			save(defaultname, varname);
			settings.file = defaultname;
			disp("Saved " + defaultname + "to: " + pwd);
		catch
			warning("Failed save to " + pwd())
			settings.file = [];
		end
	end

    [settings.Nfeatures, settings.scalarOnly] = parseFeatureset(settings.(varname));
    assert(settings.Nfeatures > 0, "Empty or corrupted featureset?");
    disp("Predicted number of features: " + settings.Nfeatures)
	
end