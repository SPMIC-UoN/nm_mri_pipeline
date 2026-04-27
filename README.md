# Parkinson's pipeline

## Table of Contents

* [Prerequisities](#prerequisities)
* [Setup](#setup)
* [Script usage](#script-usage)
* [Resulting data](#resulting-data)

<a id="prerequisities"></a>
## Prerequisities

The Parkinson's Pipeline has the following software requirements:

1. A 64-bit Linux Operating System.

2. Advanced Normalisation Tools ANTs (https://github.com/ANTsX/ANTs) for denoising and N4 bias field correction.

3. ROBEX brain extraction tool (https://www.nitrc.org/projects/robex).

4. NiftyReg for registrations (https://github.com/KCL-BMEIS/niftyreg).

5. MATLAB (we have tested versions R2018a and R2019b, but later versions and some older versions should work as well). To deal with Nifti images, this repository includes a copy of the MATLAB "Tools for Nifti and Analyze images" (https://uk.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image) in the "scripts" folder.

-----

<a id="setup"></a>
## Setup

### Data

The T1-weighted and neuromelanin-sentitive Nifti data to be processed **must** be located in a specific folder named `Original` inside `${GITHUB_ROOT}`, where `${GITHUB_ROOT}` refers to the folder where this repository has been cloned into. It **must** also adhere to the following naming convention:

<pre>
${GITHUB_ROOT}
   |
   ---- Original
           |
           ---- sub-${subject_id}-${timepoint}_T1w.nii.gz
           ---- sub-${subject_id}-${timepoint}_${nm_seq_type}.nii.gz
</pre>

* `${subject_id}` is a unique identifier for each subject that can have any format.
* `${timepoint}` is the timepoint of the data (for longitudinal studies) and **must** be a single digit integer greater or equat to 1. Typically it starts from "1" for baseline data then "2" for first follow-up, and so on. If no longitudinal data is used, this can be any single digit integer from "1" onwards. 
* `${nm_seq_type}` is the name of the neuromelanin-sensitive sequence this data represent and can have any format but **must** be setup as a sequence type (see [Neuromelanin-sensitive sequence names](#neuromelanin-sensitive-sequence-names)).

### Environmental variables

The script [`SetUpVariables.sh`](https://github.com/SPMIC-UoN/nm_mri_pipeline/blob/main/setup/SetUpVariables.sh) serves as a way for the user to setup the paths of the main software pre-requisites the pipeline has. Therefore, for the pipeline to work, the user has to edit this file to specify the specific software paths on their environment.

<a id="neuromelanin-sensitive-sequence-names"></a>
### Neuromelanin-sensitive sequence names

The script [`SetUpNMTypes.sh`](https://github.com/SPMIC-UoN/nm_mri_pipeline/blob/main/setup/SetUpNMTypes.sh) serves as a way for the user to setup the names of the neuromelanin-sensitive sequences that will be processed. The user has to edit this file to specify the specific sequence names on their data. For every subject, only the files with `${nm_seq_type}` names specified in the array will be processed. If a subject does not have data for any of the specified sequences, the pipeline will safely ignore it and proceed with the next sequence type.

-----

<a id="script-usage"></a>
## Script usage

To run the pipeline, execute the `run_pipeline.sh` script. It will proceed with all subjects in the `${GITHUB_ROOT}/Original` folder and create a `${subject_id}-${timepoint}.processed` file for each of them upon completion. If a subject has already an associated `.processed` file, the pipeline will skip this subject and proceed with the next one.

-----

<a id="resulting-data"></a>
## Resulting data

The pipeline will store the resulting data using the following folder structure (which gets automatically created if it does not exist):

<pre>
${GITHUB_ROOT}
   |
   ---- Registered
           |
           ---- dofs
           ---- MNI_space
           ---- MPRAGE_space
</pre>

* `dofs` contains all the intermediate NiftyReg transformations files.
* `MPRAGE_space` contains all the intermediate data in T1w structural space.
* `MNI_space` contains all the processed data in the space of the provided synthetic template (based on MNI152 space). This is the data that should be used for further analysis.
