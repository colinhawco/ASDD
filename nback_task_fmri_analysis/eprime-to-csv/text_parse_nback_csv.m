%Text Parser for ASDD: eprime text files to CSV for SPM GLM
%Part 1 stores everything from text file into cell array
%You have to change filepattern variable in part 1 for pre vs post CSVs
%Part 2 checks subj response with correct response, creates an array of
%correct/incorrect/miss and Trial onset time and outputs to CSV for SPM
%Outputs will be in current working directory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Path to all text files%%%%
function text_parse_nback_csv(input_dir) 
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

%%Write useful info to CSV
subjs = length(namis);      % number of files/subjects
num_of_blocks = size(values_block,3); % # of blocks - 12
resp_per_block = size(values_block,2); %number of responses per block - 20
final1 = zeros(240,2); %% create an empty matrix with 240 rows and 2 columns to store onset and Resp
for i=1:subjs          %files
    final_resp = [];   %final_resp stores correct/incorrect/miss
    onset_time = [];   %event onset times
    test = [];
    subj_resp_final=[];
    new3 = values_block(:,:,1,i); %new3 is values per file/subject
    values = [new3{:}]; %store all values per block
    values= reshape (values,[16,20]);
    values = regexprep(values,'[^\w'']','');
    values=values';
    %Check if TrailDisp.RESP is 1,2,3,4 or 2,4,6,8 or a,b,c,d
    for g=1:resp_per_block %check responses to determine type
        lett=str2double(values{g,14}); %
        lett2 = char(values{g,14}); %
        if isnan(lett) && isempty(lett2) %NaN/didnt press -> loop repeats
            test=1;
        elseif isnan(lett)%letter (a,b,c,d)
            test =2;
            break
        elseif lett == 1 || lett == 3%1,2,3,4
            test=3;
            break
        elseif lett == 6 || lett == 8%2,4,6,8
            test=4;
            break
        else
        end
    end
    %%This part where we get corrects/incorrect/miss and onset times%%
    for j=1:num_of_blocks%blocks
        new3 = values_block(:,:,j,i);
        values = [new3{:}];
        values= reshape (values,[16,20]);
        values = regexprep(values,'[^\w'']','');
        values=values';
        for k = 1:resp_per_block%responses
            if j==1%first 0 back block, different order of responses
                corr_resp = str2double(values{k,4}); %values(:,4) is what response should be
                if test==1
                    subj_resp = str2double(values{k,14}); %values(:,14) is what subject pressed, test==1 and test==3 are the same
                elseif test==2
                    subj_resp = double(values{k,14}-96); %convert a,b,c,d to 1,2,3,4
                elseif test==3
                    subj_resp = str2double(values{k,14});
                elseif test==4
                    subj_resp = str2double(values{k,14})/2;
                else
                    'miss' %Shouldn't happen
                end
                time = str2double(values{k,9}); %values{:,9} is onset time
                if corr_resp == subj_resp
                    final = 1;
                elseif isempty(subj_resp) || isnan(subj_resp)
                    final = 0;
                elseif corr_resp ~= subj_resp
                    final = 2;
                else
                    final = 99;
                end
            else%every other block
                corr_resp = str2double (values{k,3});
                if test==1
                    subj_resp = str2double(values{k,12});
                elseif test==2
                    subj_resp = double(values{k,12}-96);
                elseif test==3
                    subj_resp = str2double(values{k,12});
                elseif test==4
                    subj_resp = str2double(values{k,12})/2;
                else
                    'miss'
                end
                time = str2double (values{k,7});
                if mod(j,2)== 0%2back
                    if corr_resp == subj_resp
                        final = 3;
                    elseif isempty(subj_resp) || isnan(subj_resp)
                        final = 0;
                    elseif corr_resp ~= subj_resp
                        final = 4;
                    else
                        final = 99; %Shouldn't see 99 in final CSV, means something wrong
                    end
                else %0Back
                    if corr_resp == subj_resp
                        final = 1;
                    elseif isempty(subj_resp) || isnan(subj_resp)
                        final = 0;
                    elseif corr_resp ~= subj_resp
                        final = 2;
                    else
                        final = 99;
                    end
                end
            end
            final_resp = [final_resp final];
            subj_resp_final = [subj_resp_final subj_resp ];
            onset_time = [onset_time time];
        end

    end
        final1(:,1) = final_resp;
        %final1(1:20,1) = final_resp;
        final1(:,2) = onset_time;
        file_name = [namis{i} '.csv'];
        dlmwrite(file_name,final1,'delimiter', ',','precision', 7);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Part 2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end