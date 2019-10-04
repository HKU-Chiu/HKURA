function ReviewInfo=Test_ReviewFunc(ReviewInfo)

MaskData=ReviewInfo.MaskData;
figure, plot(MaskData(:, 1), MaskData(:, 2), 'm');

ReviewInfo.Test=1;