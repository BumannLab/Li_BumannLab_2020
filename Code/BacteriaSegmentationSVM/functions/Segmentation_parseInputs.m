function options = Segmentation_parseInputs(v)  
% Parses the arguments and fills the options structure with
% default parameter values 
%
% Usage:  OPTIONS = Segmentation_parseInputs(v)
%
% Input:  V a cell containing arguments from the AllBacteriaSegmentation (from varargin)
%
% Output: OPTIONS a structure containing various parameter values needed by
%         slice to volume registration
%
% See also: AllBacteriaSegmentation
%
% From the project, (https://github.com/Fouga/).
% Author: Chicherova Natalia, 2019
%         University of Basel  

if ~isempty(v)
    if iscell(v{1})
        v = v{1};
    end
end
% read mosaic file to find 3D resolution
paramFile=getTiledAcquisitionParamFile;
OBJECT=returnSystemSpecificClass;
param = readMosaicMetaData(OBJECT,paramFile,1);
%% options that may be specified by the user
options.Object = 'bacteria'; % can be 'neutrophil'
options.showImage = 0;  
options.filtering = 0;
options.RegionGrow = 0;
options.Filter3D = 1;
options.FilterCNN = 0;
options.OptBrightCorrection = 0;
options.NumPixThresh = 2;
options.red = 1;
options.green = 2;
options.blue = 3;
options.number_of_images = 5;
options.one_image_segmenation = [];
% read from Mosaic*.txt
options.xres = param.xres;
options.yres = param.yres;
options.zres = param.zres*2;

options.Object = 'bacteria'; % can be 'neutrophil'
options.folder_destination      = [];
 

if nargin==0 || isempty(v)
    return
end

% handle the input parameters, provided in (string, param) pairs
for i = 1:numel(v)
    if ischar(v{i})
            switch lower(v{i})
            case 'object'
                options.Object = getParam(v,i);            
             case 'show'
                options.showImage   = getParam(v,i);   
             case 'filter_artifacts'
                options.filtering  = getParam(v,i);         
             case 'region_growing'
                options.RegionGrow   = getParam(v,i);     
             case 'filter3d'
                options.Filter3D   = getParam(v,i);  
             case 'filter_cnn'
                options.FilterCNN   = getParam(v,i);  
             case 'brightness_correction'
                options.OptBrightCorrection   = getParam(v,i);  
             case 'number_pix_lowest'
                options.NumPixThresh  = getParam(v,i);  
            case 'destination'
                options.folder_destination = getFolder(v,i);   
            case 'red'
                options.red = getParam(v,i); 
            case 'green'
                options.green = getParam(v,i);  
            case 'blue'
                options.blue = getParam(v,i);  
            case 'number_of_images'
                options.number_of_images= getParam(v,i);  
            case 'one_image_segmenation'
                options.one_image_segmenation= getParam(v,i); 
            end
    end 
end

    % sort the options alphabetically so they are easier to read
options = orderfields(options);


% get parameters from the inputs
function param = getParam(v,i)

param = [];
if i+1 <= numel(v)
    if isnumeric(v{i+1})
        param = v{i+1};
    elseif isstr(v{i+1})
                param = v{i+1};

    else
        warning('SVMsegmentation:parseInput', 'Expected numeric value\n');
    end
end


function param = getFolder(v,i)

param = [];
if i+1 <= numel(v)
    if isdir(v{i+1})
        param = v{i+1};
    else
        if isstr(v{i+1});
            param = v{i+1};
            [success message] = mkdir(param);
            if ~success
                warning('SVMsegmentation:parseInput', message);
            end
        else
            warning('SVMsegmentation:parseInput', 'Expected destination path value\n');
        end
    end
end


