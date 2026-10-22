#!/bin/bash
#example: while read sub_3T ses_3T sub_7T ses_7T; do bash tutorial.sh "$sub_3T" "$ses_3T" "$sub_7T" "$ses_7T"; done < /host/verges/tank/data/youngeun/myproject/FBA/3T_7T/lists/sub_list.txt
source /host/verges/tank/data/youngeun/venv_new/bin/activate

sub_3T=$1
sub_7T=$3
ses_3T=$2
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
# Directory for storing average response data across subjects.
averg_dir="/host/verges/tank/data/youngeun/myproject/FBA/3T_7T/subjects_csd/average_response"
# Directory containing normalized CSD data for the current subject pair.
norm_dir="/host/verges/tank/data/youngeun/myproject/FBA/3T_7T/subjects_csd/${sub_7T}_${sub_3T}/Normalized_CSD"
# Directory for CSD analysis using a 50-degree threshold in sulcal regions.
sulcus_dir="/host/verges/tank/data/youngeun/myproject/FBA/3T_7T/subjects_csd/${sub_7T}_${sub_3T}/Sulcus_50"
# Directory for CSD analysis using a 40-degree threshold in gyral regions.
gyrus_dir="/host/verges/tank/data/youngeun/myproject/FBA/3T_7T/subjects_csd/${sub_7T}_${sub_3T}/Gyrus_40"

echo "▶ Processing START for ${sub_7T}_${sub_3T} !!!"

########################################################################
## Step-01. Computing Laplacian field 
########################################################################

echo "▶ Step-01-1: Convert aparc+aseg from .mgz to .nii.gz (subject: ${sub_7T}_${sub_3T})"
mri_convert ${FS_7T}/sub-${sub_7T}_ses-${ses_7T}/mri/aparc+aseg.mgz ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-fsnative_aparc+aseg.nii.gz

echo "▶ Step-01-2: Transform label map to nativepro T1w space (subject: ${sub_7T}_${sub_3T})"
antsApplyTransforms \
  -i ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-fsnative_aparc+aseg.nii.gz \
  -r ${micapipe_7T}/sub-${sub_7T}/ses-${ses_7T}/anat/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_T1w.nii.gz \
  -o ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_aparc+aseg.nii.gz \
  -n MultiLabel \
  -t ${micapipe_7T}/sub-${sub_7T}/ses-${ses_7T}/xfm/sub-${sub_7T}_ses-${ses_7T}_from-fsnative_to_nativepro_T1w_0GenericAffine.mat
 
echo "▶ Step-01-3: Solve Laplace equation (subject: ${sub_7T}_${sub_3T})"
python ${corticalDWI}/sWM/laplace_solver.py ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_aparc+aseg.nii.gz ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_laplace-wm

echo "▶ Step-01-4: Combine gradient components into vector field (subject: ${sub_7T}_${sub_3T})"
mrcat -axis 3 ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_laplace-wm_dx.nii.gz ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_laplace-wm_dy.nii.gz ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_laplace-wm_dz.nii.gz ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_laplace-wm_vec.nii.gz

########################################################################
## Step-02. Compute streamlines
#######################################################################

for hemi in L R; do
echo "▶ Step-02: Compute streamlines - Processing hemisphere: $hemi (subject: ${sub_7T}_${sub_3T})"
# Generate Laplacian streamlines
# For intra-cortical study
#python ${corticalDWI}/cortical_streamlines_ye.py ${micapipe_7T}/sub-${sub_7T}/ses-${ses_7T}/surf/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-nativepro_surf-fsLR-32k_label-white.surf.gii ${micapipe_7T}/sub-${sub_7T}/ses-${ses_7T}/surf/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-nativepro_surf-fsLR-32k_label-pial.surf.gii ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_laplace-wm_vec.nii.gz 200 0.1 ${sub_dir}/${hemi}_fsLR32k-laplace-wm_tmp.tck

