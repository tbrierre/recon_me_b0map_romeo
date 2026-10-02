% recon_dicom_me_b0map_romeo_v2
% Theodore Brierre
% 04-10-2026

clc;clear;close all;
% delete('temp/*.*');
addpath(genpath(pwd));
addpath(genpath([getenv('MY_DIR') '/code_library/matlab']));

%% Convert dicom to nifti

data_dir = 'BAY5/2026-03-20_b0db/dicom/b0db_027/';

% 1 folder for 3 echos mag
dcm_mag_dir   = [data_dir 'multi_gre_neck_1mmISO_COR_tuneup_4_MR/'];
nifti_folder  = 'temp';nifti_filename = 'me_mag_3e';
mriconvert_wrapper(dcm_mag_dir, nifti_folder, nifti_filename);% --> uint16 issues with dcm2niix (can't go negative)

% 1 folder for 3 echos phase
dcm_phi_dir   = [data_dir 'multi_gre_neck_1mmISO_COR_tuneup_5_MR/'];
nifti_folder  = 'temp';nifti_filename = 'me_phi_3e';
mriconvert_wrapper(dcm_phi_dir, nifti_folder, nifti_filename);% --> uint16 issues with dcm2niix (can't go negative)

% get all TE
for ii=1:3
    mag_info{ii} = dicominfo([dcm_mag_dir '/' num2str(ii) '.dcm']);
end

te1 = mag_info{1}.PerFrameFunctionalGroupsSequence.Item_2.MREchoSequence.Item_1.EffectiveEchoTime;
te2 = mag_info{2}.PerFrameFunctionalGroupsSequence.Item_2.MREchoSequence.Item_1.EffectiveEchoTime;
te3 = mag_info{3}.PerFrameFunctionalGroupsSequence.Item_2.MREchoSequence.Item_1.EffectiveEchoTime;

te_str3 = ['[' num2str(te1) ',' num2str(te2) ',' num2str(te3) ']']

%% Create nifti mask from first echo only

me_mag = load_nifti('temp/me_mag_3e.nii');
me_phi = load_nifti('temp/me_phi_3e.nii');

mag1 = me_mag.vol(:,:,:,1);
[mag1, mask] = bias_field_correction_v2(mag1,2);

% Morphological processing
mask = imerode(mask,[0 1 0; 1 1 1; 0 1 0]);
% mask = imerode(mask,[0 1 0; 1 1 1; 0 1 0]);
se = strel('sphere', 2);  % tune radius
mask = imdilate(imerode(mask, se), se);
% remove island
CC = bwconncomp(mask, 26);
numPixels = cellfun(@numel, CC.PixelIdxList);
[~, idx] = max(numPixels);
mask = false(size(mask));
mask(CC.PixelIdxList{idx}) = true;
% fill holes
mask = imfill(mask, 26, 'holes');
mask = double(mask);
mask_nan = mask;mask_nan(mask==0)=NaN;
niftiwrite(mask, 'temp/me_mask.nii');

close all;
permord = [2 3 1];

figure;sliceViewer(permute(mask.*mag1,permord));
axis image off;colormap('gray');colorbar;

figure;sliceViewer(permute(mask.*me_phi.vol(:,:,:,1),permord));
axis image off;colorcet('D9');colorbar;

figure;sliceViewer(permute(mask,permord));
axis image off;

%% run ROMEO

romeo_dir = '/autofs/space/guerin/theodore/code_library/julia/romeo.jl';

cd temp/;
tic;fprintf('Running ROMEO...\n');
cmd = ['env -u LD_LIBRARY_PATH -u LD_PRELOAD ' ...
       'julia ' romeo_dir ...
       ' -p me_phi_3e.nii' ...
       ' -m me_mag_3e.nii' ...
       ' -o me_phi_unwrapped_3e.nii' ...
       ' -t "' te_str3 '"' ...
       ' -k me_mask.nii' ...
       ' -B me_b0map_3e' ...
       ' --max-seeds 4000'];

[status, result] = system(cmd);
cd ../;

if status ~= 0
    error('ROMEO failed with status %d:\n%s', status, result)
else
    fprintf('ROMEO completed in %.1f s\n', toc);
end

%% load unwrapped phase and b0 map

me_phi_unw_3e = load_nifti('temp/me_phi_unwrapped_3e.nii');

close all;
me_phi_unw_3e.vol(isnan(me_phi_unw_3e.vol)) = 0;
figure;sliceViewer(permute(mask.*me_phi_unw_3e.vol(:,:,:,1),permord));colorcet('D9');clim(3*[-1 1]);

% compute b0 map
gamma = 42.576e6; % (Hz/T)
b0_strength  = 2.9;
b0_map_hz    = load_nifti('temp/me_b0map_3e.nii');
b0_map_hz    = b0_map_hz.vol;
b0_map       = squeeze(b0_map_hz / gamma);
b0_map_ppm   = b0_map / b0_strength * 1e6;

%% plot b0 map
idx_sl = round(size(mask,3)/2);
crange = 200*[-1 1];

close all;
figure;
ax1 = subplot_tight(1,2,1);
imagesc(flip(rot90(squeeze(mask(:,:,idx_sl).*mag1(:,:,idx_sl)),-1),2));
colormap(ax1, gray);colorbar;
% cb1 = colorbar; cb1.Label.String = 'Amp';
axis image off;
title('Image Magnitude');

ax2 = subplot_tight(1,2,2);
slice = flip(rot90(squeeze(mask(:,:,idx_sl).*b0_map_hz(:,:,idx_sl)),-1),2);
h = imagesc(slice);  
colormap(ax2, colorcet('D9')); 
cb2 = colorbar; cb2.Label.String = '[Hz]';clim(crange);
axis image off;
title('B0 Map');
h.AlphaData = ~isnan(slice);

figure;imagesc(vol2mos(rot90(permute(mask.*b0_map_hz,[1 2 3]),-1)));axis image off;colorbar;clim(crange);colorcet('D9');
figure;imagesc(vol2mos(permute(mask.*b0_map_hz,[1 3 2])));axis image off;colorbar;clim(crange);colorcet('D9');
figure;imagesc(vol2mos(permute(mask.*b0_map_hz,[2 3 1])));axis image off;colorbar;clim(crange);colorcet('D9');


