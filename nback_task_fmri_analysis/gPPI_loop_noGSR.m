load /mnt/tigrlab/projects/colin/ASDD/Data2/subs.mat

addpath /mnt/tigrlab/projects/colin/ASDD/git/nback_task_fmri_analysis
addpath /mnt/tigrlab/projects/colin/ASDD/git/nback_task_fmri_analysis/gPPI/PPPIv13


for idx = 1:size(subs,1)
    subj=subs{idx};
    roi_n = 'RDLPFC_glas';
    HCP_gPPI_noGSR(subj,roi_n)
    
    roi_n = 'LDLPFC_glas';
    HCP_gPPI_noGSR(subj,roi_n)
    
end

