% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved
%

close all;
clc;
clear all;
global h w QP QPc ctuSize fixedCuSizeFlag minTuSize minCuSize maxTrafoDepth
global maxTuSize frameRate numofSadCandidates numofSadCandidates8x8 numofSadCandidates16x16 numofSadCandidates32x32 rankListSize  
global numOfRdoCandidates8x8 numOfRdoCandidates16x16 numOfRdoCandidates32x32 rdoRateFactor

%% input parameters are:
% filename = 'D:\Thesis\Video Benchmark\crew_4cif.yuv';
filename = 'D:\Thesis\Video Benchmark\crew_4cif.y4m';
% filename = 'D:\Thesis\Video Benchmark\city_4cif.y4m'; 
h = 576;
w = 704;
% filename = 'D:\Thesis\Video Benchmark\crew_cif.y4m'; 
% h = 288;
% w = 352;

startFrame = 1;        % start frame
endFrame = 1;          % end frame
QP = 38;                % QP values
ctuSize = 64;
fixedCuSizeFlag = 1;
minTuSize = 4;
maxTuSize = 32;
minCuSize = 64;
frameRate = 25;
maxTrafoDepth = 0; %CUsize == TUsize 
%
numofSadCandidates = 8;
rankListSize = 15;
numOfRdoCandidates8x8 = 10; % not use
numOfRdoCandidates16x16 = 4;
numOfRdoCandidates32x32 = 3;
numofSadCandidates8x8 = 10; % not use
numofSadCandidates16x16 = 10;
numofSadCandidates32x32 = 4;
rdoRateFactor = 1;

%%------------------------------------------------
load QP_luma2chroma;
QPc = QP_luma2chroma(QP);
global bitCntr seCntr binCountsInNalUnits;
bitCntr = 0;
seCntr = 0;


%% ------------------------------------------------
% VPS & PPS are constant
PPS = '000000000000000000000000000000010100010000000001110000001001000010010001100000011010010010000000';
VPS = '00000000000000000000000000000001010000000000000100001100000000011111111111111111000000010110000000000000000000000000001100000000000000000000001100000000000000000000001100000000000000000000001100000000000000001111000000100100';

% crew_4cif 
SPS = '00000000000000000000000000000001010000100000000100000001000000010110000000000000000000000000001100000000000000000000001100000000000000000000001100000000000000000000001100000000000000001010';
SPS = [SPS,enc_golomb(w,0),enc_golomb(h,0),'1111111001011111',enc_golomb(log2(minCuSize)-3,0),enc_golomb(log2(ctuSize)-log2(minCuSize),0), ...
       enc_golomb(log2(minTuSize)-2,0),enc_golomb(log2(maxTuSize)-log2(minTuSize),0),enc_golomb(maxTrafoDepth,0),enc_golomb(maxTrafoDepth,0),...
       '01000111101101000','1'];
SPS = ByteAlign(SPS);

sliceHeader = ['0000000000000000000000010010011000000001101011',enc_golomb(QP-26,1),'1'];
sliceHeader = ByteAlign(sliceHeader);



%% Encode Frames
% fid = fopen(filename,'r');
[mov,imgRgb] = loadFileY4m(filename, w, h, 1);
imgycbcr = rgb2ycbcr(imgRgb);
% [mov,imgRgb] = loadFileYuv(filename, w, h, 1:1);
bitStream = [];
PSNR = [];
for frm = startFrame:endFrame
    Y(:,:)= imgycbcr(:,:,1);
    UV(:,:,1)= imgycbcr(:,:,2);
    UV(:,:,2)= imgycbcr(:,:,3);
    UV = double(UV(1:2:end,1:2:end,:));
    
%     Y1(:,:)=(fread(fid,[w h],'uint8')');
%     UV1(:,:,1)=(fread(fid,[w/2 h/2],'uint8')');
%     UV1(:,:,2)=(fread(fid,[w/2 h/2],'uint8')');
%     fclose(fid);
%      figure;    imshow(Y(:,:),[]);
%      figure;    imshow(UV(:,:,1),[]);
%      figure;    imshow(UV(:,:,2),[]);

    [rcY, rcUV, seqBits] = Encode_I_Frame(Y,UV);
    PSNR = [PSNR, psnr(uint8(rcY),uint8(Y))];
    savve(rcY,rcUV);
    %% make the bitstream 
    %%% emulation prevention three bytes %%%
%     the bitstream must not have the sequences 0x000000, 0x000001 %
%     0x000002, and 0x000003 and must be modified by a byte 0x03 %
    a = strfind(seqBits,'000000000000000000000000');
    b = strfind(seqBits,'000000000000000000000001');
    c = strfind(seqBits,'000000000000000000000010');
    d = strfind(seqBits,'000000000000000000000011');
    a = [a b c d];
    a(mod(a,8)~=1)=[];
    s = length(a);
    omit = [];
    for i=1:s-1
        if((a(i+1)-a(i)) < 9)
            omit = [omit, i+1];
        end
    end
    a(omit)=[];
    s = length(a);
    if(s>=1)
        emPreventedSeqBits = seqBits(1:a(1)-1);
        for i=1:s-1
            emPreventedSeqBits = [emPreventedSeqBits,seqBits(a(i):a(i)+2*8-1),'00000011',seqBits(a(i)+2*8:a(i+1)-1)];
        end
        emPreventedSeqBits = [emPreventedSeqBits,seqBits(a(s):a(s)+2*8-1),'00000011',seqBits(a(s)+2*8:length(seqBits))];
    else
        emPreventedSeqBits = seqBits;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    tmpSeq = [sliceHeader emPreventedSeqBits '1'];
    tmpSeq = ByteAlign(tmpSeq);
%     seq = [seq, sliceHeader, emPreventedSeqBits];
    bitStream = [VPS,SPS,PPS,tmpSeq];
    
    
end
    
bitstream2file(bitStream,'Result\crew_q38_s64_DC_test5.bin');
PSNR = mean(PSNR);    
bitRate = ((length(bitStream) / (endFrame-startFrame+1))*frameRate)/(2^20);

disp(['Bit-rate = ',num2str(bitRate), ' Mb/s']);
disp(['Avg. PSNR = ',num2str(PSNR), ' db']);