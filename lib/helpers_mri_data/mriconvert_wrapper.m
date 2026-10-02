% function mriconvert_wrapper(dicom_folder, nifti_folder, nifti_filename)
%
% nifti filename does not need extension .nii
%
% updated Aug 2025 per Ana's suggestions


function mriconvert_wrapper(dicom_folder, nifti_folder, nifti_filename)


nifti_folder
nifti_filename
dicom_folder


unix(['mri_convert -odt float "' dicom_folder '1.dcm" "' fullfile(nifti_folder, [nifti_filename '.nii']) '"']);
% unix(['mri_convert -odt float "' dicom_folder '" "' fullfile(nifti_folder, [nifti_filename '.nii']) '"']);


end