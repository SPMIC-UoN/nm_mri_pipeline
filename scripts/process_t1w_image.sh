#!/bin/bash

SELF_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR=${SELF_DIR}/..
TEMPLATE_DIR=${ROOT_DIR}/Template
DATA_DIR=${ROOT_DIR}/Original
REG_DIR=${ROOT_DIR}/Registered/MPRAGE_space
DOFS_DIR=${ROOT_DIR}/Registered/dofs

sub_id=$1

tmp_dir=`mktemp -d -p /tmp process_t1w_image_XXXXXXXXX`

baseline_indicator=1
while [[ ! -f ${DATA_DIR}/${sub_id:0:-2}-${baseline_indicator}_T1w.nii.gz ]]; do 
	let baseline_indicator=baseline_indicator+1
done

t1w_img_file_reg=${REG_DIR}/${sub_id}_T1w.nii.gz
t1w_img_file_reg_baseline=${REG_DIR}/${sub_id::-2}-${baseline_indicator}_T1w.nii.gz
nm_img_file_baseline=${REG_DIR}/${sub_id::-2}-${baseline_indicator}_${type}.nii.gz

echo -n "[Subject ${sub_id}] Copying original T1w image ... "
cp ${DATA_DIR}/${sub_id}_T1w.nii.gz ${t1w_img_file_reg}
echo "done"

echo -n "[Subject ${sub_id}] Running N4 on T1w image ... "
${ANTSPATH}/N4BiasFieldCorrection -i ${t1w_img_file_reg} -o ${t1w_img_file_reg} -d 3 -s 3
echo "done"

if [[ "${sub_id:0-1}" != "${baseline_indicator}" ]]; then

	echo -n "[Subject ${sub_id}] Rigidly registering T1w image to baseline T1w image ... "
	${NIFTYREGPATH}/reg_aladin -ref ${t1w_img_file_reg_baseline} -flo ${t1w_img_file_reg} -aff ${DOFS_DIR}/${sub_id}_initial_rigid_transform.mat -res ${tmp_dir}/temp_${sub_id}_T1w_longitudinal_rig_result.nii.gz -rigOnly -voff	
	echo "done"
	
	echo -n "[Subject ${sub_id}] Overwriting T1w image with baseline T1w image ... "
	cp ${t1w_img_file_reg_baseline} ${t1w_img_file_reg}
	echo "done"
else
	${NIFTYREGPATH}/reg_transform -makeAff 0 0 0 0 0 0 1 1 1 0 0 0 ${DOFS_DIR}/${sub_id}_initial_rigid_transform.mat
fi

rm -rf ${tmp_dir}