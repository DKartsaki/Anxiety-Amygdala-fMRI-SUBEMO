%-----------------------------------------------------------------------
% spm SPM - SPM25 (25.01.02)
% 
%-----------------------------------------------------------------------
%%

clc
clear
close all

% Preprocessing steps:
%   1. Slice timing correction
%   2. Realignment
%   3. T1-functional coregistration
%   4. T1 segmentation
%   5. Normalization to MNI space
%   6. Spatial smoothing (6-mm FWHM)
%
% Before running:
%   Set base_dir to the dataset directory.
%   Set spm_dir to the local SPM installation directory.
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% SELECT PREPROCESSING STEP
% -------------------------------------------------------------------------
% Run steps sequentially from 1 to 6.
%
% 1 = Slice timing
% 2 = Realignment
% 3 = Coregistration
% 4 = Segmentation
% 5 = Normalization
% 6 = Smoothing

STEP = 1;
% -------------------------------------------------------------------------
% =========================================================================
%subject 32 was removed from the analysis 

subjects= 1:37;
subjects(32)=[];

% -------------------------------------------------------------------------
% USER SETTINGS
% -------------------------------------------------------------------------

% Root directory containing the subject folders (sub-01, sub-02, ...)
base_dir = 'PATH/TO/DATA';

% SPM installation directory
spm_dir = 'PATH/TO/SPM';

addpath(spm_dir);
spm('Defaults', 'fMRI');
spm_jobman('initcfg');

% SPM tissue probability map
tpm_file = fullfile(spm_dir, 'tpm', 'TPM.nii');



