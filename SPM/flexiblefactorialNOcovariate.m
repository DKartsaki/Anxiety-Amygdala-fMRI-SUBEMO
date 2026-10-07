% =========================================================================
% SUBEMO - Second-level flexible factorial: no covariate
% SPM25
%
% Factors:
%   1. Subject
%   2. Emotion
%   3. Modality
%
% Tests the Emotion x Modality interaction without an anxiety covariate.
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

firstlevel_folder = '1stLevel_new';

output_dir = fullfile(base_dir, ...
    '2ndLevel_FlexibleFactorial_NoCovariate');

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Subjects included in the analysis
subjects = 1:37;
subjects(32) = [];

matlabbatch = {};

% -------------------------------------------------------------------------
% FLEXIBLE FACTORIAL DESIGN
% -------------------------------------------------------------------------

matlabbatch{1}.spm.stats.factorial_design.dir = {output_dir};

% Factor 1: Subject
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).name = 'Subjects';
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).dept = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).variance = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).ancova = 0;

% Factor 2: Emotion
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).name = 'Emotion';
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).dept = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).variance = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).ancova = 0;

% Factor 3: Modality
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).name = 'Modality';
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).dept = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).variance = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(3).ancova = 0;

scans = {};
conds = [];

for s = 1:length(subjects)

    sub_id = sprintf('%02d', subjects(s));

    % Order used in the original second-level analysis:
    %   con_0003
    %   con_0005
    %   con_0004
    %   con_0006

    con_files = {
        'con_0003.nii'
        'con_0005.nii'
        'con_0004.nii'
        'con_0006.nii'
    };

    for c = 1:4
        scans{end+1,1} = [fullfile( ...
            base_dir, ...
            ['sub-' sub_id], ...
            firstlevel_folder, ...
            con_files{c}) ',1'];
    end

    % [Subject Emotion Modality]
    conds = [
        conds
        s 1 1
        s 1 2
        s 2 1
        s 2 2
    ];

end

matlabbatch{1}.spm.stats.factorial_design.des.fblock.fsuball.fsubject.scans = scans;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fsuball.fsubject.conds = conds;

% Main effect of Subject and Emotion x Modality interaction
matlabbatch{1}.spm.stats.factorial_design.des.fblock.maininters{1}.fmain.fnum = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.maininters{2}.inter.fnums = [2 3];

matlabbatch{1}.spm.stats.factorial_design.cov = ...
    struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});

matlabbatch{1}.spm.stats.factorial_design.multi_cov = ...
    struct('files', {}, 'iCFI', {}, 'iCC', {});

matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};

matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

spm_jobman('run', matlabbatch);