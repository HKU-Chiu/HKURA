function settings = loadSettings(varargin)
%For each library listed, get useful setting fields: file, filehash, size
% Returns a nested struct with one top-level field for each (used) library.
%
% settings = loadSettings(varargin)
%
% input pairs library name + settings filepath string. E.g:
% loadsettings("ibex", [], "cerr", "home/cerrsettings.json") will process 2
% featuresets with a single settings file each.
%
% An empty bracket will use the default settings. 
%
% Currently supports 5 library IDs: cerr, mvalradiomics, pyradiomics, ibex,
% cgita (case insensitive). Repeats of the same library are not yet
% supported.

p = inputParser;
%validationFcn = @(x) assert(ischar(x) || isstring(x), "Only accepts paths to setting files");
addParameter(p, 'cerr', []);
addParameter(p, 'mvalradiomics', []);
addParameter(p, 'pyradiomics', []);
addParameter(p, 'ibex', []);
addParameter(p, 'cgita', []);
parse(p, varargin{:});

all = string(p.Parameters);
ex = string(p.UsingDefaults);
used = all(~contains(all, ex));

parser.cerr = @parseCerr;
parser.cgita = @parseCgita;
parser.mvalradiomics = @parseMvalradiomics;
parser.pyradiomics = @parsePyradiomics;
parser.ibex = @parseIbex;

for library = used
    file = p.Results.(library);
    if (isempty(file) || file == "")
        file = "default";
    end
    settings.(library) = parser.(library)(file);
end

end

function s = parseCerr(f)
    if strcmpi(f, "default")
        s.file = "default_cerrsettings.json";
        s.Nvariables = 143;
        s.filehash = [];
    end
    s.parameters = getRadiomicsParamTemplate(s.file); 
    s.parameters.toQuantizeFlag = true;
end

function s = parseCgita(f)
    if strcmpi(f, "default")
        s.file = "feature_settings.mat";
        s.Nvariables = 108;
        s.filehash = [];
    end 
    
    try
        assert(logical(exist(s.file,'file')), "CUSTOM:nosettings", "Can't find file by the name: " + s.file);
    catch
        create_default_feature_settings(s.file);
    end
        s.parameters = load(s.file);
        
        %additional (implicit) cgita parameters
        s.parameters.digitization_type = 'uint16';
        
        
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
    end
    s.parameters = p;
end

function s = parsePyradiomics(f)
    if strcmpi(f, "default")
        s.file = "default";
        s.Nvariables = 107;
        s.filehash = [];
        s.parameters.bincount = 64;
    end
end

function s = parseIbex(f)
    if strcmpi(f, "default")
        s.file = "Reference_IBEX_Featureset.mat";
        s.parameters = ibexLoadSettings(s.file);
        s.Nvariables = s.parameters.Nfeatures;
        s.filehash = [];
    end
end