function CorrectionTable = correctOpticalBrightness(source_dir,options)


paramFile=getTiledAcquisitionParamFile;
OBJECT=returnSystemSpecificClass;
param = readMosaicMetaData(OBJECT,paramFile,1);

save_dir = options.folder_destination;
method = options.BrightnessCorr_method;
if ~exist(fullfile(save_dir, 'BrightnessCorrection.txt'))
    CorrectionTable = table();
    for chan = 1:param.channels
        % build needed image brightness from the 1 optical section
        source = fullfile(source_dir, sprintf('%i',chan), sprintf('*_0%i.tif',1));
        [Model_needed, options] = getCorrectionModel(source, save_dir,1,chan,method);
        OptSec = 1;
        ratio = 1;
        Channel = chan;
        CorrectionTableChan = table(OptSec,ratio,Channel);

        for optS =2:param.layers
            source = fullfile(source_dir, sprintf('%i',chan), sprintf('*_0%i.tif',optS));
            Model_change = getCorrectionModel(source, save_dir,optS,chan,method);
            ratio = correctImages(Model_needed, Model_change,method);
            OptSec = optS;
            CorrectionTableRa = table(OptSec,ratio,Channel);
            CorrectionTableChan = [CorrectionTableChan; CorrectionTableRa]

        end
        CorrectionTable = [CorrectionTable; CorrectionTableChan]

    end

    writetable(CorrectionTable,fullfile(save_dir, 'BrightnessCorrection.txt'));
    options.BrightnessCorrecitonFilename =  fullfile(save_dir, 'BrightnessCorrection.txt');   
else
    disp('Brightness correction table already exist.')
    CorrectionTable = readtable(fullfile(save_dir, 'BrightnessCorrection.txt'));

end
