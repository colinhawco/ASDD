Code for ASD NBACK analysis

Overview: This is the code used for our ASD N-BACK baseline paper from our sample in the rTMS executive function trial in ASD.

the nback_task_fmri_analysis folder includes files needed to run the GLMs and PPI analysis at the single subject level.

This code used SPM, and has a further dependency on my batch script codes, which simplify SPM GLM implimentation:
https://github.com/colinhawco/SPM_bat_scripts

Note that our preprocessed data was in CIFTIFI space, via Erin Dickie's ciftify function (thank's Erin!)
https://github.com/edickie/ciftify

So, before we ran SPM, we needed to convert back to nifti space using the HCP tools (wb_command -cifti-convert). However, note the data was stil organzied as a cifti file, e.g. 3 columns.

After this, we convert the con files output by SPM back to cifti


The assets folder includes the ROIs used for the PPI analyses, as well as example SPM.mat files from the furst level analysis of one subejct.These can be used to see the design matricies. subs.mat is a list of subjects in the study. the template.dscalar was used to convert nifti files back to cifti dscalars (e.g. SPM con outputs)

The PALM_scripts folder included scripts we ran to run group analyses in PALM. These scripts are designed to work on our specific system, which used SLURM for que management. Sorry they are not more generalzied or easily understandable.

Basically they find the HCP surface files, make a mean surface for palm, then find the contrast files, merge them into a single file with all participants (based on a provided text file of filelists), and runs PLAM. THe simpleT is for a one-sample t-test (one group, is con > 0), th conmat is for between groups (e.g. CON > ASD).

overlap_ppi.sh was run to create overlap maps (e.g. Figure 5 in the paper).
asd_motion.m extracts motion paramters from fmriprep's tsv outputs.

Fly safe.



%%% STEPS TO RUN ASDD_nback_GLM-SCRIPT %%%

1.Module load matlab
2.Module load SPM/12

