function ROI_struct = DICOMRT_reader_match_image_multi_RT(filename, handles);%, zV, x1, y1, z1, x2, y2, z2)

zV = -fliplr(handles.zV_original);

name_list = {};
ROI_counter = 0;
for file_idx = 1:length(filename)
    dicom_hdr = dicominfo(filename{file_idx});
    names_field1 = fieldnames(dicom_hdr.ROIContourSequence);
    names_field2 = fieldnames(dicom_hdr.StructureSetROISequence);
    
    ROI_n = numel(names_field1);
    
    for idx = 1:ROI_n
        ROI_counter = ROI_counter +1;
        current_ROI_obj                          = getfield(dicom_hdr.StructureSetROISequence, names_field2{idx});
        name_list{ROI_counter}                   = [current_ROI_obj.ROIName '_file' num2str(file_idx)];
        current_ROI_obj                          = getfield(dicom_hdr.ROIContourSequence, names_field2{idx});
        ROI_struct(ROI_counter).roiNumber        = current_ROI_obj.ReferencedROINumber;
        ROI_struct(ROI_counter).structureName    = name_list{ROI_counter};
        if isfield(current_ROI_obj, 'ContourSequence')
            temp1= align_contour_on_slices(current_ROI_obj.ContourSequence, fliplr(-handles.Primary_image_obj.zV), ...
                fliplr(handles.Primary_image_obj.yV), handles.Primary_image_obj.xV, fliplr(-handles.Primary_image_obj.zV), ...
                fliplr(handles.Primary_image_obj.xV), fliplr(handles.Primary_image_obj.yV), fliplr(-handles.Primary_image_obj.zV));
            ROI_struct(ROI_counter).contour = temp1.contour;
        else
            ROI_struct(ROI_counter).contour.segments.points = [];
        end
    end
end

name_list{end+1} = 'merged_for_KC';

ROI_struct(end+1).roiNumber = ROI_counter+1;
ROI_struct(end).structureName = name_list{end};

ROI_counter2 = 0;
for file_idx = 1:length(filename)
    dicom_hdr = dicominfo(filename{file_idx});
    names_field1 = fieldnames(dicom_hdr.ROIContourSequence);
    names_field2 = fieldnames(dicom_hdr.StructureSetROISequence);
    
    ROI_n = numel(names_field1);
    for idx1 = 1:ROI_n
        ROI_counter2 = ROI_counter2+1;
        current_ROI_obj                        = getfield(dicom_hdr.ROIContourSequence, names_field1{ROI_n});
        
        if isfield(current_ROI_obj, 'ContourSequence')
            temp1= align_contour_on_slices(current_ROI_obj.ContourSequence, fliplr(-handles.Primary_image_obj.zV), ...
                fliplr(handles.Primary_image_obj.yV), handles.Primary_image_obj.xV, fliplr(-handles.Primary_image_obj.zV), ...
                fliplr(handles.Primary_image_obj.xV), fliplr(handles.Primary_image_obj.yV), fliplr(-handles.Primary_image_obj.zV));
            if idx1 == 1
                ROI_struct(end).contour = temp1.contour;
            else
                if isempty(ROI_struct(end).contour)
                    ROI_struct(end).contour = temp1.contour;
                else
                    for idx = 1:length(temp1.contour)
                        if ~isempty(temp1.contour(idx).segments)
                            ROI_struct(end).contour(idx).segments(end+1:end+length(temp1.contour(idx).segments)) = temp1.contour(idx).segments;
                        end
                    end
                end
            end
        end
    end
end
return;
