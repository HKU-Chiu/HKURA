function run_length_matrix_all = compute_voxel_alignment_matrix(varargin)
% row: gray level. Zero is not accounted for
% col: # of runs
mat_in = varargin{2};

if exist('run_length_matrix_all')==1
    clear run_length_matrix_all;
end

global run_length_matrix_all;
global image_property;

image_property.num_voxels = length(mat_in(:));

direction_mat = [
    1    size(mat_in,1)                                  size(mat_in, 3)
    2    size(mat_in,2)                                  size(mat_in, 3)
    3    size(mat_in,1)+size(mat_in,2)-1     size(mat_in, 3)
    4    size(mat_in,1)+size(mat_in,2)-1     size(mat_in, 3)
    5    size(mat_in,3)                                  size(mat_in, 1)
    6    size(mat_in,3)+size(mat_in,2)-1     size(mat_in, 1)
    7    size(mat_in,3)+size(mat_in,2)-1     size(mat_in, 1)
    8    size(mat_in,3)+size(mat_in,1)-1     size(mat_in, 2)  
    9    size(mat_in,3)+size(mat_in,1)-1     size(mat_in, 2)
    ]; % number, max of lines, max of loops

run_length_matrix_all = zeros(max(mat_in(:)), max(size(mat_in)), 9);

mat_in_original = mat_in;
parfor idx_direction = 1:size(direction_mat,1)
    if (idx_direction >= 5) && (idx_direction < 8)
        mat_in = permute(mat_in_original, [3 2 1]);    
    elseif idx_direction >= 8        
        mat_in = permute(mat_in_original, [1 3 2]);
    else
        mat_in = mat_in_original;
    end
        
    max_lines = direction_mat(idx_direction, 2);
    max_num_mat = direction_mat(idx_direction, 3);
    run_length_matrix = zeros(max(mat_in(:)), max(size(mat_in)));%, 9);
    for idx_slice = 1:max_num_mat
        I = mat_in(:, :, idx_slice);
        for idx_intensity = 1:max(mat_in(:))
            mat_isintensity = (I==idx_intensity);
            for idx_line = 1:max_lines
                vec_line = extract_vec(mat_isintensity, direction_mat(idx_direction, 1), idx_line);                
                now_pos = find_first_in_vec(vec_line);
                if now_pos>0
                    while (now_pos<=length(vec_line))
                        cut_vec = vec_line(now_pos:end);
                        run_length_now = determine_run_length(cut_vec);
                        run_length_matrix(idx_intensity, run_length_now) = run_length_matrix(idx_intensity, run_length_now)+1;
                        cut_vec = vec_line(now_pos+run_length_now:end);
                        first_idx = find_first_in_vec(cut_vec);
                        if first_idx > 0
                            now_pos = now_pos +run_length_now+first_idx-1;
                        else
                            break;
                        end
                    end
                end
            end
            
        end
        %stop
    end
    run_length_matrix_all(:,:,idx_direction) = run_length_matrix;
end

% Take care of the other four diagonal directions
mat_in = mat_in_original; % make it back to the original

parfor direction_idx = 1:4
    switch direction_idx
        case 1
            a = mat_in;
        case 2
            for idx_slice = 1:size(mat_in,3)
                a(:,:,idx_slice) = fliplr(mat_in(:, :, idx_slice));
            end
        case 3
            for idx_slice = 1:size(mat_in,3)
                a(:,:,idx_slice) = flipud(mat_in(:, :, idx_slice));
            end
        case 4
            for idx_slice = 1:size(mat_in,3)
                a(:,:,idx_slice) = flipud(fliplr(mat_in(:, :, idx_slice)));
            end
    end
    
    run_length_matrix = zeros(max(mat_in(:)), max(size(mat_in)));%, 9);
    
    for idx1 = 1:size(a,1)-1
        for idx2 = 1:size(a,2)-1
            for idx3 = 1:size(a,3)-1
                if ~isempty(find([idx1 idx2 idx3]==1))
                    %tempvar = find([idx1 idx2 idx3]==1);
                    %tempvar  = a(1);
                    vec = a(idx1,idx2,idx3);
                    flag = 1;
                    incre1 = 1;
                    while flag>0
                        if idx1+incre1+1 > size(a,1)
                            flag = 0;
                        end
                        if idx2+incre1+1 > size(a,2)
                            flag = 0;
                        end
                        if idx3+incre1+1 > size(a,3)
                            flag = 0;
                        end
                        vec(end+1) = a(idx1+incre1,idx2+incre1,idx3+incre1);
                        incre1 = incre1+1;
                    end
                end
                if length(vec)>1
                    for idx_intensity = 1:max(mat_in(:))
                        vec_line = vec==idx_intensity;
                        now_pos = find_first_in_vec(vec_line);
                        if now_pos>0
                            while (now_pos<=length(vec_line))
                                cut_vec = vec_line(now_pos:end);
                                run_length_now = determine_run_length(cut_vec);
                                run_length_matrix(idx_intensity, run_length_now) = run_length_matrix(idx_intensity, run_length_now)+1;
                                cut_vec = vec_line(now_pos+run_length_now:end);
                                first_idx = find_first_in_vec(cut_vec);
                                if first_idx > 0
                                    now_pos = now_pos +run_length_now+first_idx-1;
                                else
                                    break;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    run_length_matrix_all(:,:,direction_idx+9) = run_length_matrix;
