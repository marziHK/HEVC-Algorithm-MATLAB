% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved
% compelete

%%
% Gets CTU pixels and neighbors to find modes based on SAD and RDO
% Input : 
%                 origYSamples8         ->  Original Y samples of block8x8
%                 pL                    ->  Original Left Neighbours
%                 pU                    ->  Original Up Neighbours
% OutPut :
%                 ranklist              ->  sorted Best Intra mod based on SAD
%%

function ranklist = Analyse8x8(origYSamples,pL,pU)

global numofSadCandidates QP rdoRateFactor rankListSize 

[pLS, pUS] = ReferenceSubstitution(pL, pU, 8, 0);
[pLSF, pUSF] = ReferenceSmoothing(8,pLS,pUS);
% Smoothing is just for planar,2,18,34 for 8x8

% Here should check the modes and sort them 

candidateAngModes = 2:2:34;    % even modes


predictedSamples_Planar = Planar_Model(8,pLSF,pUSF);
predictedSamples_DC = DC_Model(8,pLS,pUS,'luma');
predictedSamples_Angular = Intra_Angular_Model(candidateAngModes, pLS, pUS, 8, 'luma', pLSF, pUSF);

residual(1) = {origYSamples-predictedSamples_Planar};
residual(2) = {origYSamples-predictedSamples_DC};


for i = candidateAngModes
   residual(i+1) = {origYSamples-predictedSamples_Angular{i-1}};
end

candidateModes = [1 2 candidateAngModes+1];

topSAD = zeros(2, numofSadCandidates);  %1st SAD, 2nd #mode
topSAD(1,:) = inf;
for i = candidateModes               % in this loop find modes with best SAD
    currSAD = sum(sum(abs(residual{i})));
    for j=1:numofSadCandidates
        if(currSAD < topSAD(1,j))
           for z= numofSadCandidates:-1:j+1
               topSAD(:,z) = topSAD(:,z-1);
           end
           topSAD(1,j) = currSAD;
           topSAD(2,j) = i-1;
           break;
        end
    end

end


%% Find modes based-on RDO
[ M_Mat, Quant_Mat] = GetTables(8);
topRDO = zeros(2, numofSadCandidates);  %1st , 2nd #mode
topRDO(1,:) = inf;
for i = topSAD(2,:)
    transCoeffs = HEVC_Transformation( 8, M_Mat, residual{i+1});
    [quantTransCoeffs, dist] = HEVC_Quantization( transCoeffs, Quant_Mat , QP, 8 );
    rate =0;
    if(nnz(quantTransCoeffs)~=0)
        if(i<=5 || (i>=15 && i<=21) || i>=31)
            mdcs = 'diagonal';        
        elseif(i>=6 && i<=14)
            mdcs = 'vertical';
        else       % 22 to 30
            mdcs = 'horizontal';
        end
        tuRate = EstimateTuRate(quantTransCoeffs,mdcs);
        rate = rate + tuRate;
    end    
    currCost = rdoRateFactor*rate + dist;
    for j=1:numofSadCandidates
        if( currCost < topRDO(1,j))
           for k= numofSadCandidates:-1:j+1
               topRDO(:,k) = topRDO(:,k-1);
           end
           topRDO(1,j) = currCost;
           topRDO(2,j) = i;
           break;
        end
    end
end


%% check if even modes needs to add in ranklist
SortedModes = sort(topRDO(2,:),'descend');
candidateOdd = [];
for i =1:numofSadCandidates-1
    if((abs(SortedModes(i)-SortedModes(i+1))== 2) && (SortedModes(i)>=2) && (SortedModes(i+1)>=2))
        candidateOdd = [candidateOdd (SortedModes(i)+SortedModes(i+1))/2];
    end
end

ranklist = zeros(1,rankListSize)-1;
ranklist(1:numofSadCandidates) = SortedModes;
if(~isempty(candidateOdd))
    for i = candidateOdd
       a = find(ranklist ==(i-1));
       b = find(ranklist ==(i+1));
       if(a<b)
           j=b;
       else
           j=a;
       end
       for k=rankListSize:-1:j+1
           ranklist(k) = ranklist(k-1);
       end
       ranklist(j) = i;
    end
end


%% return a sorted array with size between 8-15
% to omit -1 values in ranklist
% ranklist = nnz(ranklist>=0);


end     %End of Function