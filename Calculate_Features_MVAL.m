%--- DESCRIPTION
% Standard script template. Executes 'mainfcn' (name of toplevel m-file).
%
% calculates radiomic features for our esophagus dataset
% Output is saved as xlsx and .mat
% Dependencies assumed be inside folder: DEPEND/[mfilename] 
% (derived from mvallieres toolbox master branch, github commit: 94461c6) 

PARAM.data_root     = "C:\Users\Jurgen\Documents\PROJECT ESOTEXTURES\Data_Eso";
PARAM.settings.file = [];
PARAM.chooseDepend  = false;  %false: assume default depend locations
PARAM.fileprefix    = 'mval'; %output name prefix
mainFunctionName    = "mainfcn";

main(str2func(mainFunctionName), PARAM);




%-----------------------------------------
%-----------------------------------------
function main(mainfcn, param)
	startDir = setEnvironment(param.chooseDepend); 
	alwaysRunOnTerminate = onCleanup(@()cleanupFcn(startDir));
	mainfcn(param);
end

function cleanupFcn(start)
%Use onCleanup object because ctrl+C isn't handled by try/catch 
    cd(start);
    try resetPath(); catch, end
	disp([newline 'Environment reverted to pre-script state']);
end

function startDir = setEnvironment(chooseFlag) 
    startDir = pwd;
    freshScript();
    %Assumes a folder called 'DEPEND' exists
    try
    assert(~chooseFlag,'CUSTOM:NotDefaultLocation','script chooses to override default folder location');
    dependFolder = fullfile(fileparts(mfilename('fullpath')),'DEPEND',mfilename); %Scenario: Depend is in mfile folder
    if ~isFolder(dependFolder)
        dependFolder 	= [pwd() '\DEPEND\' mfilename]; %Scenario: Depend is in pwd, but script was run from elsewhere 
        if ~isFolder(dependFolder)
            dependFolder = what('DEPEND'); %Scenario: script was run, but Depend isn't in pwd or mfile-folder: search path (non-recursive)
            if numel(dependFolder ==1)
                dependFolder = fullfile(dependFolder.path, mfilename);
                warning('Dependency folder DEPEND/[scriptname] not in expected location');
            end
            %caution, see https://www.mathworks.com/matlabcentral/answers/347892-get-full-path-of-directory-that-is-on-matlab-search-path
            assert(isFolder(dependFolder),'CUSTOM:NotDefaultLocation',['dependency folder not found on path or pwd (' pwd ')']); 
        end
    end
    catch err
        if strcmpi(err.identifier,'CUSTOM:NotDefaultLocation')
        answer = questdlg('Dependency folder not found, manually select?');
            if strcmpi(answer,'yes')
                dependFolder = uigetdir('DEPEND'); 
                if ~ischar(dependFolder),resetThrow();end
            else
                resetThrow()
            end
        else
            resetThrow()
        end
    end
    disp(['Using dependencies under: ' dependFolder]); 
    addpath(genpath(dependFolder)); 
    
    function resetThrow()
        cd(startDir);
        rethrow(err);
    end

    function bool = isFolder(name)
        bool = logical(exist(name,'dir'));
    end
end

function resetPath()
    clear path;path(pathdef);
end

function freshScript()
    clc;    disp(newline);
    %avoid autoclearing variables: bad practice
    warning off backtrace
    disp(cstr('Running: '))
    disp(cstr(mfilename))
    try resetPath(); catch, end
end

function str = cstr(msg)
    str = strjust([msg, repmat(' ',1,100)],'center');
end
