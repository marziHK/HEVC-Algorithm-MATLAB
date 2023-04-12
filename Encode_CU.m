% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved

%%
% coded CUS
% Input : 
%                 cbOrigYSamples          ->  Original Y samples of CU 
%                 cbOrigUVSamples         ->  Original UV samples of CU
%                 pL_Y                    ->  Left Neighbours Y samples
%                 pL_UV                   ->  Left Neighbours UV samples
%                 pU_Y                    ->  TOp Neighbours Y samples
%                 pU_UV                   ->  Top Neighbours UV samples
%                 leftMode                ->  Left neighbor mode
%                 upMode                  ->  Top neighber mode
%                 bestModeY                ->  Best intra mode for coding
%                 cuSize                  ->  CU size
% OutPut :
%                 rcY                     ->  Reconstructed Y Samples of CU
%                 rcY                     ->  Reconstructed UV Samples of CU
%                 cuBits                  ->  Encoded Bitstream
%%

function [rcY, rcUV, cuBits] = Encode_CU(cbOrigYSamples, cbOrigUVSamples, pL_Y, pL_UV, pU_Y, pU_UV,...
                                                    leftMode,upMode,bestModeY,cuSize)
global QP QPc minCuSize

% if(cuSize == 64)
%     tuSize = 32;
%     lumaTbSize = tuSize;
% else
tuSize = cuSize; %     tuSize = cuSize;
lumaTbSize = tuSize; %=tuSize
chromaTbSize = cuSize/2;

    
% rcY = int16(zeros(lumaTbSize,lumaTbSize)-1);
% rcUV = cbOrigUVSamples;  %JUST NOW till add Chroma 

cuBits =[];
% CABAC encode part_mode%  % for now part_mode is 2Nx2N
% ctxIdx is always 0 for part_mode in Intra Frames
if(cuSize == minCuSize)
    tmpbits = CabacEncode('part_mode', '2Nx2N', 0);
    cuBits = [cuBits tmpbits];
end

% [pLS_Y, pUS_Y, pLS_UV, pUS_UV] = ReferenceSubstitution(pL_Y, pU_Y, lumaTbSize, 1, pL_UV, pU_UV);
% [pLSF_Y, pUSF_Y] = ReferenceSmoothing(lumaTbSize, pLS_Y, pUS_Y);
% 
% if(bestModeY ==0)
%     predictedSamplesY = Planar_Model(lumaTbSize,pLSF_Y,pUSF_Y);
% elseif(bestModeY ==1)
%     predictedSamplesY = DC_Model(lumaTbSize,pLS_Y,pUS_Y,'luma');
% else
%     predictedSamplesY_ = Intra_Angular_Model(bestModeY, pLS_Y, pUS_Y, lumaTbSize, 'luma', pLSF_Y, pUSF_Y);
%     predictedSamplesY = predictedSamplesY_{bestModeY-1};
% end
% 
% residualY = cbOrigYSamples-predictedSamplesY;
% 
% 
% if(lumaTbSize == 64) % split t0 4 32x32 Tb
%     [ M_Mat, Quant_Mat] = GetTables(32);
%     for b32 = 0:3
%         x =  mod(b32,2)*32 + 1;
%         y = (b32>1)*32 + 1;
%         transCoeffsY(y:y+31, x:x+31) = HEVC_Transformation( 8, M_Mat, residualY(y:y+31, x:x+31) );
%         quantTransCoeffsY(y:y+31, x:x+31) = HEVC_Quantization( transCoeffsY(y:y+31, x:x+31), Quant_Mat , QP, 8 );
%         invQuantY = HEVC_InvQuant(quantTransCoeffsY(y:y+31, x:x+31),Quant_Mat, QP, 8);
%         invQuantTransY(y:y+31, x:x+31) = HEVC_InvScaling(invQuantY, M_Mat, 8);
%     end
% else
%     [ M_Mat, Quant_Mat] = GetTables(lumaTbSize);
%     transCoeffsY = HEVC_Transformation( 8, M_Mat, residualY );
%     quantTransCoeffsY = HEVC_Quantization( transCoeffsY, Quant_Mat , QP, 8 );
%     invQuantY = HEVC_InvQuant(quantTransCoeffsY,Quant_Mat, QP, 8);
%     invQuantTransY = HEVC_InvScaling(invQuantY, M_Mat, 8);
% end

%% For Chroma
bestModeUV = 1;

predictedSamplesUV_DC(:,:,1) = Planar_Model(chromaTbSize,pLS_UV(:,1),pUS_UV(:,1));
predictedSamplesUV_DC(:,:,2) = Planar_Model(chromaTbSize,pLS_UV(:,2),pUS_UV(:,2));
residualUV(1,1) = {cbOrigUVSamples(:,:,1)-predictedSamplesUV_DC(:,:,1)};
residualUV(1,2) = {cbOrigUVSamples(:,:,2)-predictedSamplesUV_DC(:,:,2)};