# For SWM study
python ${corticalDWI}/cortical_streamlines_ye.py ${micapipe_7T}/sub-${sub_7T}/ses-${ses_7T}/surf/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-nativepro_surf-fsLR-32k_label-white.surf.gii no ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_laplace-wm_vec.nii.gz 200 0.1 ${sub_dir}/${hemi}_fsLR32k-laplace-wm_tmp.tck

# Add header
tckedit ${sub_dir}/${hemi}_fsLR32k-laplace-wm_tmp.tck ${sub_dir}/${hemi}_fsLR32k-laplace-wm_tmp_withheader.tck

# Resample and truncate
${inb_mrtrix}/scripts/tckresample_and_truncate ${sub_dir}/${hemi}_fsLR32k-laplace-wm_tmp_withheader.tck ${sub_dir}/${hemi}_fsLR32k-laplace-wm-streamlines.tck --step_size 0.5

# Get endpoints
tckresample -endpoints ${sub_dir}/${hemi}_fsLR32k-laplace-wm-streamlines.tck ${sub_dir}/${hemi}_fsLR32k-laplace-wm-streamlines_endsOnly.tck

#mrview ${sub_dir}/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_aparc+aseg.nii.gz -tractography.load ${hemi}_fsLR32k-laplace-wm-streamlines.tck -tractography.geometry lines -tractography.load R_fsLR32k-laplace-wm-streamlines_endsOnly.tck -tractography.geometry points

rm ${sub_dir}/${hemi}_fsLR32k-laplace-wm_tmp.tck ${sub_dir}/${hemi}_fsLR32k-laplace-wm_tmp_withheader.tck
echo "✔ Done for hemisphere: $hemi"
done

########################################################################
## Step-03. Warp streamlines to DWI space
########################################################################

echo "▶ Step-03-1: SynthSeg segmentation (subject: ${sub_7T}_${sub_3T})"
# Segment 3T DWI b0 image using SynthSeg (fixed image for registration)
mri_synthseg --threads 30 --i ${micapipe_3T}/sub-${sub_3T}/ses-${ses_3T}/dwi/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-b0.nii.gz --o ${sub_dir}/t1native_to_b0_fixed_seg.nii.gz --resample ${sub_dir}/t1native_to_b0_fixed_resampled.nii.gz

# Segment 7T T1w image using SynthSeg (moving image for registration)
mri_synthseg --threads 30 --i ${micapipe_7T}/sub-${sub_7T}/ses-${ses_7T}/anat/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_T1w.nii.gz --o ${sub_dir}/t1native_to_b0_moving_seg.nii.gz --resample ${sub_dir}/t1native_to_b0_moving_resampled.nii.gz

echo "▶ Step-03-2: Extract cortical label (subject: ${sub_7T}_${sub_3T})"
# Create binary mask for cortical ribbon from rixed segmentation
mrcalc ${sub_dir}/t1native_to_b0_fixed_seg.nii.gz 42 -999 -replace 3 -999 -replace -999 -eq ${sub_dir}/t1native_to_b0_fixed_seg_cortex.nii.gz

# Same for moving segmentation
mrcalc ${sub_dir}/t1native_to_b0_moving_seg.nii.gz 42 -999 -replace 3 -999 -replace -999 -eq ${sub_dir}/t1native_to_b0_moving_seg_cortex.nii.gz

echo "▶ Step-03-3: Register 7T T1 to 3T b0 (subject: ${sub_7T}_${sub_3T})"
# Nonlinear registration using only cortex regions
antsRegistrationSyN.sh -d 3 -f ${sub_dir}/t1native_to_b0_fixed_seg_cortex.nii.gz -m ${sub_dir}/t1native_to_b0_moving_seg_cortex.nii.gz -o ${sub_dir}/t1native_to_b0_ -t s -n 30 -p d -i ["${micapipe_3T}/sub-${sub_3T}/ses-${ses_3T}/dwi/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-b0.nii.gz","${micapipe_7T}/sub-${sub_7T}/ses-${ses_7T}/anat/sub-${sub_7T}_ses-${ses_7T}_space-nativepro_T1w.nii.gz",0]

