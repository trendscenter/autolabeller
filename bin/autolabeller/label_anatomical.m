% input: path to nifti file, index of networks and correlations with how many regions
% anatomical regions to return
% output: volumes x 2*(n+1) cell of indices, anatomical region names and correlation values
function anat_pred = label_anatomical( sm_file, networks, n )
    aal_path = which('aal.nii');
    aal_label_path = which('aal.nii.txt');

    % load SPM anatomical labels
    aal_labels = readtable( aal_label_path );

    % resample
    disp('resampling to AAL atlas')
    sm_dat = fmri_data( sm_file, [], 'noverbose' );
    aal_dat = fmri_data( aal_path, [], 'noverbose' );
    sm_dat = resample_space( sm_dat, aal_dat );
    n_vols = size(sm_dat.dat, 2);

    disp('masking AAL atlas')
    s_ = [length(aal_dat.dat) max( aal_dat.dat )];
    aal_V_4D = zeros(s_);
    for jj = 1:max( aal_dat.dat )
        idx = find( aal_dat.dat == jj );
        aal_V_4D( idx, jj ) = 1;
    end

    disp('computing correlation')
    anat_pred = cell( n_vols,  2*(n+1) );
    corrs_ = corr( sm_dat.dat, aal_V_4D );
    
    % network flags
    anat_pred(:, 2) = num2cell( networks );

    headers = {'volume', 'network'};
    header_flag = 0;
    for jj = 1:n_vols
        anat_pred{jj, 1} = jj;
        [vv, ii] = maxk( corrs_(jj, :), n );
        t1 = 3;
        for kk = 1:n
            anat_pred{jj, t1} = aal_labels{ aal_labels.Var1 == ii(kk), 'Var2' }{1};
            anat_pred{jj, t1+1} = vv(kk);
            t1 = t1 + 2;
            if ~header_flag
                headers = [headers, {['region_' num2str(kk)] ['corr_' num2str(kk)]}];
            end
        end
        header_flag = 1;
    end

    anat_pred = [headers; anat_pred];

    disp('done predicting anatomical labels')


