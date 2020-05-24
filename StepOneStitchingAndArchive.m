function experiment = StepOneStitchingAndArchive (~)

%Stitching the images from the rawData
% Before stitching we need to check the rawdata contains right images, the
% stitching parameters match the raw images
% Jiagui - Basel 2020


% Here you need to have rawData directory with all your data and a Mosaic.txt
source_dir = './'; 


% add path of all the scripts for tissuecyte (mainly stitching and Cidre and analysis).
addpath(genpath('/home/lijiag/Programming/')); 


cd (source_dir);

% make the ini file for experiment, please check parameters, such as objective
if ~exist('./stitchitConf.ini')    
	makeLocalStitchItConf    
end

% read info from Mosaic.txt 
M=readMetaData2Stitchit;

%% Check for and fix missing tiles if this was a TissueCyte acquisition
if strcmp(M.System.type,'TissueCyte')
    writeBlacktile = 0;  
    % 0, means will replace the missing tile with tiles just right up or down optical layer; 1, means will replace with black tile  
    missingTiles=identifyMissingTilesInDir('rawData',0,0,[],writeBlacktile);
else
    missingTiles = -1;
end


%% correct background illumination with cidre; if no need to do any illumination correction, this line should not be run. Other option ('basic') available
alternativeIlluminationCorrection('cidre');


%% stitch all the data
stitchAllChannels

%% Archive
% After stitching, we need compress the raw data and copy to a folder to
% archive. Here we need to run linux command. First step compress, then
% copy to M dirve folder for long term storage, at last remove rawData
% folder in the computer.
%
%You need to input a name of the experiment, here example with name 'test'
%
NameRaw = 'test'
command = strcat('tar -I lbzip2 -cvf ', NameRaw, '_rawData.tar.bz ./rawData;cp -f -r ./*tar.bz /mnt/rg-db01-data01/Data/ToBeArchived/rawData/;rm -r ./rawData/;rm -r ./*.tar.bz');
status = system(command)




 
 
 
 
 