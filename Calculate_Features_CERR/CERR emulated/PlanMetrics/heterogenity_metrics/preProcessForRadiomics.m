function [volToEval,maskBoundingBox3M, gridS] = preProcessForRadiomics(scanArray3M, mask3M)
% preProcessForRadiomics.m
% Does cropping and intensity-thresholding.
%
% AI 3/28/19

gridS.PixelSpacingV = [2.7344, 2.7344, 3.2700]; 
xval = size(scanArray3M,1) * gridS.PixelSpacingV(1);
yval = size(scanArray3M,2) * gridS.PixelSpacingV(2);
zval = size(scanArray3M,3) * gridS.PixelSpacingV(3);
xval = linspace(0,xval,size(scanArray3M,1));
yval = linspace(0,yval,size(scanArray3M,2));
zval = linspace(0,zval,size(scanArray3M,3));

uniqueSlices = find(any(mask3M,[1, 2]));

origSiz = size(mask3M); %moved this line to before padding, to fix a bug

% Pad scanArray and mask3M to interpolate
minSlc = min(uniqueSlices);
maxSlc = max(uniqueSlices);
if minSlc > 1
    mask3M = padarray(mask3M,[0 0 1],'pre');
    uniqueSlices = [minSlc-1; uniqueSlices];
end
if maxSlc < size(scanArray3M,3)
    mask3M = padarray(mask3M,[0 0 1],'post');
    uniqueSlices = [uniqueSlices; maxSlc+1];
end

%scanArray3M = scanArray3M(:,:,uniqueSlices);


% Crop scan around mask
margin = 10; %DANGER
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
minr = max(1,minr-margin);
maxr = min(origSiz(1),maxr+margin);
minc = max(1,minc-margin);
maxc = min(origSiz(2),maxc+margin);
mins = max(1,mins-margin);
maxs = min(origSiz(3),maxs+margin);
maskBoundingBox3M = mask3M(minr:maxr,minc:maxc,mins:maxs); 

gridS.yValsV = xval(minr:maxr); 
gridS.xValsV = yval(minc:maxc);
gridS.zValsV = zval(mins:maxs);

% Get the cropped scan
volToEval = double(scanArray3M(minr:maxr,minc:maxc,mins:maxs));






end