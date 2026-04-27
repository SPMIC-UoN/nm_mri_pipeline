function [img_synth, struc_posterior_maps] = compute_synth_data(img_nm, img_t1w, struc_prior_maps)
    if ~isequal(size(img_nm), size(img_t1w))
        error('Inputs must have the same size');
    end

    struc_posterior_maps = compute_posteriors(img_nm, struc_prior_maps);
    sn_posterior_map = struc_posterior_maps.l_sn_posterior + struc_posterior_maps.r_sn_posterior;
    img_synth = img_t1w .* (1 + (sn_posterior_map / 2));
end
