function names = formatstrForTable(names)
%If a table is exported with feature names as variables names, the names may not be MATLAB compliant. Use this function to ensure a valid MATLAB table is created.
% Alternatively, just export the names separately, or pivot the table into a long/vertical data shape.
%
%Replace spaces with underscore
%Remove dashes and dots
%Crop element length to 63  by removing the last characters
%In the case of name collisions: with N cases, replace last character(s) of duplicates with integers 1...N to make them unique
%
% Rules for valid variable names: 
% 1. Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% 2. Variable names have to start with a letter.
% 3. Variable names can be up to 63 characters long.

% names = strrep(names,' ','_');
% names = strrep(names,'-','');
% names = strrep(names,'.','');
names = replace(names, [" ","-","."], ["_", "", ""]);

rulebreakers = arrayfun(@(X) length(char(X)), names) >  63;
names(rulebreakers) = extractBefore(names(rulebreakers), 63); 

%todo: ensure uniqueness

end