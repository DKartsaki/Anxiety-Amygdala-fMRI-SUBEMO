% =========================================================================
% SUBEMO - First-level fMRI analysis
% SPM25
%
% Model:
%   12 task conditions
%   6 motion parameters included as nuisance regressors
%   Canonical HRF
%   High-pass filter: 128 s
%    Serial correlations: AR(1)
%
% The onset file contains 12 conditions in a fixed order:
%   1-6  = Visual conditions (Fear/Neutral across three stimulus levels)
%   7-12 = Auditory conditions (Fear/Neutral across three stimulus levels)
%
% Contrast weights below assume this exact condition ordering.
%
% Before running:
%   Set base_dir to the dataset directory.
%   Set spm_dir to the local SPM installation directory.
% =========================================================================

clc
clear
close all

% -------------------------------------------------------------------------
% USER SETTINGS
% -------------------------------------------------------------------------

base_dir = 'PATH/TO/DATA';
spm_dir  = 'PATH/TO/SPM';

addpath(spm_dir);
spm('Defaults', 'fMRI');
spm_jobman('initcfg');

% Subjects included in the analysis
% Subject 32 was excluded from the final sample.
subjects = 1:37;
subjects(32) = [];
for i=1:length(subjects)
    curSub = subjects(i);

    subject = num2str(curSub, '%02d')

    % === Directories ===
    func_dir   = fullfile(base_dir, ['sub-' subject], 'func', 'Localizer1');

   output_dir = fullfile(base_dir, ['sub-' subject], '1stLevel_new');

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

if exist(fullfile(output_dir, 'SPM.mat'), 'file')
    error(['First-level results already exist for sub-%s. ' ...
           'Use a new output directory or remove the existing results manually.'], ...
           subject);
end


% Preprocessed functional images
swrasub_func = cellstr(spm_select('FPList', func_dir, '^swrasub-.*\.nii$'));
swrasub_func = swrasub_func(:);
swrasub_func = strcat(swrasub_func, ',1');

if isempty(swrasub_func)
    error('No preprocessed functional images found for sub-%s.', subject);
end

% Condition onset file
onset_file = fullfile(base_dir, ['sub-' subject], ['Subject_' subject '.mat']);

if ~isfile(onset_file)
    error('Onset file not found for sub-%s.', subject);
end

S = load(onset_file);
fn = fieldnames(S);
Subject = S.(fn{1});

matlabbatch = {};
  
matlabbatch{1}.spm.stats.fmri_spec.dir = {output_dir};
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 2.66;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
%%
matlabbatch{1}.spm.stats.fmri_spec.sess.scans = swrasub_func;
                                                 
%%
    for c = 1:12
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(c).name     = Subject.names{c};
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(c).onset    = Subject.onsets{c};
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(c).duration = Subject.durations{c};
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(c).tmod     = 0;
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(c).pmod     = struct('name', {}, 'param', {}, 'poly', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(c).orth     = 1;
    end

matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''};
matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});

% --- Find the correct rp file for this subject ---
rp_pattern = ['^rp_asub-' subject '_.*_Localizer1_run_1\.txt$'];
rp_file = spm_select('FPList', func_dir, rp_pattern);

if isempty(rp_file)
    error('No rp file found for sub-%s. Looking for pattern: %s in %s', subject, rp_pattern, func_dir);
elseif size(rp_file,1) > 1
    error('Multiple rp files found for sub-%s. Pattern: %s in %s', subject, rp_pattern, func_dir);
end

matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {deblank(rp_file)};
matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'VisEMO>VisNeu';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1/3 -1/3 1/3 -1/3 1/3 -1/3 0 0 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'AudEMO>AudNeu';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [0 0 0 0 0 0 1/3 -1/3 1/3 -1/3 1/3 -1/3];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'All Face Fear > 0';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [1 0 1 0 1 0 0 0 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'All Face Neutral > 0';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [0 1 0 1 0 1 0 0 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = 'All Auditory Fear > 0';
matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [0 0 0 0 0 0 1 0 1 0 1 0];
matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'All Auditory Neutral > 0';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [0 0 0 0 0 0 0 1 0 1 0 1];
matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{7}.tcon.name = 'All Visual conditions';
matlabbatch{3}.spm.stats.con.consess{7}.tcon.weights = [1/6 1/6 1/6 1/6 1/6 1/6 0 0 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{7}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{8}.tcon.name = 'All Auditory Conditions';
matlabbatch{3}.spm.stats.con.consess{8}.tcon.weights = [0 0 0 0 0 0 1/6 1/6 1/6 1/6 1/6 1/6];
matlabbatch{3}.spm.stats.con.consess{8}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{9}.tcon.name = 'All Emotional Conditions';
matlabbatch{3}.spm.stats.con.consess{9}.tcon.weights = [1 0 1 0 1 0 1 0 1 0 1 0]; 
matlabbatch{3}.spm.stats.con.consess{9}.tcon.sessrep = 'none';


matlabbatch{3}.spm.stats.con.consess{10}.tcon.name = 'All Neutral Conditions';
matlabbatch{3}.spm.stats.con.consess{10}.tcon.weights = [0 1 0 1 0 1 0 1 0 1 0 1];  
matlabbatch{3}.spm.stats.con.consess{10}.tcon.sessrep = 'none';




matlabbatch{3}.spm.stats.con.delete = 0;

   spm_jobman('run', matlabbatch);
    end