%% 
 for i = 1:length(subjects)

    curSub = subjects(i);
    subject = num2str(curSub, '%02d');

    fprintf('\n====================================================\n');
    fprintf('Subject sub-%s | Preprocessing step %d\n', subject, STEP);
    fprintf('====================================================\n');

    % Define paths
    func_dir = fullfile(base_dir, ['sub-' subject], 'func', 'Localizer1');
    anat_dir = fullfile(base_dir, ['sub-' subject], 'anat', 'Localizer1');

    % Start a fresh batch for each subject
    matlabbatch = {};

    switch STEP

        % ================================================================
        % STEP 1: SLICE TIMING
        % ================================================================
        case 1

            raw_func = cellstr( ...
                spm_select('FPList', func_dir, '^sub-.*\.nii$') ...
            );
            raw_func = raw_func(:);
            raw_func = strcat(raw_func, ',1');

            if isempty(raw_func)
                error('No raw functional images found for sub-%s.', subject);
            end

            matlabbatch{1}.spm.temporal.st.scans = {raw_func};
            matlabbatch{1}.spm.temporal.st.nslices = 66;
            matlabbatch{1}.spm.temporal.st.tr = 2.66;
            matlabbatch{1}.spm.temporal.st.ta = 2.619;

            matlabbatch{1}.spm.temporal.st.so = ...
                [0 1370.303 80.60606 1450.909 161.2121 1531.515 ...
                 241.8182 1612.121 322.4242 1692.727 403.0303 ...
                 1773.333 483.6364 1853.939 564.2424 1934.545 ...
                 644.8485 2015.152 725.4545 2095.758 806.0606 ...
                 2176.364 886.6667 2256.97 967.2727 2337.576 ...
                 1047.879 2418.182 1128.485 2498.788 1209.091 ...
                 2579.394 1289.697 ...
                 0 1370.303 80.60606 1450.909 161.2121 1531.515 ...
                 241.8182 1612.121 322.4242 1692.727 403.0303 ...
                 1773.333 483.6364 1853.939 564.2424 1934.545 ...
                 644.8485 2015.152 725.4545 2095.758 806.0606 ...
                 2176.364 886.6667 2256.97 967.2727 2337.576 ...
                 1047.879 2418.182 1128.485 2498.788 1209.091 ...
                 2579.394 1289.697];

            matlabbatch{1}.spm.temporal.st.refslice = 0;
            matlabbatch{1}.spm.temporal.st.prefix = 'a';


        % ================================================================
        % STEP 2: REALIGNMENT
        % ================================================================
        case 2

            asub_func = cellstr( ...
                spm_select('FPList', func_dir, '^asub-.*\.nii$') ...
            );
            asub_func = asub_func(:);
            asub_func = strcat(asub_func, ',1');

            if isempty(asub_func)
                error(['No slice-time-corrected images found for sub-%s. ' ...
                       'Run STEP = 1 first.'], subject);
            end

            matlabbatch{1}.spm.spatial.realign.estwrite.data = {asub_func};

            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 2;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';

            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [2 1];
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 4;
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 1;
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = 'r';


        % ================================================================
        % STEP 3: T1-FUNCTIONAL COREGISTRATION
        % ================================================================
        case 3

            mean_func = cellstr( ...
                spm_select('FPList', func_dir, '^meanasub-.*\.nii$') ...
            );
            mean_func = mean_func(:);
            mean_func = strcat(mean_func, ',1');

            if isempty(mean_func)
                error(['No mean realigned functional image found for sub-%s. ' ...
                       'Run STEP = 2 first.'], subject);
            end

            anat_orig = fullfile( ...
                anat_dir, ...
                ['sub-' subject '_000001_T1w_run_1.nii'] ...
            );

            if ~isfile(anat_orig)
                error('T1 image not found for sub-%s.', subject);
            end

            matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {mean_func{1}};
            matlabbatch{1}.spm.spatial.coreg.estwrite.source = ...
                {[anat_orig ',1']};

            matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};

            matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
            matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];

            matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = ...
                [0.02 0.02 0.02 ...
                 0.001 0.001 0.001 ...
                 0.01 0.01 0.01 ...
                 0.001 0.001 0.001];

            matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];

            matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
            matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
            matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
            matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';


        % ================================================================
        % STEP 4: T1 SEGMENTATION
        % ================================================================
        case 4

            anat_file = fullfile( ...
                anat_dir, ...
                ['rsub-' subject '_000001_T1w_run_1.nii'] ...
            );

            if ~isfile(anat_file)
                error(['Coregistered T1 image not found for sub-%s. ' ...
                       'Run STEP = 3 first.'], subject);
            end

            matlabbatch{1}.spm.spatial.preproc.channel.vols = ...
                {[anat_file ',1']};

            matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.0001;
            matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
            matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1];

            matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = ...
                {[tpm_file ',1']};
            matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
            matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];

            matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = ...
                {[tpm_file ',2']};
            matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
            matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];

            matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = ...
                {[tpm_file ',3']};
            matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];

            matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = ...
                {[tpm_file ',4']};
            matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
            matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];

            matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = ...
                {[tpm_file ',5']};
            matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
            matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];

            matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = ...
                {[tpm_file ',6']};
            matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];

            matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
            matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
            matlabbatch{1}.spm.spatial.preproc.warp.reg = ...
                [0 0.001 0.5 0.05 0.2];

            matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
            matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
            matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
            matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1];
            matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;

            matlabbatch{1}.spm.spatial.preproc.warp.bb = ...
                [NaN NaN NaN
                 NaN NaN NaN];


        % ================================================================
        % STEP 5: NORMALIZATION TO MNI SPACE
        % ================================================================
        case 5

            rasub_func = cellstr( ...
                spm_select('FPList', func_dir, '^rasub-.*\.nii$') ...
            );
            rasub_func = rasub_func(:);
            rasub_func = strcat(rasub_func, ',1');

            if isempty(rasub_func)
                error('No realigned functional images found for sub-%s.', ...
                      subject);
            end

            anat_file = fullfile( ...
                anat_dir, ...
                ['rsub-' subject '_000001_T1w_run_1.nii'] ...
            );

            if ~isfile(anat_file)
                error('Coregistered T1 image not found for sub-%s.', subject);
            end

            y_r = cellstr( ...
                spm_select('FPList', anat_dir, '^y_.*\.nii$') ...
            );

            if isempty(y_r)
                error(['No deformation field found for sub-%s. ' ...
                       'Run STEP = 4 first.'], subject);
            end

            rasub_func = rasub_func(:);

            anat_file_cell = {[anat_file ',1']};
            anat_file_cell = anat_file_cell(:);

            resample_list = [rasub_func; anat_file_cell];

            matlabbatch{1}.spm.spatial.normalise.write.subj.def = y_r;
            matlabbatch{1}.spm.spatial.normalise.write.subj.resample = ...
                resample_list;

            matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = ...
                [-78 -112 -70
                  78   76  85];

            matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = ...
                [2 2 2];

            matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';


        % ================================================================
        % STEP 6: SPATIAL SMOOTHING
        % ================================================================
        case 6

            wrasub_func = cellstr( ...
                spm_select('FPList', func_dir, '^wrasub-.*\.nii$') ...
            );
            wrasub_func = wrasub_func(:);
            wrasub_func = strcat(wrasub_func, ',1');

            if isempty(wrasub_func)
                error(['No normalized functional images found for sub-%s. ' ...
                       'Run STEP = 5 first.'], subject);
            end

            matlabbatch{1}.spm.spatial.smooth.data = wrasub_func;
            matlabbatch{1}.spm.spatial.smooth.fwhm = [6 6 6];
            matlabbatch{1}.spm.spatial.smooth.dtype = 0;
            matlabbatch{1}.spm.spatial.smooth.im = 0;
            matlabbatch{1}.spm.spatial.smooth.prefix = 's';


        otherwise
            error('STEP must be an integer from 1 to 6.');

    end

    % Run selected preprocessing step for current subject
    spm_jobman('run', matlabbatch);

end