# Rename registered moving image (segmentation warped to fixed space)
mv ${sub_dir}/t1native_to_b0_Warped.nii.gz ${sub_dir}/t1native_to_b0_seg_Warped.nii.gz

echo "▶ Step-03-4: Prepare identity warp (subject: ${sub_7T}_${sub_3T})"
# Create identity warp fields to later apply inverse warping
mkdir ${sub_dir}/tmpDir_dwi
warpinit ${micapipe_3T}/sub-${sub_3T}/ses-${ses_3T}/dwi/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-b0.nii.gz ${sub_dir}/tmpDir_dwi/inv_identity_warp[].nii

echo "▶ Step-03-5: Invert deformation field (subject: ${sub_7T}_${sub_3T})"
# Apply inverse ANTs warp to each component of identity warp (x,y,z)
# Warp{0,1,2} repeat
for i in 0 1 2; do
  antsApplyTransforms \
    -d 3 \
    -e 0 \
    -i ${sub_dir}/tmpDir_dwi/inv_identity_warp${i}.nii \
    -o ${sub_dir}/tmpDir_dwi/inv_mrtrix_warp${i}.nii \
    -r ${micapipe_3T}/sub-${sub_3T}/ses-${ses_3T}/dwi/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-b0.nii.gz \
    -t [${sub_dir}/t1native_to_b0_0GenericAffine.mat, 1] \
    -t ${sub_dir}/t1native_to_b0_1InverseWarp.nii.gz \
    --default-value 2147483647
done

echo "▶ Step-03-6: Combine warp into .mif (subject: ${sub_7T}_${sub_3T})"
# Combine the inverse warp components into a single MRtrix .mif warp field
warpcorrect ${sub_dir}/tmpDir_dwi/inv_mrtrix_warp[].nii ${sub_dir}/tmpDir_dwi/inv_mrtrix_warp_corrected.mif -marker 2147483647

for hemi in L R; do
echo "▶ Step-03-7: Transform streamlines to DWI space - Processing hemisphere: $hemi (subject: ${sub_7T}_${sub_3T})"
# Warp the Laplacian streamlines to DWI space
tcktransform ${sub_dir}/${hemi}_fsLR32k-laplace-wm-streamlines.tck ${sub_dir}/tmpDir_dwi/inv_mrtrix_warp_corrected.mif ${sub_dir}/tmpDir_dwi/warped.tck -force

echo "▶ Step-03-8: Resample and truncate warped streamlines - Processing hemisphere: $hemi (subject: ${sub_7T}_${sub_3T})"
# Resample and truncate warped streamlines for consistent step size and max length
${inb_mrtrix}/scripts/tckresample_and_truncate ${sub_dir}/tmpDir_dwi/warped.tck ${sub_dir}/${hemi}_fsLR32k-laplace-wm-streamlines_dwispace.tck --step_size 0.5 --max_length 5

#mrview ${sub_dir}/t1native_to_b0_fixed_seg.nii.gz -tractography.load ${sub_dir}/R_fsLR32k-laplace-wm-streamlines_dwispace.tck
done

rm -r ${sub_dir}/tmpDir_dwi

########################################################################
## Step-04. Preprocess DWI
########################################################################

echo "▶ Step-04-1: Convert preprocessed DWI to NIfTI (subject: ${sub_7T}_${sub_3T})"
mrconvert -strides 1,2,3,4 -export_grad_fsl ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-nativepro_dwi.bvec ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-nativepro_dwi.bval -export_grad_mrtrix ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-nativepro_dwi.scheme ${micapipe_3T}/sub-${sub_3T}/ses-${ses_3T}/dwi/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-preproc_dwi.mif ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-preproc_dwi.nii.gz

echo "▶ Step-04-2: Estimate tissue response functions (subject: ${sub_7T}_${sub_3T})"
dwi2response dhollander -mask ${micapipe_3T}/sub-${sub_3T}/ses-${ses_3T}/dwi/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-brain_mask.nii.gz -grad ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-nativepro_dwi.scheme ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-preproc_dwi.nii.gz ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_response_wm.txt ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_response_gm.txt ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_response_csf.txt

