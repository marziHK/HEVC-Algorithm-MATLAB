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

tuSize = cuSize;
lumaTbSize = tuSize;
if(lumaTbSize == 4)
    chromaTbSize = tuSize;
else
    chromaTbSize = tuSize/2;
end
    
% rcY = int16(zeros(lumaTbSize,lumaTbSize)-1);
% rcUV = cbOrigUVSamples;  %JUST NOW till add Chroma 

cuBits =[];
% CABAC encode part_mode%  % for now part_mode is 2Nx2N
% ctxIdx is always 0 for part_mode in Intra Frames
if(cuSize == minCuSize)
    tmpbits = CabacEncode('part_mode', '2Nx2N', 0);
    cuBits = [cuBits tmpbits];
end

[pLS_Y, pUS_Y, pLS_UV, pUS_UV] = ReferenceSubstitution(pL_Y, pU_Y, lumaTbSize, 1, pL_UV, pU_UV);
[pLSF_Y, pUSF_Y] = ReferenceSmoothing(lumaTbSize, pLS_Y, pUS_Y);

if(bestModeY ==0)
    predictedSamplesY = Planar_Model(lumaTbSize,pLSF_Y,pUSF_Y);
elseif(bestModeY ==1)
    predictedSamplesY = DC_Model(lumaTbSize,pLS_Y,pUS_Y,'luma');
else
    predictedSamplesY_ = Intra_Angular_Model(pLS_Y, pUS_Y, pLSF_Y, pUSF_Y, lumaTbSize, bestModeY);
    predictedSamplesY = predictedSamplesY_{bestModeY-1};
end

residualY = cbOrigYSamples-predictedSamplesY;

[ M_Mat, Quant_Mat] = GetTables(lumaTbSize);
transCoeffsY = HEVC_Transformation( 8, M_Mat, residualY );
quantTransCoeffsY = HEVC_Quantization( transCoeffsY, Quant_Mat , QP, 8 );
invQuantY = HEVC_InvQuant(quantTransCoeffsY,Quant_Mat, QP, 8);
invQuantTransY = HEVC_InvScaling(invQuantY, M_Mat, 8);


%% For Chroma
% for i=1:2
%     maxJ = 4;
%     predictedSamplesUV_Planar(:,:,i) = Planar_Model(chromaTbSize,pLS_UV(:,i),pUS_UV(:,i));
%     predictedSamplesUV_DC(:,:,i) = DC_Model(chromaTbSize,pLS_UV(:,i),pUS_UV(:,i),'chroma');
%     predictedSamplesUV_Angular10(:,:,i) = Intra_Angular_Model(10, pLS_UV(:,i), pUS_UV(:,i), chromaTbSize, 'chroma');
%     predictedSamplesUV_Angular26(:,:,i) = Intra_Angular_Model(26, pLS_UV(:,i), pUS_UV(:,i), chromaTbSize, 'chroma');
%     if(bestModeY ==0 || bestModeY==1 || bestModeY==10 || bestModeY==26)
%         predictedSamplesUV_Angular34(:,:,i) = Intra_Angular_Model(34, pLS_UV(:,i), pUS_UV(:,i), chromaTbSize, 'chroma');
%         residualUV(5,i) = {cbOrigUVSamples(:,:,i)- predictedSamplesUV_Angular34{1,i}};
%         maxJ=5;
%     end
%     residualUV(1,i) = {cbOrigUVSamples(:,:,i)-predictedSamplesUV_Planar(:,:,i)};
%     residualUV(2,i) = {cbOrigUVSamples(:,:,i)-predictedSamplesUV_DC(:,:,i)};
%     residualUV(3,i) = {cbOrigUVSamples(:,:,i)-predictedSamplesUV_Angular10(:,:,i)};
%     residualUV(4,i) =
%     {cbOrigUVSamples(:,:,i)-predictedSamplesUV_Angular26(:,:,i)};%{1,i}
% end
% 
% bestSAD = inf;
% for j=1:maxJ
%     currSAD = sum(sum(abs(residualUV{j,1}))) + sum(sum(abs(residualUV{j,2})));
%     if(currSAD < bestSAD)
%        bestSAD = currSAD;
%        bestIdxUV=j;
%        if(j<3)
%           bestModeUV = j-1;
%        elseif(j==3)
%            bestModeUV = 10;
%        elseif(j==4)
%            bestModeUV = 26;
%        else
%            bestModeUV = 34;
%        end
%     end
% end

bestModeUV = 26;
predictedSamplesUV_Angular10(:,:,1) = Intra_Angular_Model(pLS_UV(:,1), pUS_UV(:,1),pLS_UV(:,1), pUS_UV(:,1), chromaTbSize, 26);
predictedSamplesUV_Angular10(:,:,2) = Intra_Angular_Model(pLS_UV(:,2), pUS_UV(:,2),pLS_UV(:,2), pUS_UV(:,2), chromaTbSize, 26);
residualUV(1,1) = {cbOrigUVSamples(:,:,1)-double(predictedSamplesUV_Angular10{:,:,1})};
residualUV(1,2) = {cbOrigUVSamples(:,:,2)-double(predictedSamplesUV_Angular10{:,:,2})};

