%% Script here is writen for distinguish the artifacts from YFP signals produced during YFP segmentation by SVM or thresholding.
%% Before you start, please make sure you have 'Matlab deep learning tool kit' installed. Main code please see following links.
%% Citation: https://ch.mathworks.com/help/deeplearning/ug/create-simple-deep-learning-network-for-classification.html
%% Jiagui LI -- 2020

close all;
clear all;


%Load and Explore Image Data
digitDatasetPath = fullfile ('D:\20200602_CNN','for trainingPixel12Folder2');

%Images file into images datastore
imds = imageDatastore(digitDatasetPath, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');

%Display some of the images in the datastore.
figure;
perm = randperm(1000,10);
for i = 1:10
    subplot(2,5,i);
    imshow(imds.Files{perm(i)});
end

%%Calculate the number of images in each category. 
labelCount = countEachLabel(imds)

%%You must specify the size of the images in the input layer of the network.
img = readimage(imds,1);
size(img)

%%Specify Training and Validation Sets
numTrainFiles = 600;
%numValidateFiles = 900;
[imdsTrain,imdsValidation] = splitEachLabel(imds,numTrainFiles,'randomize'); %splitEachLabel(imds,numTrainFiles,'randomize');


%% Define the convolutional neural network architecture.

layers = [
    imageInputLayer([15 15 3])  %430x370x3   For 3-D image input, use image3dInputLayer.RGB color should be [28 28 3]
    
    convolution2dLayer(3,8,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
        
    fullyConnectedLayer(2) %Important, this number depends on the folder numbers
     
    softmaxLayer
    classificationLayer];

%%Specify Training Options
options = trainingOptions('sgdm', ...
    'InitialLearnRate',0.01, ...
    'MaxEpochs',10, ...
    'Shuffle','every-epoch', ...
    'ValidationData',imdsValidation, ...
    'ValidationFrequency',30, ...
    'Verbose',false, ...
    'Plots','training-progress');

%%Train Network Using Training Data
net = trainNetwork(imdsTrain,layers,options);

%%Classify Validation Images and Compute Accuracy
[YPred,scores] = classify(net,imdsValidation);
YValidation = imdsValidation.Labels;
accuracy = sum(YPred == YValidation)/numel(YValidation)



%Test samples
digitDatasetPathTest = fullfile('D:\20200602_CNN\for trainingPixel12Folder2\R2500G550B450artifact');
imdsTest = imageDatastore(digitDatasetPathTest, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');
[TestPred, TestScore] = classify(net,imdsTest); % Export the results

rownames = {'Predict';'FileAddress';'ScoreArtifact';'ScoreYFP'};
ResultsTest = table(categorical(TestPred),categorical(imdsTest.Files),TestScore(:,1), TestScore(:,2),'VariableNames',rownames);% Combine the results for print



%Save the results

fid = fopen('YourFile.txt','w');
writetable(ResultsTest); % As we summary the result in table not in cat, so we do not use ResultsTest = ResultsTest' and fprintf(fid,'%s %s\n',ResultsTest);any more
fclose(fid);

%Any time after training it and before deleting it. However, give it a unique name so that it is not overwritten 
%or used by mistake. 
 gregnet1 = net;
 save gregnet1
 
 
 
% %If you want to load pretrained net file
close all;
clear all;

% Load pretrained net 
 netLoad = load('gregnet1.mat'); 
 net = netLoad.net

% Give the address of images need to be tested 
digitDatasetPathTest = fullfile('D:\20200602_CNN\for trainingPixel12Folder2\R2500G550B450yfp');
imdsTest = imageDatastore(digitDatasetPathTest, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');

[TestPred, TestScore] = classify(net,imdsTest); % Export the results
rownames = {'Predict';'FileAddress';'ScoreArtifact';'ScoreYFP'};
ResultsTest = table(categorical(TestPred),categorical(imdsTest.Files),TestScore(:,1), TestScore(:,2),'VariableNames',rownames);% Combine the results for print

% Write and save the results
fid = fopen('YourFile.txt','w');
writetable(ResultsTest); % As we summary the result in table not in cat, so we do not use ResultsTest = ResultsTest' and fprintf(fid,'%s %s\n',ResultsTest);any more
fclose(fid);

 
