function BWMatInfo=BWFillROINoZPix(BWMatInfo, structAxialROI)

BWMatInfo.XStart=[];
BWMatInfo.YStart=[];
BWMatInfo.ZStart=[];

BWMatInfo.XDim=[];
BWMatInfo.YDim=[];
BWMatInfo.ZDim=[];

BWMatInfo.MaskData=[];

ContourZLoc={structAxialROI.ZLocation}';
ContourZLoc=cell2mat(ContourZLoc);

if isempty(ContourZLoc)
    return;
end

%Get Limit box
MinZ=min(ContourZLoc);
MaxZ=max(ContourZLoc);

BWMatInfo.ZPixDim=GetZPixDim(ContourZLoc);

MinX=9999999;
MinY=9999999;
MaxX=-9999999;
MaxY=-9999999;

ContourNum=length(structAxialROI.CurvesCor);

for i=1:ContourNum
    ContourData=structAxialROI.CurvesCor{i};
    
    if ~isempty(ContourData)
        MinX=min(MinX, min(ContourData(:, 1)));
        MaxX=max(MaxX, max(ContourData(:, 1)));
        
        MinY=min(MinY, min(ContourData(:, 2)));
        MaxY=max(MaxY, max(ContourData(:, 2)));
    end
end

BWMatInfo.XStart=MinX;
BWMatInfo.YStart=MinY;
BWMatInfo.ZStart=MinZ;

MinPage=1;
MaxPage=round((MaxZ-BWMatInfo.ZStart)/BWMatInfo.ZPixDim+1);

MinCol=1;
MaxCol=round((MaxX-BWMatInfo.XStart)/BWMatInfo.XPixDim+1);

MinRow=1;
MaxRow=round((MaxY-BWMatInfo.YStart)/BWMatInfo.YPixDim+1);


%Fill
RowNum=MaxRow-MinRow+1;
ColNum=MaxCol-MinCol+1;
PageNum=MaxPage-MinPage+1;

TablePos=BWMatInfo.ZStart+(0:PageNum-1)*BWMatInfo.ZPixDim;
TablePos=TablePos';

BWMat=zeros(RowNum, ColNum, PageNum, 'uint8');

%Square Len for MKroipoly
SquareLen=max(RowNum, ColNum);

for i=1:ContourNum    
    TempZLocation=ContourZLoc(i)  ;    %ZLocation
    ContourData=structAxialROI.CurvesCor{i};
           
    if  min(abs(TablePos-TempZLocation)) <= (BWMatInfo.ZPixDim/3)      %if curve is in image domain
        
        BWC=ContourData(:,2); BWR=ContourData(:,1);
        
        CIndex=round((BWC-MinY)/BWMatInfo.YPixDim)+1;
        RIndex=round((BWR-MinX)/BWMatInfo.XPixDim)+1;
        
        %Method 1---MATLAB
%         TempImage=uint8(zeros(RowNum, ColNum, 'uint8'));
%         BWSlice=roipoly(TempImage, RIndex, CIndex);        
        
        %Method 2---MKRoipoly
        TempImage=uint8(zeros(SquareLen, SquareLen, 'uint8'));
        
        x=BWR-single(MinX); x=(x/single(BWMatInfo.XPixDim))+1;
        y=BWC-single(MinY); y=(y/single(BWMatInfo.YPixDim))+1;
        BWSlice=MKroipoly(TempImage, x, y);
        BWSlice=BWSlice(1:RowNum, 1:ColNum);
                       
        [MinT, ZIndex]=min(abs(TablePos-TempZLocation));
        
        BWMat(:,:,ZIndex)=xor(BWMat(:,:,ZIndex), BWSlice);
    end        
end
       
BWMat=flipdim(BWMat, 1);

BWMatInfo.XDim=size(BWMat, 2);
BWMatInfo.YDim=size(BWMat, 1);
BWMatInfo.ZDim=size(BWMat, 3);

BWMatInfo.MaskData=BWMat;

function ZPixDim=GetZPixDim(ContourZLoc)
ContourZLoc=sort(ContourZLoc);

DiffKernal=[1, -1]';

DiffZLoc=conv(ContourZLoc, DiffKernal);
DiffZLoc(1)=[];
DiffZLoc(end)=[];

DiffZLoc=abs(DiffZLoc);

%Same slice
TempIndex=find(DiffZLoc < 0.00000001);
if ~isempty(TempIndex)
    DiffZLoc(TempIndex)=[];
end

%only one slice
if isempty(DiffZLoc)
    ZPixDim=0.3;
    return;
end

ZPixDim=min(DiffZLoc);








