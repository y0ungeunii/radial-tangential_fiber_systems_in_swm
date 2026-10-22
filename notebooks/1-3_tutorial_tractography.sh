#!/bin/bash
#example: while read sub_3T ses_3T sub_7T ses_7T; do bash /host/verges/tank/data/youngeun/myproject/FBA/3T_7T/scripts/tutorial_tckgen_prob.sh "$sub_3T" "$ses_3T" "$sub_7T" "$ses_7T"; done < /host/verges/tank/data/youngeun/myproject/FBA/3T_7T/lists/sub_list.txt
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
# Path to the custom MRtrix3 repository maintained by Luis Concha.
# Repository: https://github.com/lconcha/mrtrix3
lconcha_mrtrix="/host/verges/tank/data/youngeun/git/mrtrix3_lconcha"
# Path to the superficial white matter (SWM) repository maintained by Jordan DeKraker.
# Repository: https://github.com/jordandekraker/superficial-white-matter
sWM="/host/verges/tank/data/youngeun/git/superficial-white-matter/sWM"

# ---------------------------------------------------------------------
# Subject-specific output directories
# ---------------------------------------------------------------------
# Output directory for CSD analysis of the paired 7T and 3T subjects.
# The directory name combines the 7T and 3T subject identifiers.
sub_dir="/host/verges/tank/data/youngeun/myproject/FBA/3T_7T/subjects_csd/${sub_7T}_${sub_3T}"
# Output directory for probabilistic tractography validation
# of the paired 7T and 3T subjects.
tckdir="/host/verges/tank/data/youngeun/myproject/FBA/3T_7T/validation_prob/${sub_7T}_${sub_3T}"

echo "▶ Processing START for ${sub_7T}_${sub_3T} !!!"

########################################################################
## Step-01: Let's get ready for processing!!
## Prepare ROI masks for probabilistic tractography validation
########################################################################

# ---------------------------------------------------------------------
# Common file paths
# ---------------------------------------------------------------------

# Subject identifier used in output filenames.
prefix="sub-${sub_7T}_ses-${ses_7T}"

# Input parcellation images in DWI space.
aparc="${tckdir}/${prefix}_space-dwi_aparc+aseg.nii.gz"
wmparc="${tckdir}/${prefix}_space-dwi_wmparc.nii.gz"

# Reference image and spatial transformation files.
b0_ref="${micapipe_3T}/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-b0.nii.gz"
fsnative_to_nativepro="${micapipe_7T}/xfm/${prefix}_from-fsnative_to_nativepro_T1w_0GenericAffine.mat"
warp="${sub_dir}/t1native_to_b0_1Warp.nii.gz"
affine="${sub_dir}/t1native_to_b0_0GenericAffine.mat"

# Create the output directory.
mkdir -p "$tckdir"

# ---------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------

# Create a binary mask for a single parcellation label.
make_label_mask() {
    local image="$1"
    local label="$2"
    local output="$3"

    mrcalc "$image" "$label" -eq "$output" -force
}

# Create a binary mask by combining multiple parcellation labels.
make_combined_mask() {
    local image="$1"
    local output="$2"
    shift 2

    local label
    local args=("$image" "$1" -eq)
    shift

    for label in "$@"; do
        args+=("$image" "$label" -eq -add)
    done

    mrcalc "${args[@]}" "$output" -force
}

echo "▶ Step-01-1: Register cortical parcellation to DWI space (${sub_7T}_${sub_3T})"

antsApplyTransforms \
    -i "${FS_7T}/${prefix}/mri/wmparc.DKTatlas.mapped.mgz" \
    -r "$b0_ref" \
    -o "$aparc" \
    -t "$warp" \
    -t "$affine" \
    -t "$fsnative_to_nativepro" \
    -n MultiLabel

## Convert parcellation image if necessary
# If integer-valued label conversion is required, uncomment and verify:
#
# mrcalc "$aparc" -round -datatype uint64 "$aparc" -force