echo "▶ Step-04-3: Compute group-average response functions."
responsemean ${sub_dir}/sub-*/sub-${sub_3T}_ses-${ses_3T}_space-dwi_response_wm.txt ${averg_dir}/11subs_average_response_wm.txt
responsemean ${sub_dir}/sub-*/sub-${sub_3T}_ses-${ses_3T}_space-dwi_response_gm.txt ${averg_dir}/11subs_average_response_gm.txt
responsemean ${sub_dir}/sub-*/sub-${sub_3T}_ses-${ses_3T}_space-dwi_response_csf.txt ${averg_dir}/11subs_average_response_csf.txt

########################################################################
## Step-05. CSD: Sample AFD along Laplacian streamlines
## Run this step only after processing all subjects in the previous step.
########################################################################

echo "▶ Step-05-1: Perform MSMT-CSD (subject: ${sub_7T}_${sub_3T})"
dwi2fod msmt_csd -mask ${micapipe_3T}/sub-${sub_3T}/ses-${ses_3T}/dwi/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-brain_mask.nii.gz -grad ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-nativepro_dwi.scheme ${sub_dir}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-preproc_dwi.nii.gz ${averg_dir}/11subs_average_response_wm.txt ${norm_dir}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_fod_wm_norm.mif ${averg_dir}/11subs_average_response_gm.txt ${norm_dir}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_fod_gm_norm.mif ${averg_dir}/11subs_average_response_csf.txt ${norm_dir}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_fod_csf_norm.mif -nthreads ${nthreads} -force

echo "▶ Step-05-2: Convert FOD to fixels (subject: ${sub_7T}_${sub_3T})"
fod2fixel -afd afd_fixels.mif -peak peak_fixels.mif -disp disp_fixels.mif ${norm_dir}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_fod_wm_norm.mif ${norm_dir}/csd_msmt -nthreads ${nthreads} -force

# Process gyral and sulcal regions using different angular thresholds.
# Gyrus: 40 degrees
# Sulcus: 50 degrees

for region in "Gyrus_40:40" "Sulcus_50:50"; do

    # Parse the region name and angular threshold.
    region_name="${region%%:*}"
    angle="${region##*:}"

    # Set the output directory for the current region.
    output_dir="${sub_dir}/${region_name}"

    # Create the output directory if it does not exist.
    mkdir -p "$output_dir"

    ####################################################################
    ## Step-05-3. Sample AFD along Laplacian streamlines
    ####################################################################

    for hemi in L R; do
        echo "▶ Step-04-5: Sampling AFD | Region: ${region_name} | Angle: ${angle}° | Hemisphere: ${hemi} | Subject: ${sub_7T}_${sub_3T}"

        "${lconcha_mrtrix}/bin/tcksamplefixels" \
            -angle "$angle" \
            "${norm_dir}/csd_msmt/afd_fixels.mif" \
            "${sub_dir}/${hemi}_fsLR32k-laplace-wm-streamlines_dwispace.tck" \
            "${output_dir}/${hemi}_fsLR32k_afd-par-perp-indices.tsf" \
            "${output_dir}/${hemi}_fsLR32k_afd-par.tsf" \
            "${output_dir}/${hemi}_fsLR32k_afd-perp.tsf" \
            "${output_dir}/${hemi}_fsLR32k_afd-perp-av.tsf" \
            -nthreads "${nthreads}" -force
    done

    ####################################################################
    ## Step-05-4. Convert TSF files to TXT files
    ####################################################################

    nCols=10

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
        awk -v C="$nCols" \
            '{ for (N=1; N<=C; N++) if ($N=="") $N="-1"; print }' \
            "${tmpDir}/cropped.txt" > "$txt_path"

        # Remove temporary files after successful conversion.
        rm -rf "$tmpDir"

        echo "[✔] Converted ${tsf} → ${txt_path}"
    done

    echo "▶ Finished processing ${region_name} for ${sub_7T}_${sub_3T}"

done

echo "▶ Processing DONE for ${sub_7T}_${sub_3T} !!!"
