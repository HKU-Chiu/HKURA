function structures = loadRT(dcm, imstruct, varargin)
% loadRT loads a DICOM RT Structure Set (RTSS) file and
% extracts the voxel segmentation/mask and metadata. If the centre of the voxel is inside the rtstruct polygon it is included.
%
% Important: The mask corresponds to image data loaded by loadRThelper, which is FLIPPED and ROTATED w.r.t. the MATLAB implementation dicomreadVolume.
% This mask orientation is the same as the result from the other github function dicomrt2matlab (https://github.com/ulrikls/dicomrt2matlab).
% To load an rtstruct file matching dicomreadVolume, try readDICOMdir from RADIOMICS by M.Vallieres (customized version in the mvalloader subfolder).
%
% This function may optionally also be passed an whitelist/blacklist atlas,
% whereby only structures matching the atlas include/exclude statements are
% returned. 
%
% Usage: structures = loadRT(dcm, imstruct, varargin)
%
% structures contains the mask field with a value of binary matrix. 
%
% The following variables are required for proper execution: 
%   dcm: string containing the path to the DICOM file 
%   imstruct: structure of reference image.  Must include fields:
%   frameRefUID, dimensions, width, position, and start.
%
%   varargin{1} (optional): cell array of atlas names, include/exclude 
%       regex statements, and load flags (if zero, matched structures will 
%       not be loaded)
%   varargin{2} (optional): flag indicating whether to ignore frame of
%       reference (1) or to verify it matches the CT (0, default)
%
% Output:
%   structures: cell array of structure names, color, start, width, 
%       dimensions, frameRefUID, and 3D mask array of same size as 
%       reference image containing fraction of voxel inclusion in structure
%
% Example:
%
%   % Load DICOM images
%   path = '/path/to/files/';
%   names = {
%       '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.1.dcm'
%       '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.2.dcm'
%       '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641582.274.3.dcm'
%   };
%   imagestruct = LoadDICOMImages(path, names); %or loadRThelper(path)
%
%   % Load DICOM structure set 
%   name = '2.16.840.1.114362.1.5.1.0.101218.5981035325.299641579.747.dcm';
%   structures = loadRT(fullfile(path, name), imagestruct);
%
% Original Author: Mark Geurts, mark.w.geurts@gmail.com
% Edited by: J. T. J. van Lunenburg
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.
  


% Read DICOM header info from file
info = dicominfo(dcm);
structures = cell(length(fieldnames(info.ROIContourSequence)), 1); % Initialize return variable (Why isn't this an array)
assert(~isempty(structures), "No contours were found");



% Loop through each StructureSetROISequence field
for roi_item = fieldnames(info.StructureSetROISequence)'
    
    % Store contour number
    n = info.StructureSetROISequence.(roi_item{1}).ROINumber;
    
    % Store the ROIName variable
    name = info.StructureSetROISequence.(roi_item{1}).ROIName;
    
    % Initialize load flag.  If this structure name matches a structure in 
    % the provided atlas with load set to false, this structure will not be 
    % loaded
    load = true;
    
    %% Compare name to atlas
    if nargin >= 4 && ~isempty(varargin{1}) && iscell(varargin{1})
        
        % Loop through each atlas structure
        for j = 1:size(varargin{1}, 2)

            % Compute the number of include atlas REGEXP matches
            in = regexpi(name, varargin{1}{j}.include);

            % If the atlas structure also contains an exclude REGEXP
            if isfield(varargin{1}{j}, 'exclude') 
                
                % Compute the number of exclude atlas REGEXP matches
                ex = regexpi(name, varargin{1}{j}.exclude);
                
            else
                % Otherwise, return 0 exclusion matches
                ex = [];
            end

            % If the structure matched the include REGEXP and not the
            % exclude REGEXP (if it exists)
            if size(in,1) > 0 && size(ex,1) == 0
                load = varargin{1}{j}.load;

                break; % Stop the atlas for loop, as the structure was matched
            end
        end

    end
    
    % If the load flag is still set to true
    if load 
        
        % If the structure frame of reference matches the image frame of 
        % reference
        if strcmp(imstruct.frameRefUID, info.StructureSetROISequence.(...
                roi_item{1}).ReferencedFrameOfReferenceUID) || ...
                (nargin >= 5 && varargin{2} == 1)
        
            % Store structure name
            structures{n}.name = name;
            
            % Store the frameRefUID
            structures{n}.frameRefUID = info.StructureSetROISequence.(...
                roi_item{1}).ReferencedFrameOfReferenceUID;

        % Otherwise, the frame of reference does not match
        else % Notify user that this structure was skipped
            throw(MException('CUSTOM:loadfail', 'frame of reference did not match the image'));
        end
        
    % Otherwise, the load flag was set to false during atlas matching
    else % Notify user that this structure was skipped
            disp(['Structure ', name, ' matched exclusion list from atlas', ...
                ' and will not be loaded']);
    end

end


% Initialize backup counter
nb = 0;

% Loop through each ROIContourSequence
for roi_item = fieldnames(info.ROIContourSequence)'
   
   % Increment backup counter
   nb = nb + 1;
   
    % Store contour number
    if isfield(info.ROIContourSequence.(roi_item{1}), 'ReferencedROINumber')
        n = info.ROIContourSequence.(roi_item{1}).ReferencedROINumber;
    else
        n = nb;
    end
    
    
    % If name was loaded (and therefore this contour matches the atlas
    if isfield(structures{n}, 'name')
        
        % Store the ROI color, if it exists
        if isfield(info.ROIContourSequence.(roi_item{1}), 'ROIDisplayColor')
            structures{n}.color = ...
                info.ROIContourSequence.(roi_item{1}).ROIDisplayColor';
        else
            structures{n}.color = [0 0 0];
        end

        % Inititalize
        structures{n}.volume = 0;
        structures{n}.points = cell(0);
        structures{n}.mask = false(imstruct.dimensions); 
        
        % If a contour sequence does not exist, skip this structure
        if ~isfield(info.ROIContourSequence.(roi_item{1}), 'ContourSequence')
            continue;
        end
        
        % Loop through each ContourSequence
        for slice_item = fieldnames(info.ROIContourSequence.(...
                roi_item{1}).ContourSequence)'
           
            % If no contour points exist skip to next sequence
            if info.ROIContourSequence.(roi_item{1}).ContourSequence.(...
                    slice_item{1}).NumberOfContourPoints == 0
                continue;
                
            else %load points
                
                % Read in the number of points in the curve, converting 
                % from mm to cm
                points = reshape(info.ROIContourSequence.(...
                    roi_item{1}).ContourSequence.(slice_item{1}).ContourData, ...
                    3, [])' / 10;
                
                
                if isempty(points)% If points are empty, warn user and continue
                        disp(['Structure ', structures{n}.name, ...
                            ' contains an empty contour']);
                    continue;
                end
                
                % Apply image orientation rotation, if available (otherwise assume HFS)
                rot = [1,1,1];
                if isfield(imstruct, 'position')

                    % Set rotation vector based on patient position
                    switch(imstruct.position)
                        case 'HFS'
                        rot = [1,1,1];
                        case 'HFP'
                        rot = [-1,-1,1];
                        case 'FFS'
                        rot = [-1,1,-1];
                        case 'FFP'
                        rot = [1,-1,-1];
                    end
                end
                
                % Re-orient points by rotation vector
                points = points .* repmat(rot, size(points, 1), 1);
                
                % Store original points
                structures{n}.points{length(structures{n}.points)+1} = ...
                    points;
                
                % Determine slice index by searching IEC-Y index using 
                % nearest neighbor interpolation
                slice = interp1(imstruct.start(3):imstruct.width(3):...
                    imstruct.start(3) + (imstruct.dimensions(3) - 1) ...
                    * imstruct.width(3), 1:imstruct.dimensions(3), ...
                    -points(1,3), 'nearest', 0);
                
                % If the slice index is within the reference image
                if slice ~= 0 %doesn't account for max+1 slice possibility?
                    
                    % Test if voxel centers are within polygon defined by 
                    % point data, adding result to structure mask.  Note 
                    % that voxels encompassed by even numbers of curves are 
                    % considered to be outside of the structure (ie, 
                    % rings), as determined by the addition test below
                    x = (points(:,2) + imstruct.start(2) + (imstruct.width(2) * (imstruct.dimensions(2) - 1) ) + imstruct.width(2)/2) / imstruct.width(2); %column
                    y = (points(:,1) - imstruct.start(1) + imstruct.width(1)/2) / imstruct.width(1); %row
                    mask = poly2mask(x, y, imstruct.dimensions(1), imstruct.dimensions(2));

                    % If the new mask will overlap an existing value, 
                    % subtract
                    if max(max(mask + structures{n}.mask(:,:,slice))) == 2
                        structures{n}.mask(:,:,slice) = ...
                            structures{n}.mask(:,:,slice) - mask;

                    else % Otherwise, add it to the mask
                        structures{n}.mask(:,:,slice) = structures{n}.mask(:,:,slice) + mask;
                    end

                % Otherwise, the contour data exists outside of the IEC-y 
                else % Warn the user that the contour did not match a slice
                        disp(['Structure ', structures{n}.name, ...
                            ' contains contours outside of image array']);
                end
            end
        end
        
        % Compute volumes from mask (note, this will differ from the true
        % volume as partial voxels are not considered)
        structures{n}.volume = sum(sum(sum(structures{n}.mask))) * ...
            prod(imstruct.width);
       
        % Copy structure width, start, and dimensions arrays from image
        structures{n}.width = imstruct.width;
        structures{n}.start = imstruct.start;
        structures{n}.dimensions = imstruct.dimensions;
        
    end
end

% Remove empty structure fields
structures = structures(~cellfun('isempty', structures));



