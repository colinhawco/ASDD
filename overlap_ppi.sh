


cd /projects/colin/ASDD/Data2/analysis



for pt in sub-*
do

  echo ${pt}

  wb_command -cifti-convert -from-nifti \
    /projects/colin/ASDD/Data2/analysis/${pt}/PPI/PPI_RDLPFC_glas/spmT_0001.nii \
    template.dscalar.nii   \
    /projects/colin/ASDD/Data2/analysis/tmaps_ppi/${pt}_RDLPFC_ppi_tmap.dscalar.nii

done


cd /projects/colin/ASDD/Data2/analysis/tmaps_ppi


MERGELIST=""
while read pt
do
  MERGELIST="${MERGELIST} -cifti sub-${pt}_ses-01_RDLPFC_ppi_tmap.dscalar.nii ";
done < /mnt/tigrlab/projects/colin/ASDD/Data2/PALM/lists/above30_sublist.txt

wb_command -cifti-merge /projects/colin/ASDD/Data2/overlap_ppi/above30_tmaps_RDLPFC_PPI_merged.dscalar.nii ${MERGELIST}

MERGELIST=""
for ff in sub-HEF*
do
  MERGELIST="${MERGELIST} -cifti $ff ";
done
wb_command -cifti-merge /projects/colin/ASDD/Data2/overlap_ppi/HC_tmaps_RDLPFC_PPI_merged.dscalar.nii ${MERGELIST}



cd /projects/colin/ASDD/Data2/overlap_ppi

wb_command -cifti-math '(x>=3.1)' above30_ppi_p001.dscalar.nii -var x above30_tmaps_RDLPFC_PPI_merged.dscalar.nii
wb_command -cifti-reduce above30_ppi_p001.dscalar.nii SUM above30_pos_ppi_rdlpfc_p001_overlap.dscalar.nii

wb_command -cifti-math '(x<=-3.1)' above30_neg_ppi_p001.dscalar.nii -var x above30_tmaps_RDLPFC_PPI_merged.dscalar.nii
wb_command -cifti-reduce above30_neg_ppi_p001.dscalar.nii SUM above30_neg_ppi_rdlpfc_p001_overlap.dscalar.nii



wb_command -cifti-math '(x>=3.1)' HC_ppi_p001.dscalar.nii -var x HC_tmaps_RDLPFC_PPI_merged.dscalar.nii
wb_command -cifti-reduce HC_ppi_p001.dscalar.nii SUM HC_ppi_rdlpfc_p001_overlap.dscalar.nii

wb_command -cifti-math '(x<=-3.1)' HC_neg_ppi_p001.dscalar.nii -var x HC_tmaps_RDLPFC_PPI_merged.dscalar.nii
wb_command -cifti-reduce HC_neg_ppi_p001.dscalar.nii SUM HC_neg_ppi_rdlpfc_p001_overlap.dscalar.nii
