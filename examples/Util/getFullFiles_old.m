function files = getFullFiles(input)
%str    = file       | dir      | pattern

% switch nargin
%     case 1
        input = char(input);
         files = dir(input);
%         assert(~isempty(files),'No matching files or folders found');
%         if strcmp(files(1).name,'.') && isempty(regexp(input,'\*','once'))
%             DIR = true;%?
%             if (input(end)=='\')||(input(end)=='/'), input(end) = [];end
%         else 
%             DIR = false;
%         end
%     case 0
%         files = dir();
%         assert(~isempty(files),'No matching files or folders found');
%         input = '';
%         DIR = false;
%     otherwise
%         error('too many arguments');
% end

%De-folder
folders = cell2mat({files.isdir});
files = {files.name};
files = files(~folders);
assert(~isempty(files),'No files found to match');

%get root
if isfolder(input)
    root = input;
    current = pwd;
    if ~(strcmpi(input(1:2),current(1:2))) %subfolder, if path is floating
        root = [pwd filesep input];
    end
else
    sepidx = regexp(input,'(\\|/)');
    if ~isempty(sepidx)
        root = checkAbsRel(input(1:sepidx(end)-1));
    else
        root = pwd;
    end
end
    
files = strcat([root filesep],files);
end