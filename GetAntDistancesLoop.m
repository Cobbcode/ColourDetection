% Note:
% Readtable ignores first few rows of images if they are all NA. Don't
% think this is an issue, just means need to code that when searching
% across different colours, if no matching image name, skip it%


% TO DO:
% With getting shape overlap, fix so if NAs, handles appropriately for
% shape and boundaries

% After meeting w N and A, time to change to network analysis in R
%% Specify folder inputs etc.
getInputFolder = uigetdir([],"Choose Input Folder");
getOutputFolder = uigetdir([],"Choose Output Folder");
getParametersFolder = uigetdir([],"Choose Parameters Folder");
getDataFolder = uigetdir([],"Choose Data Folder");

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
if ~isfolder(getDataFolder)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s\nCheck your folder paths again', getDataFolder);
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

% Read table to determine whether ants are invaders/hosts
worker_list_file = sprintf("%s%s",ParametersFolder,"\GetDist_worker_list.txt");
worker_list = readtable(worker_list_file);
worker_list = table2cell(worker_list);

% Create filename to store nearest neighbour distances
distances_txt_filename = sprintf("%s%s",getDataFolder,"\EucDistances.txt");
meanDistances_txt_filename = sprintf("%s%s",getDataFolder,"\MeanEucDistances.txt");


% Remove . and .. from folder.name (this refers to parent folders, not needed)
InputFolders = InputFolders(~ismember({InputFolders.name}, {'.', '..'}));
OutputFolders = OutputFolders(~ismember({OutputFolders.name}, {'.', '..'}));
%
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

