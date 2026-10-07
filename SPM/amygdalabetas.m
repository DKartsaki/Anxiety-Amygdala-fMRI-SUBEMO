% =========================================================================
% SUBEMO - ROI extraction from first-level contrast images
% SPM25
%
% Extracts the mean contrast estimate across all voxels within a
% predefined ROI for each subject and saves the results as a CSV file.
%
% Before running:
%   Set spm_dir to the local SPM installation directory.
%   Set root_dir to the dataset directory.
%   Set roi_mask to the ROI NIfTI file.
%   Set firstlevel_folder to the relevant first-level directory.
%   Set con_file to the first-level contrast image to be extracted.
%   Set contrast_name to a descriptive name used for the output CSV.
% =========================================================================

clc
clear
close all

% -------------------------------------------------------------------------
% USER SETTINGS
% -------------------------------------------------------------------------

spm_dir = 'PATH/TO/SPM';
root_dir = 'PATH/TO/DATA';
roi_mask = 'PATH/TO/ROI.nii';

firstlevel_folder = '1stLevel_new';

% Contrast to extract
con_file = 'con_XXXX.nii';
contrast_name = 'CONTRAST_NAME';

% Output directory
output_dir = fullfile(root_dir, 'ROI_results');

% -------------------------------------------------------------------------

addpath(spm_dir);
spm('Defaults', 'fMRI');
spm_jobman('initcfg');

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

out_csv = fullfile(output_dir, [contrast_name '.csv']);

% Load ROI mask
Vm = spm_vol(roi_mask);
Ym = spm_read_vols(Vm);

% Include all voxels with a positive mask value.
% Change this threshold if using a probabilistic ROI requiring a
% different inclusion threshold.
mask_idx = Ym > 0;

% Find subject directories
subs = dir(fullfile(root_dir, 'sub-*'));
subs = subs([subs.isdir]);

% Create output CSV
fid = fopen(out_csv, 'w');
fprintf(fid, 'subject,amygdala_mean\n');

for i = 1:numel(subs)

    subj = subs(i).name;

    con_path = fullfile( ...
        root_dir, subj, firstlevel_folder, con_file);

    if ~exist(con_path, 'file')
        fprintf('Missing contrast for %s: %s\n', subj, con_path);
        continue;
    end

    Vc = spm_vol(con_path);

    % Safety check: ROI and contrast image must have matching dimensions
    % and spatial transformations.
    if any(Vc.dim ~= Vm.dim) || ...
            max(abs(Vc.mat(:) - Vm.mat(:))) > 1e-4
        error(['Image-space mismatch for %s. ROI and contrast image ' ...
               'must be in the same space and resolution.'], subj);
    end

    Yc = spm_read_vols(Vc);

    % Extract contrast estimates within ROI
    vals = Yc(mask_idx);
    vals = vals(~isnan(vals));

    mean_val = mean(vals);

    fprintf(fid, '%s,%.6f\n', subj, mean_val);
    fprintf('OK %s: %.6f\n', subj, mean_val);

end

fclose(fid);

fprintf('\nSaved ROI results to:\n%s\n', out_csv);