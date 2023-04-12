% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved
% compelete

%%
% Gets Candidate and Select #numOfRdoCandidates Modes based on SAD values
% Input : 
%                 origSamples           ->  Original Y samples of block8x8
%                 pL                    ->  Original Left Neighbours
%                 pU                    ->  Original Up Neighbours
%                 inList                ->  Input candidates modes
%                 nTbs                  ->  CU size
%                 numOfRdoCandidates    ->  number of modes to select
% OutPut :
%                 candidates            ->  sorted Best Intra mod based on SAD
%%


function candidates = SADcandidates(origSamples, pL, pU, inList, nTbS, numOfRdoCandidates)

[pLS, pUS] = ReferenceSubstitution(pL, pU, nTbS, 0);
[pLSF, pUSF] = ReferenceSmoothing(nTbS,pLS,pUS);

if(nnz(inList==0))
    predictedSamples_Planar = Planar_Model(nTbS,pLSF,pUSF);
    residual(1) = {origSamples-predictedSamples_Planar};
end

if(nnz(inList==1))
    predictedSamples_DC = DC_Model(nTbS,pLS,pUS,'luma');
    residual(2) = {origSamples-predictedSamples_DC};
end

candidateAngModes = inList(inList~=0 & inList~=1);
predictedSamples_Angular = Intra_Angular_Model(candidateAngModes, pLS, pUS, nTbS, 'luma', pLSF, pUSF);
for i = 1:length(candidateAngModes)
    i = candidateAngModes(i);
    residual(i+1) = {origSamples-predictedSamples_Angular{i-1}};
end

for i = 1:length(inList)
    SAD(i) = sum(sum(abs(residual{inList(i)+1})));
end
[temp, order] = sort(SAD);
candidates = inList(order);
candidates = candidates(1:numOfRdoCandidates);

end

