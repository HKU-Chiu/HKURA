function [ImageInfo_InROIBox, BinaryMaskInfo_InROIBox]=RemoveStripe_FFTNotchFilter(DataItemInfo, Param)
%%%Doc Starts%%%
%-Description: 
%Remove repetitive "spectral" noise slice-by-slice from the image using FFT notch filters

%-Parameters:
%Put paramenter description here.

%-Revision:
%Put revision history here.

%-Author:
%Put author descriptoin here.
%%%Doc Ends%%%

%Purpose:       To preprocess image data or binary mask before caculating features
%Architecture: All the preprocess-relevant files are under \IBEXCodePath\FeatureAlgorithm\Preprocess.
%Files:            *PreprocessName*.m, *PreprocessName*.INI

%%---------------Input Parameters Passed In By IBEX--------------%
%DataItemInfo:  a structure containing information on the entire image, image-inside-ROIBoundingBox and binary-mask-inside-ROIBoundingBox
%Param:            The entry used for IBEX to accept the parameters from GUI. Use .INI to define the default parameters

%%--------------Output Parameters------------%
%ImageInfo_InROIBox:           information on image-inside-ROIBoundingBox
%BinaryMaskInfo_InROIBox:  information on binary-mask-inside-ROIBoundingBox

%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%
%-----------------------------DO_NOT_CHANGE_STARTS--------------------------%
%%-----------RemoveStripe_FFTNotchFilter.INI------%
%Load the default parameters from INI
[MFilePath, MFileName]=fileparts(mfilename('fullpath'));