% predictedSamplesUV_DC(:,:,1) = Planar_Model(chromaTbSize,pLS_UV(:,1),pUS_UV(:,1));
% predictedSamplesUV_DC(:,:,2) = Planar_Model(chromaTbSize,pLS_UV(:,2),pUS_UV(:,2));
% predictedSamplesUV_DC(:,:,1) = DC_Model(chromaTbSize,pLS_UV(:,1),pUS_UV(:,1),'chroma');
% predictedSamplesUV_DC(:,:,2) = DC_Model(chromaTbSize,pLS_UV(:,2),pUS_UV(:,2),'chroma');
% residualUV(1,1) = {cbOrigUVSamples(:,:,1)-predictedSamplesUV_DC{:,:,1}};
% residualUV(1,2) = {cbOrigUVSamples(:,:,2)-predictedSamplesUV_DC{:,:,2}};

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

%% Coding Coeffs
 trafoDepth = log2(cuSize/tuSize); %p:247
 
 if(trafoDepth==0)
     ctxIdx=1;
 else
     ctxIdx=0;
 end
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
  
 if(lumaTbSize==4 || lumaTbSize==8)
     if(bestModeY<=5 || (bestModeY>=15 && bestModeY<=21) || bestModeY>=31)
         mdcs = 'diagonal';         % Mode Dependent Coefficient Scan
     elseif(bestModeY>=6 && bestModeY<=14)
         mdcs = 'vertical';
     else       % 22 to 30
         mdcs = 'horizontal';
     end
 else
     mdcs = 'diagonal';
 end
 if(nnz(quantTransCoeffsY)==0)
     tmpBits = CabacEncode('cbf_luma',0,ctxIdx);
     cuBits = [cuBits tmpBits];
 else
     tmpBits = CabacEncode('cbf_luma',1,ctxIdx);
     cuBits = [cuBits tmpBits];
     tuBits = Encode_TU(quantTransCoeffsY,mdcs,0);
     cuBits = [cuBits tuBits];
 end


 if(chromaTbSize==4)
     if(bestModeUV<=5 || (bestModeUV>=15 && bestModeUV<=21) || bestModeUV>=31)
         mdcs = 'diagonal';         % Mode Dependent Coefficient Scan
     elseif(bestModeUV>=6 && bestModeUV<=14)
         mdcs = 'vertical';
     else       % 22 to 30
         mdcs = 'horizontal';
     end
 else
     mdcs = 'diagonal';
 end
 if(nnz(quantTransCoeffsU)~=0)
     tuBits = Encode_TU(quantTransCoeffsU,mdcs,1);
     cuBits = [cuBits tuBits];
 end
 if(nnz(quantTransCoeffsV)~=0)
     tuBits = Encode_TU(quantTransCoeffsV,mdcs,2);
     cuBits = [cuBits tuBits];
 end

 
%% Reconstrocted
rcY = double(uint8(invQuantTransY + predictedSamplesY));


rcUV(:,:,1) = double(uint8(invQuantTransU + double(predictedSamplesUV_Angular10{:,:,1})));
rcUV(:,:,2) = double(uint8(invQuantTransV + double(predictedSamplesUV_Angular10{:,:,2})));


a = predictedSamplesUV_Angular10(:,:,1);
b = predictedSamplesUV_Angular10(:,:,2);

% rcUV(:,:,1) = double(uint8(invQuantTransU + predictedSamplesUV_DC(:,:,1)));
% rcUV(:,:,2) = double(uint8(invQuantTransV + predictedSamplesUV_DC(:,:,2)));

% if(bestModeUV==0)
%     rcUV(:,:,1) = double(uint8(invQuantTransU + predictedSamplesUV_Planar(:,:,1)));
%     rcUV(:,:,2) = double(uint8(invQuantTransV + predictedSamplesUV_Planar(:,:,2)));
% elseif(bestModeUV==1)
%     rcUV(:,:,1) = double(uint8(invQuantTransU + predictedSamplesUV_DC(:,:,1)));
%     rcUV(:,:,2) = double(uint8(invQuantTransV + predictedSamplesUV_DC(:,:,2)));
% elseif(bestModeUV==10)
%     rcUV(:,:,1) = double(uint8(invQuantTransU + predictedSamplesUV_Angular10{1,1}));
%     rcUV(:,:,2) = double(uint8(invQuantTransV + predictedSamplesUV_Angular10{1,2}));
% elseif(bestModeUV==26)
%     rcUV(:,:,1) = double(uint8(invQuantTransU + predictedSamplesUV_Angular26{1,1}));
%     rcUV(:,:,2) = double(uint8(invQuantTransV + predictedSamplesUV_Angular26{1,2}));
% elseif(bestModeUV==34)
%     rcUV(:,:,1) = double(uint8(invQuantTransU + predictedSamplesUV_Angular34{1,1}));
%     rcUV(:,:,2) = double(uint8(invQuantTransV + predictedSamplesUV_Angular34{1,2}));
% end
    
end
 