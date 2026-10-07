# Anxiety-Amygdala-fMRI-SUBEMO
# Analysis code

This repository contains the analysis code accompanying the manuscript:

"[State and trait anxiety modulate hemodynamic amygdala responses to neutral relative to fearful auditory stimulation]"

## Contents

### R

`statistical_analyses_SUBEMO.R`

R code used for behavioral analyses, correlations, robustness and
sensitivity analyses, ROI analyses, and figure generation.

### SPM

`SPM/`

MATLAB/SPM scripts used for preprocessing and first- and second-level
fMRI analyses, as well as ROI extraction.

The scripts provided in the `SPM` folder represent the analysis framework
used in the study. During the analyses, the same first- and second-level
batch structures were reused for several planned and follow-up comparisons
by modifying the relevant first-level contrast definitions and/or the
contrast images entered into the second-level models.

Therefore, separate scripts are not provided for every individual contrast
or follow-up analysis. The provided first-level script documents the model
specification and representative contrast definitions, while the second-level
scripts illustrate the flexible-factorial analyses without a covariate and
with STAI-State or STAI-Trait.

To reproduce a specific comparison, the relevant first-level contrast weights
and second-level contrast-image selections should be modified accordingly
while retaining the model structure described in the manuscript.

## Software

- R 4.5.2
- MATLAB
- SPM25

## Data availability

The neuroimaging dataset associated with this study is available on OpenNeuro:
[https://openneuro.org/datasets/ds007690/versions/1.0.0 (doi:10.18112/openneuro.ds007690.v1.0.0)]

## Authors

Despoina Kartsaki et al.