if nargin < 2
    ConfigFile=[MFilePath, '\', MFileName, '.INI'];
    Param=GetParamFromINI(ConfigFile);
end
%-----------------------------DO_NOT_CHANGE_ENDS------------------------------%
%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%

%DataItemInfo.XDim: X Dimension of the entire image
%DataItemInfo.YDim: Y Dimension of the entire image
%DataItemInfo.ZDim: Z Dimension of the entire image
%DataItemInfo.XPixDim: X Pixel Size of the entire image
%DataItemInfo.YPixDim: Y Pixel Size of the entire image
%DataItemInfo.ZPixDim: Z Pixel Size of the entire image
%DataItemInfo.XStart: X Start Point of the entire image
%DataItemInfo.YStart: Y Start point of the entire image
%DataItemInfo.ZStart: Z Start Point of the entire image

%DataItemInfo.ROIImageInfo:  information on image-inside-ROIBoundingBox
%DataItemInfo.ROIImageInfo.MaskData: Image Data of the image-inside-ROIBoundingBox
%DataItemInfo.ROIImageInfo.XDim: X Dimension of the image-inside-ROIBoundingBox
%DataItemInfo.ROIImageInfo.YDim: Y Dimension of the image-inside-ROIBoundingBox
%DataItemInfo.ROIImageInfo.ZDim: Z Dimension of the image-inside-ROIBoundingBox
%DataItemInfo.ROIImageInfo.XPixDim: X Pixel Size of the image-inside-ROIBoundingBox
%DataItemInfo.ROIImageInfo.YPixDim: Y Pixel Size of the image-inside-ROIBoundingBox
%DataItemInfo.ROIImageInfo.ZPixDim: Z Pixel Size of the image-inside-ROIBoundingBox
%DataItemInfo.ROIImageInfo.XStart: X Start Point of the image-inside-ROIBoundingBox
%DataItemInfo.ROIImageInfo.YStart: Y Start point of the image-inside-ROIBoundingBox
%DataItemInfo.ROIImageInfo.ZStart: Z Start Point of the image-inside-ROIBoundingBox

%DataItemInfo.ROIBWInfo:  information on ROI-binary-mask-inside-ROIBoundingBox
%DataItemInfo.ROIBWInfo.MaskData: Image Data of the ROI-binary-mask-inside-ROIBoundingBox
%DataItemInfo.ROIBWInfo.XDim: X Dimension of the ROI-binary-mask-inside-ROIBoundingBox
%DataItemInfo.ROIBWInfo.YDim: Y Dimension of the ROI-binary-mask-inside-ROIBoundingBox
%DataItemInfo.ROIBWInfo.ZDim: Z Dimension of the ROI-binary-mask-inside-ROIBoundingBox
%DataItemInfo.ROIBWInfo.XPixDim: X Pixel Size of the ROI-binary-mask-inside-ROIBoundingBox
%DataItemInfo.ROIBWInfo.YPixDim: Y Pixel Size of the ROI-binary-mask-inside-ROIBoundingBox
%DataItemInfo.ROIBWInfo.ZPixDim: Z Pixel Size of the ROI-binary-mask-inside-ROIBoundingBox
%DataItemInfo.ROIBWInfo.XStart: X Start Point of the ROI-binary-mask-inside-ROIBoundingBox
%DataItemInfo.ROIBWInfo.YStart: Y Start point of the ROI-binary-mask-inside-ROIBoundingBox
%DataItemInfo.ROIBWInfo.ZStart: Z Start Point of the ROI-binary-mask-inside-ROIBoundingBox


%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%
%%-----------Implement your code starting from here---------%
%****The skeleton preprocess smoothes the image and erodes binary mask****%

%---Sanity Check
if ~isfield(Param, 'Size')
    ImageInfo_InROIBox=[];
    BinaryMaskInfo_InROIBox=[];
    return;
end

%----Remove high-frequency peaks
ROIImageInfo=DataItemInfo.ROIImageInfo;


%Filter
DataType=class(ROIImageInfo.MaskData);
fhandle=str2func(DataType);

for i=1:DataItemInfo.ROIImageInfo.ZDim
    CurrentData=ROIImageInfo.MaskData(:, :, i);       
    
    if ~isempty(find(CurrentData))
        CurrentData=FFTNotch2(CurrentData, Param);
        ROIImageInfo.MaskData(:, :, i)=fhandle(CurrentData);
    end
end


%----ROI Binary Mask
ROIBWInfo=DataItemInfo.ROIBWInfo;

%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%
%-----------------------------DO_NOT_CHANGE_STARTS--------------------------%
%---Return Value
ROIImageInfo.Description=MFileName;
ImageInfo_InROIBox=ROIImageInfo;

BinaryMaskInfo_InROIBox=ROIBWInfo;
%-----------------------------DO_NOT_CHANGE_ENDS------------------------------%
%///////////////////////////////////////////////////////////////////////////////////////////////////////////////////%


function CurrentData=FFTNotch2(CurrentData, Param)
I=CurrentData;

I=double(I);
IOri=I;

PQ=PaddedSize(size(I));

MeanV=mean(I(:));
I=I-MeanV;
f = fftshift(fft2(I, PQ(1), PQ(2)));
fabs=abs(f);

[RowNum, ColNum]=size(f);

Radius=1/4*max(RowNum, ColNum)/2;
for i=1:RowNum
    for j=1:ColNum
        if (i-RowNum/2)^2+(j-ColNum/2)^2>(Radius*Radius)   % periodic noise locates in the position outside the 20-pixel-radius circle
            f(i, j)=0;
        end
    end
end

Inew=ifft2(fftshift(f));
Inew=real(Inew);
Inew=Inew(1:size(IOri, 1), 1:size(IOri, 2));

Inew=Inew+MeanV;

figure, colormap(gray)
subplot(2,2,1),imagesc(IOri); title('Original Image')
subplot(2,2,2),imagesc(log(1 + fabs)); title('Fourier Image')
subplot(2,2,3),imagesc(log(1 + abs(f))); title('Zeroed Fourier Image')
subplot(2,2,4),imagesc(Inew); title('Cleaned Image')
annotation('textbox', [0 0.9 1 0.1], ...
    'String', 'Fourier Analysis on Clown Image', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 15, ...
    'FontWeight', 'bold')

CurrentData=Inew;

A=1;

function CurrentData=FFTNotch(CurrentData, Param)
I=CurrentData;

I=double(I);
IOri=I;

PQ=PaddedSize(size(I));

MeanV=mean(I(:));

I=I-MeanV;
f = fftshift(fft2(I, PQ(1), PQ(2)));
fabs=abs(f);

roi=3; 
local_extr = ordfilt2(fabs, roi^2, ones(roi));  % find local maximum within 3*3 range

thresh=max(local_extr(:))*0.05;

result = (fabs == local_extr) & (fabs > thresh);

[r, c] = find(result);

[RowNum, ColNum]=size(result);

NotchPos=[];
for i=1:length(r)
    if (r(i)-RowNum/2)^2+(c(i)-ColNum/2)^2>(35*35)   % periodic noise locates in the position outside the 20-pixel-radius circle
        NotchPos=[NotchPos; r(i), c(i)];
    end
end

if isempty(NotchPos)
    CurrentData=I;
end

for i=1:size(NotchPos, 1)
    H=notch('btw', PQ(1), PQ(2), 10, NotchPos(i, 2), NotchPos(i, 1));
    f=f.*H;
end

Inew=ifft2(fftshift(f));
Inew=real(Inew);
Inew=Inew(1:size(IOri, 1), 1:size(IOri, 2));

Inew=Inew+MeanV;

figure, colormap(gray)
subplot(2,2,1),imagesc(IOri); title('Original Image')
subplot(2,2,2),imagesc(log(1 + fabs)); title('Fourier Image')
subplot(2,2,3),imagesc(log(1 + abs(f))); title('Zeroed Fourier Image')
subplot(2,2,4),imagesc(Inew); title('Cleaned Image')
annotation('textbox', [0 0.9 1 0.1], ...
    'String', 'Fourier Analysis on Clown Image', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 15, ...
    'FontWeight', 'bold')

CurrentData=Inew;

A=1;