[ M_Mat, Quant_Mat] = GetTables(chromaTbSize);
transCoeffsU = HEVC_Transformation( 8, M_Mat, residualUV{1,1} );
quantTransCoeffsU = HEVC_Quantization( transCoeffsU, Quant_Mat , QPc, 8 );
invQuantU = HEVC_InvQuant(quantTransCoeffsU ,Quant_Mat, QPc, 8);
invQuantTransU = HEVC_InvScaling(invQuantU, M_Mat, 8);
transCoeffsV = HEVC_Transformation( 8, M_Mat, residualUV{1,2} );
quantTransCoeffsV = HEVC_Quantization( transCoeffsV, Quant_Mat , QPc, 8 );
invQuantV = HEVC_InvQuant(quantTransCoeffsV ,Quant_Mat, QPc, 8);
invQuantTransV = HEVC_InvScaling(invQuantV, M_Mat, 8);






%% Coding Modes - CABAC functions
encModeBits = IntraModeCoding(bestModeY,bestModeUV,leftMode,upMode); 
cuBits = [cuBits encModeBits];



%% new for 64x64
% trafoDepth = 0; %p:128
% trafoDepth= 5 - log2(cuSize/tuSize); %p:247
% tmpbits = CabacEncode('split_transform_flag',1 , trafoDepth);
% cuBits = [cuBits tmpbits];


%% Coding Coeffs chroma for 64x64
trafoDepth = log2(cuSize/tuSize); %p:247

if(nnz(quantTransCoeffsU)==0)
    tmpBits = CabacEncode('cbf_cb',0,trafoDepth);
else
    tmpBits = CabacEncode('cbf_cb',1,trafoDepth);
end
cuBits = [cuBits tmpBits];

if(nnz(quantTransCoeffsV)==0)
    tmpBits = CabacEncode('cbf_cr',0,trafoDepth);
else
    tmpBits = CabacEncode('cbf_cr',1,trafoDepth);
end
cuBits = [cuBits tmpBits];


%% Split to 4block size 32x32
tuSize = 32;
chromaTbSize = 16;
lumaTbSize =32;
for b32 = 0:3
    x = mod(b32,2)*32 + 1;
    y = (b32>1)*32 + 1;
    xUV = (x-1)/2 + 1;
    yUV = (y-1)/2 + 1;
    
    % Chromas
    trafoDepth = log2(cuSize/tuSize); %p:247
    if(nnz(quantTransCoeffsU(yUV:yUV+15, xUV:xUV+15))==0)
        tmpBits = CabacEncode('cbf_cb',0,trafoDepth);
    else
        tmpBits = CabacEncode('cbf_cb',1,trafoDepth);
    end
    cuBits = [cuBits tmpBits];

    if(nnz(quantTransCoeffsV(yUV:yUV+15, xUV:xUV+15))==0)
        tmpBits = CabacEncode('cbf_cr',0,trafoDepth);
    else
        tmpBits = CabacEncode('cbf_cr',1,trafoDepth);
    end
    cuBits = [cuBits tmpBits];
    
    %Luma
    pL_Y32 = (zeros(65,1)-1);
    pU_Y32 = (zeros(65,1)-1);
    
    if(x == 1)
        pL_Y32 = pL_Y(y:y+64);
    else
        if(y == 33)    % the down-right block
            pL_Y32(2:33) = cbOrigYSamples(y:y+31, x-1);
        else           % the up-right block
            pL_Y32(2:65) = cbOrigYSamples(y:y+63, x-1);
        end
        if(y ~= 1)
            pL_Y32(1) = cbOrigYSamples(y-1, x-1);
        else
            pL_Y32(1) = pU_Y(y);
        end 
    end
    if(y == 1)
        pU_Y32 = pU_Y(x:x+64);
    else
        if(x == 33)    % the down-right block
            pU_Y32(2:33) = cbOrigYSamples(y-1,x-1:x+31);
        else
            pU_Y32(2:65) = cbOrigYSamples(y-1,x:x+63);
        end
        if(x ~= 1)
            pU_Y32(1) = cbOrigYSamples(y-1, x-1);
        else
            pU_Y32(1) = pL_Y(x);
        end   
    end
    
    [pLS_Y, pUS_Y, pLS_UV, pUS_UV] = ReferenceSubstitution(pL_Y32, pU_Y32, lumaTbSize, 1, pL_UV32, pU_UV32);
    [pLSF_Y, pUSF_Y] = ReferenceSmoothing(lumaTbSize, pLS_Y32, pUS_Y32);

    if(bestModeY ==0)
        predictedSamplesY = Planar_Model(lumaTbSize,pLSF_Y,pUSF_Y);
    elseif(bestModeY ==1)
        predictedSamplesY = DC_Model(lumaTbSize,pLS_Y,pUS_Y,'luma');
    else
        predictedSamplesY_ = Intra_Angular_Model(bestModeY, pLS_Y, pUS_Y, lumaTbSize, 'luma', pLSF_Y, pUSF_Y);
        predictedSamplesY = predictedSamplesY_{bestModeY-1};
    end
    residualY = cbOrigYSamples(y:y+31, x:x+31)-predictedSamplesY;
    [ M_Mat, Quant_Mat] = GetTables(lumaTbSize);
    transCoeffsY = HEVC_Transformation( 8, M_Mat, residualY );
    quantTransCoeffsY = HEVC_Quantization( transCoeffsY, Quant_Mat , QP, 8 );
    invQuantY = HEVC_InvQuant(quantTransCoeffsY,Quant_Mat, QP, 8);
    invQuantTransY = HEVC_InvScaling(invQuantY, M_Mat, 8);
    
    mdcs = 'diagonal';
    ctxIdx=0;
    if(nnz(quantTransCoeffsY)==0)
         tmpBits = CabacEncode('cbf_luma',0,ctxIdx);
         cuBits = [cuBits tmpBits];
    else
         tmpBits = CabacEncode('cbf_luma',1,ctxIdx);
         cuBits = [cuBits tmpBits];
         tuBits = Encode_TU(quantTransCoeffsY,mdcs,0);
         cuBits = [cuBits tuBits];
    end
    
    if(nnz(quantTransCoeffsU(yUV:yUV+15, xUV:xUV+15))~=0)
         tuBits = Encode_TU(quantTransCoeffsU(yUV:yUV+15, xUV:xUV+15),mdcs,1);
         cuBits = [cuBits tuBits];
    end
    if(nnz(quantTransCoeffsV(yUV:yUV+15, xUV:xUV+15))~=0)
         tuBits = Encode_TU(quantTransCoeffsV(yUV:yUV+15, xUV:xUV+15),mdcs,2);
         cuBits = [cuBits tuBits];
    end

