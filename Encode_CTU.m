% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved
%  

%%
% this function contains all predictions and mode selection and encode ctu
% Input : 
%                 ctbOrigYSamples       ->   Original Luma Samples of current CTU
%                 ctbOrigUVSamples      ->   Original chroma Samples of current CTU
%                 leftRcNbsY            ->   left neighbours of the reconstructed luma samples of current CTU , used for prediction
%                 leftRcNbsUV           ->   left neighbours of the reconstructed chroma samples of current CTU , used for prediction
%                 upRcNbsY              ->   upper neighbours of the reconstructed luma samples of current CTU , used for prediction
%                 upRcNbsUV             ->   upper neighbours of the reconstructed chroma samples of current CTU , used for prediction
%                 leftOrigNbsY          ->   left neighbours of the Original luma samples of current CTU
%                 upOrigNbsY            ->   up neighbours of the Original luma samples of current CTU
%                 leftCtuIntraModes     ->   intra modes of the left CTU used for intra mode coding
%                 leftCtDepths          ->   left coding tree dephts used for context selection for split_cu_flag
%                 upCtDepths            ->   upper coding tree dephts used for context selection for split_cu_flag
% OutPuts :
%                 rcY                   ->  reconstructed Luma samples of current CTU
%                 rcUV                  ->  reconstructed Chroma Samples of current CTU
%                 ctuBits               ->  encoded Bitstream of current CTU
%                 currCtuIntraModes     ->  intra modes of the TUs placed on the right side of the current CTU
%                 rightCtDepths         ->  coding tree dephts of the right samplesof current CTU used for context selection for split_cu_flag
%                 downCtDepths          ->  coding tree dephts of the down samplesof current CTU used for context selection for split_cu_flag
%%

function [rcY, rcUV, ctuBits, currIntraModes, rightCtDepths, downCtDepths] = Encode_CTU(ctbOrigYSamples,...
                                      ctbOrigUVSamples, leftRcNbsY, leftRcNbsUV, upRcNbsY, upRcNbsUV,...
                                      leftOrigNbsY, upOrigNbsY, leftCtuIntraModes, leftCtDepths, upCtDepths)

global ctuSize ctbSizeY ctbSizeUV minTuSize minCuSize 
% global numOfRdoCandidates8x8 numOfRdoCandidates16x16 numOfRdoCandidates32x32 rdoRateFactor 
% global numofSadCandidates16x16 numofSadCandidates32x32

ctbSizeY = ctuSize;
ctbSizeUV = ctuSize/2;
numOfTuInCtuWidth = ctuSize/minTuSize;
numOfCuInCtuWidth = ctuSize/minCuSize;
ctuBits =[];

%% Analazing    %9812
if(ctuSize == 32)
    b16Max = 3;
else                %ctuSize=16
    b16Max = 0;
