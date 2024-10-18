clear all
tStart = tic;

% add requirements to path
addpath( '../GroupICATv4.0b/' )      % GIFT toolbox
addpath( '/matlab/toolboxes/spm12/' )      % SPM12 toolbox
addpath( '../2019_03_03_BCT' )       % Brain connectivity toolbox
addpath( '../autolabeller/' )       % add the autolabeller src folder only

% GICA example with fbirn dataset
clear params;
params.param_file = 'ica_parameter_info.mat';
params.outpath = './results';
params.fit_method = 'mnr';
params.n_corr = 3;
params.skip_noise = 0;
params.skip_anatomical = 0;
params.skip_functional = 0;
params.noise_training_set = 'pre_fbirn_sub';
params.anatomical_atlas = 'aal';
params.threshold = 3;
params.functional_atlas = 'yeo_buckner';
% params.functional_atlas = 'gordon2016';
% params.functional_atlas = 'caren';
disp( 'Running the autolabeller on the selected dataset' )
label_auto_main( params );

% Spatial map example with neuromark template
clear params;
params.sm_path = '/Spatial_Maps.nii';
params.mask_path = '/data/mialab/competition2019/NetworkTemplate/Mask.img';
params.outpath = './results/';
params.fit_method = 'mnr';
params.n_corr = 3;
params.skip_noise = 0;
params.skip_anatomical = 0;
params.skip_functional = 0;
params.noise_training_set = 'pre_aggregate';
params.anatomical_atlas = 'aal';
params.threshold = 3;
params.functional_atlas = 'yeo_buckner';
% params.functional_atlas = 'gordon2016';
% params.functional_atlas = 'caren';
disp( 'Running the autolabeller on the selected dataset' )
label_auto_main( params );

tEnd = toc(tStart)
