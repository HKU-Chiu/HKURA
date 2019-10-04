function BWMatInfo=BWFillROI(ROIIndex, PlanIndex, handles, ZLocation, LineX, LineY)
BWMatInfo.XStart=[];
BWMatInfo.YStart=[];
BWMatInfo.ZStart=[];

BWMatInfo.XDim=[];
BWMatInfo.YDim=[];
BWMatInfo.ZDim=[];

BWMatInfo.XPixDim=[];
BWMatInfo.YPixDim=[];
BWMatInfo.ZPixDim=[];

BWMatInfo.MaskData=[];

 %Preprocess--resample
if isfield(handles, 'ZStart')
    ResampleFlag=1;
else
    ResampleFlag=0;
end

if ResampleFlag <1
    %SpecifyData, ROIEditor, ROIEditorDataSet
    ImageDataInfoAxial=GetImageDataInfo(handles, 'Axial');
else
    %Preprocess--resample
    ImageDataInfoAxial=handles;
    ImageDataInfoAxial.TablePos=handles.ZStart+((1:handles.ZDim)-1)*handles.ZPixDim;
    structViewROI=handles.structAxialROI;    
end

switch nargin
    case 3
        if ~isempty(PlanIndex)
            structViewROI=handles.PlansInfo.structAxialROI{PlanIndex};
        end
        
        ContourNum=length(structViewROI(ROIIndex).CurvesCor);        
        ContourZLoc=structViewROI(ROIIndex).ZLocation;                
    case 4       
        structViewROI=handles.PlansInfo.structAxialROI{PlanIndex};     
        structViewROI=structViewROI(ROIIndex);
        ContourZLoc=structViewROI.ZLocation;
        
        TempIndex=find(abs(ContourZLoc-ZLocation) < ImageDataInfoAxial.ZPixDim/3);
        if isempty(TempIndex)
            return;
        end
        
        structViewROI.ZLocation=structViewROI.ZLocation(TempIndex);
        structViewROI.CurvesCor=structViewROI.CurvesCor(TempIndex);
        
        ContourNum=length(structViewROI.CurvesCor);
        ContourZLoc=structViewROI.ZLocation;
        
        ROIIndex=1;
    case 6        
        structViewROI.CurvesCor(1)={[LineX', LineY']};
        ContourNum=length(structViewROI.CurvesCor);
        ContourZLoc=ZLocation;
        
        ROIIndex=1;
end

if isempty(ContourZLoc)
    return;
end

%Get Limit box
if ResampleFlag <1
    MinZ=min(ContourZLoc);
    MaxZ=max(ContourZLoc);

    MinX=9999999;
    MinY=9999999;
    MaxX=-9999999;
    MaxY=-9999999;
    
    for i=1:ContourNum
        ContourData=structViewROI(ROIIndex).CurvesCor{i};
        
        if ~isempty(ContourData)
            MinX=min(MinX, min(ContourData(:, 1)));
            MaxX=max(MaxX, max(ContourData(:, 1)));
            
            MinY=min(MinY, min(ContourData(:, 2)));
            MaxY=max(MaxY, max(ContourData(:, 2)));
        end
    end
else
    %Preprocess--resample
    MinX=ImageDataInfoAxial.XStart;
    MaxX=ImageDataInfoAxial.XStart+(ImageDataInfoAxial.XDim-1)*ImageDataInfoAxial.XPixDim;
    
    MinY=ImageDataInfoAxial.YStart;
    MaxY=ImageDataInfoAxial.YStart+(ImageDataInfoAxial.YDim-1)*ImageDataInfoAxial.YPixDim;
    
    MinZ=ImageDataInfoAxial.ZStart;
    MaxZ=ImageDataInfoAxial.ZStart+(ImageDataInfoAxial.ZDim-1)*ImageDataInfoAxial.ZPixDim;
end

