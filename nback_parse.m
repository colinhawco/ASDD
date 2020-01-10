function out = nback_parse(file)
% output event types:
% type 1 is a 0back correct
% type 2 is a 0back incorrect
% type 3 is a 2back correct
% type 4 is a 2back incorrect
% type -1 is a 0back miss
% type -2 is a twback miss
%
%
% out in format type, onset, RT

fid=fopen(file);

% parse text file, line by line, and brute force find the relevant info
stop=0; trial=0;
ln = textscan(fid, '%s', 1, 'Delimiter', '\n', 'Headerlines', 22);
while stop==0
    
    ln = deblank(textscan(fid, '%s', 1, 'Delimiter', '\n'));
    ln=ln{1}{1};
    ln=ln(2:2:end);
    
    if findstr(ln, 'trialproc') ~= 0
        trial=trial+1;
    elseif findstr(ln, 'CorrResp:') ~= 0
        CorrResp(trial) = str2num(ln(end));
    elseif findstr(ln, 'TrialDisp.OnsetTime:') ~= 0
        [s r] = strtok(ln);
        OnsetTime(trial) = str2num(r)/1000;
    elseif findstr(ln, 'TrialDisp.RT:') ~= 0
        [s r] = strtok(ln);
        RT(trial) = str2num(r);
    elseif findstr(ln, 'TrialDisp.RESP:') ~= 0
        resp(trial) = ln(end);
    elseif findstr(ln, 'Experiment:') ~= 0
        stop=1; 
        fclose(fid)
    end
end



% resp can be either 1234, 2468, or abcd, gotta fix this
if findstr(resp, 'a')  ~= 0
    resp(findstr(resp, 'a'))='1'; 
    resp(findstr(resp, 'b'))='2';
    resp(findstr(resp, 'c'))='3';
    resp(findstr(resp, 'd'))='4';
elseif findstr(resp, '8') ~= 0
    resp(findstr(resp, '2'))='1'; 
    resp(findstr(resp, '4'))='2';
    resp(findstr(resp, '6'))='3';
    resp(findstr(resp, '8'))='4';
end

% if they did not responde we'll have a ":" for the resp
resp(findstr(resp, ':'))='0';

% define block typs for each trial, trials 1:20 are 0back, type 1, trials
% 21:40 are 2back, type 2, and so on
blocks(1:240,1) = 1; 
blockons = 21:40:240; %2 back blocsk first trial
for idx = 1:6 % 6 2back blocks
    blocks(blockons(idx):blockons(idx)+19,1) = 2;
end

for idx = 1:length(resp)
    r=str2num(resp(idx)); 
    if r == CorrResp(idx)
       out(idx,1)= blocks(idx)^2 - (blocks(idx) -1); 
    elseif r == 0 
        out(idx,1)= blocks(idx)*-1;
    else
        out(idx,1)= blocks(idx)^2 - (blocks(idx) -1) +1;
    end
    out(idx,2) = OnsetTime(idx); 
    out(idx,3) = RT(idx);

end
        
    
    
    