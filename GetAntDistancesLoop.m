% Note:
% Readtable ignores first few rows of images if they are all NA. Don't
% think this is an issue, just means need to code that when searching
% across different colours, if no matching image name, skip it


%% Specify folder inputs etc.
prompt_message = "Do you want to specify folder inputs/outputs manually, or are you working from uni or home?";
answers = questdlg(prompt_message,"Pick an option","Manually","Home","University","University");
% Handle response
switch answers
    case 'Manually'
        getInputFolder = uigetdir([],"Choose Input Folder");
        getOutputFolder = uigetdir([],"Choose Output Folder");
        getParametersFolder = uigetdir([],"Choose Parameters Folder");
    case 'Home'
        getInputFolder = "F:\Temnothorax_fusion\fusion_experiment\images\images_original";
        getOutputFolder = "C:\Users\Ben\OneDrive - University of Bristol\PhD\Year 2\Temnothorax_output";
        getParametersFolder = "C:\Users\Ben\OneDrive - University of Bristol\PhD\Year 2\Temnothorax_parameters";
        getTrialsProcessedFolder = "C:\Users\Ben\OneDrive - University of Bristol\PhD\Year 2\Temnothorax_trials_processed";
    case 'University'
        getInputFolder = "D:\Temnothorax_fusion\fusion_experiment\images\images_original";
        getOutputFolder = "C:\Users\bc16551\OneDrive - University of Bristol\PhD\Year 2\Temnothorax_output";
        getParametersFolder = "C:\Users\bc16551\OneDrive - University of Bristol\PhD\Year 2\Temnothorax_parameters";
        getTrialsProcessedFolder = "C:\Users\bc16551\OneDrive - University of Bristol\PhD\Year 2\Temnothorax_trials_processed";
    otherwise
        errorMessage = sprintf("%s","Error: No folders chosen");
        uiwait(warndlg(errorMessage));
        return
end
%%
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


worker_list_file = sprintf("%s%s",ParametersFolder,"\GetDist_worker_list.txt");
worker_list = readtable(worker_list_file);
worker_list = table2cell(worker_list);

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

if ~isfile("EucDistances.txt")
writematrix(["Host_workers","Invader_workers","Image","Index","Distance","Type_comparison","Current_X","Current_Y","NN_X","NN_Y","Image_width","Image_height"],"EucDistances.txt","Delimiter","tab","WriteMode","Append");
else
    fprintf("EucDistances text file already exists, not overwriting\n")
end

