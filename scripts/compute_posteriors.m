function struc_posterior_maps = compute_posteriors(img, struc_prior_maps)
    % 1. Extract and flatten priors into [num_total_voxels, 4] matrix
    % Columns: 1:background, 2:brainstem, 3:l_sn, 4:r_sn
    priors_all = [struc_prior_maps.background_prior(:), ...
                  struc_prior_maps.brainstem_prior(:), ...
                  struc_prior_maps.l_sn_prior(:), ...
                  struc_prior_maps.r_sn_prior(:)];
    
    % 2. Define ROI
    brainstem_mask = (struc_prior_maps.brainstem_prior > 0.5);
    background_thresh = compute_nm_background_threshold(img, brainstem_mask);
    roi_voxels = (sum(priors_all, 2) > 0.999) & (img(:) > background_thresh);
    
    % 3. Extract priors for ROI only [num_roi_voxels, 4]
    priors = priors_all(roi_voxels, :);
    log_priors = log(max(priors, 1e-15));
    
    % 4. Initialize log_likelihoods matrix [num_roi_voxels, 4]
    log_likelihoods = zeros(size(priors));
    
    % 5. Calculate Log-Likelihoods for ROI voxels
    img_flat = img(:);
    img_roi = img_flat(roi_voxels);
    
    for i = 1:4
        % Weighted mean/std calculation restricted to the ROI
        % Note: We weight by the prior inside the ROI
        p_roi = priors(:, i);
        mu = sum(img_roi .* p_roi) / sum(p_roi);
        sigma = sqrt(sum(p_roi .* (img_roi - mu).^2) / sum(p_roi));
        sigma = max(sigma, 1e-15);
        
        log_likelihoods(:, i) = -0.5 * log(2 * pi * sigma^2) - ((img_roi - mu).^2) ./ (2 * sigma^2);
    end
    
    % 6. Log-Sum-Exp Trick for Posteriors
    log_unnormalized = log_likelihoods + log_priors;
    max_log = max(log_unnormalized, [], 2);
    log_evidence = max_log + log(sum(exp(log_unnormalized - max_log), 2));
    log_posteriors = log_unnormalized - log_evidence;
    
    % 7. Map back to 3D structure
    % Initialize 3D volumes with zeros, then fill only ROI voxels
    posteriors_3d = zeros([size(img), 4]);
    for i = 1:4
        temp = zeros(size(img_flat));
        temp(roi_voxels) = exp(log_posteriors(:, i));
        posteriors_3d(:,:,:,i) = reshape(temp, size(img));
    end
    
    struc_posterior_maps.background_posterior = posteriors_3d(:,:,:,1);
    struc_posterior_maps.brainstem_posterior = posteriors_3d(:,:,:,2);
    struc_posterior_maps.l_sn_posterior = posteriors_3d(:,:,:,3);
    struc_posterior_maps.r_sn_posterior = posteriors_3d(:,:,:,4);
end
