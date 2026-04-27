#!/bin/bash

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

sub_id=$1

tmp_dir=`mktemp -d -p /tmp t1w_to_mni_registration_XXXXXXXXX`

baseline_indicator=1
while [[ ! -f ${REG_DIR}/${sub_id:0:-2}-${baseline_indicator}_T1w.nii.gz ]]; do
	let baseline_indicator=baseline_indicator+1
done

t1w_img_file_reg=${REG_DIR}/${sub_id}_T1w.nii.gz
nm_img_file_baseline=${REG_DIR}/${sub_id:0:-2}-${baseline_indicator}_${type}.nii.gz

if [[ "${sub_id:0-1}" == "${baseline_indicator}" ]]; then
	echo -n "[Subject ${sub_id}] Computing temporal brain-extracted T1w image for MNI registration ... "
	${ROBEXPATH}/runROBEX.sh ${t1w_img_file_reg} ${tmp_dir}/temp_${sub_id}_T1w_masked.nii.gz > /dev/null
	echo "done"
	
	echo -n "[Subject ${sub_id}] Affinely registering temporal brain-extracted T1w image to T1w MNI template ... "
	${NIFTYREG_BIN_DIR}/reg_aladin -ref ${TEMPLATE_DIR}/brain_masked.nii.gz -flo ${tmp_dir}/temp_${sub_id}_T1w_masked.nii.gz -aff ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.mat -res ${tmp_dir}/temp_${sub_id}_T1w_aff_result.nii.gz -voff > /dev/null
	echo "done"

	echo -n "[Subject ${sub_id}] Affinely registering temporal brain-extracted T1w image to T1w MNI template (ROI only) ... "
	${NIFTYREG_BIN_DIR}/reg_aladin -ref ${TEMPLATE_DIR}/brain_masked.nii.gz -flo ${tmp_dir}/temp_${sub_id}_T1w_masked.nii.gz -inaff ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.mat -aff ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.mat -res ${tmp_dir}/temp_${sub_id}_T1w_aff_result.nii.gz -rmask ${TEMPLATE_DIR}/ROI_mask.nii.gz -voff > /dev/null
	echo "done"

	echo -n "[Subject ${sub_id}] Non-linearly registering temporal brain-extracted T1w image to T1w MNI template (ROI only) ... "
	${NIFTYREG_BIN_DIR}/reg_f3d --lncc 0.5 -be 0.05 -pad 0 -sx 5 -ref ${TEMPLATE_DIR}/brain_masked.nii.gz -flo ${tmp_dir}/temp_${sub_id}_T1w_masked.nii.gz -aff ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.mat -cpp ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.nii.gz -res ${tmp_dir}/temp_${sub_id}_T1w_ffd_result.nii.gz -rmask ${TEMPLATE_DIR}/ROI_mask.nii.gz -voff > /dev/null
	echo "done"
	
	echo -n "[Subject ${sub_id}] Computing inverse transform of last non-linear registration ... "
	${NIFTYREG_BIN_DIR}/reg_transform -ref ${TEMPLATE_DIR}/brain_masked.nii.gz -invNrr ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.nii.gz ${tmp_dir}/temp_${sub_id}_T1w_masked.nii.gz ${DOFS_DIR}/${sub_id}_template_to_T1w_ffd.nii.gz
	echo "done"
else
	dof_file_baseline_aff=${DOFS_DIR}/${sub_id::-2}-${baseline_indicator}_T1w_to_template_aff.mat
	dof_file_baseline_ffd=${DOFS_DIR}/${sub_id::-2}-${baseline_indicator}_T1w_to_template_ffd.nii.gz
	dof_file_baseline_ffd_inv=${DOFS_DIR}/${sub_id::-2}-${baseline_indicator}_template_to_T1w_ffd.nii.gz
	
	echo -n "[Subject ${sub_id}] Copying affine and non-linear transformations of baseline T1w image to T1w MNI template ... "
	cp ${dof_file_baseline_aff} ${DOFS_DIR}/${sub_id}_T1w_to_template_aff.mat
	cp ${dof_file_baseline_ffd} ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.nii.gz
	echo "done"
	
	echo -n "[Subject ${sub_id}] Copying non-linear transformation of T1w MNI template to baseline T1w image ... "
	cp ${dof_file_baseline_ffd_inv} ${DOFS_DIR}/${sub_id}_template_to_T1w_ffd.nii.gz
	echo "done"
fi

rm -rf ${tmp_dir}