for k = 56:56(InputFolders);
    
    % Generate folder paths
    Input = sprintf("%s",InputFolders(k).folder,"\",InputFolders(k).name);
    Output = sprintf("%s",OutputFolders(k).folder,"\",InputFolders(k).name,"\");
    Current_folder = InputFolders(k).name;
    
    fprintf("\n%s%s\n","Processing ",Current_folder)
    
    filePatternOutputFolder = fullfile(Output,"*.txt"');
    txtFilesOutputFolder = dir(filePatternOutputFolder);    
    
    % Get a list of all JPG files in the folder
    filePattern = fullfile(Input, '*.JPG');
    jpgFiles = dir(filePattern);
    
    % Sort jpg files using nasortfules function, filexchange
    [~,ndx] = natsortfiles({jpgFiles.name});
    jpgFiles = jpgFiles(ndx);
    
    % sort files using nasortfiles from filexchange
    [~,ndx] = natsortfiles({txtFilesOutputFolder.name});
    txtFilesOutputFolder = txtFilesOutputFolder(ndx);
    
    % Index list of trials with each worker and queen colour trial in them
    Workers_invader_colour = worker_list{k,3};
    Workers_host_colour = worker_list{k,4};
    Queen_invader_1_colour = worker_list{k,5};
    Queen_invader_2_colour = worker_list{k,6};
    Queen_host_1_colour = worker_list{k,7};
    Queen_host_2_colour = worker_list{k,8};
    Queen_host_3_colour = worker_list{k,9};
    
    % Create filenames for each type of ant
    Workers_invader_filename = sprintf("%s%s%s",Output,Workers_invader_colour,"_coordinates.txt");
    Workers_host_filename = sprintf("%s%s%s",Output,Workers_host_colour,"_coordinates.txt");
    Queen_invader_1_filename = sprintf("%s%s%s",Output,Queen_invader_1_colour,"_coordinates.txt");
    Queen_invader_2_filename = sprintf("%s%s%s",Output,Queen_invader_2_colour,"_coordinates.txt");
    Queen_host_1_filename = sprintf("%s%s%s",Output,Queen_host_1_colour,"_coordinates.txt");
    Queen_host_2_filename = sprintf("%s%s%s",Output,Queen_host_2_colour,"_coordinates.txt");
    Queen_host_3_filename = sprintf("%s%s%s",Output,Queen_host_3_colour,"_coordinates.txt");
     

    % Read in text file for each worker and each queen
    % if NA, ignores, but if not NA and mising - warns user.
    if ~isfile(Workers_invader_filename)
        fprintf("%s%s\n","Warning: invader workers not found:",Workers_invader_colour)
    else
        Workers_invader = readtable(Workers_invader_filename);
        fprintf("%s%s\n","Invader workers file has been found: ",Workers_invader_colour)
    end
    
    if ~isfile(Workers_host_filename)
        fprintf("%s%s\n","Warning: host workers not found:",Workers_host_colour)
    else
        Workers_host = readtable(Workers_host_filename);
         fprintf("%s%s\n","Host workers file has been found: ",Workers_host_colour)
    end
    
    %Invader queen 1
    if contains(Queen_invader_1_filename,"NA")
        fprintf("Invader queen 1 = NA, not attempting to read file\n")
    else
        if ~isfile(Queen_invader_1_filename)
            fprintf("%s%s\n","Warning: invader queen 1 file not found:",Queen_invader_1_colour)
        else
            Queen_invader_1 = readtable(Queen_invader_1_filename);
            fprintf("%s%s\n","Invader queen 1 file has been found: ",Queen_invader_1_colour)
        end
    end
    
    % Invader queen 2
    if contains(Queen_invader_2_filename,"NA")
        fprintf("Invader queen 2 = NA, not attempting to read file\n")
    else
        if ~isfile(Queen_invader_2_filename)
            fprintf("%s%s\n","Warning: invader queen 2 file not found:",Queen_invader_2_colour)
        else
            Queen_invader_2 = readtable(Queen_invader_2_filename);
            fprintf("%s%s\n","Invader queen 2 file has been found: ",Queen_invader_2_colour)
        end
    end
    
    if contains(Queen_host_1_filename,"NA")
       fprintf("Host queen 1 = NA, not attempting to read file\n")
    else
        if ~isfile(Queen_host_1_filename)
             fprintf("%s%s\n","Warning: host queen 1 file not found:",Queen_host_1_colour)
        else
            Queen_host_1 = readtable(Queen_host_1_filename);
            fprintf("%s%s\n","Host queen 1 file has been found: ",Queen_host_1_colour)
        end
    end
    
    if contains(Queen_host_2_filename,"NA")
        fprintf("Host queen 2 = NA, not attempting to read file\n")
    else
        if ~isfile(Queen_host_2_filename)
           fprintf("%s%s\n","Warning: host queen 2 file not found:",Queen_host_2_colour)
        else
            Queen_host_2 = readtable(Queen_host_2_filename);
            fprintf("%s%s\n","Host queen 2 file found and read ",Queen_host_2_colour)
        end
    end
    if contains(Queen_host_3_filename,"NA")
        fprintf("Host queen 3 = NA, not attempting to read file\n")
    else
        if ~isfile(Queen_host_3_filename)
             fprintf("%s%s\n","Warning: host queen 3 file not found:",Queen_host_3_colour)
        else
            Queen_host_3 = readtable(Queen_host_3_filename);
            fprintf("%s%s\n","Host queen 3 file found and read ",Queen_host_3_colour)
        end
    end
    
% List image names but remove any repetitions, to ge a unique list of
% images
unique_image_list_host = unique(Workers_host.Image);

% For each image, 
% First loop - for each image of the host txt file, index the table to extract all coordinates for just one image
for f = 300:350(jpgFiles);
   
    % get current image name
    current_image = sprintf("%s",jpgFiles(f).name);
    
    % Process host-host distances
    index_workers = Workers_host.Image == current_image;
    indexed_table_workers = Workers_host(index_workers,:);
    DistanceType = "HostHost";
    GetDistancesHHorWW(indexed_table_workers,Workers_host_colour,Workers_invader_colour, current_image,DistanceType)
   
    % Process invader-invader distances
    index_workers = Workers_invader.Image == current_image;
    indexed_table_workers = Workers_invader(index_workers,:);
    DistanceType = "InvaderInvader";
    GetDistancesHHorWW(indexed_table_workers,Workers_host_colour,Workers_invader_colour, current_image,DistanceType)

    % Process host-invader distances
    index_workers_host = Workers_host.Image == current_image;
    indexed_table_workers_host = Workers_host(index_workers,:);
    index_workers_invader = Workers_invader.Image == current_image;
    indexed_table_invader = Workers_invader(index_workers,:);
    DistanceType = "Host-Invader"
    
    
    
% %       Plot image with coordinates
% % This goes before the loop
% image =  imread("image_test.jpg");
% imshow(image); hold on;
% plot(indexed_table_workers_host{:,2},indexed_table_workers_host{:,3},"yo","markersize",5);
% 
% % This goes within the loop at the end
% x = [current_coordinate(1,1), nearest_coord(1,1)];
% y = [current_coordinate(1,2), nearest_coord(1,2)];
% line(x,y,"LineWidth",3)
% annotation('textarrow',x,y)
% text(x(1),y(1),num2str(dist,'%.2f'),'FontSize', 10, 'FontWeight','Bold',"Color","Yellow")
   
end
end

function [] = GetDistancesHHorWW(indexed_table_workers,Workers_host_colour,Workers_invader_colour, current_image,DistanceType);

if ~isempty(indexed_table_workers) % if table is not empty, process the image:
    
    for b = 1:height(indexed_table_workers);
        current_coordinate = indexed_table_workers{b,2:3};              % index x and y coords, at row b
        indexed_table_workers{b,2:3} = [NaN];                          % remove current coordinate from table to be searched
        [idx,dist] = dsearchn(indexed_table_workers{:,2:3}, current_coordinate); % Search list of coordinates with current coordinate
        nearest_coord = indexed_table_workers{idx,2:3};
        image_width_height = indexed_table_workers{b,7:8};
        indexed_table_workers{b,2:3} = current_coordinate; % return current coord to table after calculated distances
        
        if DistanceType == "HostHost"
            writematrix([Workers_host_colour,"NA",current_image,idx,dist,"Host-Host",current_coordinate,nearest_coord,image_width_height],"EucDistances.txt","Delimiter","tab","WriteMode","Append");
        else
            if DistanceType == "InvaderInvader"
                writematrix(["NA",Workers_invader_colour,current_image,idx,dist,"Invader-Invader",current_coordinate,nearest_coord,image_width_height],"EucDistances.txt","Delimiter","tab","WriteMode","Append");
            end
        end
    end
else
    if DistanceType == "HostHost"
        writematrix([Workers_host_colour,"NA",current_image,"NA","NA","Host-Host","NA","NA","NA","NA","NA","NA"],"EucDistances.txt","Delimiter","tab","WriteMode","Append");
    else
        if DistanceType == "InvaderInvader"
            writematrix(["NA",Workers_invader_colour,current_image,"NA","NA","Invader-Invader","NA","NA","NA","NA","NA","NA"],"EucDistances.txt","Delimiter","tab","WriteMode","Append");
        end
    end
end
end

function [] = GetDistancesHWorWH(indexed_table_workers_host,indexed_table_workers_invader,Workers_host_colour,Workers_invader_colour, current_image,DistanceType);

if ~isempty(num) & ~isempty(zeros)
    disp("Not Empty")
    % put code in here!
    
else
    disp("EMPTY")
end



%     for b = 1:height(indexed_table_workers);
%         current_coordinate = indexed_table_workers{b,2:3};              % index x and y coords, at row b
%         indexed_table_workers{b,2:3} = [NaN];                          % remove current coordinate from table to be searched
%         [idx,dist] = dsearchn(indexed_table_workers{:,2:3}, current_coordinate); % Search list of coordinates with current coordinate
%         nearest_coord = indexed_table_workers{idx,2:3};
%         image_width_height = indexed_table_workers{b,7:8};
%         indexed_table_workers{b,2:3} = current_coordinate; % return current coord to table after calculated distances
%         
%         if DistanceType == "HostHost"
%             writematrix([Workers_host_colour,"NA",current_image,idx,dist,"Host-Host",current_coordinate,nearest_coord,image_width_height],"EucDistances.txt","Delimiter","tab","WriteMode","Append");
%         else
%             if DistanceType == "InvaderInvader"
%                 writematrix(["NA",Workers_invader_colour,current_image,idx,dist,"Invader-Invader",current_coordinate,nearest_coord,image_width_height],"EucDistances.txt","Delimiter","tab","WriteMode","Append");
%             end
%         end
%     end
% else
%     if DistanceType == "HostHost"
%         writematrix([Workers_host_colour,"NA",current_image,"NA","NA","Host-Host","NA","NA","NA","NA","NA","NA"],"EucDistances.txt","Delimiter","tab","WriteMode","Append");
%     else
%         if DistanceType == "InvaderInvader"
%             writematrix(["NA",Workers_invader_colour,current_image,"NA","NA","Invader-Invader","NA","NA","NA","NA","NA","NA"],"EucDistances.txt","Delimiter","tab","WriteMode","Append");
%         end
%     end
% end
end
