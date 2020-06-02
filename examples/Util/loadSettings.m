function settings = loadSettings(varargin)
%Load a datastructure with settings for each featureset in HKURA
% Returns a nested struct with one top-level field per loaded library.
% Each library has 4 subfields: file, filehash, Nvariables, parameters
% The "parameters" field may contain unique subfields specific to a featureset
%
% settings = loadSettings(varargin)
%
% input pairs library name + settings filepath string. E.g:
% loadsettings("ibex", [], "cerr", "home/cerrsettings.json") will process 2
% featuresets with a single settings file each. 
%
% An empty bracket will use the default settings. To load all default settings use loadSettings("all"). 
%
% Currently supports 5 library IDs: cerr, mvalradiomics, pyradiomics, ibex,
% cgita (case insensitive). Repeats of the same library are not yet
% supported. Presently, predicting a non-default featureset size is only
% supported for IBEX.

p = inputParser;
%validationFcn = @(x) assert(ischar(x) || isstring(x), "Only accepts paths to setting files");
addParameter(p, 'cerr', []);
addParameter(p, 'mvalradiomics', []);
addParameter(p, 'pyradiomics', []);
addParameter(p, 'ibex', []);
addParameter(p, 'cgita', []);
all = string(p.Parameters);
parseskip = false;

if (nargin == 1 && strcmpi(varargin{1}, "all"))
    used = all;
    parseskip = true;
else
    parse(p, varargin{:});
    ex = string(p.UsingDefaults);
    used = all(~contains(all, ex));
end

filereader.cerr = @parseCerr;
filereader.cgita = @parseCgita;
filereader.mvalradiomics = @parseMvalradiomics;
filereader.pyradiomics = @parsePyradiomics;
filereader.ibex = @parseIbex;

for library = used
    if ~parseskip 
        file = p.Results.(library);
        if (isempty(file) || file == "")
            file = "default";
        end
    else
        file = "default";
    end

    settings.(library) = filereader.(library)(file);
end

end

function s = parseCerr(f)
    if strcmpi(f, "default")
        s.file = "default_cerrsettings.json";
        s.Nvariables = 143;
        s.filehash = [];
    else
        s.file = f;
    end
    
    s.parameters = getRadiomicsParamTemplate(s.file); %sane loader
    s.parameters.toQuantizeFlag = true;
    s.parameters.meta.xres = 1;
    s.parameters.meta.yres = 1;
    s.parameters.meta.zres = 1;
    
    if ~strcmpi(f, "default")
        s.Nvariables = [];
        s.filehash = [];
    end
end

function s = parseCgita(f)
    if strcmpi(f, "default")
        s.file = "feature_settings.mat";
        s.Nvariables = 108;
        s.filehash = [];
    else
        s.file = f;
    end 
    
    try
        assert(logical(exist(s.file,'file')), "CUSTOM:nosettings", "Can't find file by the name: " + s.file);
    catch
        create_default_feature_settings(s.file);
    end
        s.parameters = load(s.file); %raw load, no sanity check
        s.parameters.digitization_type = 'uint16';
    
    if ~strcmpi(f, "default")
        s.Nvariables = [];
        s.filehash = [];
    end     
end

function s = parseMvalradiomics(f)
    if strcmpi(f, "default")
        s.file = "default";
        s.Nvariables = 52;
        s.filehash = [];
        p.bincount = 64;
        p.quantization = 'Uniform';
        p.planeRes    = 1; %mm
        p.sliceRes    = 1; %mm
        p.tgtIsoRes   = 1; %mm
        s.parameters = p;
    else
        s.file = f;
        assert(logical(exist(s.file,'file')), "CUSTOM:nosettings", "Can't find file by the name: " + s.file);
        s.parameters = load(s.file); %raw load, no sanity check
    end
    
    if ~strcmpi(f, "default")
        s.Nvariables = [];
        s.filehash = [];
    end     
end

function s = parsePyradiomics(f)
    if strcmpi(f, "default")
        s.file = "Calculate_Features_PYRAD/settings/default.yaml";
        assert(logical(exist(s.file,'file')), "CUSTOM:nosettings", "Can't find file by the name: " + s.file);
        s.Nvariables = 107;
        s.filehash = [];
        s.parameters.kwa = s.file;
        %s.parameters.bincount = 64;
        %s.parameters.kwa = pyargs('binCount', uint8(s.parameters.bincount));
    else
        s.file = f;
        assert(logical(exist(s.file,'file')), "CUSTOM:nosettings", "Can't find file by the name: " + s.file);
        s.parameters.kwa = s.file;
    end
    
    if ~strcmpi(f, "default")
        s.Nvariables = [];
        s.filehash = [];
    end     
end

function s = parseIbex(f)
    if strcmpi(f, "default")
        s.file = "Reference_IBEX_Featureset.mat";
        s.filehash = [];
    else
        s.file = f;    
    end
  
    s.parameters = ibexLoadSettings(s.file); %sane loader
    s.Nvariables = s.parameters.Nfeatures;
    
    if ~strcmpi(f, "default")
        s.filehash = [];
    end     
end