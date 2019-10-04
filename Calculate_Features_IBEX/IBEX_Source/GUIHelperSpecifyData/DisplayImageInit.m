function DisplayImageInit(handles)

% AxesMargin=0.05;
AxesMargin=0;

%Image display --Axial
axes(handles.AxesImageAxial)

set(gca, 'CLim', [handles.GrayMin, handles.GrayMax]);

ImageDataInfo=GetImageDataInfo(handles, 'Axial');

if ~isfield(handles, 'SliceNum')
    CenterCut=round(size(ImageDataInfo.ImageData, 3)/2);
    handles.SliceNum=CenterCut;
end

set(gca, 'XLimMode', 'manual', 'XLim', [ImageDataInfo.XLimMin-AxesMargin, ImageDataInfo.XLimMax+AxesMargin]);
set(gca, 'YLimMode', 'manual', 'YLim', [ImageDataInfo.YLimMin-AxesMargin, ImageDataInfo.YLimMax+AxesMargin]);
set(gca, 'DataAspectRatioMode', 'auto', 'PlotBoxAspectRatioMode', 'auto', 'CameraViewAngleMode', 'auto');
set(gca, 'Color', 'none');
set(gca, 'XDir', 'normal'), set(gca, 'YDir', 'normal');

set(gca, 'Box', 'on', 'XTickMode', 'auto', 'YTickMode', 'auto');

pbaspect([1,1,1])
daspect([1,1,1]);

%colormap(gray);

hold on,
image([ImageDataInfo.XLimMin, ImageDataInfo.XLimMax], [ImageDataInfo.YLimMin, ImageDataInfo.YLimMax],...
    ImageDataInfo.ImageData(:, :, handles.SliceNum), 'CDataMapping', 'scaled'),
caxis([handles.GrayMin, handles.GrayMax]);

axis([ImageDataInfo.XLimMin-AxesMargin, ImageDataInfo.XLimMax+AxesMargin, ImageDataInfo.YLimMin-AxesMargin, ImageDataInfo.YLimMax+AxesMargin]); set(gca, 'Color', 'none');

pbaspect([1,1,1])
daspect([1,1,1]);


set(handles.TextZLoc, 'String', sprintf('%.3f', ImageDataInfo.TablePos(handles.SliceNum)));

guidata(handles.figure1, handles);

set(handles.AxesImageAxial, 'CLim', [handles.GrayMin, handles.GrayMax]);

%Display---Coronal
axes(handles.AxesImageCor)

set(gca, 'CLim', [handles.GrayMin, handles.GrayMax]);

ImageDataInfo=GetImageDataInfo(handles, 'Cor');

set(gca, 'XLimMode', 'manual', 'XLim', [ImageDataInfo.XLimMin-AxesMargin, ImageDataInfo.XLimMax+AxesMargin]);
set(gca, 'YLimMode', 'manual', 'YLim', [ImageDataInfo.ZLimMin-AxesMargin, ImageDataInfo.ZLimMax+AxesMargin]);
set(gca, 'DataAspectRatioMode', 'auto', 'PlotBoxAspectRatioMode', 'auto', 'CameraViewAngleMode', 'auto');
set(gca, 'Color', 'none');
set(gca, 'XDir', 'normal'), set(gca, 'YDir', 'reverse');

set(gca, 'Box', 'on', 'XTickMode', 'auto', 'YTickMode', 'auto');

pbaspect([1,1,1])
daspect([1,1,1]);

%colormap(gray);

if ~isfield(handles, 'SliceNumCor')
    CenterCutCor=round(ImageDataInfo.YDim/2);
    handles.SliceNumCor=CenterCutCor;
end

hold on,
CorImage=(squeeze(ImageDataInfo.ImageData(handles.SliceNumCor, :, :)))';

image([ImageDataInfo.XLimMin, ImageDataInfo.XLimMax], [ImageDataInfo.ZLimMin, ImageDataInfo.ZLimMax], CorImage,  'CDataMapping', 'scaled'),
caxis([handles.GrayMin, handles.GrayMax]);

axis([ImageDataInfo.XLimMin-AxesMargin, ImageDataInfo.XLimMax+AxesMargin, ImageDataInfo.ZLimMin-AxesMargin, ImageDataInfo.ZLimMax+AxesMargin]); set(gca, 'Color', 'none');

pbaspect([1,1,1])
daspect([1,1,1]);


YLoc=(handles.SliceNumCor-1)*ImageDataInfo.YPixDim+ImageDataInfo.YLimMin;
set(handles.TextYLoc, 'String', sprintf('%.3f', YLoc));

%Display---Sagittal
axes(handles.AxesImageSag)

set(gca, 'CLim', [handles.GrayMin, handles.GrayMax]);

ImageDataInfo=GetImageDataInfo(handles, 'Sag');

set(gca, 'XLimMode', 'manual', 'XLim', [ImageDataInfo.YLimMin-AxesMargin, ImageDataInfo.YLimMax+AxesMargin]);
set(gca, 'YLimMode', 'manual', 'YLim', [ImageDataInfo.ZLimMin-AxesMargin, ImageDataInfo.ZLimMax+AxesMargin]);
set(gca, 'DataAspectRatioMode', 'auto', 'PlotBoxAspectRatioMode', 'auto', 'CameraViewAngleMode', 'auto');
set(gca, 'Color', 'none');
set(gca, 'XDir', 'reverse'), set(gca, 'YDir', 'reverse');

set(gca, 'Box', 'on', 'XTickMode', 'auto', 'YTickMode', 'auto');

pbaspect([1,1,1])
daspect([1,1,1]);

%colormap(gray);

if ~isfield(handles, 'SliceNumSag')
    CenterCutSag=round(ImageDataInfo.XDim/2);
    handles.SliceNumSag=CenterCutSag;
end

hold on,
SagImage=(squeeze(ImageDataInfo.ImageData(:, handles.SliceNumSag, :)))';

image([ImageDataInfo.YLimMin, ImageDataInfo.YLimMax], [ImageDataInfo.ZLimMin, ImageDataInfo.ZLimMax], SagImage, 'CDataMapping', 'scaled'),
caxis([handles.GrayMin, handles.GrayMax]);

axis([ImageDataInfo.YLimMin-AxesMargin, ImageDataInfo.YLimMax+AxesMargin, ImageDataInfo.ZLimMin-AxesMargin, ImageDataInfo.ZLimMax+AxesMargin]); set(gca, 'Color', 'none');

pbaspect([1,1,1])
daspect([1,1,1]);

XLoc=(handles.SliceNumSag-1)*ImageDataInfo.XPixDim+ImageDataInfo.XLimMin;
set(handles.TextXLoc, 'String', sprintf('%.3f', XLoc));

set([handles.AxesImageAxial, handles.AxesImageSag, handles.AxesImageCor], 'CLim', [handles.GrayMin, handles.GrayMax]);

guidata(handles.figure1, handles);