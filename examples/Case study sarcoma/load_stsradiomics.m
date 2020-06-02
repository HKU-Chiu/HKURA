function cohort = load_stsradiomics(rootdir, varargin)
% Parse the Soft-Tissue Sarcome data files for subsequent loading. 
% Source: http://doi.org/10.7937/K9/TCIA.2015.7GO2GSKS
%
% Returns an array of patient structs, each with 3 fields: patientID, image
% (path to CT dicom folder), roi (path to single roi dicom file). roi is
% empty if there is no RTSTRUCT file.
% Based on the default folder structure from TCIA:
% [Root]
% - [Patients]
% -- [Single Study Folder]
% --- [roifolder]
% --- [imagefolder]
%
% Usage: cohort = load_stsradiomics(rootdir[, filter])
%
% rootdir: the string/character path to Root.
% filter: an optional argument to subset based on ROI presence,
% it allows 3 possible values: "all", "roi", "noroi". It defaults to "all".

if nargin > 1
    filter = lower(varargin{1});
    assert(any(strcmp(filter, ["all", "roi", "noroi"])), "")
else
    filter = "all";
end

patientfolders = getFullFolders(rootdir);
patientIDs = getFolders(rootdir); %alt: [~, ID, dotname] = cellfun(@fileparts, patientfolders, 'Uni', false);
N = length(patientIDs);
assert(N == numel(patientfolders), "Problem parsing folder structure");
  
cohort = struct("patientID",{},"image",{},"roi",{});
for ID = 1:N
    s.patientID = patientIDs{ID};
    s.image = {};
    s.roi = {};
    
    subfolders = getFullFolders(patientfolders{ID}); %doesn't handle recursive wildcards
    subfolders = getFullFolders(subfolders{1}); %...but we only need to go 1 level down
    Nsub = length(subfolders);
    switch Nsub % Visual inspection indicates not all folders have a ROI.
        case 2
            % ROI and image folders can't be discriminated by name. 
            % Assuming single roi.dcm vs multiple .dcm.
            dcm_a = getFullFiles(subfolders{1});
            dcm_b = getFullFiles(subfolders{2});
            if (numel(dcm_a) == 1)
                s.roi = dcm_a{1};
                s.image = subfolders{2};
            elseif (numel(dcm_b)==1)
                s.roi = dcm_b{1};
                s.image = subfolders{1};
            else
                if ~strcmp(filter, "noroi")
                disp("Skipping due to unexpected number of ROIs:" + s.patientID)
                continue
                end
            end
        case 1
            s.image = subfolders{1};
        otherwise
            disp("Unexpected folder structure in: " + s.patientID, ", skipping");
            continue;
    end
    switch filter
        case "roi"
            if ~isempty(s.roi)
                cohort(end+1) = s;
            end
        case "noroi"
            if isempty(s.roi)
                cohort(end+1) = s;
            end
        otherwise
            cohort(end+1) = s;
    end

            
        
end