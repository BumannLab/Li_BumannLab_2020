function Shift_allFrames = ShiftCorrection(chansToStitch, source, avDir)

% add necessary paths
% if (~isdeployed)
%     p = mfilename('fullpath');
%     p = p(1:end-5);
%     addpath(p); 
% end

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
Shift_allFrames = zeros(optical_sections*physical_sections*tiles_num,9);
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
    phSec_name = strcat('test-',counter);

    for opt = 1:optical_sections
        tiles = tile_sequence(start_opt:start_opt+tiles_num-1);
        for t = 1:length(tiles)
            tile_name = sprintf('/*-%i_*.tif', tiles(t));
            d = rdir([source phSec_name tile_name]);
            IM = uint16(zeros(param.rows, param.columns, length(chansToStitch)));
            parfor i = chansToStitch
                % load 3 channels for one tile
                IM(:,:,i) = imread(d(i).name);
            end
            % calcualte a shift
            [shift_optim,stripe_size] =  sim_measureRows(IM,'line_difference');
            % save the values
            Shift_allFrames(Shift_allFrames(:,1)==frame & Shift_allFrames(:,2)==opt & Shift_allFrames(:,3)==tiles(t),4:end) =  [shift_optim; stripe_size]';
        end
        start_opt = start_opt + tiles_num;
        % save txt
        fid = fopen([avDir '/Shifts_per_tile.txt'], 'w');
        fprintf(fid, ['Fame\t','Optical_section\t','Tile\t','Shift1\t','Shift1\t','Shift1\t','Stripe1\t','Stripe2\t','Stripe3\n']);
        fprintf(fid, '%d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t \n', Shift_allFrames');
        fclose(fid);
    end
end




end



%% sim
function [shift_optim,stripe_size] = sim_measureRows(IM,method)

[M N] = size(IM(:,:,1));  
% emperically found subdivisions of a tile where the combo artifact changes
stripe_ratio = 0.12;
stripe_size = [floor(N*stripe_ratio);floor(N-N*stripe_ratio);N];

sim = zeros(7,length(stripe_size)); 
k = 1;
im1 = IM(:,:,1); 
im2 = IM(:,:,2); 
im3 = IM(:,:,3); 
for shift = -3:3
    % initialize the shift image for channel 1
    im1_shift =  IM(:,:,1);
    if shift >=0
        for rows = 2:2:size(im1_shift,1)
            im1_shift(rows,shift+1:end) = im1(rows,1:end-shift);
        end
    else
        for rows = 2:2:size(im1_shift,1)
            im1_shift(rows,1:end-abs(shift)) = im1(rows,abs(shift)+1:end);
        end
    end
    

    im2_shift =  IM(:,:,2);
    if shift >=0
        for rows = 2:2:size(im2_shift,1)
            im2_shift(rows,shift+1:end) = im2(rows,1:end-shift);
        end
    else
        for rows = 2:2:size(im2_shift,1)
            im2_shift(rows,1:end-abs(shift)) = im2(rows,abs(shift)+1:end);
        end
    end

    im3_shift =  IM(:,:,3);
    if shift >=0
        for rows = 2:2:size(im3_shift,1)
            im3_shift(rows,shift+1:end) = im3(rows,1:end-shift);
        end
    else
        for rows = 2:2:size(im3_shift,1)
            im3_shift(rows,1:end-abs(shift)) = im3(rows,abs(shift)+1:end);
        end
    end

    
    start_stripe = 0;
    for s = 1:length(stripe_size)%stripe_size:stripe_size:N
        stripes = stripe_size(s);
        im_stripe_shift = im1_shift(:,start_stripe+1:stripes);
        im_stripe = im1(:,start_stripe+1:stripes);
        
        im_stripe_shift2 = im2_shift(:,start_stripe+1:stripes);
        im_stripe_shift3 = im3_shift(:,start_stripe+1:stripes);
        
        im_stripe2 = im2(:,start_stripe+1:stripes);
        im_stripe3 = im3(:,start_stripe+1:stripes);
        % sum up the channels for more robust similarity measure
        im_stripe_shift = im_stripe_shift + im_stripe_shift2 + im_stripe_shift3;
        im_stripe = im_stripe + im_stripe2 + im_stripe3;
        % extract even and odd lines with the shifted and original image
        even_lines = im_stripe_shift(2:2:end,:);
        odd_lines = im_stripe(1:2:end,:);
        
        switch method
            case 'line_difference'
                sim(k,s) = sum(abs(even_lines(:)-odd_lines(:)));
            case 'norm_line_difference'
                sim(k,s) = sum(abs(double(even_lines(:) - odd_lines(:))/norm(double(even_lines(:))) ));
        end
    
        start_stripe = stripes;
     end
    k = k+1;
end
% figure, plot(sim(:))
% add a threshold to the similarity to exclude low differences - not
% prominant minima
sh_vec = -3:3; 
switch method
    case 'line_difference'
        thresh_sim1 = 3.7*10^4;
        thresh_sim2 = 3*10^4;
    case 'norm_line_difference'
        thresh_sim1 = 5;        
        thresh_sim2 = 1.5;
end

% add some limitations
if sum(sim(:,1)==0)>=2
 ind1 = 4;
else 
 [sim_optim1, ind1] = min(sim(:,1));
 % if the minima is too close to another values
 sorted_sim = sort (sim(:,1));

 if ~(abs(sorted_sim(1)-sorted_sim(end))<thresh_sim1)
     if (abs(sorted_sim(1)-sorted_sim(2))<thresh_sim2)
        ind11 = find(sim(:,1)==sorted_sim(2));
        % take the smallest shift
        if abs(sh_vec(ind11)) < abs(sh_vec(ind1))
            ind1 = ind11;
        end
     end
 else
     ind1 = 4;
 end
end
 
 if sum(sim(:,2)==0)>=2
     ind2 = 4;
 else
     [sim_optim2, ind2] = min(sim(:,2));
     % if the minima is too close to another values
     sorted_sim = sort (sim(:,2));
     if ~(abs(sorted_sim(1)-sorted_sim(end))<thresh_sim1)
         if (abs(sorted_sim(1)-sorted_sim(2))<thresh_sim2)
            ind21 = find(sim(:,2)==sorted_sim(2));
            if abs(sh_vec(ind21)) < abs(sh_vec(ind2))
                ind2 = ind21;
            end
         end
     else
         ind2 = 4;
     end
 end
 if sum(sim(:,3)==0)>=2
     ind3 = 4;
 else 
     [sim_optim3, ind3] = min(sim(:,3));
     % if the minima is too close to another values
     sorted_sim = sort (sim(:,3));
     if ~(abs(sorted_sim(1)-sorted_sim(end))<thresh_sim1)
         if (abs(sorted_sim(1)-sorted_sim(2))<thresh_sim2)
            ind31 = find(sim(:,3)==sorted_sim(2));
            if abs(sh_vec(ind31)) < abs(sh_vec(ind3))
                ind3 = ind31;
            end
         end
     else
         ind3 = 4;
     end
 end
     
shift_optim = [sh_vec(ind1); sh_vec(ind2); sh_vec(ind3)];
% take shift only [-2;2]
if shift_optim(1)>2 || shift_optim(1)<-2
    shift_optim(1) = 0;
end
if shift_optim(2)>2 || shift_optim(2)<-2
    shift_optim(2) = 0;
end
if shift_optim(3)>2 ||  shift_optim(3)<-2
    shift_optim(3) = 0;
end

% rgbIm_shift =shift_striped_image(im1,im2,im3,shift_optim,stripe_size, im_n,save_dir);



end