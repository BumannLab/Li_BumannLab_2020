function correctL1norm

% add necessary paths
% if (~isdeployed)
%     p = mfilename('fullpath');
%     p = p(1:end-5);
%     addpath(p); 
% end
% destination folder is average dir of the average images
userConfig=readStitchItINI;
avDir = [userConfig.subdir.rawDataDir,filesep,userConfig.subdir.averageDir];

% find the number of channels for stitching
chansToStitch=channelsAvailableForStitching;

% load all the tiles of all the channels
% break source into a path, filter, and extension
OBJECT=returnSystemSpecificClass;
param = OBJECT.readMosaicMetaData(getTiledAcquisitionParamFile);

% number of optical sections
optical_sections = param.layers;
% number of physical sections
physical_sections = param.sections;
% number of tiles per image
tiles_num = param.mrows*param.mcolumns;

% allocate memory for the matrix of shifts
M=param.rows; N = param.columns;
l1=400;
Shift_allFrames = zeros(optical_sections*physical_sections*tiles_num,4+(floor(N/l1)+1)*(floor(M/l1)+1));
Shift_allFrames(:,1) = reshape(repmat(1:physical_sections, optical_sections*tiles_num,1),[tiles_num*optical_sections*physical_sections 1]);
Shift_allFrames(:,2) = reshape(repmat(repmat(1:optical_sections,tiles_num,1),1,physical_sections),[optical_sections*physical_sections*tiles_num 1]); 
tile_sequence = 0:tiles_num*optical_sections*physical_sections-1;
Shift_allFrames(:,3) = tile_sequence; 
start_opt = 1;

for frame = 1:physical_sections
    if frame < 10 
      counter = strcat('000',int2str(frame)); 
    elseif frame < 100 
      counter = strcat('00',int2str(frame));   
    else
      counter = strcat('0',int2str(frame));   
    end
    phSec_name = strcat('/test-',counter);
    fprintf('Calculating shifts for frame %i...\n',frame);
    
    for opt = 1:optical_sections
        tiles = tile_sequence(start_opt:start_opt+tiles_num-1);
        for t = 1:length(tiles)
            tile_name = sprintf('/*-%i_*.tif', tiles(t));
            d = rdir([userConfig.subdir.rawDataDir phSec_name tile_name]);
            IM = uint16(zeros(param.rows, param.columns, length(chansToStitch)));
            parfor i = chansToStitch
                % load 3 channels for one tile
                IM(:,:,i) = imread(d(i).name);
            end
            % calcualte a shift
            [shift_optim,l1] =  sim_measure(IM,l1);
            % save the values
            Shift_allFrames(Shift_allFrames(:,1)==frame & Shift_allFrames(:,2)==opt & Shift_allFrames(:,3)==tiles(t),4:end) =  [l1,shift_optim]';
        end
        start_opt = start_opt + tiles_num;
        % save txt
%         fid = fopen([avDir '/MakeL1Correction.txt'], 'w');
% %         fprintf(fid, ['Fame\t','Optical_section\t','Tile\t','l1','Shifts\n']);
%         fprintf(fid, '%d', Shift_allFrames);
%         fclose(fid);

    end
    dlmwrite([avDir '/MakeL1Correction.txt'],Shift_allFrames)
end
dlmwrite([avDir '/MakeL1Correction.txt'],Shift_allFrames);



end



%% sim
function [SHIFT,l1] = sim_measure(IM,l1)

[M N] = size(IM(:,:,1)); 

thresh = 800;
IM(IM>thresh) = thresh;
rgbIm = uint8((double(IM)./double( max(IM(:)) ))*2^8);

i = 1:floor(N/l1);
sizVert = [1,l1*i];
SIM = zeros(7,floor(N/l1)+1,floor(N/l1)+1);


for i = 1:floor(N/l1)+1
    for j = 1:floor(N/l1)+1
    imagePatche = imcrop(rgbIm,[sizVert(j) sizVert(i) l1-1 l1-1]);
    if j==floor(N/l1)+1 && i~=floor(N/l1)+1
       imagePatche = imcrop(rgbIm,[sizVert(j) sizVert(i)  N-sizVert(j)-1 l1-1]);
    elseif i==floor(N/l1)+1 && j~=floor(N/l1)+1
       imagePatche = imcrop(rgbIm,[sizVert(j) sizVert(i) l1-1  M-sizVert(i)-1]);
    elseif j==floor(N/l1)+1 && i==floor(N/l1)+1
       imagePatche = imcrop(rgbIm,[sizVert(j) sizVert(i) N-sizVert(j)-1   M-sizVert(i)-1]);
    end


