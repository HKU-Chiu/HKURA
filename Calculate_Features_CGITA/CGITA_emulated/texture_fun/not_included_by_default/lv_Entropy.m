function feature_output = voxel_Entropy(varargin)
global image_global;
global image_property;
global mask_for_TA;
%image_property.pixel_spacing = img_obj.pixel_spacing;

%img_in = varargin{2}; % Use the resampled image volume to compute the co-occurrence matrix

% mask_in = varargin{4}.mask_vol_for_TA{varargin{5}}{varargin{6}};
% 
% img_in(find(mask_in==0)) = NaN;

%img_vec = img_in(find(mask_for_TA));

feature_output = 0;

if exist('image_global')==1
    temp1 = image_global(:);
    vox_vec = temp1(find(mask_for_TA));
    p=hist(vox_vec, 100)/length(vox_vec);
    feature_output = -sum( p(find(p>0)).*log(p(find(p>0))));
else
    error('The parent image must be computed first');
end

return;