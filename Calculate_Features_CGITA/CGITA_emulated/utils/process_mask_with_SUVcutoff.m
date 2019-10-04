function mask = process_mask_with_SUVcutoff(mask, img1, SUV_cutoff)

label1 = bwlabeln(mask);

if max(label1(:)) == 1    
    mask_1 = imdilate(mask, ones(3,3,3));
    mask_2 = imerode(mask, ones(3,3,3));
    mask_new = mask_1-mask_2;
    mask_new(img1<SUV_cutoff & mask_new==1) = 0;
    mask = imfill(mask_new, 'holes');

else
    mask_all = zeros(size(mask,1), size(mask,2), size(mask,3));
    for idx1 = 1:max(label1(:))
        mask = label1==idx1;
        mask_1 = imdilate(mask, ones(3,3,3));
        mask_2 = imerode(mask, ones(3,3,3));
        mask_new = mask_1-mask_2;
        mask_new(img1<SUV_cutoff & mask_new==1) = 0;
        mask = imfill(mask_new, 'holes');
        mask_all = mask_all+mask;
    end
    mask = mask_all;
end

%     idx_max = find(img1==max(img1(mask==1)));
%     if length(idx_max)>1
%         for idx_temptemp = 1:length(idx_max)
%             if mask(idx_max(idx_temptemp))==1
%                 idx_max = idx_max(idx_temptemp);
%                 break;
%             end
%         end
%     end
%     label_temptemp = bwlabeln(img1>SUV_cutoff, 6);
%     mask_new = label_temptemp == label_temptemp(idx_max);
%     mask = imfill(mask_new, 'holes');    
return;