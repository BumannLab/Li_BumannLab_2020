%% StepTwoSegmentationAndAnalysis
%
%We combined functions by Natalia and Jiagui for 
%
% Jiagui LI - Basel 2020



% All tissuecyte related folders should be loaded for matlab
addpath(genpath('/home/lijiag/Programming/'));

%% If no model file availabe, you need to create a new model file based on the SVM.

sourceD = '/media/natasha/0C81DABC57F3AF06/Data/Spleen_data/20170223_D5_GFPfil/stitchedImages_100/';

% load an image which has the largest amount of objects of interest (bacteria)
red_name = [sourceD '1/section_004_01.tif']; % point to the red channel image
green_name = [sourceD '2/section_004_01.tif'];
blue_name = [sourceD '3/section_004_01.tif'];

% Build a new model or improve one exist model
[SVMModel, model_name] = InitializeYourModel(red_name, green_name, blue_name);





%% segmentation with a model.
% get full path of the model
model_name = '/home/natasha/Programming/GitHub_clone/BacteriaSegmentationSVM/models/20170223_D5_GFPfil';

%segment the object in the entire data set
AllBacteriaSegmentation(sourceD,model_name,'object','bacteria','show',1,'filter_artifacts',1,'brightness_correction',1,...
    'number_pix_lowest',2,'number_of_images',1);



%% save pathes with bacteria and/or compartments
%For the purpose of checking compartments, we need to crop the images with
%the bacteria in the centre.
%For controling the quality of the trained models, we also need to crop the
%small images to confirm artifacts or bacteria with a larger scale.
%When do the croping, with the size of shift, 400 pixels for compartments, 100 pixels for bactetria

addpath(genpath('/home/natasha/Programming/GitHub_clone/DataAnalysis_scripts/'));
segmentation_dir = '/media/natasha/0C81DABC57F3AF06/Data/Spleen_data/20170223_D5_GFPfil/Segmentation_results_bacteria_beforeCNN/SegmenatationPerSlice/';
shift = 400; 
for frame = 93
    for optical = 2
%       show_segmentation_resutlsPatches(sourceD,frame,optical,segmentation_dir,0,1);
        saveSegmentedPatches(sourceD,frame,optical,segmentation_dir, shift);
    end
end



