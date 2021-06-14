%% Worker loop
%%
clear
clc
%% Setup
% To process all folders for one colour worker or queen, two text files are
% needed PER folder, stored in the GetParameters Folder.
% - F1 and F2 parameters in one textfile
% - ROI values stored in another
% The loop then looks at each folder, looks for these files, then applies
% the parameters in order to detect colours

% To get these parameter files, use the other script - it will create txt
% files for each folder in a given location. Or, if you need to tweak each
% folder, use the "Single_folder_loop" script to tweak things. Then move
% the output txt files to the GetParametersFolder

%% Specify folder inputs
        getInputFolder = uigetdir([],"Choose Input Folder");
        getOutputFolder = uigetdir([],"Choose Output Folder");
        getParametersFolder = uigetdir([],"Choose Parameters Folder");
end

% Check if all folders exist
if ~isfolder(getInputFolder)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s\nCheck your folder paths again', getInputFolder);
    uiwait(warndlg(errorMessage));
    return
end
if ~isfolder(getOutputFolder)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s\nCheck your folder paths again', getOutputFolder);
    uiwait(warndlg(errorMessage));
    return
end
if ~isfolder(getParametersFolder)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s\nCheck your folder paths again', getParametersFolder);
    uiwait(warndlg(errorMessage));
    return
end
if ~isfolder(getTrialsProcessedFolder)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s\nCheck your folder paths again', getTrialsProcessedFolder);
    uiwait(warndlg(errorMessage));
    return
end

% Create path for txtfile with list of trials with the invader name, in
% order to later skip the first 100 images or so
Invader_trials_path = sprintf("%s",getParametersFolder,"\Invader_trials_list.txt");
if ~isfile(Invader_trials_path)
    errorMessage = sprintf("Error: The list of invader trials doesn't exist!");
    uiwait(warndlg(errorMessage));
    return
else
    % Read trials to be processsed if they do exist
    Invader_trials_to_process = readtable(Invader_trials_path,"Delimiter","tab");
    Invader_trials_to_process = table2array(Invader_trials_to_process);
    fprintf("%s\n","Successfully found text file with list of invader folders")
end

% Get directory of folders
InputFolders = dir(getInputFolder);
OutputFolders = dir(getOutputFolder);
ParametersFolder = getParametersFolder; % don't need directory yet

% Specify worker colour using UI input with list of options
list = {'darkblue','lightblue','green','yellow','red','orange','pink'};
[indx,tf] = listdlg('ListString',list,"SelectionMode","Single");

prompt_message = "Do you want to process worker or queen images";
answers = questdlg(prompt_message,"Pick an option","Worker","Queen","Queen");
% Handle response
switch answers
    case 'Worker'
        ant_colour = sprintf("%s","Workers_",list{indx});
    case 'Queen'
        ant_colour = sprintf("%s","Queen_",list{indx});
    otherwise
        return
