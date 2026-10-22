#!/bin/bash
#example: while read sub_3T ses_3T sub_7T ses_7T; do bash tutorial_patch.sh "$sub_3T" "$ses_3T" "$sub_7T" "$ses_7T"; done < /host/verges/tank/data/youngeun/myproject/FBA/3T_7T/lists/sub_list.txt
source /host/verges/tank/data/youngeun/venv_new/bin/activate

sub_3T=$1
ses_3T=$2
sub_7T=$3
ses_7T=$4

# ---------------------------------------------------------------------
# Input data and preprocessing outputs
# ---------------------------------------------------------------------
# Path to the micapipe v0.2.0 derivatives generated from 3T data.
micapipe_3T="/data/mica3/BIDS_MICs/derivatives/micapipe_v0.2.0"
# Path to the micapipe v0.2.0 derivatives generated from 7T data.
micapipe_7T="/data/mica3/BIDS_PNI/derivatives/micapipe_v0.2.0"
# Path to the FastSurfer output directory for 7T data.
FS_7T="/data/mica3/BIDS_PNI/derivatives/fastsurfer"

# ---------------------------------------------------------------------
# External software and custom processing modules
# ---------------------------------------------------------------------
# Path to the corticalDWI repository.
# Tutorial: https://github.com/lconcha/corticalDWI/blob/main/tutorial.md
corticalDWI="/host/verges/tank/data/youngeun/git/corticalDWI"
# Path to the INB MRtrix3 custom modules repository.
# Repository: https://github.com/lconcha/inb_mrtrix_modules
inb_mrtrix="/host/verges/tank/data/youngeun/git/inb_mrtrix_modules"
# Path to the custom MRtrix3 repository maintained by Luis Concha.
# Repository: https://github.com/lconcha/mrtrix3
lconcha_mrtrix="/host/verges/tank/data/youngeun/git/mrtrix3_lconcha"

# ---------------------------------------------------------------------
# Subject-specific output directory
# ---------------------------------------------------------------------
# Output directory for the CSD analysis of paired 7T and 3T subjects.
# The directory name combines the 7T and 3T subject identifiers.
sub_dir="/host/verges/tank/data/youngeun/myproject/FBA/3T_7T/subjects_csd/${sub_7T}_${sub_3T}"
# Output directory for MRDS analysis of the current 7T–3T subject pair.
sub_dir_mrds="/host/verges/tank/data/youngeun/myproject/FBA/3T_7T/subjects_mrds/${sub_7T}_${sub_3T}"
# Directory containing local Git repositories.
git_dir="/host/verges/tank/data/youngeun/git"

########################################################################
## Step-05. MRDS
## Run this step only after processing tutorial_CSD.sh step.
########################################################################

