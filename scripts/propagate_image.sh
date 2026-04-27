#!/bin/bash

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
REG_MNI_DIR=${ROOT_DIR}/Registered/MNI_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

sub_id=$1
type=$2

nm_img_file=${REG_DIR}/${sub_id}_${type}.nii.gz
synth_img_file=`echo ${nm_img_file} | sed s/${type}/synth-${type}/g`

if [[ -f ${nm_img_file} ]]; then
	echo -n "[Subject ${sub_id}] Propagating ${type} image to MNI space ... "
	${NIFTYREG_BIN_DIR}/reg_resample -ref ${TEMPLATE_DIR}/synth_template.nii.gz -flo ${nm_img_file} -res ${REG_MNI_DIR}/${sub_id}_${type}.nii.gz -trans ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.nii.gz -voff
	echo "done"
	
	echo -n "[Subject ${sub_id}] Computing masked version of ${type} image in MNI space ... "
	${NIFTYREG_BIN_DIR}/reg_tools -in ${REG_MNI_DIR}/${sub_id}_${type}.nii.gz -nan ${TEMPLATE_DIR}/ROI_mask.nii.gz -out ${REG_MNI_DIR}/${sub_id}_${type}-masked.nii.gz > /dev/null
	echo "done"
fi

if [[ -f ${synth_img_file} ]]; then
	echo -n "[Subject ${sub_id}] Propagating synthetic (${type} based) image to MNI space ... "
	${NIFTYREG_BIN_DIR}/reg_resample -ref ${TEMPLATE_DIR}/synth_template.nii.gz -flo ${synth_img_file} -res ${REG_MNI_DIR}/${sub_id}_synth-${type}.nii.gz -trans ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.nii.gz -voff
	echo "done"
	
	echo -n "[Subject ${sub_id}] Computing masked version of synthetic (${type} based) image in MNI space ... "
	${NIFTYREG_BIN_DIR}/reg_tools -in ${REG_MNI_DIR}/${sub_id}_synth-${type}.nii.gz -nan ${TEMPLATE_DIR}/ROI_mask.nii.gz -out ${REG_MNI_DIR}/${sub_id}_synth-${type}-masked.nii.gz > /dev/null
	echo "done"
fi
