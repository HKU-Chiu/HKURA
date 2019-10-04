function files = getFullFiles(varargin)
%str    = file       | dir      | pattern
%returns: f[1], d[0] | f*,d[2+] | f*, d*
switch nargin
    case 1
        str= varargin{1};
        files = dir(str);
        assert(~isempty(files),'No matching files or folders found');
        if strcmp(files(1).name,'.') && isempty(regexp(str,'\*','once'));
            DIR = true;%?
            if (str(end)=='\')||(str(end)=='/'), str(end) = [];end
        else 
            DIR = false;
        end
    case 0
        files = dir();
        assert(~isempty(files),'No matching files or folders found');
        str = '';
        DIR = false;
    otherwise
        error('too many arguments');
end

%De-folder
folders = cell2mat({files.isdir});
files = {files.name};
files = files(~folders);
assert(~isempty(files),'No files found to match');

%get root
if DIR
    root = checkAbsRel(str);
else
    sepidx = regexp(str,'(\\|/)');
    if ~isempty(sepidx)
        root = checkAbsRel(str(1:sepidx(end)-1));
    else
        root = pwd;
    end
end
    
files = strcat([root filesep],files);
end

function str = checkAbsRel(str)
    ABS = fileparts(pwd);
    ABS = ABS(1:2);
    if ~(strcmpi(str(1:2),ABS)) %relative 
        str = [pwd filesep str];
    end
end