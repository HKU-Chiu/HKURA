function [ a ] = getFolders( path )
%Removes . and .. and non-folders from list. Returns cell array of names.
%   names = GetFolders(path)
% 
%   path: path of parent (string)
%   names: cell array with strings of folder names according to dir()

a = dir(path);
a(~[a.isdir])=[];
a(ismember({a.name},{'.','..'}))=[];
a = {a.name};
end