end
%
% Creat txt file name for storing txtfile with list of trials that have
% been processed (doesn't need to be in loop)
txtfile_name_trials_processed = sprintf("%s", getTrialsProcessedFolder,"\",ant_colour,"_Trials processed.txt");
if ~isfile(txtfile_name_trials_processed)
    writematrix(["Trials processed"],txtfile_name_trials_processed,"Delimiter","tab");
else
    fprintf("%s\n","Trials processed txt file already exists, NOT overwriting")
end

% Remove . and .. from folder.name (this refers to parent folders, not needed)
InputFolders = InputFolders(~ismember({InputFolders.name}, {'.', '..'}));
OutputFolders = OutputFolders(~ismember({OutputFolders.name}, {'.', '..'}));

% Sort folder order correctly with a file exchange function nasortfiles
% (must have nasortfiles downloaded and in your matlab project folder path)
[~,ndx] = natsortfiles({InputFolders.name});
InputFolders = InputFolders(ndx);
[~,ndx] = natsortfiles({OutputFolders.name});

% Check if folder length is equal
if isequal(length(InputFolders),length(OutputFolders))
    fprintf("Length of input and output folders match (%s)\n",num2str(length(InputFolders)));
else
    error("Folder length does not match - check directories again!")
end

tic % start timer

for k = 1:length(InputFolders);
    
    % Generate folder paths
    Input = sprintf("%s",InputFolders(k).folder,"\",InputFolders(k).name);
    Output = sprintf("%s",OutputFolders(k).folder,"\",InputFolders(k).name,"\");
    Current_folder = InputFolders(k).name;
    
    % Get a list of all JPG files in the folder
    filePattern = fullfile(Input, '*.JPG');
    jpgFiles = dir(filePattern);
    
    % Sort jpg files using nasortfules function, filexchange
    [~,ndx] = natsortfiles({jpgFiles.name});
    jpgFiles = jpgFiles(ndx);
    
    % Get a list of txt files in parameters folder
    filePatternTxt = fullfile(ParametersFolder,"*.txt"');
    txtFiles = dir(filePatternTxt);
    
    [~,ndx] = natsortfiles({txtFiles.name});
    txtFiles = txtFiles(ndx);
    
    if isfile(sprintf("%s",ParametersFolder,"\",InputFolders(k).name,"_",ant_colour,"_ROI.txt")) && ...
            isfile(sprintf("%s",ParametersFolder,"\",InputFolders(k).name,"_",ant_colour,".txt"))
        fprintf("Parameters and ROI files found for %s%s%s%s \n",InputFolders(k).name,"_",ant_colour, ", processing...");
        
        % Read in ROI values from pre-existing txt file
        ROI_path = sprintf("%s",ParametersFolder,"\",InputFolders(k).name,"_",ant_colour,"_ROI.txt");
        ROI_table = readtable(ROI_path);
        ROI_table_values = ROI_table(:,2);
        ROI_table_values = table2cell(ROI_table_values);
        aMean = ROI_table_values{1};
        bMean = ROI_table_values{2};
        
        % Read in parameters from pre-existing txt file
        Parameters_path = sprintf("%s",ParametersFolder,"\",InputFolders(k).name,"_",ant_colour,".txt");
        Parameters_table = readtable(Parameters_path);
        table_values = Parameters_table(:,3);    % index the third column
        table_values = table2cell(table_values); % convert to cells, so don't have to index both row and column
        
        % Index parameter values from the txt file
        F1Parameters.adaptedThresholdValue = table_values{1};
        F1Parameters.BWopenValue = table_values{2};
        F1Parameters.seDiskValue = table_values{3};
        F2Parameters.distLab_ThresholdValue = table_values{4};
        F2Parameters.seDiskValue = table_values{5};
        F2Parameters.smallestPixelSize = table_values{6};
        F2Parameters.largestPixelSize = table_values{7};
        F2Parameters.maxNumberofAnts = table_values{8};
        F2Parameters.circularity_min_size = table_values{9};
        F2Parameters.luminanceMax = table_values{10};
        F2Parameters.luminanceMin = table_values{11};
        F2Parameters.AChannelMax  = table_values{12};
        F2Parameters.AChannelMin = table_values{13};
        F2Parameters.BChannelMin = table_values{14};
        F2Parameters.BChannelMax = table_values{15};
        F2Parameters.gaussian_filterValue = table_values{16};
        F2Parameters.MinExtent = table_values{17};
        F2Parameters.MaxExtent = table_values{18};
        F2Parameters.FinalMaxPixelSize = table_values{19};
        
        % create name values for output files, may not need all
        txtfile_name = sprintf("%s",Output,InputFolders(k).name,"_",ant_colour);
        txtfile_name_parameters = sprintf("%s",txtfile_name,".txt");
        txtfile_name_ROI = sprintf("%s",txtfile_name,"_","ROI.txt");
        txtfile_name_coords = sprintf("%s",txtfile_name,"_","coordinates.txt");
                
        % Append trials processed txt file, with current folder
        writematrix([InputFolders(k).name],txtfile_name_trials_processed,"WriteMode","append", "Delimiter","tab");
        
       
        % Try and write txt file of coordinates at default location - if
        % file is locked, then use alternative txt file name to avoid
        % script stopping
        try
            if ~isfile(txtfile_name_coords)
                % create txt file with headers to be appended later in loop, storing image name, coordinates, and area of blob
                writematrix(["Image","X","Y","Area","Circularity","Extent","Height","Width"],txtfile_name_coords,"Delimiter","tab"); % write matrix to txt file. This OVERWRITES the previous file if run a second time
            else
                fprintf("Txtfile with coords already exists, not overwriting\n")
            end
        catch
            fprintf("Coordinate txt file locked, CHECK TRIAL! \n")
            writematrix([InputFolders(k).name, "ERROR - Coord file COULD BE LOCKED. Check trial!"],txtfile_name_trials_processed,"WriteMode","append", "Delimiter","tab");c
            continue
        end
        
        % Run loop function
        ProcessAntImages(jpgFiles,F1Parameters,F2Parameters, aMean, bMean, Output,txtfile_name_coords,ant_colour,Current_folder,Invader_trials_to_process,txtfile_name);
        
    else fprintf("Parameter and ROI files not found for %s%s%s%s \n",InputFolders(k).name,"_",ant_colour,", skipping folder");
        
    end
end
toc % end timer

% Single_folder_loop placed into function
function [] = ProcessAntImages(jpgFiles,F1Parameters,F2Parameters, aMean, bMean, Output,txtfile_name_coords,ant_colour,Current_folder,Invader_trials_to_process,txtfile_name)

% If trial is invader folder, skip first 185 images to avoid extra false
% positives
Trial_name = sprintf("%s",Current_folder,"_",ant_colour);
%
if contains(Trial_name,Invader_trials_to_process) == 1
    fprintf("Ants from this trial are invaders, starting from image 250... \n");
    firstimage = 150;
%         firstimage = [250, 400, 800, 1200];
else
    fprintf("Ants from this trial are hosts, (Used to be) starting from the first image... \n");
    firstimage = 1;
%         firstimage = [250, 400, 800 ,1200];
end

% Read in existing coordinate table, so you can check if an image has
% already been processed in the for loop below
check_if_processed_table = readtable(txtfile_name_coords,"Delimiter","tab","Format","%s%*s%*s%*s%*s%*s%*s%*s"); % %s specifies text, * doesn't read a given column - only need first column here
check_if_processed_array = table2array(check_if_processed_table);

for k = firstimage:length(jpgFiles)
    
    baseFileName = jpgFiles(k).name;
    fullFileName = fullfile(jpgFiles(k).folder, baseFileName);
    
    % create filename for final output path
    filename = sprintf("%s", baseFileName);            % Naming the file output
    finalfile = sprintf("%s",Output,filename);         % combine output path + file name
    [~,name,~] = fileparts(finalfile);
    append_end_image = sprintf("%s",Output,ant_colour,"_",name,".jpg");
   
    if ~isfile(append_end_image) % If image does not exist, do the following below
        if ~isempty(check_if_processed_array) % if coordinate txt file was not empty when read in above loop, do the following
            if any(contains(check_if_processed_array,filename,"IgnoreCase",true)) % if coordinates text file contains the current image name, don't process the file
                continue % end current iteration of loop, do not process image 
            end
        end
            % read image, name as "ant"
            ant = imread(fullFileName);
            
            % apply local function to ant (see bottom of script)
            burnedAnt = createAntSegmentation(ant,F1Parameters); % create burned image with function 1
            [centroids, area_of_centroid, circularity, extent] = createantmask(burnedAnt,aMean,bMean,F2Parameters); % create final image with function 2
            
            % write Image for testing accuracy, if at least one centroid
            if centroids >= 1
                cla reset;
                close
                figure("Visible","off"), imshow(ant); % plot the figure without displaying in Matlab
                hold on;                              % hold figure
                plot(centroids(:,1),centroids(:,2),"yo","markersize",10,"linewidth",1); % plot centroid locations on the image
                hold on
                text(1,40,sprintf("No.blobs:%s",num2str(height(centroids))),'FontSize', 20, 'FontWeight','Bold',"Color","Yellow") % add text of number of blobs (height of centroids matrix)
                hold off                        % end figure display
                exportgraphics(gca,append_end_image);  % export current plot to file
            end
            
            % Take height and width of image in case needed
            [imageheight, imagewidth, ~] = size(ant);
            
            % concatenate filename of image and centroids, so there is one row per
            % image and centroid. If no centroids detected, ensure a blank row
            % is created for the image anyway by changing 0 to 1
            row_length = height(centroids); % get the number of rows in centroids
            row_length(row_length < 1) = 1; % and if less than 1, change it to one
            filename_repeated = repelem(filename,row_length); % repeat the filename for every row (every time a centroid detected)
            filename_column = filename_repeated(:); % turn this vector into one single column, so you can concatenate it with the correct number of centroids
            
            height_repeated = repelem(imageheight,row_length);
            width_repeated = repelem(imagewidth,row_length);
            height_column = height_repeated(:);
            width_column = width_repeated(:);
            
            
            % write matrix to txt file
            try
                if centroids >= 1
                    writematrix([filename_column, centroids, area_of_centroid, circularity, extent, height_column, width_column],txtfile_name_coords,"WriteMode","append", "Delimiter","tab"); % write matrix to txt file. Append the file each team, instead of overwriting
                else
                    writematrix([filename_column, "NA", "NA", "NA", "NA","NA","NA","NA"],txtfile_name_coords,"WriteMode","append", "Delimiter","tab"); % Write txtfile with image name, and NAs if no ants detected
                end
            catch
                fprintf("%s\n","Could not write coordinate text file, file could be locked, so writing file to alternative txtfile name")               
            end

    else % do nothing if image file already exists, stop too many text lines appearing, but should reduce time so not overwriting images
    end
end
end
%% Function 1
%  segment ants, and burn this mask onto original image
%  parameters are specified in Part 1.

function burnedAnt = createAntSegmentation(ant,F1Parameters)

greyant = rgb2gray(ant); % convert image to grayscale
adaptedAnt = adaptthresh(greyant,F1Parameters.adaptedThresholdValue,"ForegroundPolarity","dark"); % threshold image. Higher = more lenient filering

BW = imbinarize(greyant,adaptedAnt);               % binarize ant image, using the above thresholding
BWopen = bwareaopen(~BW,F1Parameters.BWopenValue); % exclude pixels smaller than X

se = strel("disk",F1Parameters.seDiskValue); % create shape used for dilating image
BWdilate = imdilate(BWopen,se);              % dilate image, expand the white pixels to ensure not cutting off relevant areas

BWfilled = imfill(BWdilate,"holes");      % fill in any holes
burnedAnt = imoverlay(ant,~BWfilled,"k"); % produce final image, mask burned onto original image, with black (k) fill.

end

%% Function 2
% using burned mask from function 1, apply colour detection function using reference shape drawn in Part 3
% the parameters are specified in Part 1.

function [centroids, area_of_centroid, circularity, extent] = createantmask(burnedAnt, aMean, bMean, F2Parameters)
% outputs the final iamge, centroid x and y, and the area of each centroid

% introduce gaussian filter, to avoid jagged edges later. Increase if want more blur
burnedAnt = imgaussfilt(burnedAnt, F2Parameters.gaussian_filterValue);

antLAB = rgb2lab(burnedAnt); % convert RGB to LAB colour space. L not used
antL = antLAB(:,:,1);        % luminance channel
antA = antLAB(:,:,2);        % red-green channel
antB = antLAB(:,:,3);        % blue-yellow channel
distLab = sqrt((antA - aMean).^2 + (antB - bMean).^2) % distance matrix, difference between average colour and every pixel

% threshold the distance matrix - which pixels are similar to sample colour. Smaller = stricter treshold.
mask = distLab < F2Parameters.distLab_ThresholdValue & antL < F2Parameters.luminanceMax...
    & antL > F2Parameters.luminanceMin & antA < F2Parameters.AChannelMax & antA > F2Parameters.AChannelMin & antB < F2Parameters.BChannelMax & antB > F2Parameters.BChannelMin;

% Pixel size filter
maskcleaned = bwareafilt(mask,[F2Parameters.smallestPixelSize, F2Parameters.largestPixelSize]);

% remove areas with low circularity
connected_BW = bwconncomp(maskcleaned);
stats = regionprops(connected_BW,"Circularity");
filter_areas = find([stats.Circularity] > F2Parameters.circularity_min_size);
maskcleaned_shadows = ismember(labelmatrix(connected_BW),filter_areas);

% remove areas with low extent
maskcleaned_extent = bwpropfilt(maskcleaned_shadows,"Extent",[F2Parameters.MinExtent, F2Parameters.MaxExtent]);

% dilate image
se = strel("disk",F2Parameters.seDiskValue);   % create disk shaped area to use to dilate image next.
dilatedant = imdilate(maskcleaned_extent,se); % dilate image - to join blotches that should be one blob
maskfilledholes = imfill(dilatedant,"holes");  % fill in holes within a blob

% filter for largest X blobs - depending on how many workers there are
mask_maxnumberants = bwpropfilt(maskfilledholes,"area",F2Parameters.maxNumberofAnts,"largest");

% final pixel size filter - to remove very large blobs e.g. brood
finalantimage = bwareafilt(mask_maxnumberants,[1, F2Parameters.FinalMaxPixelSize]);

% find coordinates of centroids
antmeasurements = regionprops(finalantimage, "centroid","area","circularity","extent"); % extract the centroid and area values of each blob
centroids = cat(1,antmeasurements.Centroid); % turn centroids into two columns (x and y coordinates)
area_of_centroid = [antmeasurements.Area]';   % extract area of each blob into new variable
circularity = [antmeasurements.Circularity]';
extent = [antmeasurements.Extent]';
end
