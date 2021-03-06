function [out_border extended_range] = determine_mask_range(in_mask)

temp1 = squeeze(sum(in_mask,1));
temp2 = sum(temp1);
list1 = find(temp2>0);
out_border{1} = [list1(1):list1(end)];

if list1(1)==1 && list1(end) == size(in_mask,3)
    extended_range{1} = [list1(1):list1(end)];
elseif list1(1)==1
    extended_range{1} = [list1(1):list1(end)+1];
elseif list1(end) == size(in_mask,3)
    extended_range{1} = [list1(1)-1:list1(end)];
else
    extended_range{1} = [list1(1)-1:list1(end)+1];
end

temp2 = sum(temp1,2);
list1 = find(temp2>0);
out_border{2} = [list1(1):list1(end)];

if list1(1)==1 && list1(end) == size(in_mask,2)
    extended_range{2} = [list1(1):list1(end)];
elseif list1(1)==1
    extended_range{2} = [list1(1):list1(end)+1];
elseif list1(end) == size(in_mask,2)
    extended_range{2} = [list1(1)-1:list1(end)];
else
    extended_range{2} = [list1(1)-1:list1(end)+1];
end

temp1 = squeeze(sum(in_mask,2));
temp2 = sum(temp1,2);
list1 = find(temp2>0);
out_border{3} = [list1(1):list1(end)];

if list1(1)==1 && list1(end) == size(in_mask,1)
    extended_range{3} = [list1(1):list1(end)];
elseif list1(1)==1
    extended_range{3} = [list1(1):list1(end)+1];
elseif list1(end) == size(in_mask,1)
    extended_range{3} = [list1(1)-1:list1(end)];
else
    extended_range{3} = [list1(1)-1:list1(end)+1];
end

return;