# Step-01-3 to Step-01-6. Create cortical ROI masks
for hemi in L R; do

    # Set hemisphere-specific FreeSurfer label IDs.
    if [[ "$hemi" == "L" ]]; then
        PrCG_label=1024
        PoCG_label=1022
        IPL_labels=(1031 1008)
        FL_labels=(1003 1012 1014 1027 1028 1032)
        hemi_low=1000
        hemi_high=2000
    else
        PrCG_label=2024
        PoCG_label=2022
        IPL_labels=(2031 2008)
        FL_labels=(2003 2012 2014 2027 2028 2032)
        hemi_low=2000
        hemi_high=3000
    fi

    # Define output paths for the current hemisphere.
    PrCG_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_PrCG.nii.gz"
    PoCG_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_PoCG.nii.gz"
    IPL_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_IPL.nii.gz"
    FL_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_FL.nii.gz"

    # Step-01-3. Extract the precentral gyrus (PrCG).
    echo "▶ Step-01-3: Extract PrCG (${hemi})"
    make_label_mask "$aparc" "$PrCG_label" "$PrCG_out"

    # Step-01-4. Extract the postcentral gyrus (PoCG).
    echo "▶ Step-01-4: Extract PoCG (${hemi})"
    make_label_mask "$aparc" "$PoCG_label" "$PoCG_out"

    # Step-01-5. Combine the supramarginal and angular gyri to define IPL.
    echo "▶ Step-01-5: Extract the inferior parietal lobe (IPL; ${hemi})"
    make_combined_mask "$aparc" "$IPL_out" "${IPL_labels[@]}"

    # Step-01-6. Combine selected cortical labels to define the frontal lobe.
    echo "▶ Step-01-6: Extract the frontal lobe (FL; ${hemi})"
    make_combined_mask "$aparc" "$FL_out" "${FL_labels[@]}"

done

# Register white matter parcellation to DWI space
# Uncomment this block if the WM parcellation has not already been generated.
 echo "▶ Step-01-7: Register WM parcellation to DWI space (${sub_7T}_${sub_3T})"

 antsApplyTransforms \
     -i "${FS_7T}/${prefix}/mri/wmparc.DKTatlas.mapped.mgz" \
     -r "$b0_ref" \
     -o "$wmparc" \
     -t "$warp" \
     -t "$affine" \
     -t "$fsnative_to_nativepro" \
     -n MultiLabel

# Step-01-8 to Step-01-10. Create white matter seeding ROI masks
for hemi in L R; do

    # Set hemisphere-specific white matter label IDs.
    if [[ "$hemi" == "L" ]]; then
        PrCwm_label=3024
        PoCwm_label=3022
        IPLwm_labels=(3031 3008)
    else
        PrCwm_label=4024
        PoCwm_label=4022
        IPLwm_labels=(4031 4008)
    fi

    # Define output paths for the current hemisphere.
    PrCwm_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_PrCwm.nii.gz"
    PoCwm_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_PoCwm.nii.gz"
    IPLwm_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_IPwm.nii.gz"

    # Step-01-8. Extract precentral white matter.
    echo "▶ Step-01-8: Extract precentral white matter (${hemi})"
    make_label_mask "$wmparc" "$PrCwm_label" "$PrCwm_out"

    # Step-01-9. Extract postcentral white matter.
    echo "▶ Step-01-9: Extract postcentral white matter (${hemi})"
    make_label_mask "$wmparc" "$PoCwm_label" "$PoCwm_out"

    # Step-01-10. Combine supramarginal and angular gyrus white matter.
    echo "▶ Step-01-10: Extract inferior parietal white matter (${hemi})"
    make_combined_mask "$wmparc" "$IPLwm_out" "${IPLwm_labels[@]}"

done

echo "▶ Step-01-11: Create exclusion masks for PrCG and PoCG"

