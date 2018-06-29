%Variation of text_parse_nback_csv, this just outputs RT and onset time.
%Part 1 is exactly the same. Change filepattern variable for pre/post.
%Part 2 only gets RT and onset time
%Outputs will be in current working directory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Path to all text files%%%%
function text_parse_rt_csv(input_dir) 
%input_dir = '/path/to/N-Back-Behav-Data';
%%%Generate every possible path to every folder+subfolder and put into array
%%%to search for text files
paths = genpath(input_dir);
remain = paths;
folderlist = {};
%%% This loop create a cell array that contain all the path to each subject
%%% textfiles

%Replace all ; to : %genpath uses colon on linux, semicolon on windows
remain = strrep(remain, ';', ':');
while true
    [singleSubFolder, remain] = strtok(remain, ':');
    if isempty (singleSubFolder)
        break;
    end
    folderlist = [folderlist singleSubFolder];
end
foldernumber = length(folderlist); %% number of paths %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Part 1%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n=0;    %file counter, increases after every succesfully read file
%This for loop reads the textfiles
for k = 1:foldernumber
    curfolder = folderlist{k};
    filepattern = sprintf(['%s' filesep filesep '*1.txt'],curfolder); %CHANGE TO 2 FOR POST
    base_file = dir(filepattern); %base_file is the nback textfile
    if ~isempty(base_file)
        for z=1:length(base_file) %account for more than 1 text file in a folder
            fullfilename = fullfile(folderlist{k}, base_file(z).name);%fullpath to nback text file
            FID = fopen(fullfilename, 'r');
            values=0; % value represent blocks in the NBack task?????
            if FID > 0
                n=n+1;
                name = strrep(fullfilename, '\', '/');%Change windows \ to /
                name_ind = regexp(name, '/');
                namis{n} = name((name_ind(length(name_ind)-2)+1):end);
                while (~feof(FID))               %%%%end of file not reached
                    if values>=12 %12 blocks
                        break
                    elseif values ~= 0 && mod(values,2) == 0 %%% skip 9 lines after every pairs of zero-back & two-back block
                        headerlines =9;
                    else
                        headerlines = 0;
                    end
                    
                    %%%Parsering textfiles%%%
                    if values== 0 
                        text_block = textscan(FID, '%s1', 'Headerlines', 23); %%%Remove first 23 lines of textfile, first cell after headers is "..."
                        delims = text_block{1}(1); %assign first cell as delimiter, every other cell is a tab
                                                   %380 lines per block
                        text_block=textscan (FID,'%s%s', 380, 'Delimiter', delims, 'Headerlines', headerlines); %This line reads the entire text file, first s is all spaces &second is all info
                        text_block(1) = []; %1st dimension is all spaces or tabs, remove
                    else 
                        text_block=textscan (FID,'%s%s', 380, 'Delimiter', delims, 'Headerlines', headerlines); %first s is all spaces, second is all info
                        text_block(1) = [];                                                                     %remove 1st dimension is all spaces or tabs,
                    end
                    %%%End of parser%%%
                    clean_text_block = reshape (text_block{1}, [19,20]);
                    clean_text_block(1,:) = [];%remove level:3, logframe start, and end
                    clean_text_block (1,:) = [];
                    clean_text_block(17,:) = [];
                    for i = 1:16 %16 useful infos for 20 trials for 12 blocks for n participants
                        for j = 1:20%# of trial in each block
                            info_block{i,j,(values+1),n} = strsplit(char(clean_text_block(i,j)));%convert each string into title and value
                            values_block{i,j,(values+1),n} = info_block{i,j,(values+1),n}(3) ;%get value only
                        end
                    end
                    %%%Make variable to hold column names (Structures)%%%
                    for i=1:16
                        heading_block{i,(values+1)} = info_block{i,1,(values+1),n}(2); 
                    end
                    values= values+1;
                end
                fclose(FID);
            end
        end
    end
end
namis = strrep(namis, '/','_'); %Replace ASD/EF001/vis... to ASD_EF001_vis     
namis = strrep(namis, '.txt','');   %Remove text
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Part 1%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Part 2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subjs = length(namis);      % number of files/subjects
num_of_blocks = size(values_block,3); % # of blocks - 12
resp_per_block = size(values_block,2); %number of responses per block - 20
final1 = zeros(240,2); %% create an empty matrix with 240 rows and 2 columns to store RT and Resp
for i=1:subjs%files
    final1 = zeros(240,2);
    onset_time = [];
    RT = [];
    new3 = values_block(:,:,1,i); %new3 is values per file/subject
    values = [new3{:}]; %store all values per block
    values= reshape (values,[16,20]);
    values = regexprep(values,'[^\w'']','');
    values=values';
    for j=1:num_of_blocks%blocks
        new3 = values_block(:,:,j,i);
        values = [new3{:}];
        values= reshape (values,[16,20]);
        values = regexprep(values,'[^\w'']','');
        values=values';
        for k = 1:resp_per_block%responses
            if j==1%first 0 back block
                time = str2double(values{k,9});
                reaction = str2double(values{k,13});
            else
                time = str2double(values{k,7});
                reaction = str2double(values{k,11});
            end
            onset_time = [onset_time time];
            RT = [RT reaction];
        end
    end
    final1(:,1) = RT;
    final1(:,2) = onset_time;
    file_name = [namis{i} '-RT.csv'];
    dlmwrite(file_name,final1,'delimiter', ',','precision', 7);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%END Part 2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%