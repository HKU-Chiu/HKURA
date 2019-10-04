function list = absDir(varargin)
switch nargin
    case 1 %(relative or absolute)(pattern, folder or file) = 6 scenarios
        str     = varargin{1};
        list    = dir(str);
            if isempty(dir), return; end
        pflag   = ~isempty(regexp(str,'\*','once'));
        str     = getAbs(str);
        if pflag, str = fileparts(str); end
        
        if strcmp(list(1).name,'.')    
            newnames = fullfile(str,{list.name});
            [list(:).name] = deal(newnames{:});
            return;
        elseif ~pflag
            list.name = str;
            return;
        else 
            newnames = fullfile(str,{list.name});
            [list(:).name] = deal(newnames{:});
            return;
        end
    case 0
        list = dir();
        newnames = fullfile(pwd,{list.name});
        [list(:).name] = deal(newnames{:});
    otherwise
        error('too many arguments');
end


end

function str = getAbs(str)
    if length(str)==1, return; end
    if (str(end)=='\')||(str(end)=='/'), str(end) = [];end
    [root,child] = fileparts(pwd);
    while (~isempty(child))
        [root,child] = fileparts(root);
    end
    if root == filesep, root = fullfile(root,child);end
    
    if ~(strcmpi(str(1:length(root)),root)) %relative 
        str = fullfile(pwd,str);
    end
end