%% Bias field correction using 2D polynomial fit
% Input: img (2D MRI magnitude image)

function [vol_corr, mask] = bias_field_correction_v2(vol,norder,mask)
%% 3D MRI bias field correction using polynomial fit
% Input: vol  -> 3D MRI magnitude volume [Nx Ny Nz]
% Output: vol_corr, bias
plots_on = 0;  % turn on plots --> -12

mean_in = mean(mean(mean(vol)));

if nargin < 2 || isempty(norder)
    order = 2;
else
    order = norder;
end

vol = double(vol);

if nargin < 3 || isempty(mask)
    mask_zero = zeros(size(vol));
    mask_zero(vol > .25 * mean(mean(mean(vol)))) = 1;
    vol = vol .* double(mask_zero);
    vol = vol / max(vol(:));
    mask = mask_zero > 0;
    % Simple foregroundmask (tune threshold if needed)
    % mask = vol > 0.05 * max(vol(:)); %REMOVED BY THEODORE 
else
    mask_zero = mask;
    vol = vol .* double(mask);
    vol = vol / max(vol(:));
end

% Volume size
[nx, ny, nz] = size(vol);

% Normalized coordinate grid
[x, y, z] = ndgrid( ...
    linspace(-1,1,nx), ...
    linspace(-1,1,ny), ...
    linspace(-1,1,nz));

% Build design matrix for masked voxels
X = [];
for i = 0:order
    for j = 0:(order-i)
        for k = 0:(order-i-j)
            X = [X, ...
                (x(mask).^i) .* ...
                (y(mask).^j) .* ...
                (z(mask).^k)];
        end
    end
end

% Fit polynomial to log-domain
b = X \ log(vol(mask));

% Evaluate polynomial over full volume
Xfull = [];
for i = 0:order
    for j = 0:(order-i)
        for k = 0:(order-i-j)
            Xfull = [Xfull, ...
                (x(:).^i) .* ...
                (y(:).^j) .* ...
                (z(:).^k)];
        end
    end
end

bias_log = reshape(Xfull * b, size(vol));
bias = exp(bias_log);

% Normalize bias field
bias = bias / mean(bias(mask));
bias(isnan(bias)) = 0;

% Correct volume
vol_corr = vol ./ bias;
vol_corr(isnan(vol_corr)) = 0;
vol_corr(vol_corr > 15*mean(mean(mean(vol_corr)))) = 0;
vol_corr = vol_corr * mean_in .* mask_zero;

if plots_on
    % Display middle slices
    figure(100);
    subplot(1,3,1), imagesc(vol(:,:,round(nz/2))), axis image off
    title('Original'), colormap gray
    subplot(1,3,2), imagesc(bias(:,:,round(nz/2))), axis image off
    title('Estimated Bias')
    subplot(1,3,3), imagesc(vol_corr(:,:,round(nz/2))), axis image off
    title('Corrected')
end