for hemi in L R; do

    # Select the label range and central gyri labels for each hemisphere.
    if [[ "$hemi" == "L" ]]; then
        hemi_low=1000
        hemi_high=2000
        PrCG_label=1024
        PoCG_label=1022
    else
        hemi_low=2000
        hemi_high=3000
        PrCG_label=2024
        PoCG_label=2022
    fi

    exclude_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_exclude-PrCG-PoCG.nii.gz"

    # Retain labels within the hemisphere's cortical range,
    # excluding the precentral and postcentral gyri.
    mrcalc "$aparc" "$hemi_low" -gt "$aparc" "$hemi_high" -lt -mult "$aparc" "$PrCG_label" -eq -sub "$aparc" "$PoCG_label" -eq -sub 0 -gt "$exclude_out" -force

done

# Create exclusion masks for the frontal and inferior
# parietal lobes
echo "▶ Step-01-12: Create exclusion masks for FL and IPL"

for hemi in L R; do

    FL_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_FL.nii.gz"
    IPL_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_IPL.nii.gz"
    exclude_out="${tckdir}/${prefix}_hemi-${hemi}_space-dwi_exclude-FL-IPL.nii.gz"

    # Restrict the mask to the current hemisphere's cortical labels,
    # then exclude the frontal and inferior parietal lobe masks.
    if [[ "$hemi" == "L" ]]; then
        hemi_low=1000
        hemi_high=2000
    else
        hemi_low=2000
        hemi_high=3000
    fi

    mrcalc "$aparc" "$hemi_low" -gt "$aparc" "$hemi_high" -lt -mult "$FL_out" -sub "$IPL_out" -sub 0 -gt "$exclude_out" -force

done

echo "▶ Step-01 processing completed for ${sub_7T}_${sub_3T}."

########################################################################
## Step-02: Generate 3 mm SWM masks
########################################################################

# Output directory and common file paths
swm_dir="${tckdir}/swm_masks"
native_prefix="sub-${sub_7T}_ses-${ses_7T}"
dwi_ref="${micapipe_3T}/sub-${sub_3T}_ses-01_space-dwi_desc-b0.nii.gz"

mkdir -p "$swm_dir"

## Step-02-1. Generate SWM surfaces
echo "▶ Step-02-1: Generate SWM surfaces (${sub_7T}_${sub_3T})"

for hemi in L R; do
    python "${sWM}/surface_generator_YH.py" \
        "${micapipe_7T}/surf/${native_prefix}_hemi-${hemi}_space-nativepro_surf-fsLR-32k_label-white.surf.gii" \
        "${sub_dir}/${native_prefix}_space-nativepro_laplace-wm.nii.gz" \
        "${swm_dir}/${native_prefix}_hemi-${hemi}_space-nativepro_swm_" \
        0,1,2,3
done

## Step-02-2. Convert SWM surfaces to volume masks
echo "▶ Step-02-2: Convert SWM surfaces to volume masks (${sub_7T}_${sub_3T})"

depth="3.00"

for hemi in L R; do
    surface="${swm_dir}/${native_prefix}_hemi-${hemi}_space-nativepro_swm_${depth}mm"

    # Convert GIFTI surface to VTK format.
    mris_convert "${surface}.surf.gii" "${surface}.vtk"

    # Rasterize the surface in nativepro space.
    mesh2voxel "${surface}.vtk" "${sub_dir}/${native_prefix}_space-nativepro_aparc+aseg.nii.gz" "${surface}.nii.gz" -force
done

## Step-02-3. Merge left and right hemisphere masks
echo "▶ Step-02-3: Merge hemisphere masks (${sub_7T}_${sub_3T})"

left_mask="${swm_dir}/${native_prefix}_hemi-L_space-nativepro_swm_${depth}mm.nii.gz"
right_mask="${swm_dir}/${native_prefix}_hemi-R_space-nativepro_swm_${depth}mm.nii.gz"
native_mask="${swm_dir}/${native_prefix}_space-nativepro_swm-${depth}mm_mask.nii.gz"

mrcalc "$left_mask" "$right_mask" -add 0 -gt "$native_mask" -force

