function ROI_struct = PMOD_VOI_reader_match_image(filename, handles);%, zV, x1, y1, z1, x2, y2, z2)
% only support PMOD VOI on static images
% only support ROI drawn on axial slices
% does support multiple contours on the same slice
h = msgbox('Reading the PMOD VOI file. Please wait...');

zV = -fliplr(handles.zV_original)*10;

fid = fopen(filename);
tol = 1e-4;

%fid = fopen('C:\Users\USER\Desktop\ROI2_07852673.voi', 'r');
text1 = fread(fid);
text1 = char(text1');
fclose(fid);

n_slices = get_value_from_text(text1, '# number_of_slices_z', '%d ');

%%%%%
out_struct = {};
tempvar.segments = struct('points',{});

for idx = 1:n_slices
    empty_struct.contour(idx) = tempvar;
end

%%%%%


k = strfind(text1, '#NUMBER OF VOI TIME LISTS:');
n_list = sscanf(text1(k+27:end)','%d ');

list_des_begin_pos = strfind(text1,'#VOI TIME LIST NUMBER');

if length(list_des_begin_pos) ~= n_list
    error('Number of VOIs do not equal the sections describing the VOIs');
end

nx = get_value_from_text(text1, '# number_of_columns_x', '%d # number_of_columns_x');
ny = get_value_from_text(text1, '# number_of_rows_y', '%d # number_of_rows_y');
nz = get_value_from_text(text1, '# number_of_slices_z', '%d # number_of_slices_z');
spacing_x = get_value_from_text(text1, '# x_pixel_size', '%f # x_pixel_size');
spacing_y = get_value_from_text(text1, '# y_pixel_size', '%f # y_pixel_size');
spacing_z = get_value_from_text(text1, '# z_pixel_size', '%f # z_pixel_size');

origin_x = get_value_from_text(text1(strfind(text1,'#ORIGIN LOCATION IN MM:'):end), '# x_origin_location', '%f # x_origin_location');
origin_y = get_value_from_text(text1(strfind(text1,'#ORIGIN LOCATION IN MM:'):end), '# y_origin_location', '%f # y_origin_location');
origin_z = get_value_from_text(text1(strfind(text1,'#ORIGIN LOCATION IN MM:'):end), '# z_origin_location', '%f # z_origin_location');

header.xV = -origin_x : spacing_x : -origin_x+(nx)*spacing_x;
header.yV = -origin_y : spacing_y : -origin_y+(ny)*spacing_y;
header.zV = -origin_z : spacing_z : -origin_z+(nz)*spacing_z;

% %out.original_x_location = (out.x_location); % Not sure why this has to be flipped...
% 
% out.y_location = metainfo{idx,1}.ImagePositionPatient(2) : metainfo{idx,1}.PixelSpacing(2): metainfo{idx,1}.ImagePositionPatient(2)+(ny-1)*metainfo{idx,1}.PixelSpacing(2);
% out.y_location = -(out.y_location);
% out.original_y_location = (out.y_location); % Not sure why this has to be flipped...
% out.pmod_y_location = metainfo{idx,1}.ImagePositionPatient(2) : metainfo{idx,1}.PixelSpacing(2) : metainfo{idx,1}.ImagePositionPatient(2)+(ny)*metainfo{idx,1}.PixelSpacing(2);
% out.pmod_y_location = -(out.pmod_y_location);
% out.pmod_y_location_2 = out.pmod_y_location(1): (out.pmod_y_location(end)-out.pmod_y_location(1))/(ny-1): out.pmod_y_location(end);

vertices_counter = 0;
for idx_list = 1:n_list
    
    ROI_struct(idx_list).contour = empty_struct.contour;
    if idx_list == n_list
        text_list = text1(list_des_begin_pos(idx_list):end);
    else
        text_list = text1(list_des_begin_pos(idx_list):list_des_begin_pos(idx_list+1)-1);
    end
    
    temp_str = get_value_from_text(text_list, '# voi_name', '%c');
    temp_pos_str = strfind(temp_str, '# voi_name');
    
    ROI_struct(idx_list).structureName = temp_str(1:temp_pos_str-1);
    n_voi = get_value_from_text(text_list, '# number_of_vois', '%d ');
    
    if round(n_voi)~=n_voi
        error('VOI number not integer; stopped');
    end
    if n_voi > 1
        error('This function does not support multiple VOIs within a VOI');
    end
    voi_des_begin_pos = strfind(text_list, '#TIME VOI NUMBER');
    if isempty(voi_des_begin_pos)
        voi_des_begin_pos = strfind(text_list, '#VOI TIME LIST NUMBER');
    end
    text_voi = text_list(voi_des_begin_pos:end);
    % determine number of slices within the VOI
    n_roi = get_value_from_text(text_voi, '# number_of_rois', '%d ');
    if isempty(n_roi)
        n_roi = 0;
    end
    if n_roi > 0
        contour_name = {};
        roi_des_begin_pos = strfind(text_voi, '#ROI ON SLICE');
        for idx_roi = 1:n_roi
            if idx_roi == n_roi
                text_roi = text_voi(roi_des_begin_pos(idx_roi):end);
            else
                text_roi = text_voi(roi_des_begin_pos(idx_roi):roi_des_begin_pos(idx_roi+1)-1);
            end
            InputText=textscan(text_roi, '%s', 'delimiter', '\n');
            slice_info = sscanf(InputText{1}{2}, '%d %d');
            % The slice location should be matched to the images. So the
            % slice number here should not be trusted.
            %slice_now=slice_info(1)+1; % slice 0 means slice #1, etc.
            n_contour=slice_info(2);
            idx_temp = 1;
            while idx_temp<=numel(InputText{1})
                if ~isempty(strfind(InputText{1}{idx_temp}, '# number_of_vertices'));
                    double_quote_pos = find(InputText{1}{idx_temp}=='"');
                    if isempty(double_quote_pos)
                        now_contour_name = 'not_available';
                    else
                        now_contour_name = InputText{1}{idx_temp}(double_quote_pos(1)+2:double_quote_pos(2)-2);
                    end
                    if isempty(find(strcmp(InputText{1}{idx_temp}, contour_name)))
                        contour_name{end+1} =now_contour_name;
                        contour_index = length(contour_name);
                    else
                        contour_index =find(strcmp(InputText{1}{idx_temp}, contour_name));
                    end
                    n_vertices = sscanf(InputText{1}{idx_temp}, '%d '); %13 137.0 -137.0 false 0 " Contour 1 "
                    n_vertices = n_vertices(1);
                    
                    pos_vertices = [];
                    for idx_vertices = 1:n_vertices-1
                        pos_vertices(idx_vertices, :) = sscanf(InputText{1}{idx_temp + idx_vertices}, '%f %f %f');
                    end
                    if numel(pos_vertices) > 1
                        if (min(zV)<=pos_vertices(1,3))&&(max(zV)>=pos_vertices(1,3))                            
                            [dummy slice_now] = min(abs(zV-pos_vertices(1,3)));
                            %slice_now
                            vertices_counter = vertices_counter+1;
                            all_pos_vertices{vertices_counter}.pos_vertices = pos_vertices;
                            all_pos_vertices{vertices_counter}.idx_list = idx_list;
                            all_pos_vertices{vertices_counter}.slice_now = slice_now;
                            all_pos_vertices{vertices_counter}.contour_index = contour_index;
                                                        
                            %corrected_vertices = process_pmod_vertice(pos_vertices, handles);
                            %ROI_struct(idx_list).contour(slice_now).segments(contour_index).points = corrected_vertices/10;                       
                        end
                    end
                    idx_temp = idx_temp + idx_vertices;
                    
                else
                    idx_temp = idx_temp +1;
                end
                
            end
        end
    end
    
end

parfor vertices_idx = 1:vertices_counter
    corrected_vertices = process_pmod_vertice(all_pos_vertices{vertices_idx}.pos_vertices, handles);        
    temp_parfor{vertices_idx} = corrected_vertices;
end

for vertices_idx = 1:vertices_counter
    ROI_struct(all_pos_vertices{vertices_idx}.idx_list).contour(all_pos_vertices{vertices_idx}.slice_now).segments(all_pos_vertices{vertices_idx}.contour_index).points = temp_parfor{vertices_idx}/10;
end
% dicom_hdr = dicominfo(filename);
%
%
%
% names_field1 = fieldnames(dicom_hdr.ROIContourSequence);
% names_field2 = fieldnames(dicom_hdr.StructureSetROISequence);
%
% ROI_n = numel(names_field1);
%
% name_list = {};
% for idx = 1:ROI_n
%     current_ROI_obj = getfield(dicom_hdr.StructureSetROISequence, names_field2{idx});
%     name_list{current_ROI_obj.ROINumber} = current_ROI_obj.ROIName;
% end
%
% for idx = 1:ROI_n
%     if idx == 10
%         display('here');
%     end
%     current_ROI_obj                        = getfield(dicom_hdr.ROIContourSequence, names_field1{idx});
%     ROI_struct(idx).roiNumber        = current_ROI_obj.ReferencedROINumber;
%     ROI_struct(idx).structureName = name_list{current_ROI_obj.ReferencedROINumber};
%     if isfield(current_ROI_obj, 'ContourSequence')
%         temp1= align_contour_on_slices(current_ROI_obj.ContourSequence, zV, x1, y1, z1, x2, y2, z2);
%         ROI_struct(idx).contour = temp1.contour;
%     else
%         ROI_struct(idx).contour.segments.points = [];
%     end
% end
%
close(h);

return;

function outvar = get_value_from_text(str1, str2, str3)
InputText=textscan(str1, '%s', 10, 'delimiter', '\n');
outvar = [];
for idx = 1:numel(InputText{1})
    if ~isempty(strfind(InputText{1}{idx}, str2))
        outvar = sscanf(InputText{1}{idx}, str3);
        break;
    end
end
return;