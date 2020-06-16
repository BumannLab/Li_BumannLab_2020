function saveSegmentedPatches(sourceD,frame,optical,segmentation_dir,shift,varargin)
%
% To check the compartments, we need to crop the area with bacteria.
% for some datasets with less perfect trained model, we need to crop the
% bacteria out for manuel check. This function could locat and crop them
% out and save in small images.
%
%
% By Jiagui Li Basel 2019



if nargin > 4
    doMask = varargin{1};
else doMask = 0;
end


% save patches
save_dir = fullfile(segmentation_dir, 'Patches');
if ~exist(save_dir)
    mkdir(save_dir)
end


if frame < 10
  counter = strcat('00',int2str(frame)); 
elseif frame < 100 
  counter = strcat('0',int2str(frame));   
else
  counter = int2str(frame);   
end
prefix = 'section_';
name = strcat(prefix, counter);
% load a mask after svm segmentation 
mask_name = fullfile(segmentation_dir, [name, '_0' int2str(optical) ,'.pbm'])

% Load the mask   
BW = imread(mask_name);

if sum(BW(:))>0

    %load the stitched images
    ext = '.tif';
    green = imread(fullfile(sourceD, '2',[name, '_0',  int2str(optical), ext]));
    red = imread(fullfile(sourceD, '1', [name, '_0',  int2str(optical), ext]));
    blue = imread(fullfile(sourceD, '3', [name, '_0',  int2str(optical), ext]));
    rgbIm =  cat(3, red,green,blue);

    if doMask
       rgbIm = rgbIm.*uint16(BW);
    end
    cc = bwconncomp(BW,8);
    s = regionprops(cc,'basic');
    centroids = cat(1, s.Centroid);
    rect = round(cat(1,s.BoundingBox));

    
 
    for i =1:size(centroids,1)
        rect2 = rect(i,:);

        if shift > rect2(1) || shift > rect2(2) || rect2(1)+shift>size(red,2) || rect2(2)+shift>size(red,1)
            shift = 0;
            IM = imcrop(rgbIm,[rect2(1)-shift/2 rect2(2)-shift/2 rect2(3)+shift rect2(4)+shift]);
        else
            IM = imcrop(rgbIm,[rect2(1)-shift/2 rect2(2)-shift/2 rect2(3)+shift rect2(4)+shift]);
        end
       
        name2  = sprintf('Frame_%i_optical_%i_Bacterium_%i_patch.tif',frame,optical,i);
        imwrite(IM,fullfile(save_dir, name2));

    end
end