%     figure, imshow(imagePatche,[])
%     k = k+1
%     end
% end
k = 1;
        for Shift = -3:3
            imP1 = imagePatche(:,:,1);
            im1_shift = imP1 ;
            if Shift >=0
                for rows = 2:2:size(im1_shift,1)
                    im1_shift(rows,Shift+1:end) = imP1(rows,1:end-Shift);
                end
            else
                for rows = 2:2:size(im1_shift,1)
                    im1_shift(rows,1:end-abs(Shift)) = imP1(rows,abs(Shift)+1:end);
                end
            end
            
            imP2 = imagePatche(:,:,2);
              im2_shift =  imP2;
                if Shift >=0
                    for rows = 2:2:size(im2_shift,1)
                        im2_shift(rows,Shift+1:end) = imP2(rows,1:end-Shift);
                    end
                else
                    for rows = 2:2:size(im2_shift,1)
                        im2_shift(rows,1:end-abs(Shift)) = imP2(rows,abs(Shift)+1:end);
                    end
                end
                
                imP3 = imagePatche(:,:,3);
                im3_shift =  imagePatche(:,:,3);
                if Shift >=0
                    for rows = 2:2:size(im3_shift,1)
                        im3_shift(rows,Shift+1:end) = imP3(rows,1:end-Shift);
                    end
                else
                    for rows = 2:2:size(im3_shift,1)
                        im3_shift(rows,1:end-abs(Shift)) = imP3(rows,abs(Shift)+1:end);
                    end
                end
                
                im_shift = im1_shift+im2_shift+im3_shift;
                im_ = imagePatche(:,:,1)+imagePatche(:,:,2)+imagePatche(:,:,3);
                even_lines = im_shift(2:2:end,:);
                odd_lines = im_(1:2:end,:);
                if length(even_lines(:))<length(odd_lines(:))
                    odd_lines = im_(3:2:end,:);
%                 elseif length(even_lines(:))>length(odd_lines(:))
%                        even_lines = im_shift(4:2:end,:);
                end
                SIM(k,i,j) = sumabs((even_lines(:)-odd_lines(:)));
                k= k+1;

        end
    end
end

thresh_sim1 = 1000;%for 50x503.7*10^4;
thresh_sim2 = 500;%3*10^4;
sh_vec = -3:3;
SHIFT = zeros(1,(floor(N/l1)+1)*(floor(M/l1)+1)); k = 1;
% IMall = cell(floor(N/l1)+1,3);
for i = 1:floor(N/l1)+1
%     IM1 = [];
%     IM2 = [];
%     IM3 = [];
    for j = 1:floor(N/l1)+1
        sim = SIM(:,i,j);
%          imagePatche = imcrop(rgbIm,[sizVert(j) sizVert(i) l1-1 l1-1]);
%         if j==floor(N/l1)+1 && i~=floor(N/l1)+1
%            imagePatche = imcrop(rgbIm,[sizVert(j) sizVert(i)  N-sizVert(j)-1 l1-1]);
%         elseif i==floor(N/l1)+1 && j~=floor(N/l1)+1
%            imagePatche = imcrop(rgbIm,[sizVert(j) sizVert(i) l1-1  M-sizVert(i)-1]);
%         elseif j==floor(N/l1)+1 && i==floor(N/l1)+1
%            imagePatche = imcrop(rgbIm,[sizVert(j) sizVert(i) N-sizVert(j)-1   M-sizVert(i)-1]);
%         end
        
%         thresh_sim1 = (size(imagePatche,1)*size(imagePatche,2));
%         thresh_sim2 = (size(imagePatche,1)*size(imagePatche,2));
%         figure, plot(sim)

         if sum(sim(:)==0)>=2
             ind1 = 4;
         else 
             [sim_optim1, ind1] = min(sim);
%              if the minima is too close to another values
             sorted_sim = sort (sim);
            % if the difference between the 1 and the last is very small than no
            % shift
            
             if ~(abs(sorted_sim(1)-sorted_sim(end))<thresh_sim1)
                 % if the difference beween 2 smallest is not enough than take the
                 % smallest shift
                 if (abs(sorted_sim(1)-sorted_sim(2))<thresh_sim2)
                    ind11 = find(sim==sorted_sim(2));
                    if length(ind11)~=1
                        ind1 = 4;
                    end
                    % take the smallest shift
                    if abs(sh_vec(ind11)) < abs(sh_vec(ind1))
                        ind1 = ind11;
                    end
                 end
             else
                 ind1 = 4;
             end
         end
         shift_optim = sh_vec(ind1);
         if shift_optim(1)>2 || shift_optim(1)<-2
            shift_optim(1) = 0;
         end
         
         
         
%          
%          if shift_optim==0
% %              disp('No shift');
% %              figure, imshow(imagePatche,[])
%              rgbIm_shift = imagePatche;
%          else
%             rgbIm_shift =shiftImage(imagePatche,shift_optim);
% 
% %             figure, subplot(1,2,1),imshow(imagePatche,[])
% %                        subplot(1,2,2),imshow(rgbIm_shift,[]), title(sprintf('shift%i',shift_optim))
%          end
% 
%          IM1 = cat(2,IM1,rgbIm_shift(:,:,1));
%          IM2 = cat(2,IM2,rgbIm_shift(:,:,2));
%          IM3 = cat(2,IM3,rgbIm_shift(:,:,3));
         SHIFT(k) = shift_optim;
         k = k+1;

    end
%     IMall{i,1} = IM1;
%      IMall{i,2} = IM2;
%       IMall{i,3} = IM3;
end
% figure,plot(SHIFT)
% RGBim1=cat(1,IMall{1:floor(N/l1)+1,1});
% RGBim2=cat(1,IMall{1:floor(N/l1)+1,2});
% RGBim3=cat(1,IMall{1:floor(N/l1)+1,3});


end