function handles = Perform_TA_in_GUI(handles)
% adds Feature_table and Feature_display_cell to handles
% Feature_table is redundant as output, has non-unique texture names
% Modified to only handle single image and single voi input

%Handles contains:
%   mask_vol_for_TA
%   Primary_image_obj
%   image_vol_for_TA
%   resampled_image_vol_for_TA
%   range

assert(~isempty(handles.mask_vol_for_TA{1}{1}));
feature_structure = handles.feature_structure;

n_parent = 10;
Feature_table = {};
Feature_display_cell = cell(108,3);
now_img_obj = handles.Primary_image_obj;
table_column_now_idx =3;
table_row_now_idx = 1;

for idx_parent = 1:n_parent
    n_features_in_parent = length(feature_structure{idx_parent});
    if n_features_in_parent  < 1
        continue;
    end
    parent_function_name = feature_structure{idx_parent}{1}.parentfcn;
    parent_fcn_is_the_same = true;
    for idx_feature = 1:n_features_in_parent
        if ~strcmp(parent_function_name, feature_structure{idx_parent}{idx_feature}.parentfcn)
            parent_fcn_is_the_same = false;
        end
    end

    if  parent_fcn_is_the_same && (exist(parent_function_name)>0)
        %display(['Evaluating parent function: ' parent_function_name]);
        feval(parent_function_name, handles.image_vol_for_TA{1}{1}, ...
            handles.resampled_image_vol_for_TA{1}{1}, ...
            now_img_obj, ...
            handles, ...
            1, ...
            1, ...
            handles.range{1});

    end
    for idx_feature = 1:n_features_in_parent
        if  ~parent_fcn_is_the_same % if not all parent functions are the same, evaluate its parent function for each feature
            if idx_feature == 1
                prev_parent_name = '';
            end
            if ~strcmp(prev_parent_name, feature_structure{idx_parent}{idx_feature}.parentfcn)
                %display(['Evaluating parent function: ' feature_structure{idx_parent}{idx_feature}.parentfcn]);
                feval(feature_structure{idx_parent}{idx_feature}.parentfcn, handles.image_vol_for_TA{1}{1}, ...
                    handles.resampled_image_vol_for_TA{1}{1}, ...
                    now_img_obj, ...
                    handles, ...
                    1, ...
                    1, ...
                    handles.range{1});
                prev_parent_name = feature_structure{idx_parent}{idx_feature}.parentfcn;
            end
        end
        % 1: name, 2: value

        Feature_table{1}{1}{idx_parent}{idx_feature}{1} = feature_structure{idx_parent}{idx_feature}.name;
        Feature_table{1}{1}{idx_parent}{idx_feature}{2} = feval(feature_structure{idx_parent}{idx_feature}.matlab_fun, ...
            handles.image_vol_for_TA{1}{1}, ...
            handles.resampled_image_vol_for_TA{1}{1}, ...
            now_img_obj, ...
            handles, ...
            1, ...
            1, ...
            handles.range{1});

        
        if table_column_now_idx == 3
            Feature_display_cell{table_row_now_idx, 1} = feature_structure{idx_parent}{idx_feature}.parent;
            Feature_display_cell{table_row_now_idx, 2} = feature_structure{idx_parent}{idx_feature}.name;
        end
        Feature_display_cell{table_row_now_idx, table_column_now_idx} = Feature_table{1}{1}{idx_parent}{idx_feature}{2};
        table_row_now_idx = table_row_now_idx+1;
    end
end




handles.Feature_table = Feature_table;
handles.Feature_display_cell = Feature_display_cell;

return;