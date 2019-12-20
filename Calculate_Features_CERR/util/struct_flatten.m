function S = struct_flatten(S)
% Recursive version by J.T.J. van Lunenburg
%
% flatS = struct_flatten(nestedS)
%
% See also: https://www.mathworks.com/matlabcentral/fileexchange/45849-flattenstruct2cell

for field = string(fieldnames(S))' %for loop syntax requires horizontal string array
    if (isa(S.(field), 'struct'))
        childS = struct_flatten(S.(field));
        S = rmfield(S,field);
        S = mergestruct(S,childS,field);
    end
end

end

function S = mergestruct(A,B,parentname)
%See also: https://www.mathworks.com/matlabcentral/fileexchange/7842-catstruct
    namesA = fieldnames(A);
    namesB = fieldnames(B);
    dupesB = ismember(namesB,namesA);
    if any(dupesB)
        namesB(dupesB) = strcat(namesB(dupesB),'_', char(parentname)); %strcat returns a string(?!) if parentname isn't converted to char
    end
    S = cell2struct([struct2cell(A);struct2cell(B)], [namesA;namesB], 1);  %has builtin duplicate check
end

% function st = randomstring() %or just use sequential numbering?
%     symbols = ['a':'z' 'A':'Z'];
%     MAX_ST_LENGTH = 10;
%     nums = randi(numel(symbols),[1 randi(MAX_ST_LENGTH)]);
%     st = symbols(nums);
% end