function nii = read_nifti_image(path)
    nii = load_untouch_nii(path);
    nii.img(isinf(nii.img)) = 0;
    nii.img(isnan(nii.img)) = 0;
    nii.img(nii.img < 0) = 0;
    nii.img = double(nii.img);
end
