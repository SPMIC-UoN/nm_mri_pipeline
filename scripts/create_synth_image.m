function create_synth_image(base_dir, id, type)
    data_dir = fullfile(base_dir, 'Registered', 'MPRAGE_space');
    
    t1w_file = [id '_T1w.nii.gz'];
    nm_file = strrep(t1w_file, 'T1w', type);
    synth_nm_file = strrep(t1w_file, 'T1w', ['synth-' type]);
    
    synth_nm_background_weight_file = strrep(t1w_file, 'T1w', ['background_synth-' type '_weight_map']);
    synth_nm_brainstem_weight_file = strrep(t1w_file, 'T1w', ['brainstem_synth-' type '_weight_map']);
    synth_nm_l_sn_weight_file = strrep(t1w_file, 'T1w', ['l_sn_synth-' type '_weight_map']);
    synth_nm_r_sn_weight_file = strrep(t1w_file, 'T1w', ['r_sn_synth-' type '_weight_map']);
    
    if exist(fullfile(data_dir, nm_file), 'file')
        nii_t1w = load_untouch_nii(fullfile(data_dir, t1w_file));
        img_t1w = double(nii_t1w.img);

        nii_nm = load_untouch_nii(fullfile(data_dir, nm_file));
        img_nm = double(nii_nm.img);

        nii_synth_nm_background_weight = load_untouch_nii(fullfile(data_dir, synth_nm_background_weight_file));
        nii_synth_nm_brainstem_weight = load_untouch_nii(fullfile(data_dir, synth_nm_brainstem_weight_file));
        nii_synth_nm_l_sn_weight = load_untouch_nii(fullfile(data_dir, synth_nm_l_sn_weight_file));
        nii_synth_nm_r_sn_weight = load_untouch_nii(fullfile(data_dir, synth_nm_r_sn_weight_file));

        struc_weight_maps.background_weight = nii_synth_nm_background_weight.img;
        struc_weight_maps.brainstem_weight = nii_synth_nm_brainstem_weight.img;
        struc_weight_maps.l_sn_weight = nii_synth_nm_l_sn_weight.img;
        struc_weight_maps.r_sn_weight = nii_synth_nm_r_sn_weight.img;

        struc_prior_maps = weight2prior(struc_weight_maps);

        [img_synth_nm, ~] = compute_synth_data(img_nm, img_t1w, struc_prior_maps);

        nii_synth_nm = nii_t1w;
        nii_synth_nm.img = img_synth_nm;
        nii_synth_nm.hdr.dime.bitpix = 32;
        nii_synth_nm.hdr.dime.datatype = 16;
        nii_synth_nm.hdr.dime.glmin = min(nii_synth_nm.img(:));
        nii_synth_nm.hdr.dime.glmax = max(nii_synth_nm.img(:));

        save_untouch_nii(nii_synth_nm, fullfile(data_dir, synth_nm_file));
    end
end