## Step-02-4. Erode the merged SWM mask
echo "▶ Step-02-4: Erode SWM mask (${sub_7T}_${sub_3T})"

eroded_mask="${swm_dir}/${native_prefix}_space-nativepro_swm-${depth}mm_mask_erodded.nii.gz"
fslmaths "$native_mask" -ero "$eroded_mask"

## Step-02-5. Transform SWM mask to DWI space
echo "▶ Step-02-5: Transform SWM mask to DWI space (${sub_7T}_${sub_3T})"

dwi_mask="${swm_dir}/${native_prefix}_space-dwi_swm-${depth}mm_mask.nii.gz"

antsApplyTransforms \
    -d 3 \
    -e 0 \
    -i "$eroded_mask" \
    -o "$dwi_mask" \
    -r "$dwi_ref" \
    -t "${sub_dir}/t1native_to_b0_1Warp.nii.gz" \
    -t "${sub_dir}/t1native_to_b0_0GenericAffine.mat" \
    -n MultiLabel
    
########################################################################
## Step-03: Perform U-fiber tractography
########################################################################

for hemi in L R; do
    echo "▶ Step-03-1: Run U-fiber tractography (${hemi} hemisphere; subject: ${sub_7T}_${sub_3T})"

    # Generate U-fiber streamlines between the precentral and postcentral gyri
    tckgen -nthreads ${nthreads} \
        ${sub_dir}/sub-${sub_3T}_ses-01_space-dwi_fod_wm.mif \
        ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_PrCG-PoCG_seed-random.tck \
        -algorithm iFOD2 \
        -backtrack \
        -crop_at_gmwmi \
        -seed_random_per_voxel ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_PrCwm.nii.gz 500 \
        -seed_random_per_voxel ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_PoCwm.nii.gz 500 \
        -select 10000 \
        -step 0.5 \
        -cutoff 0.1 \
        -minlength 30 \
        -maxlength 60 \
        -angle 60 \
        -act ${micapipe_3T}/sub-${sub_3T}_ses-01_space-dwi_desc-5tt.nii.gz \
        -include ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_PrCG.nii.gz \
        -include ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_PoCG.nii.gz \
        -exclude ${tckdir}/swm_masks/sub-${sub_7T}_ses-${ses_7T}_space-dwi_swm-3.00mm_mask.nii.gz \
        -exclude ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_exclude-PrCG-PoCG.nii.gz \
        -force
done

########################################################################
## Step-04: Perform long-range fiber tractography
########################################################################

