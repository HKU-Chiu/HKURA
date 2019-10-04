function varargout = compute_local_entropy(varargin)
% This function prepares the image volume in the unit of SUV for computing
% the statistics of SUV
img_original = varargin{3}.image_volume_data;
img_obj = varargin{3};

scale =  varargin{4}.scale_entropy;
nhood = ones(3,3,3); %nhood(1,1,1) = 0;nhood(1,3,1) = 0;nhood(3,1,1) = 0;nhood(3,3,1) = 0;nhood(1,1,3) = 0;nhood(1,3,3) = 0;nhood(3,1,3) = 0;nhood(3,3,3) = 0;
%nhood = zeros(3,3,3); nhood(2,2,2) = 1;nhood(1,2,2) = 1;nhood(2,1,2) = 1;nhood(3,2,2) = 1;nhood(2,3,2) = 1;nhood(2,2,1) = 1;nhood(2,2,3) = 1;

max_suv = 40;
paraimg_entropy = entropyfilt(rescale_img(img_original, 2.5, max_suv), nhood);

%paraimg_entropy = entropyfilt(cast(img_original*scale, 'uint16'), nhood);
%se = strel('disk',1);
mask = varargin{4}.mask_volume;
%mask = imerode(mask, se);

if exist('image_global') == 1
    clear image_global;
end
global image_global;
image_global = paraimg_entropy ; % Should be in double already
global mask_for_TA;
mask_for_TA = mask;

if exist('image_property') == 1
    clear image_property;
end
global image_property;
image_property.pixel_spacing = img_obj.pixel_spacing;

return;