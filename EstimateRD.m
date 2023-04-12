% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved
% compelete



%%
% Gets CTU pixels and neighbors to find modes based on SAD and RDO
% Input : 
%                 origYSamples8         ->  Original Y samples of block8x8
%                 pL                    ->  Left Neighbours
%                 pU                    ->  Top Neighbours
%                 candidate             ->  candidate modes for current block
%                 mpm                   ->  MPM of current block
%                 nTbS                  ->  block size
% OutPut :
%                 bestMode              ->  The Best selected mode based on RDO
%                 bestCost              ->  The cost of selected mode
%                 rcSamples             ->  Reconstructed block based on the bestMode
%%


function [bestMode, bestCost, rcSamples] = EstimateRD(origSamples,pL,pU,candidate,mpm,nTbS)

global QP minCuSize rdoRateFactor

[pLS, pUS] = ReferenceSubstitution(pL, pU, nTbS, 0);
[pLSF, pUSF] = ReferenceSmoothing(nTbS,pLS,pUS);

if(candidate(1) == 0 || candidate(2) == 0 || candidate(3) == 0)
    predictedSamples_Planar = Planar_Model(nTbS,pLSF,pUSF);
    residual(1) = {origSamples-predictedSamples_Planar};
end

if(candidate(1) == 1 || candidate(2) == 1 || candidate(3) == 1)
    predictedSamples_DC = DC_Model(nTbS,pLS,pUS,'luma');
    residual(2) = {origSamples-predictedSamples_DC};
end


candidateAngModes = candidate(candidate~=0 & candidate~=1);
predictedSamples_Angular = Intra_Angular_Model(candidateAngModes, pLS, pUS, nTbS, 'luma', pLSF, pUSF);


for i = 1:length(candidateAngModes)
    i = candidateAngModes(i);
% for i = candidateAngModes
    residual(i+1) = {origSamples - predictedSamples_Angular{i-1}};
end

[ M_Mat, Quant_Mat] = GetTables(nTbS);
initRate =0;
if(nTbS == minCuSize)
    initRate = initRate+1;    
end

% for i = 1:length(candidate)
%     i = candidate(i);
bestCost = inf;
for i = 1:length(candidate)
    i = candidate(i);
    transCoeffs = HEVC_Transformation( 8, M_Mat, residual{i+1});
    [quantTransCoeffs, dist] = HEVC_Quantization( transCoeffs, Quant_Mat , QP, 8);
    rate = initRate;
    if(i == mpm(1))     % 1 bin for prev_intra_luma_pred_flag & 1 bin for mpm(1)
        rate = rate + 2; 
    elseif(i == mpm(2) || i == mpm(3)) % 1 bin for prev_intra_luma_pred_flag & 2 bin for mpm(2 or 3)
        rate = rate + 3;
    else            % 1 bin for prev_intra_luma_pred_flag & 5 bin for rem_intra_luma_pred_flag
        rate = rate + 6;
    end
    rate = rate +1;     % 1 bin for coding block flag
    if(nnz(quantTransCoeffs)~=0)
        if(nTbS==4 || nTbS==8)
            if(i<=5 || (i>=15 && i<=21) || i>=31)
                mdcs = 'diagonal';         
            elseif(i >=6 && i<=14)
                mdcs = 'vertical';
            else       % 22 to 30
                mdcs = 'horizontal';
            end
        else
             mdcs = 'diagonal';
        end
        tuRate = EstimateTuRate(quantTransCoeffs,mdcs);
        rate = rate + tuRate;
    end
    cost = rdoRateFactor*rate + dist;
    if(cost < bestCost)
        bestMode = i ;
        bestCost = cost;
    end
end
invQuant = HEVC_InvQuant(quantTransCoeffs,Quant_Mat, QP, 8);
invQuantTrans = HEVC_InvScaling(invQuant, M_Mat, 8);
if(bestMode==0)
     rcSamples = int16(uint8(invQuantTrans + predictedSamples_Planar));
elseif(bestMode==1)
     rcSamples = int16(uint8(invQuantTrans + predictedSamples_DC));
else
     rcSamples = int16(uint8(invQuantTrans + predictedSamples_Angular{bestMode-1}));%bestMode-1
end

end

