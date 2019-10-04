function [ResultStruct, ResultStructBW]=Laws_Filter(CDataSetInfo, Param)
%%%Doc Starts%%%
%-Description: 
%This method is to perform Law's image filters in slice-by-slice. 

%-Parameters:
%1.  averWindSize: Size of the average window of Law's filters.

%-Revision:
%2016-06-14: The method is implemented.

%-Author:
%Joy Zhang, lifzhang@mdanderson.org
%Young Yul Kim, yk13@rice.edu
%%%Doc Ends%%%


%--Parameters
[MFilePath, MFileName]=fileparts(mfilename('fullpath'));

if nargin < 2    
    ConfigFile=[MFilePath, '\', MFileName, '.INI'];
    
    Param=GetParamFromINI(ConfigFile);   
     
end

%Parameter Check
if ~isfield(Param,'averWindSize')
    ResultStruct=[];
    ResultStructBW=[];
    return;
end

%--Preprocess
%Kernel
FilterKernel={};
FilterKernel{1}=[1 4 6 4 1];
FilterKernel{2}=[-1 -2 0 2 1];
FilterKernel{3}=[-1 0 2 0 -1];
FilterKernel{4}=[1 -4 6 -4 1];

ROIImageInfo=CDataSetInfo.ROIImageInfo;

%Filter
smooth = ones(Param.averWindSize,Param.averWindSize)/(Param.averWindSize^2);
for i=1:CDataSetInfo.ROIImageInfo.ZDim
    CurrentData=ROIImageInfo.MaskData(:, :, i);
    CurrentData=imfilter(CurrentData,smooth,'conv','symmetric');
    filtered2D={};
    for k=1:size(FilterKernel,2)
        for j=1:size(FilterKernel,2)
            temp=FilterKernel{k}'*FilterKernel{j};
            filtered2D{end+1}=imfilter(CurrentData,temp);
        end
    end
    
    CurrentData=0.5*filtered2D{2}+0.5*filtered2D{5};
    ROIImageInfo.MaskData(:, :, i)=CurrentData;
end

%Return Value
ROIImageInfo.Description=MFileName;
ResultStruct=ROIImageInfo;
ResultStructBW=CDataSetInfo.ROIBWInfo;






