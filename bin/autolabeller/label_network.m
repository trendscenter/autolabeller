% input: fALFF and dynamic range of ICA timecourses collected from ICA session info
% output: 1 (network) or 0 (artifact)
function network_pred = label_network( sesInfo, sm_path, fit_method )
    disp('predicting networks')

    % training
    % load fbirn features
    [feat_fbirn, labels_fbirn] = load_fbirn_true_labels();
    [feat_train, headers] = get_training_features( feat_fbirn, sesInfo );
    model_ = get_trained_model( feat_train, labels_fbirn, fit_method );

    % testing
    % get brain mask correlations
    mask_corrs = get_mask_corrs( sm_path );
    feat_test = get_testing_features( mask_corrs, sesInfo );

    network_pred = fit_test_data( feat_test, model_, fit_method );
    network_pred = [network_pred, feat_test];
    network_pred = num2cell( network_pred );
    network_pred = [headers; network_pred];

    disp('done predicting network')
end

function [feat_, headers] = get_training_features( feat_fbirn, sesInfo )
    if ~isempty( sesInfo )
        % fit fbirn model with all features
        feat_ = feat_fbirn;
        headers = {'network', 'probability', 'fALFF', 'dynamic_range', 'brain_corr', 'wm_corr', 'csf_corr'};
    else
        % fit fbirn model with only brain mask corr features
        feat_ =  feat_fbirn( :, 3:5 );
        headers = {'network', 'probability', 'brain_corr', 'wm_corr', 'csf_corr'};
    end
end

function feat_ = get_testing_features( mask_corrs, sesInfo )
    if ~isempty( sesInfo )
        % get all features
        % load GICA post_process result 
        post_process = load( fullfile(sesInfo.outputDir, [sesInfo.userInput.prefix '_postprocess_results.mat']) );
        % load fALFF and dynamic range from post_process output
        fALFF = post_process.fALFF;
        dyn_range = post_process.dynamic_range;

        % create noise features
        feat_ = [fALFF dyn_range mask_corrs];
        feat_ = zscore( feat_ );
    else
        % get only brain mask corr features
        feat_ = zscore( mask_corrs );
    end
end

function mdl_ = get_trained_model( feat_, labels_, fit_method )
    labels_ = categorical( labels_ );
    switch fit_method
        case 'mnr'
            disp('train using mnr')
            [mdl_, dev, stats] = mnrfit( feat_, categorical( labels_ ) );
        case 'svm'  % does not work very well, needs tuning
            disp('train using svm')
            mdl_ = fitcsvm( feat_, categorical( labels_ ) );
    end
end

function network_pred = fit_test_data( feat_, model_, fit_method )
    feat_ = zscore( feat_ );
    switch fit_method
        case 'mnr'
            disp('predict using mnr')
            p_hat = mnrval(model_, feat_);
            network_pred = p_hat(:,1) < p_hat(:,2);
            network_pred = [network_pred, p_hat(:,2)];
        case 'svm'
            disp('predict using svm')
            network_pred = predict(model_, feat_);
            network_pred = double( flip( network_pred ) ) - 1;
    end
end

function corrs_ = get_mask_corrs( sm_path )
    structFile = which( 'ch2better_aligned2EPI_resampled.nii' );
    
    %% correlation w/ brain masks
    % resample everything to the same space
    struct_dat = fmri_data(structFile, [], 'noverbose');

    % load IC aggregate map
    sm_dat = fmri_data( sm_path, [], 'noverbose' );
    sm_dat = resample_space( sm_dat, struct_dat );

    % brain mask
    mask_dat = fmri_data( which('mask_ch2better_aligned2EPI.nii'), [], 'noverbose');
    mask_dat = resample_space(mask_dat, struct_dat);
    corr_brainmask = corr(sm_dat.dat, mask_dat.dat);

    % white matter mask
    mask_dat = fmri_data( which('WhiteMask_09_61x73x61.hdr'), [], 'noverbose');
    mask_dat = resample_space(mask_dat, struct_dat);
    corr_whitemask = corr(sm_dat.dat, mask_dat.dat);

    % csf mask
    mask_dat = fmri_data( which('CsfMask_07_61x73x61.hdr'), [], 'noverbose');
    mask_dat = resample_space(mask_dat, struct_dat);
    corr_csfmask = corr(sm_dat.dat, mask_dat.dat);

    corrs_ = [corr_brainmask corr_whitemask corr_csfmask];
end