MinPage=round((MinZ-ImageDataInfoAxial.ZStart)/ImageDataInfoAxial.ZPixDim+1);
MaxPage=round((MaxZ-ImageDataInfoAxial.ZStart)/ImageDataInfoAxial.ZPixDim+1);

if MinPage > ImageDataInfoAxial.ZDim || MaxPage < 1
    return;
end

if MinPage < 1
    MinPage=1;
end

if MaxPage > ImageDataInfoAxial.ZDim
    MaxPage=ImageDataInfoAxial.ZDim;
end

MinCol=round((MinX-ImageDataInfoAxial.XStart)/ImageDataInfoAxial.XPixDim+1);
MaxCol=round((MaxX-ImageDataInfoAxial.XStart)/ImageDataInfoAxial.XPixDim+1);

MaxRow=round(ImageDataInfoAxial.YDim-(MinY-ImageDataInfoAxial.YStart)/ImageDataInfoAxial.YPixDim);
MinRow=round(ImageDataInfoAxial.YDim-(MaxY-ImageDataInfoAxial.YStart)/ImageDataInfoAxial.YPixDim);

%Refine MinX, MinY, MinZ
MinX=(MinCol-1)*ImageDataInfoAxial.XPixDim+ImageDataInfoAxial.XStart;
MinY=(ImageDataInfoAxial.YDim-MaxRow)*ImageDataInfoAxial.XPixDim+ImageDataInfoAxial.YStart;
MinZ=ImageDataInfoAxial.TablePos(MinPage);

%Fill
RowNum=MaxRow-MinRow+1;
ColNum=MaxCol-MinCol+1;
PageNum=MaxPage-MinPage+1;

TablePos=ImageDataInfoAxial.TablePos(MinPage:MaxPage);

BWMat=zeros(RowNum, ColNum, PageNum, 'uint8');

%Square Len for MKroipoly
SquareLen=max(RowNum, ColNum);

for i=1:ContourNum
    
    TempZLocation=ContourZLoc(i)  ;    %ZLocation
    ContourData=structViewROI(ROIIndex).CurvesCor{i};
           
    if  min(abs(TablePos-TempZLocation)) <= (ImageDataInfoAxial.ZPixDim/3)      %if curve is in image domain
        
        BWC=ContourData(:,2); BWR=ContourData(:,1);
        
        CIndex=round((BWC-MinY)/ImageDataInfoAxial.YPixDim)+1;
        RIndex=round((BWR-MinX)/ImageDataInfoAxial.XPixDim)+1;
        
        %Method 1---MATLAB
%         TempImage=uint8(zeros(RowNum, ColNum, 'uint8'));
%         BWSlice=roipoly(TempImage, RIndex, CIndex);        
        
        %Method 2---MKRoipoly
        TempImage=uint8(zeros(SquareLen, SquareLen, 'uint8'));
        
        x=BWR-single(MinX); x=(x/single(ImageDataInfoAxial.XPixDim))+1;
        y=BWC-single(MinY); y=(y/single(ImageDataInfoAxial.YPixDim))+1;
        BWSlice=MKroipoly(TempImage, x, y);
        BWSlice=BWSlice(1:RowNum, 1:ColNum);
                       
        [MinT, ZIndex]=min(abs(TablePos-TempZLocation));
        
        BWMat(:,:,ZIndex)=xor(BWMat(:,:,ZIndex), BWSlice);
    end        
end
       
BWMat=flipdim(BWMat, 1);


BWMatInfo.XStart=MinX;
BWMatInfo.YStart=MinY;
BWMatInfo.ZStart=MinZ;

BWMatInfo.XDim=size(BWMat, 2);
BWMatInfo.YDim=size(BWMat, 1);
BWMatInfo.ZDim=size(BWMat, 3);

BWMatInfo.XPixDim=ImageDataInfoAxial.XPixDim;
BWMatInfo.YPixDim=ImageDataInfoAxial.YPixDim;
BWMatInfo.ZPixDim=ImageDataInfoAxial.ZPixDim;

BWMatInfo.MaskData=BWMat;

