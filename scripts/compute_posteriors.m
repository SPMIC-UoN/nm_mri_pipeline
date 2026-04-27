function struc_posterior_maps = compute_posteriors(img, struc_prior_maps)
    warning('off', 'stats:gmdistribution:FailedToConvergeReps');
	
	img = imgaussfilt3(img, 0.5);

    background_prior_map = struc_prior_maps.background_prior;
    brainstem_prior_map = struc_prior_maps.brainstem_prior;
    l_sn_prior_map = struc_prior_maps.l_sn_prior;
    r_sn_prior_map = struc_prior_maps.r_sn_prior;
    
    img_size = size(img);
    max_iterations = 20;

    brainstem_mask = (brainstem_prior_map > 0.5);
    background_thresh = compute_nm_background_threshold(img, brainstem_mask);
	
	background_prior_map(background_prior_map < 0) = 0;
	brainstem_prior_map(brainstem_prior_map < 0) = 0;
	l_sn_prior_map(l_sn_prior_map < 0) = 0;
	r_sn_prior_map(r_sn_prior_map < 0) = 0;

    roi_voxels = (background_prior_map(:) + brainstem_prior_map(:) + l_sn_prior_map(:) + r_sn_prior_map(:) > 0.99) & (img(:) > background_thresh);

    img_data = img(roi_voxels);
    
    background_prior_prob = background_prior_map(roi_voxels);
    brainstem_prior_prob = brainstem_prior_map(roi_voxels);
    l_sn_prior_prob = l_sn_prior_map(roi_voxels);
    r_sn_prior_prob = r_sn_prior_map(roi_voxels);
    
    % --- Soft init from priors (normalize across classes per voxel) ---
    prior_stack = [background_prior_prob, brainstem_prior_prob, l_sn_prior_prob, r_sn_prior_prob];
    prior_stack = prior_stack ./ (sum(prior_stack, 2) + eps);

    gamma_background = prior_stack(:,1);
    gamma_brainstem = prior_stack(:,2);
    gamma_l_sn = prior_stack(:,3);
    gamma_r_sn = prior_stack(:,4);

    for i = 1:max_iterations
        % --- M-step: fit class-conditional GMMs using responsibilities as weights ---
        weights_background = max(gamma_background, 1e-6);
        weights_brainstem = max(gamma_brainstem, 1e-6);
        weights_l_sn = max(gamma_l_sn, 1e-6);
        weights_r_sn = max(gamma_r_sn, 1e-6);

        pd_background = weighted_gmm_1d(img_data, weights_background, 2);
        pd_brainstem = weighted_gmm_1d(img_data, weights_brainstem, 2);
        pd_l_sn = weighted_gmm_1d(img_data, weights_l_sn, 2);
        pd_r_sn = weighted_gmm_1d(img_data, weights_r_sn, 2);

        % --- E-step: compute log posterior up to a constant: log p(x|c) + log p(c) ---
        log_background = log(pdf(pd_background, img_data) + realmin) + log(background_prior_prob + eps);
        log_brainstem = log(pdf(pd_brainstem, img_data) + realmin) + log(brainstem_prior_prob + eps);
        log_l_sn = log(pdf(pd_l_sn, img_data) + realmin) + log(l_sn_prior_prob + eps);
        log_r_sn = log(pdf(pd_r_sn, img_data) + realmin) + log(r_sn_prior_prob + eps);

        log_stack = [log_background, log_brainstem, log_l_sn, log_r_sn];

        % log-sum-exp normalization across classes (row-wise)
        m = max(log_stack, [], 2);
        log_norm = m + log(sum(exp(log_stack - m), 2) + eps);

        gamma_new = exp(log_stack - log_norm);

        gamma_background_new = gamma_new(:,1);
        gamma_brainstem_new = gamma_new(:,2);
        gamma_l_sn_new = gamma_new(:,3);
        gamma_r_sn_new = gamma_new(:,4);

        % --- Convergence: analogous to your old "changed voxels" criterion, but soft ---
        diff_total = sum(abs(gamma_background - gamma_background_new)) + sum(abs(gamma_brainstem - gamma_brainstem_new)) + sum(abs(gamma_l_sn - gamma_l_sn_new)) + sum(abs(gamma_r_sn - gamma_r_sn_new));

        gamma_background = gamma_background_new;
        gamma_brainstem = gamma_brainstem_new;
        gamma_l_sn = gamma_l_sn_new;
        gamma_r_sn = gamma_r_sn_new;

        if diff_total <= 0.001 * sum(roi_voxels)            
            break;
        end
    end

    struc_posterior_maps.background_posterior = zeros(img_size);
    struc_posterior_maps.background_posterior(roi_voxels) = gamma_background;

    struc_posterior_maps.brainstem_posterior = zeros(img_size);
    struc_posterior_maps.brainstem_posterior(roi_voxels) = gamma_brainstem;

    struc_posterior_maps.l_sn_posterior = zeros(img_size);
    struc_posterior_maps.l_sn_posterior(roi_voxels) = gamma_l_sn;

    struc_posterior_maps.r_sn_posterior = zeros(img_size);
    struc_posterior_maps.r_sn_posterior(roi_voxels) = gamma_r_sn;
    
    warning('on', 'stats:gmdistribution:FailedToConvergeReps');
end

function gm = weighted_gmm_1d(x, w, K)

    x = x(:);
    w = w(:);
    w = w / sum(w);

    % Initialize using kmeans on data (unweighted, minimal change)
    idx = kmeans(x, K, 'MaxIter', 2000, 'Replicates', 5);

    mu = zeros(K,1);
    sigma2 = zeros(K,1);
    pi_k = zeros(K,1);

    for k = 1:K
        wk = w(idx == k);
        xk = x(idx == k);

        if isempty(xk)
            mu(k) = mean(x);
            sigma2(k) = var(x) + 1e-6;
            pi_k(k) = 1/K;
        else
            wk = wk / sum(wk);
            mu(k) = sum(wk .* xk);
            sigma2(k) = sum(wk .* (xk - mu(k)).^2) + 1e-6;
            pi_k(k) = sum(w(idx == k));
        end
    end

    % Build MATLAB GMM object
    gm = gmdistribution(mu, reshape(sigma2,1,1,[]), pi_k');
end