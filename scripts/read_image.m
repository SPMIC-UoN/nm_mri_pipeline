function img = read_image(path)
    nii_img = load_untouch_nii(path);
    img = double(nii_img.img);
    img(isinf(img)) = 0;
    img(isnan(img)) = 0;
    img(img < 0) = 0;
end