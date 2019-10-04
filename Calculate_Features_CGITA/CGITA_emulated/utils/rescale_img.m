function out_img = rescale_img(in_img, min1, max1)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

out_img = (in_img-min1)/(max1-min1)*255;
out_img(out_img<0) = 0;
out_img(out_img>255) = 255;
out_img = out_img/255;
return;