for hemi in L R; do
    echo "▶ Step-04-1: Run long-range fiber tractography (${hemi} hemisphere; subject: ${sub_7T}_${sub_3T})"

    # Generate long-range streamlines between the frontal lobe and inferior parietal lobule
    tckgen -nthreads ${nthreads} \
        ${sub_dir}/sub-${sub_3T}_ses-01_space-dwi_fod_wm.mif \
        ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_FL-IPL_seed-random.tck \
        -algorithm iFOD2 \
        -backtrack \
        -crop_at_gmwmi \
        -seed_random_per_voxel ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_IPwm.nii.gz 500 \
        -select 10000 \
        -step 0.5 \
        -cutoff 0.1 \
        -minlength 60 \
        -maxlength 180 \
        -angle 45 \
        -act ${micapipe_3T}/sub-${sub_3T}_ses-01_space-dwi_desc-5tt.nii.gz \
        -include ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_FL.nii.gz \
        -include ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_IPL.nii.gz \
        -exclude ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_exclude-FL-IPL.nii.gz \
        -exclude ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_temporal-cingulate-insula-wm.nii.gz \
        -exclude ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_for-hemi-${hemi}_space-dwi_mask.nii.gz \
        -exclude ${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_subcortex.nii.gz \
        -force
done

########################################################################
## Exclude insular and opposite-hemisphere streamlines
########################################################################

echo "▶ Create insular white matter masks"

wmparc_dwi="${tckdir}/${prefix}_space-dwi_wmparc.nii.gz"

for hemi in L R; do
    if [[ "$hemi" == "L" ]]; then
        label=3035
    else
        label=4035
    fi

    mrcalc "$wmparc_dwi" "$label" -eq \
        "${tckdir}/${prefix}_hemi-${hemi}_space-dwi_insula-wm.nii.gz" \
        -force
done


# Create temporary masks for subcortical structures, cortex, and white matter.
mask_tmp="${tckdir}/mask_tmp"
mkdir -p "$mask_tmp"

for hemi in L R; do

    if [[ "$hemi" == "L" ]]; then
        sub_min=1
        sub_max=39
        cortex_min=1000
        cortex_max=2000
        wm_min=3000
        wm_max=4000
    else
        sub_min=40
        sub_max=71
        cortex_min=2000
        cortex_max=3000
        wm_min=4000
        wm_max=5000
    fi

    # Extract subcortical structures.
    mrcalc "$aparc_dwi" "$sub_min" -ge \
        $(mrcalc "$aparc_dwi" "$sub_max" -le -) \
        -mult "${mask_tmp}/${prefix}_hemi-${hemi}_space-dwi_subcortex.nii.gz" \
        -force

    # Extract cortical regions.
    mrcalc "$aparc_dwi" "$cortex_min" -gt \
        $(mrcalc "$aparc_dwi" "$cortex_max" -lt -) \
        -mult "${mask_tmp}/${prefix}_hemi-${hemi}_space-dwi_cortex.nii.gz" \
        -force

    # Extract white matter regions.
    mrcalc "$aparc_dwi" "$wm_min" -gt \
        $(mrcalc "$aparc_dwi" "$wm_max" -lt -) \
        -mult "${mask_tmp}/${prefix}_hemi-${hemi}_space-dwi_wm.nii.gz" \
        -force
done


# Create whole-hemisphere exclusion masks.
mrcalc \
    "${mask_tmp}/${prefix}_hemi-L_space-dwi_subcortex.nii.gz" \
    "${mask_tmp}/${prefix}_hemi-L_space-dwi_cortex.nii.gz" \
    -add \
    "${mask_tmp}/${prefix}_hemi-L_space-dwi_wm.nii.gz" \
    -add \
    $(mrcalc "$aparc_dwi" 5001 -eq -) \
    -add \
    "${tckdir}/${prefix}_hemi-L_space-dwi_mask.nii.gz" \
    -force

mrcalc \
    "${mask_tmp}/${prefix}_hemi-R_space-dwi_subcortex.nii.gz" \
    "${mask_tmp}/${prefix}_hemi-R_space-dwi_cortex.nii.gz" \
    -add \
    "${mask_tmp}/${prefix}_hemi-R_space-dwi_wm.nii.gz" \
    -add \
    $(mrcalc "$aparc_dwi" 5002 -eq -) \
    -add \
    $(mrcalc "$aparc_dwi" 16 -eq -) \
    -add \
    $(mrcalc "$aparc_dwi" 24 -eq -) \
    -add \
    "${tckdir}/${prefix}_hemi-R_space-dwi_mask.nii.gz" \
    -force


# Exclude the opposite hemisphere and ipsilateral insular white matter.
echo "▶ Step-04-6: Exclude opposite-hemisphere and insular streamlines"

tckedit \
    "${tckdir}/${prefix}_hemi-L_space-dwi_FL-IPL.tck" \
    -exclude "${tckdir}/${prefix}_hemi-R_space-dwi_mask.nii.gz" \
    -exclude "${tckdir}/${prefix}_hemi-L_space-dwi_insula-wm.nii.gz" \
    "${tckdir}/${prefix}_hemi-L_space-dwi_FL-IPL_exclude-insula-rightHEMI.tck" \
    -force

tckedit \
    "${tckdir}/${prefix}_hemi-R_space-dwi_FL-IPL.tck" \
    -exclude "${tckdir}/${prefix}_hemi-L_space-dwi_mask.nii.gz" \
    -exclude "${tckdir}/${prefix}_hemi-R_space-dwi_insula-wm.nii.gz" \
    "${tckdir}/${prefix}_hemi-R_space-dwi_FL-IPL_exclude-insula-leftHEMI.tck" \
    -force


# Apply SIFT to the filtered tractograms.
echo "▶ Step-04-7: Apply SIFT to filtered long-range tractograms"

tcksift \
    "${tckdir}/${prefix}_hemi-L_space-dwi_FL-IPL_exclude-insula-rightHEMI.tck" \
    "$fod_wm" \
    "${tckdir}/${prefix}_hemi-L_space-dwi_FL-IPL_exclude-insula-rightHEMI_sift.tck"

tcksift \
    "${tckdir}/${prefix}_hemi-R_space-dwi_FL-IPL_exclude-insula-leftHEMI.tck" \
    "$fod_wm" \
    "${tckdir}/${prefix}_hemi-R_space-dwi_FL-IPL_exclude-insula-leftHEMI_sift.tck"
    

########################################################################
## Step-05: Transform streamlines from DWI space to MNI space
########################################################################

# MNI template and subject registration variables
work_dir="/host/verges/tank/data/youngeun/myproject/FBA/3T_7T/template/subjects/${sub_3T}"

# MNI template images
mni_synth_affine="${work_dir}/mni_icbm152_space-T1w_affine.nii.gz"
mni_synth_sub="${work_dir}/mni_icbm152_space-T1w_synthseg.nii.gz"
mni_in_t1w="${work_dir}/mni_icbm152_space-T1w.nii.gz"

# Subject nativepro T1w reference and SynthSeg outputs
ref="/data_/mica3/BIDS_MICs/derivatives/micapipe_v0.2.0/sub-${sub_3T}/ses-01/anat/sub-${sub_3T}_ses-01_space-nativepro_T1w.nii.gz"

ref_synth="${work_dir}/sub-${sub_3T}_ses-01_space-nativepro_T1w_synthseg.nii.gz"
ref_resample="${work_dir}/sub-${sub_3T}_ses-01_space-nativepro_T1w_synthseg_resampled.nii.gz"
ref_resample2orig="${work_dir}/sub-${sub_3T}_ses-01_synthresample_to_orig_"
ref_synthseg_orig="${work_dir}/sub-${sub_3T}_ses-01_space-nativepro_T1w_synthseg_orig.nii.gz"

# Registration output prefixes
reg_str1="${work_dir}/from-mni_to-sub_"
reg_str2="${work_dir}/from-mnisub_to-sub_"

# Edge-based registration
ref_edge="${work_dir}/sub-${sub_3T}_ses-01_space-nativepro_T1w_edge.nii.gz"
mni_edge="${work_dir}/mni_icbm152_space-T1w_edge.nii.gz"
reg_str_edge="${work_dir}/from-subedge_to-mniedge_"

# Input images
dwi_ref="${micapipe_3T}/sub-${sub_3T}/ses-${ses_3T}/dwi/sub-${sub_3T}_ses-${ses_3T}_space-dwi_desc-b0.nii.gz"
aparc_dwi="${tckdir}/sub-${sub_7T}_ses-${ses_7T}_space-dwi_aparc+aseg.nii.gz"

# Output directory and warp files
mnidir="${tckdir}/reg-to-mni"
mkdir -p "${mnidir}"

warp_prefix="${mnidir}/inv_mrtrix_warp"
warp_corrected="${mnidir}/inv_mrtrix_warp_corrected.mif"

echo "▶ Step-05-1: Initialize the MNI-to-DWI warp fields (subject: ${sub_7T}_${sub_3T})"

# Generate identity warp fields in MNI space
warpinit "${mni_in_t1w}" "${mnidir}/identify_mni_warp[].nii" -force


echo "▶ Step-05-2: Transform the warp fields to DWI space (subject: ${sub_7T}_${sub_3T})"

# Apply the existing registration transforms to each warp component
for i in 0 1 2; do
    antsApplyTransforms \
        -d 3 \
        -i "${mnidir}/identify_mni_warp${i}.nii" \
        -r "${dwi_ref}" \
        -o "${warp_prefix}${i}.nii" \
        -t "${micapipe_3T}/xfm/sub-${sub_3T}_ses-${ses_3T}_space-dwi_from-dwi_to-dwi_mode-image_desc-SyN_1Warp.nii.gz" \
        -t "${micapipe_3T}/xfm/sub-${sub_3T}_ses-${ses_3T}_space-dwi_from-dwi_to-dwi_mode-image_desc-SyN_0GenericAffine.mat" \
        -t "[${micapipe_3T}/xfm/sub-${sub_3T}_ses-${ses_3T}_space-dwi_from-dwi_to-nativepro_mode-image_desc-affine_0GenericAffine.mat,1]" \
        -t "[${reg_str_edge}0GenericAffine.mat,1]" \
        -t "${reg_str_edge}1InverseWarp.nii.gz" \
        -t "${reg_str2}1Warp.nii.gz" \
        -t "${reg_str2}0GenericAffine.mat" \
        -t "${reg_str1}0GenericAffine.mat"
done


echo "▶ Step-05-3: Correct the warp fields for MRtrix (subject: ${sub_7T}_${sub_3T})"

# Convert the three warp components into an MRtrix-compatible warp field
warpcorrect "${warp_prefix}[].nii" "${warp_corrected}" -force


echo "▶ Step-05-4: Generate angular gyrus masks (subject: ${sub_7T}_${sub_3T})"

# Left angular gyrus (FreeSurfer label 1008)
mrcalc "${aparc_dwi}" 1008 -eq \
    "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-L_space-dwi_AG.nii.gz" \
    -force

# Right angular gyrus (FreeSurfer label 2008)
mrcalc "${aparc_dwi}" 2008 -eq \
    "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-R_space-dwi_AG.nii.gz" \
    -force


echo "▶ Step-05-5: Generate middle frontal gyrus masks (subject: ${sub_7T}_${sub_3T})"

# Left middle frontal gyrus: combine labels 1003 and 1027
mrcalc "${aparc_dwi}" 1003 -eq \
    "${aparc_dwi}" 1027 -eq \
    -add \
    "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-L_space-dwi_MFG.nii.gz" \
    -force

# Right middle frontal gyrus: combine labels 2003 and 2027
mrcalc "${aparc_dwi}" 2003 -eq \
    "${aparc_dwi}" 2027 -eq \
    -add \
    "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-R_space-dwi_MFG.nii.gz" \
    -force


echo "▶ Step-05-6: Select MFG–AG streamlines (subject: ${sub_7T}_${sub_3T})"

for hemi in L R; do

    # Select streamlines passing through both the MFG and angular gyrus
    tckedit \
        "${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_FL-IPL_new2.tck" \
        -include "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_AG.nii.gz" \
        -include "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_MFG.nii.gz" \
        "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_MFG-AG.tck" \
        -force


    echo "▶ Step-05-7: Transform MFG–AG streamlines to MNI space (${hemi} hemisphere; subject: ${sub_7T}_${sub_3T})"

    # Transform the selected streamlines using the corrected warp field
    tcktransform \
        "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_MFG-AG.tck" \
        "${warp_corrected}" \
        "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-mni_MFG-AG.tck" \
        -force

    # Optional: Transform additional streamline bundles
    # tcktransform \
    #     "${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_PrCG-PoCG_new.tck" \
    #     "${warp_corrected}" \
    #     "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-mni_PrCG-PoCG.tck" \
    #     -force

    # tcktransform \
    #     "${tckdir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-dwi_FL-IPL_new2.tck" \
    #     "${warp_corrected}" \
    #     "${mnidir}/sub-${sub_7T}_ses-${ses_7T}_hemi-${hemi}_space-mni_FL-IPL.tck" \
    #     -force

done

