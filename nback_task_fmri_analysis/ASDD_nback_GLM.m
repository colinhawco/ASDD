function  ASDD_nback_GLM(subj)
% run a first level GLM on a single subject
% subj is the subject ID, e.g. EF0001

tsk='nbk'

%%%Parameters you have to change %%%
%%%basedir is where the fMRI data is %%%
basedir = ['/projects/colin/ASDD/Data2/analysis/'];%%%
outdir = [basedir '/sub-' subj '_ses-01/'];
mkdir(outdir);
cd([outdir]);


% make a file lsit for analysis, according to SPM expectations
fn = deblank(ls([ '*' tsk '*s8.nii']));
fname =[outdir fn];

for sdx = 1:416
    ftemp = [fname ',' num2str(sdx)];
    files(sdx,1:length(ftemp)) = ftemp;
end


% create event matrix of onsets, accoridng to my SPM script requrments
name = subj;

cd(['/projects/ttan/ASSD/Data/CSV/Pre_CSV']);   %%%you have to change this to the directory where CSV files are%%%

%load CSV of trial events, parsed from the eprime files
fn=deblank(ls(['*_' name '*.csv']));
ev_dat = csvread(fn);
ev_dat(:,2)= (ev_dat(:,2)/1000); % time to seconds
ev_dat(:,2)= ev_dat(:,2) - ev_dat(1,2) + 7.45; %adjust to first trial osnet time

blocks_ons = ev_dat(1:20:240,2);
blocktype = [ 1 2 1 2 1 2 1 2 1 2 1 2]';
block_dur(1:length(blocktype),1)=49;
% base onset for blocks
ons=[ones(length(blocktype),1) blocktype blocks_ons block_dur];

%% the first 2 trials in the 2 back have no response, but we dont want tom to be missed so code as '9'
ev_dat(21:40:end, 1) = 9;
ev_dat(22:40:end, 1) = 9;
%find time of incorrect respoonses
n0back_miss_ons = ev_dat(ev_dat(:,1)==2,2);
n2back_miss_ons = ev_dat(ev_dat(:,1)==4,2);
miss= ev_dat(ev_dat(:,1)==0,2);

%if no incorrect responses, create dummy event with an onset at the every
%end of the run
if isempty(n0back_miss_ons)
    n0back_miss_ons=831.5;
end
if isempty(n2back_miss_ons)
    n2back_miss_ons=831.5-8;
end
if isempty(miss)
    miss=831.5-8;
end

other_ons = [n0back_miss_ons;n2back_miss_ons;miss;];

other_evs = [ones(length(n0back_miss_ons),1)*3; ones(length(n2back_miss_ons),1)*4; ...
    ones(length(miss),1)*5]; %%%covert n0_back_miss_on into 3 and 2back into 4 and miss into 5

% event types in ons matrix
% 1 is 0 baack block    2 is 2back block
%3 is o back miss 4 is 2 back miss  5 is a no response
ons = [ons ; [ones(length(other_evs),1) other_evs other_ons zeros(length(other_evs),1)] ];


% OK now for regressors, from the tsv file output from fmristat
%%%%%%%%%%%%%%%%%%%%%%% generating mregress fname='sub-HCT201_ses-01_task-nbk_bold_confounds.tsv'
cd(outdir)
fname = deblank(ls(['*' tsk '*.tsv']))
mf=tdfread(fname);
dvars = [0; str2num(mf.stdDVARS(2:end,:))];
fd=[0; str2num(mf.FramewiseDisplacement(2:end,:))];

%matrix of regressors
mregress = [mf.CSF mf.WhiteMatter dvars fd mf.X mf.Y mf.X mf.RotX mf.RotY mf.RotZ];


% run actual first level model, SPms design specifciation and estimation in
% one line
analyze_spm12_design_hcp(outdir, files, 3, 2, ons, mregress);

% not contrasts and stat maps, single subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%note we used HRF plus 1st deriv and dispesion
contrasts = [
    -1 0 0 1 0 0 zeros(1, (max(ons(:,2))-2)*3) zeros(1,size(mregress,2))  0 %2back-0back (con0001)
    1 0 0 0 0 0 zeros(1, (max(ons(:,2))-2)*3) zeros(1,size(mregress,2))  0 %Main effect 0back (con0002)
    0 0 0 1 0 0 zeros(1, (max(ons(:,2))-2)*3) zeros(1,size(mregress,2))  0] %Main effect 2back (con0003)

%con names
names ={'N2back_N0back'; 'N0back'; 'N2back' };

% run contrasts, generates SPM con and smT files
analyze_spm_contrasts( [outdir], contrasts, names');

%congrats, one subejct run. 
