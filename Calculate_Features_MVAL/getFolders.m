function [ a ] = getFolders( path )
%Removes . and .. and non-folders from list. Returns natsorted cell array of full names.
%   names = GetFolders(path)
% 
%   path: path of parent (string)
%   names: cell array with strings of folder names according to dir()

a = absDir(path);
b = dir(path);
a(~[a.isdir])=[];
a(ismember({b.name},{'.','..'}))=[];%a = a(3:end);
a = {a.name};
a = natsort(a);
end

