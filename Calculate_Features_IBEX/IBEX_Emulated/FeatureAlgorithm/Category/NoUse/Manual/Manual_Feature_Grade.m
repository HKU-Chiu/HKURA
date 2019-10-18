function [Value, ReviewInfo]=Manual_Feature_Grade(ParentInfo, Param)

Value=[];

%Review Info
if ~iscell(Param.ItemList)
    Param.ItemList=cellstr(num2str(Param.ItemList));
end

ItemListStr='{';
for i=1:length(Param.ItemList)
    ItemListStr=[ItemListStr, Param.ItemList{i}, ', '];
end
ItemListStr(end-1:end)=[];

ItemListStr=[ItemListStr, '}'];   
    
ReviewInfo.Value=ItemListStr;
