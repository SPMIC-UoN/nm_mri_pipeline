function struc_prior_maps = weight2prior(struc_weight_maps)
    norm_map = struc_weight_maps.background_weight + struc_weight_maps.brainstem_weight + struc_weight_maps.l_sn_weight + struc_weight_maps.r_sn_weight + eps;
              
    struc_prior_maps.background_prior = struc_weight_maps.background_weight ./ norm_map;
    struc_prior_maps.brainstem_prior = struc_weight_maps.brainstem_weight ./ norm_map;
    struc_prior_maps.l_sn_prior = struc_weight_maps.l_sn_weight ./ norm_map;
    struc_prior_maps.r_sn_prior = struc_weight_maps.r_sn_weight ./ norm_map;
end

