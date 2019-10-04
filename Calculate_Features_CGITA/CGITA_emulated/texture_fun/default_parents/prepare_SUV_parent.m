function varargout = prepare_SUV_parent(varargin)
% This function prepares the image volume in the unit of SUV for computing
% the statistics of SUV
img_in = varargin{1}; % Use the original masked image volume to compute the co-occurrence matrix
img_obj = varargin{3};
mask = varargin{4}.mask_vol_for_TA{varargin{5}}{varargin{6}};

if exist('image_global') == 1
    clear image_global;
end
global image_global;
image_global = img_in; % Should be in double already
% global image_global_ni;
% image_global_ni = img_in2;
global mask_for_TA;
mask_for_TA = mask;

if exist('image_property') == 1
    clear image_property;
end
global image_property;
image_property.pixel_spacing = img_obj.pixel_spacing;
image_property.patient_LBM_ratio = img_obj.patient_LBM_ratio;

return;