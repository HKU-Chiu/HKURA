function CDataSetInfo=PreprocessImage(TestStruct, CDataSetInfo)
PreprocessName={TestStruct.Name}';
for i=1:length(PreprocessName)
    fhandle=str2func(PreprocessName{i});
    
    [ROIImageInfo, ROIBWInfo]=fhandle(CDataSetInfo, TestStruct(i).Value);
    
    %Preprocess-Resample Voxel
    if isfield(ROIImageInfo, 'CDataSetInfo')
        CDataSetInfo=UpdateCDataSetInfo(CDataSetInfo, ROIImageInfo.CDataSetInfo);
        ROIImageInfo=rmfield(ROIImageInfo, 'CDataSetInfo');
    end
    
    CDataSetInfo.ROIImageInfo=ROIImageInfo;
    CDataSetInfo.ROIBWInfo=ROIBWInfo;
end

function CDataSetInfo=UpdateCDataSetInfo(CDataSetInfo, NewCDataSetInfo)
CDataSetInfo.XDim=NewCDataSetInfo.XDim;
CDataSetInfo.YDim=NewCDataSetInfo.YDim;
CDataSetInfo.ZDim=NewCDataSetInfo.ZDim;

CDataSetInfo.ImageXDim=NewCDataSetInfo.XDim;
CDataSetInfo.ImageYDim=NewCDataSetInfo.YDim;
CDataSetInfo.ImageZDim=NewCDataSetInfo.ZDim;

CDataSetInfo.ROIXDim=size(CDataSetInfo.ROIBWInfo.MaskData, 2);
CDataSetInfo.ROIYDim=size(CDataSetInfo.ROIBWInfo.MaskData, 1);
CDataSetInfo.ROIZDim=size(CDataSetInfo.ROIBWInfo.MaskData, 3);

CDataSetInfo.XPixDim=NewCDataSetInfo.XPixDim;
CDataSetInfo.YPixDim=NewCDataSetInfo.YPixDim;
CDataSetInfo.ZPixDim=NewCDataSetInfo.ZPixDim;

CDataSetInfo.XStart=NewCDataSetInfo.XStart;
CDataSetInfo.YStart=NewCDataSetInfo.YStart;
CDataSetInfo.ZStart=NewCDataSetInfo.ZStart;

CDataSetInfo.structAxialROI=NewCDataSetInfo.structAxialROI;








