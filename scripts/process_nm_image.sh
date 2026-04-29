#!/bin/bash

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
DATA_DIR=${ROOT_DIR}/Original
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

sub_id=$1
type=$2

t1w_img_file_reg=${REG_DIR}/${sub_id}_T1w.nii.gz

nm_img_file_orig=${DATA_DIR}/${sub_id}_${type}.nii.gz
nm_img_file_reg=${REG_DIR}/${sub_id}_${type}.nii.gz

if [[ -f ${nm_img_file_orig} ]]; then
	echo -n "[Subject ${sub_id}] Computing initial transformed ${type} image in T1w space ... "
	${NIFTYREGPATH}/reg_resample -ref ${t1w_img_file_reg} -flo ${nm_img_file_orig} -res ${nm_img_file_reg} -trans ${DOFS_DIR}/${sub_id}_initial_rigid_transform.mat -voff 
	echo "done"
	
	echo -n "[Subject ${sub_id}] Running N4 on initial transformed ${type} image ... "
	${ANTSPATH}/N4BiasFieldCorrection -i ${nm_img_file_reg} -o ${nm_img_file_reg} -d 3 -s 3
	echo "done"
	
	echo -n "[Subject ${sub_id}] Running non-local means denoising on initial transformed ${type} image ... "
	${ANTSPATH}/DenoiseImage -i ${nm_img_file_reg} -o ${nm_img_file_reg} -d 3 -s 1
	echo "done"
	
	echo -n "[Subject ${sub_id}] Rigidly registering initial transformed ${type} image to T1w image ... "
	${NIFTYREGPATH}/reg_aladin -ref ${t1w_img_file_reg} -flo ${nm_img_file_reg} -aff ${DOFS_DIR}/${sub_id}_${type}_to_${sub_id}_T1w.mat -res ${nm_img_file_reg} -rigOnly -ln 1 -voff	
	echo "done"
fi
