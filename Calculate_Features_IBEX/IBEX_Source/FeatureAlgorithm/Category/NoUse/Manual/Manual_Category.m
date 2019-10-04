function ParentInfo=Manual_Category(CDataSetInfo, Mode)

switch Mode
    case 'Review'
        ReviewInfo=CDataSetInfo.ROIImageInfo;        
        ParentInfo=ReviewInfo;
        
    case 'Child'
        ParentInfo=CDataSetInfo;
end