echo "▶ Step-05-1: Start MRDS processing (subject: ${sub_7T}_${sub_3T})"
# Add header
mredit ${micapipe_3T}/sub-${sub_3T}/ses-${ses_3T}/dwi/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-brain_mask.nii.gz ${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-brain_mask_withheader.nii.gz

# Generate bval bvec files
mrconvert -strides 1,2,3,4 -export_grad_fsl ${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_dwi.bvec ${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_dwi.bval -export_grad_mrtrix ${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_dwi.scheme ${micapipe_3T}/sub-${sub_3T}/ses-${ses_3T}/dwi/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-preproc_dwi.mif ${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_space-dwi-preproc_dwi_desc-preproc_dwi.nii.gz

# Generate scheme file
mkdir ${sub_dir_mrds}/tmp_scheme
cat ${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_dwi.bvec ${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_dwi.bval > ${sub_dir_mrds}/tmp_scheme/bvalbvec
bash /host/verges/tank/data/youngeun/git/inb_tools/transpose_table.sh ${sub_dir_mrds}/tmp_scheme/bvalbvec > ${sub_dir_mrds}/tmp_scheme/schemeorig
awk '{printf "%.5f %.5f %.5f %.4f\n", $1,$2,$3,$4}' ${sub_dir_mrds}/tmp_scheme/schemeorig > ${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_dwi.scheme
rm -rf ${sub_dir_mrds}/tmp_scheme

echo "▶ Step-05-2: Fit multi-tensors using DTI (subject: ${sub_7T}_${sub_3T})"
# Run DTI
singularity exec \
  --writable-tmpfs \
  --containall \
  -B ${sub_dir_mrds}:/dir_mrds \
  ${git_dir}/mrds-flow_dev.sif dti \
    -mask /dir_mrds/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-brain_mask_withheader.nii.gz \
    -response 0 \
    -correction 0 \
    -fa \
    -md \
    /dir_mrds/sub-${sub_3T}_ses-${ses_3T}_space-dwi-preproc_dwi_desc-preproc_dwi.nii.gz \
    /dir_mrds/sub-${sub_3T}_ses-${ses_3T}_dwi.scheme \
    /dir_mrds/sub-${sub_3T}_ses-${ses_3T}

nAnisoVoxels=`/data_/mica1/01_programs/fsl-6-0-3/bin/fslstats ${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_DTInolin_ResponseAnisotropicMask.nii.gz -V | awk '{print $1}'`
response=`cat ${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_DTInolin_ResponseAnisotropic.txt | awk '{OFS = "," ;print $1,$2}'`

echo "▶ Step-05-3: Fit multi-tensors using multi-resolution discrete search (MRDS) (subject: ${sub_7T}_${sub_3T})"
singularity exec \
  --writable-tmpfs \
  --containall \
  -B ${sub_dir_mrds}:/sub_dir_mrds \
  ${git_dir}/mrds-flow_dev.sif mdtmrds \
    /sub_dir_mrds/sub-${sub_3T}_ses-${ses_3T}_space-dwi-preproc_dwi_desc-preproc_dwi.nii.gz \
    /sub_dir_mrds/sub-${sub_3T}_ses-${ses_3T}_dwi.scheme \
    /sub_dir_mrds/sub-${sub_3T}_ses-${ses_3T} \
    -correction 0 \
    -response ${response} \
    -mask /sub_dir_mrds/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-brain_mask_withheader.nii.gz \
    -modsel ftest \
    -each \
    -intermediate \
    -fa \
    -md \
    -mse \
    -method diff > sub-${sub_3T}_ses-${ses_3T}_mdtmrds_log.txt


########################################################################
## Step-05-4. Convert MRDS metrics to fixels and sample along streamlines
########################################################################

echo "▶ Step-05-4: Convert MRDS metrics to fixels (subject: ${sub_7T}_${sub_3T})"

# Create output directories for fixel data and regional analyses.
mkdir -pv "${sub_dir_mrds}/mrds_fixels_ftest"
mkdir -pv "${sub_dir_mrds}/Gyrus_40_ftest"
mkdir -pv "${sub_dir_mrds}/Sulcus_50_ftest"

# Process each MRDS metric.
for v in FA MD COMP_SIZE; do

    echo "▶ Processing MRDS metric: ${v}"

    # Scale PDDs by the selected MRDS metric.
    bash "${git_dir}/inb_tools/inb_mrds_scalePDDs_YH.sh" \
        -e 0.0000000000000001 \
        "${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_MRDS_Diff_FTest_PDDs_CARTESIAN.nii.gz" \
        "${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_MRDS_Diff_FTest_${v}.nii.gz" \
        "${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_MRDS_Diff_FTest_PDDs_CARTESIAN_scaled-by-${v}.nii.gz" \
        -force

    # Convert the scaled PDDs to fixels.
    mkdir -pv "${sub_dir_mrds}/tmp_ft"

    peaks2fixel \
        "${sub_dir_mrds}/sub-${sub_3T}_ses-${ses_3T}_MRDS_Diff_FTest_PDDs_CARTESIAN_scaled-by-${v}.nii.gz" \
        "${sub_dir_mrds}/tmp_ft/" \
        -nthreads "${nthreads}" -force

    # Store the metric-specific fixel amplitudes.
    mv -v "${sub_dir_mrds}/tmp_ft/amplitudes.mif" \
        "${sub_dir_mrds}/mrds_fixels_ftest/MRDS_DIFF_FTest_${v}.mif"

    # Store the fixel directions and indices.
    for file in directions index; do
        mv -v "${sub_dir_mrds}/tmp_ft/${file}.mif" \
            "${sub_dir_mrds}/mrds_fixels_ftest/"
    done

    # Remove temporary fixel-conversion files.
    rm -rf "${sub_dir_mrds}/tmp_ft"


    ####################################################################
    ## Step-05-5. Sample MRDS values along Laplacian streamlines
    ####################################################################

    # Process gyral and sulcal regions with different angular thresholds.
    for region in "Gyrus_40:40" "Sulcus_50:50"; do

        region_name="${region%%:*}"
        angle="${region##*:}"
        output_dir="${sub_dir_mrds}/${region_name}_ftest"

        for hemi in L R; do

            echo "▶ Step-05-5: Sampling ${v} | Region: ${region_name} | Angle: ${angle}° | Hemisphere: ${hemi} | Subject: ${sub_7T}_${sub_3T}"

            "${lconcha_mrtrix}/bin/tcksamplefixels" \
                -angle "${angle}" \
                "${sub_dir_mrds}/mrds_fixels_ftest/MRDS_DIFF_FTest_${v}.mif" \
                "${sub_dir}/${hemi}_fsLR32k-laplace-wm-streamlines_dwispace.tck" \
                "${output_dir}/${hemi}_fsLR32k_${v}-par-perp-indices.tsf" \
                "${output_dir}/${hemi}_fsLR32k_${v}-par.tsf" \
                "${output_dir}/${hemi}_fsLR32k_${v}-perp.tsf" \
                "${output_dir}/${hemi}_fsLR32k_${v}_perp-av.tsf" \
                -nthreads "${nthreads}" -force

        done
    done

done


########################################################################
## Step-05-6. Convert TSF files to TXT files
########################################################################

nCols=10

# Convert TSF files in both gyral and sulcal output directories.
for region_name in Gyrus_40 Sulcus_50; do

    output_dir="${sub_dir_mrds}/${region_name}_ftest"

    for tsf in "${output_dir}"/*.tsf; do

        # Skip the loop if no TSF files are found.
        [[ -f "$tsf" ]] || continue

        tsf_base=$(basename "$tsf" .tsf)
        txt_path="${output_dir}/${tsf_base}.txt"
        tmpDir="${output_dir}/tmp_${tsf_base}"

        mkdir -p "$tmpDir"

        # Export TSF data as ASCII files.
        tsfinfo -ascii "${tmpDir}/prefix" "$tsf" \
            -nthreads "${nthreads}"

        # Append a delimiter to each exported file.
        for f in "${tmpDir}"/prefix*; do
            [[ -f "$f" ]] || continue
            echo "X" >> "$f"
        done

        # Concatenate the exported data.
        > "${tmpDir}/full_X.txt"

        for f in "${tmpDir}"/prefix*; do
            [[ -f "$f" ]] || continue
            cat "$f" >> "${tmpDir}/full_X.txt"
        done

        # Reconstruct rows using the delimiter.
        tr '\n' ' ' < "${tmpDir}/full_X.txt" \
            | sed 's/X/\n/g; s/^ //' \
            > "${tmpDir}/full.txt"

        # Keep the first nCols columns.
        cut -d ' ' -f "1-${nCols}" "${tmpDir}/full.txt" \
            > "${tmpDir}/cropped.txt"

        # Replace empty fields with -1.
        awk -v C="${nCols}" \
            '{ for (N=1; N<=C; N++) if ($N=="") $N="-1"; print }' \
            "${tmpDir}/cropped.txt" > "$txt_path"

        # Remove temporary files after conversion.
        rm -rf "$tmpDir"

        echo "[✔] Converted ${tsf} → ${txt_path}"

    done
done

echo "▶ Processing DONE for ${sub_7T}_${sub_3T} !!!"
