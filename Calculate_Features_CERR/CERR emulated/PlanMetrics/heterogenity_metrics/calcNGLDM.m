function s = calcNGLDM(scanArray3M, patchSizeV, numGrLevels, a, hWait)
% function s = calcNGLDM(scanArray3M, patchSizeV, numGrLevels, a, hWait)
%
% a: coarseness parameter
%
% Neighborhood gray level dependence matrix.
%
% APA, 03/16/2017

% Flag to draw waitbar
waitbarFlag = 0;
if exist('hWait','var') && ishandle(hWait)
    waitbarFlag = 1;
end

% Get indices of non-NaN voxels
calcIndM = ~isnan(scanArray3M);

% % Grid resolution
slcWindow = 2 * patchSizeV(3) + 1;
rowWindow = 2 * patchSizeV(1) + 1;
colWindow = 2 * patchSizeV(2) + 1;

% Build distance matrices
numColsPad = floor(colWindow/2);
numRowsPad = floor(rowWindow/2);
numSlcsPad = floor(slcWindow/2);

% Get number of voxels per slice
[numRows, numCols, numSlices] = size(scanArray3M);
numVoxels = numRows*numCols;

% Pad q, so that sliding window works also for the edge voxels
%scanArrayTmp3M = padarray(scanArray3M,[numRowsPad numColsPad
%numSlcsPad],NaN,'both'); % aa commented
q = padarray(scanArray3M,[numRowsPad numColsPad numSlcsPad],NaN,'both');
calcIndM = padarray(calcIndM,[0 0 numSlcsPad],0,'both');

% Create indices for 2D blocks
[m,n,~] = size(q);
m = uint32(m);
n = uint32(n);
colWindow = uint32(colWindow);
rowWindow = uint32(rowWindow);
slcWindow = uint32(slcWindow);

% Index calculation adapted from 
% http://stackoverflow.com/questions/25449279/efficient-implementation-of-im2col-and-col2im

%// Start indices for each block
start_ind = reshape(bsxfun(@plus,[1:m-rowWindow+1]',[0:n-colWindow]*m),[],1); %//'

%// Row indices
lin_row = permute(bsxfun(@plus,start_ind,[0:rowWindow-1])',[1 3 2]);  %//'
%lin_row = permute(bsxfun(@plus,start_ind,[0 patchSizeV(1) rowWindow-1])',[1 3 2]);  %//'

%// Get linear indices based on row and col indices and get desired output
% imTmpM = A(reshape(bsxfun(@plus,lin_row,[0:ncols-1]*m),nrows*ncols,[]));
indM = reshape(bsxfun(@plus,lin_row,(0:colWindow-1)*m),rowWindow*colWindow,[]);
%indM = reshape(bsxfun(@plus,lin_row,[0 patchSizeV(2) colWindow-1]*m),3*3,[]);

% [Fx,Fy] = gradient(q);
%Fx = abs(Fx);
%Fy = abs(Fy);

% domOrient3M = zeros(size(scanArray3M));
% domOrient2M = zeros(size(scanArray3M(:,:,1)));

% Initialize the s (NGTDM) matrix
maxNbhoodSz = prod(2*patchSizeV+1)-1;
%maxNbhoodSz = 8;
s = zeros(numGrLevels,maxNbhoodSz+1);


% Iterate over slices. compute cooccurance for all patches per slice
for slcNum = (1+numSlcsPad):(numSlices+numSlcsPad)
    
    
    calcSlcIndV = calcIndM(:,:,slcNum);    
    calcSlcIndV = calcSlcIndV(:);
    numCalcVoxs = sum(calcSlcIndV);
    indSlcM = indM(:,calcSlcIndV);
    slcV = slcNum-patchSizeV(3):slcNum+patchSizeV(3);
    nbhoodSiz = size(indSlcM,1);
    qM = zeros(length(slcV)*nbhoodSiz,numCalcVoxs,'single');
    mM = zeros(length(slcV)*nbhoodSiz,numCalcVoxs,'single');
    count = 1;
    for iSlc = slcV 
        qSlc = q(:,:,iSlc);
        maskSlcM = padarray(calcIndM(:,:,iSlc),[numRowsPad, numColsPad],0,'both');
        qM((count-1)*nbhoodSiz+1:count*nbhoodSiz,:) = qSlc(indSlcM);
        mM((count-1)*nbhoodSiz+1:count*nbhoodSiz,:) = maskSlcM(indSlcM);
        count = count + 1;
    end
    
    currentVoxelIndex = ceil(nbhoodSiz*length(slcV)/2);
    voxValV = qM(currentVoxelIndex,:);
    qM(currentVoxelIndex,:) = [];       
    % numNeighborsV = sum(mM,1)-1;
    % qM(:,:) = bsxfun(@rdivide,qM,numNeighborsV);
    voxMaskV = mM(currentVoxelIndex,:);
    mM(currentVoxelIndex,:) = []; 
    qM(isnan(qM)) = 0;
    qM = abs(bsxfun(@minus,qM,voxValV)) <= a;
    qM(~mM) = 0;
    qM = sum(qM,1);
    
    for lev = 1:numGrLevels
        indLevV = voxValV == lev & voxMaskV;
        valsV = qM(indLevV);
        s(lev,:) = s(lev,:) + accumarray(valsV(:)+1,1,[maxNbhoodSz+1 1])';
    end
            
    if waitbarFlag
        set(hWait, 'Vertices', [[0 0 slcNum/numSlices slcNum/numSlices]' [0 1 1 0]']);
        drawnow;
    end 
    
end

