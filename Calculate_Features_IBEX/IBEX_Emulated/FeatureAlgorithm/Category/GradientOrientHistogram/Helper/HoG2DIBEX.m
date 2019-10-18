function [fdat, BinCenter, OrientImg] = HoG2DIBEX(varargin)
% Implementation of Histogram of gradient orientations (HoG) features for 
% 2D images.
%
% fdat = HoG2D(Img)
% fdat = HoG2D(Img, Mask)
% fdat = HoG2D(Img, nBins)
% fdat = HoG2D(Img, Mask, nBins)
%
% INPUT
%       Img  - 2-dimensional image
%       Mask - binary mask with the same size as Img. Value 1 indicates the
%              voxel will be considered.
%       nBins - number of bins for histogram, default: 20.
%
% OUTPUT
%       fdat - HoG feature data, a 1-dimensional vector.
%
% REFERENCE
% T. Pallavi, et al. Texture Descriptors to distinguish Radiation Necrosis 
% from Recurrent Brain Tumors on multi-parametric MRI. Proc SPIE. 2014; 
% 9035: 90352B. http://www.ncbi.nlm.nih.gov/pmc/articles/PMC4045619/
Img=varargin{1};
Mask=varargin{2};
nBins=varargin{3};


% compute gradient image
[Fx, Fy] = gradient(double(Img));

% compute orientations
orient = atan(Fy./Fx);

% convert to degree
orient = orient.*180./pi;
idx = find(orient<0);
orient(idx) = orient(idx) + 180;

% apply the mask
OrientImg=orient;

orient = orient(Mask>0);

% compute the histogram of orientations
BinSize=360/nBins;
BinCenter=BinSize/2:BinSize:359;

[fdat, BinCenter] = hist(orient, BinCenter);

fdat=fdat/sum(fdat);

% fdat=0;
% for i=1:size(Img, 3)
%     % compute gradient image
%     [Fx, Fy] = gradient(Img);
%     
%     % compute orientations
%     orient = atan(Fy./Fx);
%     
%     % apply the mask
%     orient = orient(Mask>0);
%     
%     % convert to degree
%     orient = orient.*180./pi;
%     idx = find(orient<0);
%     orient(idx) = orient(idx) + 180;    
%     
%     subfdat= hist(orient, BinCenter);
%     
%     fdat=fdat+subfdat;
% end
% fdat=fdat/sum(fdat);







