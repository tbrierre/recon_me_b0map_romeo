# Multi-echo GRE B0 map reconstruction with ROMEO

`recon_dicom_me_b0map_romeo_v2.m` builds a B0 field map from multi-echo GRE DICOMs (3 echoes, magnitude and phase):

1. Converts the magnitude and phase DICOMs to NIfTI (`mri_convert`).
2. Reads the echo times from the DICOM headers.
3. Builds a brain/neck mask from echo 1 (bias-field correction, then morphological cleanup).
4. Unwraps the phase and computes the B0 map with [ROMEO](https://github.com/korbinian90/ROMEO.jl) (Julia).
5. Displays the B0 map in Hz.

## Layout

```
recon_dicom_me_b0map_romeo_v2.m   main script
lib/                              MATLAB dependencies
julia/                            ROMEO command-line wrapper (romeo.jl, Project.toml, Manifest.toml)
```

## Requirements

- MATLAB with the Image Processing Toolbox
- FreeSurfer (`mri_convert` on the PATH)
- Julia. The first run of `julia/romeo.jl` installs ROMEO, MriResearchTools and ArgParse.

## Usage

The script uses `addpath(genpath(pwd))`, a relative `data_dir`, and a `temp/` folder in the working directory. Before running it:

- add `lib/` to the MATLAB path,
- set `data_dir` to your DICOM folder,
- set `romeo_dir` to the path of `julia/romeo.jl`,
- create `temp/`.

## Third-party code

- `colorcet.m`: Peter Kovesi
- `subplot_tight.m`: MATLAB File Exchange
- `load_nifti.m`, `load_nifti_hdr.m`, `fsgettmppath.m`, `vol2mos.m` and the mosaic helpers: FreeSurfer