end
% if(nnz(quantTransCoeffsU)~=0)
%      tuBits = Encode_TU(quantTransCoeffsU,mdcs,1);
%      cuBits = [cuBits tuBits];
% end
% if(nnz(quantTransCoeffsV)~=0)
%      tuBits = Encode_TU(quantTransCoeffsV,mdcs,2);
%      cuBits = [cuBits tuBits];
% end  
    
% if(lumaTbSize==4 || lumaTbSize==8)
%      if(bestModeY<=5 || (bestModeY>=15 && bestModeY<=21) || bestModeY>=31)
%          mdcs = 'diagonal';         % Mode Dependent Coefficient Scan
%      elseif(bestModeY>=6 && bestModeY<=14)
%          mdcs = 'vertical';
%      else       % 22 to 30
%          mdcs = 'horizontal';
%      end
% else
%     mdcs = 'diagonal';
% end
% 
%  
% if(trafoDepth==0)
%     ctxIdx=1;
% else
%     ctxIdx=0;
% end
%  
%  
% if(nnz(quantTransCoeffsY)==0)
%      tmpBits = CabacEncode('cbf_luma',0,ctxIdx);
%      cuBits = [cuBits tmpBits];
% else
%      tmpBits = CabacEncode('cbf_luma',1,ctxIdx);
%      cuBits = [cuBits tmpBits];
%      tuBits = Encode_TU(quantTransCoeffsY,mdcs,0);
%      cuBits = [cuBits tuBits];
% end
%  
% if(chromaTbSize==4)
%      if(bestModeUV<=5 || (bestModeUV>=15 && bestModeUV<=21) || bestModeUV>=31)
%          mdcs = 'diagonal';         % Mode Dependent Coefficient Scan
%      elseif(bestModeUV>=6 && bestModeUV<=14)
%          mdcs = 'vertical';
%      else       % 22 to 30
%          mdcs = 'horizontal';
%      end
% else
%      mdcs = 'diagonal';
% end
% if(nnz(quantTransCoeffsU)~=0)
%      tuBits = Encode_TU(quantTransCoeffsU,mdcs,1);
%      cuBits = [cuBits tuBits];
% end
% if(nnz(quantTransCoeffsV)~=0)
%      tuBits = Encode_TU(quantTransCoeffsV,mdcs,2);
%      cuBits = [cuBits tuBits];
% end

 
%% Reconstrocted
rcY = double(uint8(invQuantTransY + predictedSamplesY));
rcUV(:,:,1) = double(uint8(invQuantTransU + predictedSamplesUV_DC(:,:,1)));
rcUV(:,:,2) = double(uint8(invQuantTransV + predictedSamplesUV_DC(:,:,2)));

    
end
 