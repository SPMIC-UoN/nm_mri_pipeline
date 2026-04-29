#!/bin/bash

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
DATA_DIR=${ROOT_DIR}/Original
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
REG_MNI_DIR=${ROOT_DIR}/Registered/MNI_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

SCRIPTS_DIR=${ROOT_DIR}/scripts

labels=('background' 'brainstem' 'r_sn' 'l_sn')

sub_id=$1
type=$2

baseline_indicator=1
while [[ ! -f ${REG_DIR}/${sub_id:0:-2}-${baseline_indicator}_T1w.nii.gz ]]; do 
	let baseline_indicator=baseline_indicator+1
done

nm_img_file=${REG_DIR}/${sub_id}_${type}.nii.gz
nm_img_file_baseline=${REG_DIR}/${sub_id:0:-2}-${baseline_indicator}_${type}.nii.gz

synth_img_file=`echo ${nm_img_file} | sed s/${type}/synth-${type}/g`

if [[ -f ${nm_img_file} ]]; then
	if [[ "${sub_id:0-1}" == "${baseline_indicator}" ]] || [[ ! -f ${nm_img_file_baseline} ]]; then
		for index in {0..3}; do
			label=${labels[$index]}
			
			echo -n "[(Initial) Subject ${sub_id}] Propagating weight map of label '${label}' back to subject space (${type} version) ... "
			${NIFTYREGPATH}/reg_resample -ref ${nm_img_file} -flo ${TEMPLATE_DIR}/${label}_synth-NM_weight_map.nii.gz -res ${REG_DIR}/${sub_id}_${label}_synth-${type}_weight_map.nii.gz -trans ${DOFS_DIR}/${sub_id}_template_to_T1w_ffd.nii.gz -voff > /dev/null
			echo "done"
		done

		echo -n "[(Initial) Subject ${sub_id}] Computing initial synthetic (${type} based) image ... "
		${MATLABPATH}/matlab -nodesktop -nosplash -r "addpath(genpath('${SCRIPTS_DIR}')); create_synth_image('${ROOT_DIR}', '${sub_id}', '${type}'); exit" > /dev/null
		echo "done"

		echo -n "[(Initial) Subject ${sub_id}] Non-linearly registering synthetic (${type} based) image to MNI space (ROI only) ... "
		${NIFTYREGPATH}/reg_f3d --lncc 0.5 -be 0.05 -pad 0 -ln 1 -maxit 250 -ref ${TEMPLATE_DIR}/synth_template.nii.gz -flo ${synth_img_file} -incpp ${DOFS_DIR}/${sub_id}_T1w_to_template_ffd.nii.gz -cpp ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.nii.gz -res ${REG_MNI_DIR}/${sub_id}_${type}.nii.gz -rmask ${TEMPLATE_DIR}/ROI_mask.nii.gz -voff > /dev/null
		echo "done"
		
		echo -n "[(Initial) Subject ${sub_id}] Computing inverse transform of last non-linear registration ... "
		${NIFTYREGPATH}/reg_transform -ref ${TEMPLATE_DIR}/synth_template.nii.gz -invNrr ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.nii.gz ${synth_img_file} ${DOFS_DIR}/${sub_id}_template_to_synth-${type}_ffd.nii.gz
		echo "done"

		for index in {0..3}; do
			label=${labels[$index]}
			
			echo -n "[(Refined) Subject ${sub_id}] Propagating weight map of label '${label}' back to subject space (${type} version) ... "
			${NIFTYREGPATH}/reg_resample -ref ${nm_img_file} -flo ${TEMPLATE_DIR}/${label}_synth-NM_weight_map.nii.gz -res ${REG_DIR}/${sub_id}_${label}_synth-${type}_weight_map.nii.gz -trans ${DOFS_DIR}/${sub_id}_template_to_synth-${type}_ffd.nii.gz -voff > /dev/null
			echo "done"
		done

		echo -n "[(Refined) Subject ${sub_id}] Computing refined synthetic (${type} based) image ... "
		${MATLABPATH}/matlab -nodesktop -nosplash -r "addpath(genpath('${SCRIPTS_DIR}')); create_synth_image('${ROOT_DIR}', '${sub_id}', '${type}'); exit" > /dev/null
		echo "done"

		echo -n "[(Refined) Subject ${sub_id}] Non-linearly registering synthetic (${type} based) image to MNI space (ROI only) ... "
		${NIFTYREGPATH}/reg_f3d --lncc 0.5 -be 0.05 -pad 0 -ln 1 -maxit 250 -ref ${TEMPLATE_DIR}/synth_template.nii.gz -flo ${REG_MNI_DIR}/${sub_id}_${type}.nii.gz -incpp ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.nii.gz -cpp ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.nii.gz -res ${REG_MNI_DIR}/${sub_id}_${type}.nii.gz -rmask ${TEMPLATE_DIR}/ROI_mask.nii.gz -voff > /dev/null
		echo "done"
		
		echo -n "[(Refined) Subject ${sub_id}] Computing inverse transform of last non-linear registration ... "
		${NIFTYREGPATH}/reg_transform -ref ${TEMPLATE_DIR}/synth_template.nii.gz -invNrr ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.nii.gz ${synth_img_file} ${DOFS_DIR}/${sub_id}_template_to_synth-${type}_ffd.nii.gz
		echo "done"
	else
		dof_file_baseline_ffd=${DOFS_DIR}/${sub_id::-2}-${baseline_indicator}_synth-${type}_to_template_ffd.nii.gz
		dof_file_baseline_ffd_inv=${DOFS_DIR}/${sub_id::-2}-${baseline_indicator}_template_to_synth-${type}_ffd.nii.gz
		
		echo -n "[Subject ${sub_id}] Copying non-linear transformation of baseline synthetic (${type} based) image to synthetic MNI template ... "
		cp ${dof_file_baseline_ffd} ${DOFS_DIR}/${sub_id}_synth-${type}_to_template_ffd.nii.gz
		echo "done"
		
		echo -n "[Subject ${sub_id}] Copying inverse non-linear transformation ... "
		cp ${dof_file_baseline_ffd_inv} ${DOFS_DIR}/${sub_id}_template_to_synth-${type}_ffd.nii.gz
		echo "done"
	fi
	
	for index in {0..3}; do
		label=${labels[$index]}
		
		echo -n "[(Final) Subject ${sub_id}] Propagating weight map of label '${label}' back to subject space (${type} version) ... "
		${NIFTYREGPATH}/reg_resample -ref ${nm_img_file} -flo ${TEMPLATE_DIR}/${label}_synth-NM_weight_map.nii.gz -res ${REG_DIR}/${sub_id}_${label}_synth-${type}_weight_map.nii.gz -trans ${DOFS_DIR}/${sub_id}_template_to_synth-${type}_ffd.nii.gz -voff > /dev/null
		echo "done"
	done

	echo -n "[(Final) Subject ${sub_id}] Computing final synthetic (${type} based) image ... "
	${MATLABPATH}/matlab -nodesktop -nosplash -r "addpath(genpath('${SCRIPTS_DIR}')); create_synth_image('${ROOT_DIR}', '${sub_id}', '${type}'); exit" > /dev/null
	echo "done"
fi
