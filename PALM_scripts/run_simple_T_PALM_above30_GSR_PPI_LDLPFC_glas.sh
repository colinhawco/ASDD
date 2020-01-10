#!/bin/bash
#SBATCH --partition=high-moby
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --time=4:00:00
#SBATCH --export=ALL
#SBATCH --job-name PALM
#SBATCH --output=/projects/ttan/ASDD/Data1/PALM/logs/PALM_above30_GSR_LDLPFC_glas%j.txt
#SBATCH --error=/projects/ttan/ASDD/Data1/PALM/logs/PALM_above30_GSR_LDLPFC_glas%jerr.txt
#SBATCH --array=1-3

# HCP_DATA is a global variable,
# eg: export HCP_DATA='/scratch/colin/MST_open/hcp/'
source /etc/profile.d/modules.sh
source /etc/profile.d/quarantine.sh
module load matlab/R2017b
module load palm/alpha102
module load connectome-workbench/1.3.2

# assign the variable curdir for current directory

DIR="/projects/ttan/ASDD/Data1/PALM"

sublistids="${DIR}/subid_GSR/above30_sublist_GSR.txt"
filename="$(find $DIR/filelists/above30/PPI_LDLPFC_glas/filelist* -type f | head -n $SLURM_ARRAY_TASK_ID | tail -n 1)"
truncname="$(echo $(basename `echo "$filename"`) | sed 's/filelist/above30_GSR_PPI_LDLPFC_glas_con/;s/.txt//')"
outdir="${DIR}/Results/$truncname"
#desmat="$DIR/lists/con_design/post_pre_group_diff_RS_design.csv"
#conmat="$DIR/lists/con_design/post_pre_group_diff_RS_contrast.csv"


#outdier is the place where users want to save results in
echo output directory is $outdir
mkdir -p $outdir
cd $outdir


#echo $sublistids
HCP_DATA=/projects/colin/ASDD/Data3/analysis/
#/scratch/jjeyachandra/test_env/archive/data/ASDD/pipelines/ciftify/

infile=allsubs_merged.dscalar.nii
fname=merge_split
#extracting the first element of sublistids file
exampleSubid=$(head -n 1 ${sublistids})
#first Instance of sublistids file
surfL=${HCP_DATA}/sub-${exampleSubid}_ses-01/sub-CMH${exampleSubid}.L.midthickness.32k_fs_LR.surf.gii
surfR=${HCP_DATA}/sub-${exampleSubid}_ses-01/sub-CMH${exampleSubid}.R.midthickness.32k_fs_LR.surf.gii

#stage 1 merge files (do a while loop reading a text file with a lsit of cifti files
mergefiles() {
    args=""
    while read ff
    do
	args="${args} -cifti $ff"
    done < ${filename} #users need to specify the full path for filename file
    echo $args

    # allsubs_merged.dscalar.nii is the file that PALM will use
    wb_command -cifti-merge ${infile} ${args}
}

#stage 2 separate cifti into gifti
cifti2gifti() {
    wb_command -cifti-separate $infile COLUMN -volume-all ${fname}_sub.nii -metric CORTEX_LEFT ${fname}_L.func.gii -metric CORTEX_RIGHT ${fname}_R.func.gii
    wb_command -gifti-convert BASE64_BINARY ${fname}_L.func.gii ${fname}_L.func.gii
    wb_command -gifti-convert BASE64_BINARY ${fname}_R.func.gii ${fname}_R.func.gii
}
#stage 3 Calculate mean surface
meansurface() {
    MERGELIST=""
    while read subids; do
	dir=${HCP_DATA}/sub-${subids}_ses-01
	MERGELIST="${MERGELIST} -metric $dir/sub-CMH${subids}_L_midthick_va.shape.gii";
    done < ${sublistids}

    #wb_command will automatically save results in the current dir, which is outdir
    wb_command -metric-merge L_midthick_va.func.gii ${MERGELIST}
    wb_command -metric-reduce L_midthick_va.func.gii MEAN L_area.func.gii

    MERGELIST=""
    while read subids; do
	dir=${HCP_DATA}/sub-${subids}_ses-01
	MERGELIST="${MERGELIST} -metric $dir/sub-CMH${subids}_R_midthick_va.shape.gii";
    done < ${sublistids}

    wb_command -metric-merge R_midthick_va.func.gii ${MERGELIST}
    wb_command -metric-reduce R_midthick_va.func.gii MEAN R_area.func.gii
}

#stage 4: RUN PALM
runpalm() {
    palm -i ${fname}_L.func.gii -o results_L_cort -T -tfce2D -s $surfL L_area.func.gii -logp -n 1000
    palm -i ${fname}_R.func.gii -o results_R_cort -T -tfce2D -s $surfR R_area.func.gii -logp -n 1000
    palm -i ${fname}_sub.nii -o results_sub -T -logp -n 1000

    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c1.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c1.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c1.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c1.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c2.dscalar.nii  -volume-all results_sub_tfce_tstat_fwep_c2.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c2.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c2.gii

    wb_command -cifti-math '(x-y)' ${fname}_tstat_fwep_c12.dscalar.nii -var x results_cort_tfce_tstat_fwep_c1.dscalar.nii -var y results_cort_tfce_tstat_fwep_c2.dscalar.nii
}
#back to the previous directory

mergefiles &&
    cifti2gifti &&
    meansurface &&
    runpalm
