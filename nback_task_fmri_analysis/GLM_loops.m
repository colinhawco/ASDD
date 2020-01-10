%loops through partiicpants to run GLM and PPI first level analyses

cd /projects/colin/ASDD/Data2/

load subs.mat
cd analysis

spm fmri % laod SPM to add all needed funtions to path, can clsoe after
addpath ('/projects/colin/ASDD/git/nback_task_fmri_analysis/gPPI/PPPIv13/')

% Loop main GLM through subjects
fail=[];
for pdx = 1:length(subs)
    try
    subj = subs{pdx};
    subj=subj(5:end-7)
    ASDD_nback_GLM_noGSR(subj)
    roi_n='LDLPFC_glas'
    HCP_gPPI(subs{pdx},roi_n )
    roi_n='RDLPFC_glas'
    HCP_gPPI(subs{pdx},roi_n )
    catch
        fail(length(fail)+1) = pdx;
    end
end









