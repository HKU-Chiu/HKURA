function [ a ] = getFullFolders( path )
%Removes . and .. and non-folders from list. Returns cell array of names.
%   names = GetFullFolders(path)
% 
%   path: path of parent (string)
%   names: cell array with strings of folder names according to dir()

a = getFolders(path);

%cut off wildcard pattern, if applicable
if contains(path, "*")
	path = extractBefore(path, "*"); %regexp(path, '^.+?[*]+?', 'once', 'match'); 
end

a = fullfile(char(path), a);
end

