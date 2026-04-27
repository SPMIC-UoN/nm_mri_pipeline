function thresh = compute_nm_background_threshold(img_nm, brainstem_mask)
    if ~isequal(size(img_nm), size(brainstem_mask))
        error('Map sizes do not match');
    end
    thresh = 0.8 * median(img_nm(brainstem_mask(:)));
end

