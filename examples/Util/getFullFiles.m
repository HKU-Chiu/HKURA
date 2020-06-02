function files = getFullFiles(input)
%str    = file       | dir      | pattern

if nargin == 0
    input = pwd();
end
input = char(input);
files = dir(input);
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
    root = fileparts(input);
end
    
files = strcat([root filesep], files);
end