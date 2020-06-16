function MASK = SVMsegmentation(RED, GREEN, BLUE, SVMModel, inds,options)

% 
% 
% Usage:          SVMsegmentation(RED, GREEN, BLUE, SVMModel, inds,options)
%
% Input: RED      an image containing red color of the sample
%        GREEN    an image containing green color of the sample
%        BLUE     an image containing blue color of the sample
%        SVMModel a Support Vector Machine model obtained using InitializeYourModel
%        inds     index of the vertical posistion of the slice in the 3D
%                 image stack. It is needed for loading several images in parallel
%        options  structure containing information and parameters of the
%                 segmentation pipeline

%                 
%
% Output: MASK    is an image with ones and zeros where 1 - is an object to segment 
%                 and 0 - is a background    
%
%
%
% See also: InitializeYourModel, SVMsegmentation
%
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
% Author: Chicherova Natalia, 2019
%         University of Basel  

CPRE = ApplySVMModel(RED, GREEN, BLUE, SVMModel,inds, options);


% build a mask
MASK = cell(1,size(RED,2));

for i = 1:size(RED,2)
        red = RED{i};
        Mask = zeros(size(red));
        Mask(CPRE{i}==20) =1;
        
        MASK{i} = Mask;
end
 




function  CPRE = ApplySVMModel(RED, GREEN, BLUE, SVMModel,inds, options)
% paramFile=getTiledAcquisitionParamFile;
% OBJECT=returnSystemSpecificClass;
% param = readMosaicMetaData(OBJECT,paramFile,1);
if options.OptBrightCorrection
    % TO DO
    CorrectionTable = readtable(fullfile(options.folder_destination, 'BrightnessCorrection.txt'));
    ratioGreen = CorrectionTable.ratio( CorrectionTable.Channel==options.green);
    ratioGreen = repmat(ratioGreen,options.number_of_optic_sec*options.number_of_frames,1);
    ratioGreen = ratioGreen(inds);
    ratioRed = CorrectionTable.ratio( CorrectionTable.Channel==options.red);
    ratioRed = repmat(ratioRed,options.number_of_optic_sec*options.number_of_frames,1);
    ratioRed = ratioRed(inds);
    ratioBlue = CorrectionTable.ratio( CorrectionTable.Channel==options.blue);
    ratioBlue = repmat(ratioBlue,options.number_of_optic_sec*options.number_of_frames,1);
    ratioBlue = ratioBlue(inds);
    %param.layers
else
    ratioGreen = ones(size(RED,2),1);
    ratioRed = ones(size(RED,2),1);
    ratioBlue = ones(size(RED,2),1);
end
% to do brightness correction
test = cell(1,size(RED,2));
parfor i = 1:size(RED,2)
    gr = GREEN{i}.*ratioGreen(i);
    red = RED{i}.*ratioRed(i);
    bl = BLUE{i}.*ratioBlue(i);
    test{i}= [red(:), gr(:), bl(:)];
end

CPRE = cell(1,size(RED,2));
for i = 1:size(RED,2)
    fprintf('Predicting model %i...\n',i);
    cpre = predict(SVMModel,double(test{i}));
    CPRE{i} = cpre;
end