3.In matlab command window: >> spm fmri
4.The output will be in the same folder as the fMRI/*s8.nii
5. GLM_loops.m will loops through subs and run task GLM and PPIs

%%%%%%%%%%%%%%%%%%%%%END%%%%%%%%%%%%%%%%%%



%%%%%%%                 STEPS TO RUN run_PALM_simpleT.sh SCRIPT                       %%%%%%%%%%

#export HCP_DATA=/scratch/mmanogaran/fmriprep/roi_ASDD_out/ciftify_ses/


%%% Run this loop in terminal to convert the contrast nii file into dscalar to use in HCP %%%

for dir in /projects/ttan/ASSD/Data/testing/*; do
	wb_command -cifti-convert -from-nifti $dir/PPI/PPI_PCC_right/con_0001.nii /projects/colin/ASDD/smooth_activations/sub-EF001_ses-01/con_0001.dscalar.nii $dir/PPI/PPI_PCC_right/con_0001.dscalar.nii;
	wb_command -cifti-convert -from-nifti $dir/PPI/PPI_PCC_right/con_0002.nii /projects/colin/ASDD/smooth_activations/sub-EF001_ses-01/con_0002.dscalar.nii $dir/PPI/PPI_PCC_right/con_0002.dscalar.nii;
	wb_command -cifti-convert -from-nifti $dir/PPI/PPI_PCC_right/con_0003.nii /projects/colin/ASDD/smooth_activations/sub-EF001_ses-01/con_0003.dscalar.nii $dir/PPI/PPI_PCC_right/con_0003.dscalar.nii;

done

	wb_command -cifti-convert -from-nifti $dir/con_0002.nii /projects/colin/ASDD/smooth_activations/sub-EF001_ses-01/con_0002.dscalar.nii $dir/con_0002.dscalar.nii;
	wb_command -cifti-convert -from-nifti $dir/con_0003.nii /projects/colin/ASDD/smooth_activations/sub-EF001_ses-01/con_0003.dscalar.nii $dir/con_0003.dscalar.nii;
done

%%%  Create filelist and sublist for all the subjects based on the fMRI folders  %%%%
for dir in /projects/ttan/ASSD/Data/testing/*; do echo $dir >> filelist.txt; done
%%% /projects/ttan/ASSD/Data/testing/sub-EF001_ses-01 %%%% <--- this filelist.txt contain all the subject paths
for dir in /projects/ttan/ASSD/Data/testing/*; do k=${dir##*sub-}; echo ${k%%_*};
done
%%% EF001 <--- this is the sublist %%%

%%% Create further filelist and sublist of each group (i.e ASD_below8_filelist and sublist). This is what we you to run PALM since this script only run once group in each condition seperately %%%
%%% /projects/ttan/ASSD/Data/testing/sub-EF008_ses-01/con_0003.dscalar.nii %%% <--- this is what it should be in your filelist of each group
%%% Change the con_0001, con_0002, con_0003 depend on which contrast you like to run (i.e con_0001 is for 2back versus 0 back, con_0002 is 0back, con_0003 is N2back) %%%%

IMPORTANT NOTE: DO NOT LEAVE ANY SPACE IN THE SUBLIST AND FILELIST AFTER THE LAST SUBJECT.



%have to make output directory or PALM runs in dir
mkdir $dir/groups
mkdir /projects/ttan/ASSD/PALM/groups/ASD_Above8_2backv0Back

%%% Load this in terminal %%%
module load matlab
module load palm/alpha102
module load connectome-workbench
dir=/projects/ttan/ASSD/Data/PALM/ %%% dir is the path you store your PALM script %%%

${dir}run_PALM_simpleT.sh  ${dir}ASD_above8_sublist.txt  ${dir}above8_filelistPPI.txt ${dir}PPI/Above8/DLPFC_right/2back

${dir}run_PALM_simpleT.sh  ${dir}ASD_below8_sublist.txt  ${dir}below8_filelistPPI.txt ${dir}PPI/Below8/DLPFC_right/0back

${dir}run_PALM_simpleT.sh  ${dir}HC_sublist.txt  ${dir}HC_filelistPPI.txt ${dir}PPI/HC/DLPFC_right/0back

%%% This script only do statistical analysis different condition (N2B vs 0B) within a single group from the con_003_dscalar.nii %%%
%%% This is comparing 2back vs 0B in ASD_Above8 group. The parameters you have to change are:

sublistids=$1 <-- change the sublist depend on which group you want to run
filelist=$2 <--- in the filelist, you can change the con_003 to con_001 to run different condition for each group
outdir=$3   <--- change this output directory to which condition you want to run for each group

%%%%%%%%%%                              END                           %%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%                 STEPS TO RUN run_PALM_conmat.sh SCRIPT                     %%%%%%%%%%
%%% This script will compare between group (i.e ASD_Above8 versus ASD_Below8) %%%

1. You have to generate designmatrix.csv that specifies a one-sided t-test assessing whether there is a higher activation . The following design matrix persoms a t-test with three data points per group, where each column represent a group.
HCabove30_design.csv
	1,0
	1,0
	1,0
	0,1
	0,1
	0,1
2. Create a Ab8vBel8con.csv
	1,-1 <--- HC > ASD
	-1,1 <--- ASD > HC

3. Create a filelist and sublist.txt that contain subjects from ASD_Above to ASD_Below8
	This is HCabove30_filelist.txt

	/mnt/tigrlab/projects/ttan/ASSD/Data/testing/sub-HEF003_ses-01/con_0003.dscalar.nii
	/projects/ttan/ASSD/Data/testing/sub-EF008_ses-01/con_0003.dscalar.nii

	HCabove30_sublist.txt should follow the filelist order.

4.Create outdir$3, depend on which group comparison you want to run, in /projects/ttan/ASSD/PALM/groups/

5. Run the PALM scripts