end
rcY = (zeros(ctuSize,ctuSize)-1);
rcUV = (zeros(ctbSizeUV,ctbSizeUV,2)-1);
% rcLocalY = (zeros(ctuSize,ctuSize)-1); 
localModes = (zeros(numOfTuInCtuWidth,numOfTuInCtuWidth)-1); 
localCtDepths = (zeros(numOfCuInCtuWidth,numOfCuInCtuWidth)-1);
% splitcuFlag = [];
splitcuFlag = 0;
%% for 64x64 block
% if(ctuSize == 64)
%     for b32 = 0:3
%         x = mod(b32,2)*32 + 1;
%         y = (b32>1)*32 + 1;
%         leftRcNbY32 = (zeros(65,1)-1);   
%         leftRcNbY32 = (zeros(65,1))-1;
%         
%         leftOrigNbY32 = (zeros(65,1))-1;
%         upOrigNbY32 = (zeros(65,1))-1;
%         
%         ctbOrigYSamples32 = ctbOrigYSamples(y:y+31, x:x+31);
%         
%         if(x == 1)              % first column block and should fill the parameters from rec
%             leftRcNbY32 = leftRcNbsY(y:y+64);
%             leftOrigNbY32 = leftOrigNbsY(y:y+64);
%             leftMode = leftCtuIntraModes((y-1)/minTuSize+1);
%         else
%             leftMode = localModes((y-1)/minTuSize+1, ((x-1)/minTuSize));
%             if(y == ctuSize-32+1)    % the downest block(s)
%                 leftRcNbY32(2:33) = rcLocalY(y:y+31, x-1);
%                 leftOrigNbY32(2:33) = ctbOrigYSamples(y:y+31, x-1);
%             else
%                 leftRcNbY32(2:65) = rcLocalY(y:y+63, x-1);
%                 leftOrigNbY32(2:65) = ctbOrigYSamples(y:y+63, x-1);
%             end
%             if(y ~= 1)      % the up-left neighbour pix is in current ctu
%                 leftRcNbY32(1) = rcLocalY(y-1, x-1);
%                 leftOrigNbY32(1) = ctbOrigYSamples(y-1, x-1);
%             else            % is in the previous predicted 
%                 leftRcNbY32(1) = upRcNbsY(x);
%                 leftOrigNbY32(1) = upOrigNbsY(x);
%             end   
%         end
%         if(y == 1)              % first row block and should fill the parameters from rec
%             leftRcNbY32 = upRcNbsY(x:x+64);
%             upOrigNbY32 = upOrigNbsY(x:x+64);
%             upMode = 1;         % DC
%         else
%             upMode = localModes(((y-1)/minTuSize), (x-1)/minTuSize+1);
%             if(x == ctuSize-32+1)    % the right block(s)
%                 leftRcNbY32(2:33) = rcLocalY(y-1,x:x+31);
%                 upOrigNbY32(2:33) = ctbOrigYSamples(y-1,x:x+31);
%             else
%                 leftRcNbY32(2:65) = rcLocalY(y-1,x:x+63);
%                 upOrigNbY32(2:65) = ctbOrigYSamples(y-1,x:x+63);
%             end
%             if(x ~= 1)
%                 leftRcNbY32(1) = rcLocalY(y-1, x-1);
%                 upOrigNbY32(1) = ctbOrigYSamples(y-1, x-1);
%             else
%                 leftRcNbY32(1) = leftRcNbsY(y);
%                 upOrigNbY32(1) = leftOrigNbsY(x);
%             end   
%         end
%         
%         [bestMode32, bestCost32, rcSamples32] = EstimateRD(ctbOrigYSamples32,leftRcNbY32,upRcNbsY32,1,1,32);
%         
%         rcLocalY(y:y+31, x:x+31) = rcSamples32;
%     end
% 
%     localModes(:,:) = 1;
%     localCtDepths(:,:) = 0;
%   
% end


rightCtDepths = localCtDepths(:,numOfCuInCtuWidth);
downCtDepths = localCtDepths(numOfCuInCtuWidth,:);

%% Encodeing
currIntraModes = localModes(1:numOfTuInCtuWidth,numOfTuInCtuWidth);

ctxInc = (leftCtDepths(1)>localCtDepths(1,1)) + (upCtDepths(1)>localCtDepths(1,1)); %p:248
ctxIdx = ctxInc + 0;
tmpbits = CabacEncode('split_cu_flag', 0, ctxIdx);
ctuBits = [ctuBits tmpbits];
leftMode = leftCtuIntraModes(1);%leftCtuIntraModes(1)
upMode = 1;

bestModeY = 1;

[rcY, rcUV, cuBits] = Encode_CU(ctbOrigYSamples,ctbOrigUVSamples,leftRcNbsY,leftRcNbsUV,upRcNbsY,upRcNbsUV,...
                                    leftMode,upMode,bestModeY,ctuSize);
ctuBits = [ctuBits cuBits];



end
%% prev
% [rcY, rcUV, cuBits, cuIntraMode] = Encode_CU(ctbOrigYSamples,ctbOrigUVSamples,leftRcNbsY,leftRcNbsUV,upRcNbsY,upRcNbsUV,...
%                                 upAvailableFlag,leftAvailableFlag,upRightAvailableFlag,leftDownAvailableFlag,...
%                                 currCuSize,leftCuPrevIntraMode,upCuPrevIntraMode);
%                             
% currCtuIntraModes = zeros(1,numOfTuInCtuWidth) + cuIntraMode;      % Intra_DC mode
% ctuBits=[ctuBits cuBits];