if ~isfile(distances_txt_filename)
    writematrix(["Host_workers","Invader_workers","Image","Index","Distance","Type_comparison","Current_X","Current_Y","NN_X","NN_Y","Image_width","Image_height","Image_number"],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
else
    fprintf("EucDistances text file already exists, not overwriting\n")
end

if ~isfile(meanDistances_txt_filename)
    writematrix(["Host_workers","Invader_workers","Image","MeanDistance","Type_comparison","Image_number"],meanDistances_txt_filename,"Delimiter","tab","WriteMode","Append");
else
    fprintf("MeanEucDistances text file already exists, not overwriting\n")
end


tic

Manual_folders_to_run = [4,11,13,18,20,22,23,25,35,36,38,40,43,47,49,50,52,56,58,61,65,67,68,70,71];
%
for k = 1:1
    
    % Generate folder paths
    Input = sprintf("%s",InputFolders(k).folder,"\",InputFolders(k).name);
    Output = sprintf("%s",OutputFolders(k).folder,"\",InputFolders(k).name,"\");
    Current_folder = InputFolders(k).name;
    
    % Skip removed trials due to data error
    if Current_folder == "21I_x_25H_W_x_Q"
        continue
    end
    
    fprintf("\r\n%s%s\n","Processing ",Current_folder)
    
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
    
    
    % For each image,
    % First loop - for each image of the host txt file, index the table to extract all coordinates for just one image
    images_to_run = [250,400,800,1200];
    % 1:length(jpgFiles)
    for f = images_to_run
        
        % get current image name
        current_image = sprintf("%s",jpgFiles(f).name);
        current_image_number = f;
        % read image if want for plotting distances
        image_path = sprintf("%s%s%s",Input,"\",current_image);
        current_image_plot = imread(image_path);
        
        % Set up variables to process worker host-invader and invader-host distances
        index_workers_host = Workers_host.Image == current_image;
        indexed_table_workers_host = Workers_host(index_workers_host,:);
        index_workers_invader = Workers_invader.Image == current_image;
        indexed_table_workers_invader = Workers_invader(index_workers_invader,:);
        
        
          % Set up queen variables
        if exist("Queen_host_1","var")
        index_Queen_host_1 = Queen_host_1.Image == current_image;
        indexed_table_Queen_host_1 = Queen_host_1(index_Queen_host_1,:);
        end
        
          % Set up queen variables
        if exist("Queen_host_2","var")
        index_Queen_host_2 = Queen_host_2.Image == current_image;
        indexed_table_Queen_host_2 = Queen_host_2(index_Queen_host_2,:);
        end
        
        % Set up queen variables
        if exist("Queen_host_3","var")
        index_Queen_host_3 = Queen_host_3.Image == current_image;
        indexed_table_Queen_host_3 = Queen_host_3(index_Queen_host_3,:);
        end
        
        % Set up queen variables
        if exist("Queen_invader_1","var")
        index_Queen_invader_1 = Queen_invader_1.Image == current_image;
        indexed_table_Queen_invader_1 = Queen_invader_1(index_Queen_invader_1,:);
        end
        
         % Set up queen variables
        if exist("Queen_invader_2","var")
        index_Queen_invader_2 = Queen_invader_2.Image == current_image;
        indexed_table_Queen_invader_2 = Queen_invader_2(index_Queen_invader_2,:);
        end
        
       
   
        % Run through each type of NN distances by running the function
        % GetDistances at bottom of the script
        DistanceType = "Host-Host";
        GetDistances(indexed_table_workers_host,indexed_table_workers_invader, Workers_host_colour,Workers_invader_colour, current_image,DistanceType,distances_txt_filename,meanDistances_txt_filename,current_image_number);
        
        DistanceType = "Invader-Invader";
        GetDistances(indexed_table_workers_host,indexed_table_workers_invader, Workers_host_colour,Workers_invader_colour, current_image,DistanceType,distances_txt_filename,meanDistances_txt_filename,current_image_number);
        
        DistanceType = "Host-Invader";
        GetDistances(indexed_table_workers_host,indexed_table_workers_invader,Workers_host_colour,Workers_invader_colour, current_image,DistanceType,distances_txt_filename,meanDistances_txt_filename,current_image_number);
        
        DistanceType = "Invader-Host";
        GetDistances(indexed_table_workers_host,indexed_table_workers_invader,Workers_host_colour,Workers_invader_colour, current_image,DistanceType,distances_txt_filename,meanDistances_txt_filename,current_image_number);
        
        
        
        % Plot figures?
        plot_figures = "No";
        if plot_figures == "Yes"
            
            % create output image name for data folder
            output_image_filename = sprintf("%s%s%s%s%s%s", getDataFolder,"\",Current_folder,"_",current_image,".jpg");
            
            % Index current image in file, to plot current image with distances
            EucDistances = readtable(distances_txt_filename, "Delimiter","tab");
            
            % show figure, plot using the function bottom of script
            figure("Visible","off"), imshow(current_image_plot); hold on
            
            % Plot each type of distance
            DistanceType = "Host-Host";
            PlotDistances(EucDistances,current_image,DistanceType); hold on
            
            DistanceType = "Invader-Invader";
            PlotDistances(EucDistances,current_image,DistanceType); hold on
            
            DistanceType = "Host-Invader";
            PlotDistances(EucDistances,current_image,DistanceType); hold on
            
            DistanceType = "Invader-Host";
            PlotDistances(EucDistances,current_image,DistanceType); hold on
            
            % Create blank plots to get the correct legend
            legend_plot(1) = plot(NaN,NaN,"yo","markersize",10,"LineWidth",1.5); % host-host
            legend_plot(2) = plot(NaN,NaN,"bs","markersize",10,"LineWidth",1.5); % invader-invader
            legend_plot(3) = line(NaN,NaN,"LineWidth",2,"Color","Yellow","LineStyle","-"); % host-host line
            legend_plot(4) = line(NaN,NaN,"LineWidth",2,"Color","Blue","LineStyle","-"); % invader-invader line
            legend_plot(4) = line(NaN,NaN,"LineWidth",2,"Color","Yellow","LineStyle","--"); % % host-invader line
            legend_plot(4) = line(NaN,NaN,"LineWidth",2,"Color","Blue","LineStyle","--"); % invader-host line
            legend(legend_plot,"Host workers","Invader workerss","Host-host","Invader-invader","Host-invader","Invader-host");
            set(legend,'color','red');
            text(1,40,sprintf("%s%s%s%s",Current_folder,": ",current_image,", auto"),'FontSize', 10, 'FontWeight','Bold',"Color","Yellow","Interpreter","none"); % add text of number of blobs (height of centroids matrix)
            exportgraphics(gca,output_image_filename,"Resolution",300)
        
        else fprintf("%s\nFigure creation disabled, not exporting figures")
        end
        
    end
end
toc

function [] = PlotDistances(EucDistances,current_image,DistanceType)

index_EucDistances = EucDistances.Image == current_image & EucDistances.Type_comparison == DistanceType;
indexed_table_EucDistances = EucDistances(index_EucDistances,:);

x_coord = indexed_table_EucDistances{:,7}; % Get coordinates for focal ants
y_coord = indexed_table_EucDistances{:,8}; % Get coordinates for focal ants

% Depending on distance type, assign colours and marker styles to figures
if DistanceType == "Host-Host"
    markerstyle = "yo";  % yellow circles
    linecolour = "Yellow";
    linestyle = "-";
elseif DistanceType == "Invader-Invader"
    markerstyle = "bs";  % blue square
    linecolour = "Blue";
    linestyle = "-";
elseif DistanceType == "Host-Invader"
    markerstyle = "yo";
    linecolour = "yellow";
    linestyle = "--";
elseif DistanceType =="Invader-Host"
    markerstyle = "bs";
    linecolour = "blue";
    linestyle = "--";
end

% Plot ant coordinates
 plot(x_coord,y_coord,markerstyle,"markersize",10,"LineWidth",1.5); hold on
 
% WORK OUT HOW TO NOT USE A LOOP TO SAVE TIME
for n = 1:height(indexed_table_EucDistances);
    x_line = [indexed_table_EucDistances{n,7},indexed_table_EucDistances{n,9}];  % Get coords for creating lines from focal to NN
    y_line = [indexed_table_EucDistances{n,8},indexed_table_EucDistances{n,10}]; % Get coords for creating lines from focal to NN
    line(x_line,y_line,"LineWidth",2,"Color",linecolour,"LineStyle",linestyle); hold on % Create the line
end

end

function [] = GetDistances(indexed_table_workers_host,indexed_table_workers_invader,Workers_host_colour,Workers_invader_colour, current_image,DistanceType,distances_txt_filename,meanDistances_txt_filename,current_image_number);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% REWRITING FUNCTION To be more concise 
if DistanceType == "Host-Host"
    check_if_skip = ~isempty(indexed_table_workers_host) & isnumeric(indexed_table_workers_host{1,2})
    indexed_table = indexed_table_workers_host;
    indexed_table_to_search = indexed_table_workers_host;
    Workers_host_colour_matrix = Workers_host_colour;
    Workers_invader_colour_matrix = "NA";
end

if DistanceType == "Invader-Invader"
    check_if_skip = ~isempty(indexed_table_workers_invader) & isnumeric(indexed_table_workers_invader{1,2})
    indexed_table = indexed_table_workers_invader;
    indexed_table_to_search = indexed_table_workers_invader;
    Workers_host_colour_matrix = "NA";
    Workers_invader_colour_matrix = Workers_invader_colour;
end

if DistanceType == "Host-Invader"
    check_if_skip = ~isempty(indexed_table_workers_host) & ~isempty(indexed_table_workers_invader) & isnumeric(indexed_table_workers_host{1,2}) & isnumeric(indexed_table_workers_invader{1,2});
    indexed_table = indexed_table_workers_host;
    indexed_table_to_search = indexed_table_workers_invader;
    Workers_host_colour_matrix = Workers_host_colour;
    Workers_invader_colour_matrix = Workers_invader_colour;
end

if DistanceType == "Invader-Host"
    check_if_skip = ~isempty(indexed_table_workers_host) & ~isempty(indexed_table_workers_invader) & isnumeric(indexed_table_workers_host{1,2}) & isnumeric(indexed_table_workers_invader{1,2});
    indexed_table = indexed_table_workers_invader;
    indexed_table_to_search = indexed_table_workers_host;
    Workers_host_colour_matrix = Workers_host_colour;
    Workers_invader_colour_matrix = Workers_invader_colour;
end

temp_table_store = [];
if check_if_skip == 1
    for b = 1:height(indexed_table)
        current_coordinate = indexed_table{b,["X","Y"]}
        indexed_table{b,["X","Y"]} = [NaN];
        if DistanceType == "Host-Host" | DistanceType == "Invader-Invader"
            [idx,dist] = dsearchn(indexed_table{:,["X","Y"]}, current_coordinate);
            nearest_coord = indexed_table{idx,["X","Y"]};
        elseif DistanceType == "Host-Invader" | DistanceType == "Invader-Host"
            [idx,dist] = dsearchn(indexed_table_to_search{:,["X","Y"]}, current_coordinate);
            nearest_coord = indexed_table_to_search{idx,["X","Y"]};
        end
        image_width_height = indexed_table{b,["Height","Width"]};
        indexed_table{b,["X","Y"]} = current_coordinate;
        writematrix([Workers_host_colour_matrix,Workers_invader_colour_matrix,current_image,idx,dist,DistanceType,current_coordinate,nearest_coord,image_width_height,current_image_number],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
        temp_table_store = [temp_table_store; dist];
    end
else
    writematrix([Workers_host_colour_matrix,Workers_invader_colour_matrix,current_image,"NA","NA",DistanceType,"NA","NA","NA","NA","NA","NA",current_image_number],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
    temp_table_store = [temp_table_store; "NA"];
end
dist_column = str2double(temp_table_store(:,1));
mean_distance_current_image = mean(dist_column);
writematrix([Workers_host_colour_matrix, Workers_invader_colour_matrix,current_image,mean_distance_current_image,DistanceType,current_image_number],meanDistances_txt_filename,"Delimiter","tab","WriteMode","Append");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% old function method
% 
% 
% if DistanceType =="Host-Host"
%     host_host_table_store = [];
%     if ~isempty(indexed_table_workers_host) & isnumeric(indexed_table_workers_host{1,2}) % if table isn't empty, and if the coord is a number (e.g. not "NA" text), do following
%         for b = 1:height(indexed_table_workers_host);
%             current_coordinate = indexed_table_workers_host{b,2:3};             % index x and y coords, at row b
%             indexed_table_workers_host{b,2:3} = [NaN];                          % remove current coordinate from table to be searched
%             [idx,dist] = dsearchn(indexed_table_workers_host{:,2:3}, current_coordinate); % Search list of coordinates with current coordinate
%             nearest_coord = indexed_table_workers_host{idx,2:3};
%             image_width_height = indexed_table_workers_host{b,7:8};
%             indexed_table_workers_host{b,2:3} = current_coordinate; % return current coord to table after calculated distances
%             writematrix([Workers_host_colour,"NA",current_image,idx,dist,"Host-Host",current_coordinate,nearest_coord,image_width_height,current_image_number],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
%             host_host_table_store = [host_host_table_store; Workers_host_colour,"NA",current_image,idx,dist,"Host-Host",current_coordinate,nearest_coord,image_width_height,current_image_number];
%         end
%     else
%         writematrix([Workers_host_colour,"NA",current_image,"NA","NA","Host-Host","NA","NA","NA","NA","NA","NA",current_image_number],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
%         host_host_table_store = [host_host_table_store; Workers_host_colour,"NA",current_image,"NA","NA","Host-Host","NA","NA","NA",current_image_number];
%     end
%     host_host_dist_column = str2double(host_host_table_store(:,5));
%     mean_distance_current_image = mean(host_host_dist_column);
%     writematrix([Workers_host_colour, "NA",current_image,mean_distance_current_image,"Host-Host",current_image_number],meanDistances_txt_filename,"Delimiter","tab","WriteMode","Append");
% end
% 
% if DistanceType =="Invader-Invader"
%     invader_invader_table_store = [];
%     if ~isempty(indexed_table_workers_invader) & isnumeric(indexed_table_workers_invader{1,2})
%         for b = 1:height(indexed_table_workers_invader);
%             current_coordinate = indexed_table_workers_invader{b,2:3};             % index x and y coords, at row b
%             indexed_table_workers_invader{b,2:3} = [NaN];                          % remove current coordinate from table to be searched
%             [idx,dist] = dsearchn(indexed_table_workers_invader{:,2:3}, current_coordinate); % Search list of coordinates with current coordinate
%             nearest_coord = indexed_table_workers_invader{idx,2:3};
%             image_width_height = indexed_table_workers_invader{b,7:8};
%             indexed_table_workers_invader{b,2:3} = current_coordinate; % return current coord to table after calculated distances
%             writematrix(["NA",Workers_invader_colour,current_image,idx,dist,"Invader-Invader",current_coordinate,nearest_coord,image_width_height,current_image_number],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
%             invader_invader_table_store = [invader_invader_table_store; Workers_host_colour,"NA",current_image,idx,dist,"Host-Host",current_coordinate,nearest_coord,image_width_height,current_image_number];
%         end
%     else
%         writematrix(["NA",Workers_invader_colour,current_image,"NA","NA","Invader-Invader","NA","NA","NA","NA","NA","NA",current_image_number],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
%         invader_invader_table_store = [invader_invader_table_store; Workers_host_colour,"NA",current_image,"NA","NA","Invader-Invader","NA","NA","NA",current_image_number];
%     end
%     invader_invader_dist_column = str2double(invader_invader_table_store(:,5));
%     mean_distance_current_image = mean(invader_invader_dist_column);
%     writematrix(["NA", Workers_invader_colour, current_image, mean_distance_current_image,"Invader-Invader",current_image_number],meanDistances_txt_filename,"Delimiter","tab","WriteMode","Append");
% end
% 
% if DistanceType == "Host-Invader"
%     host_invader_table_store = [];
%     if ~isempty(indexed_table_workers_host) & ~isempty(indexed_table_workers_invader) & isnumeric(indexed_table_workers_host{1,2}) & isnumeric(indexed_table_workers_invader{1,2})
%         for b = 1:height(indexed_table_workers_host);
%             current_coordinate = indexed_table_workers_host{b,2:3};             % index x and y coords, at row b
%             indexed_table_workers_host{b,2:3} = [NaN];                          % remove current coordinate from table to be searched
%             [idx,dist] = dsearchn(indexed_table_workers_invader{:,2:3}, current_coordinate); % Search list of coordinates with current coordinate
%             nearest_coord = indexed_table_workers_invader{idx,2:3};
%             image_width_height = indexed_table_workers_host{b,7:8}; % Get height and width of image
%             indexed_table_workers_host{b,2:3} = current_coordinate; % return current coord to table after calculated distances
%             writematrix([Workers_host_colour,Workers_invader_colour,current_image,idx,dist,"Host-Invader",current_coordinate,nearest_coord,image_width_height,current_image_number],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
%             host_invader_table_store = [host_invader_table_store; Workers_host_colour,Workers_invader_colour,current_image,idx,dist,"Host-Invader",current_coordinate,nearest_coord,image_width_height,current_image_number];
%         end
%     else
%         writematrix([Workers_host_colour,Workers_invader_colour,current_image,"NA","NA","Host-Invader","NA","NA","NA","NA","NA","NA",current_image_number],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
%         host_invader_table_store = [host_invader_table_store; Workers_host_colour,Workers_invader_colour,current_image,"NA","NA","Host-Invader","NA","NA","NA",current_image_number];
%     end
%     host_invader_dist_column = str2double(host_invader_table_store(:,5));
%     mean_distance_current_image = mean(host_invader_dist_column);
%     writematrix([Workers_host_colour, Workers_invader_colour, current_image, mean_distance_current_image,"Host-Invader",current_image_number],meanDistances_txt_filename,"Delimiter","tab","WriteMode","Append");
% end
% 
% if DistanceType == "Invader-Host"
%     invader_host_table_store = [];
%     if ~isempty(indexed_table_workers_host) & ~isempty(indexed_table_workers_invader) & isnumeric(indexed_table_workers_host{1,2}) & isnumeric(indexed_table_workers_invader{1,2})
%         for b = 1:height(indexed_table_workers_invader);
%             current_coordinate = indexed_table_workers_invader{b,2:3};             % index x and y coords, at row b
%             indexed_table_workers_invader{b,2:3} = [NaN];                          % remove current coordinate from table to be searched
%             [idx,dist] = dsearchn(indexed_table_workers_host{:,2:3}, current_coordinate); % Search list of coordinates with current coordinate
%             nearest_coord = indexed_table_workers_host{idx,2:3};
%             image_width_height = indexed_table_workers_invader{b,7:8}; % Get height and width of image
%             indexed_table_workers_invader{b,2:3} = current_coordinate; % return current coord to table after calculated distances
%             writematrix([Workers_host_colour,Workers_invader_colour,current_image,idx,dist,"Invader-Host",current_coordinate,nearest_coord,image_width_height,current_image_number],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
%             invader_host_table_store = [invader_host_table_store; Workers_host_colour,Workers_invader_colour,current_image,idx,dist,"Invader-Host",current_coordinate,nearest_coord,image_width_height,current_image_number];
%         end
%     else
%         writematrix([Workers_host_colour,Workers_invader_colour,current_image,"NA","NA","Invader-host","NA","NA","NA","NA","NA","NA",current_image_number],distances_txt_filename,"Delimiter","tab","WriteMode","Append");
%         invader_host_table_store = [invader_host_table_store; Workers_host_colour,Workers_invader_colour,current_image,"NA","NA","Host-Invader","NA","NA","NA",current_image_number];
%     end
%     invader_host_dist_column = str2double(invader_host_table_store(:,5));
%     mean_distance_current_image = mean(invader_host_dist_column);
%     writematrix([Workers_host_colour, Workers_invader_colour, current_image, mean_distance_current_image,"Invader_Host",current_image_number],meanDistances_txt_filename,"Delimiter","tab","WriteMode","Append");
% end

end