end
run_length_matrix_all = sum(run_length_matrix_all, 3);

% Re-calculate the number of run length == 1
for idx_intensity = 1:max(mat_in(:))
    equal_mat = (mat_in==idx_intensity);
    for idx1 = 1:size(mat_in,1)
        for idx2 = 1:size(mat_in, 2)
            for idx3 = 1:size(mat_in,3)
                if equal_mat(idx1,idx2,idx3) == 1
                    try
                        if equal_mat(idx1-1,idx2,idx3) == 1
                            equal_mat(idx1-1, idx2, idx3) = 0;
                            equal_mat(idx1, idx2, idx3) = 0;
                        end
                    catch
                    end
                    try
                        if equal_mat(idx1+1,idx2,idx3) == 1
                            equal_mat(idx1+1, idx2, idx3) = 0;
                            equal_mat(idx1, idx2, idx3) = 0;
                        end
                    catch
                    end
                    try
                        if equal_mat(idx1,idx2-1,idx3) == 1
                            equal_mat(idx1, idx2-1, idx3) = 0;
                            equal_mat(idx1, idx2, idx3) = 0;
                        end
                    catch
                    end
                    try
                        if equal_mat(idx1,idx2+1,idx3) == 1
                            equal_mat(idx1, idx2+1, idx3) = 0;
                            equal_mat(idx1, idx2, idx3) = 0;
                        end
                    catch
                    end
                    try
                        if equal_mat(idx1,idx2,idx3-1) == 1
                            equal_mat(idx1, idx2, idx3-1) = 0;
                            equal_mat(idx1, idx2, idx3) = 0;
                        end
                    catch
                    end
                    try
                        if equal_mat(idx1,idx2,idx3+1) == 1
                            equal_mat(idx1, idx2, idx3+1) = 0;
                            equal_mat(idx1, idx2, idx3) = 0;
                        end
                    catch
                    end
                end
            end
        end
    end
    run_length_matrix_all(idx_intensity, 1) = sum(equal_mat(:));
end

% ARL = sum(sum(run_length_matrix_all.*repmat(1:max(size(mat_in)), [max(mat_in(:)) 1]))) / sum(sum(run_length_matrix_all)); % average run length
% run_length_matrix_normalized = run_length_matrix_all / ARL ; % To normalize the run length matrix
% 
% run_length_matrix_all = run_length_matrix_normalized;
% 
return;
%
% run_length_matrix = zeros(max(mat_in(:)), max(size(mat_in)));%, 9);
%
% % same slice, 90 degrees == towards the top
% for idx_intensity = 1:max(mat_in(:))
%     mat_isintensity = (I==idx_intensity);
%     for idx2 = 1:size(mat_in,2)
%         now_row = find_first_in_vec(mat_isintensity(:,idx2));
%         if now_row>0
%             while (now_row<=size(mat_in,1))
%                 cut_vec = mat_isintensity(now_row:end, idx2);
%                 run_length_now = determine_run_length(cut_vec);
%                 run_length_matrix(idx_intensity, run_length_now) = run_length_matrix(idx_intensity, run_length_now)+1;
%                 cut_vec = mat_isintensity(now_row+run_length_now:end, idx2);
%                 first_idx = find_first_in_vec(cut_vec);
%                 if first_idx > 0
%                     now_row = now_row+run_length_now+first_idx-1;
%                 else
%                     break;
%                 end
%             end
%         end
%     end
% end

%return;


% img_as_vec = img_in(:);
%
% index_mapping_mat = make_index_matrix(size(img_in));
