function TableHeaderFinal=FormatTableHeader(TableHeader)
TableHeaderFinal=[{' '}];

for i=1:length(TableHeader)
    TableHeaderFinal=[TableHeaderFinal, {['<html><b><font size="4" face="Times New Roman" color="rgb(0,0,100)">', TableHeader{i}]}];
end

