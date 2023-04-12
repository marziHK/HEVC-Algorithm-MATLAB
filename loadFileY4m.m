% function mov = loadFileYuv(fileName, width, height, nrFrame)

function [mov,imgRgb] = loadFileY4m(fileName, width, height, nrFrame)
% load RGB movie [0, 255] from YUV 4:2:0 file

fileId = fopen(fileName, 'r');

subSampleMat = [1, 1; 1, 1];

dummy = fgetl(fileId); % Skip file header

% progressbar
for f = 1:nrFrame
%     f
    
    % Skip frame header
    dummy = fgetl(fileId);
    
    % read Y component
    buf = fread(fileId, width * height, 'uint8');
    imgYuv(:, :, 1) = reshape(buf, width, height).'; % reshape
    
    % read U component
    buf = fread(fileId, width / 2 * height / 2, 'uint8');
    buf = reshape(buf, width / 2, height / 2).';
    imgYuv(:, :, 2) = kron(buf, subSampleMat); % reshape and upsample
%     imgYuv(:, :, 2) = buf;
    
    % read V component
    buf = fread(fileId, width / 2 * height / 2, 'uint8');
    buf = reshape(buf, width / 2, height / 2).';
    imgYuv(:, :, 3) = kron(buf, subSampleMat); % reshape and upsample
%     imgYuv(:, :, 3) = buf;
    
    % convert YUV to RGB
    imgRgb = reshape(convertYuvToRgb(reshape(imgYuv, height * width, 3)), height, width, 3);
%     imgycbcr = rgb2ycbcr(imgRgb);
    mov(f) = im2frame(imgRgb);
    
%     progressbar(f/nrFrame)
end
fclose(fileId);
