% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved

% compeleted

%%
% Gets frame pixels and divded them into CTUs & also finde the neighbors
% Input : 
%                 Y         ->   Luma Samples of frame
%                 UV        ->  Chroma Samples of frame
% OutPuts :
%                 rcY       ->  reconstructed Luma Samples of frame
%                 rcUV      -> reconstructed Chroma Samples of frame
%                 seqBits   ->  encoded Bitstream of current frame
%%


function [rcY, rcUV, seqBits] = Encode_I_Frame(Y,UV)

Y = double(Y);
UV = double(UV);

global h w ctuSize ctbSizeY ctbSizeUV minTuSize minCuSize contextTables rangeTabLps stateTransIdx

cnt = 1;
ctbSizeY = ctuSize;
ctbSizeUV= ctuSize/2;
numOfTuInCtuWidth = ctuSize/minTuSize;
numOfCuInCtuWidth = ctuSize/minCuSize;
rcY = (zeros(h,w)-1);
rcUV= (zeros(h/2,w/2,2)-1);
picWidthInCtbY = w/ctuSize;
picHeightInCtbY = h/ctuSize;
seqBits=[];
leftCtuPrevIntraModes = zeros(1,numOfTuInCtuWidth) + 1;      % Intra_DC mode -- Default
downCtbDepthsBuffer = zeros(picWidthInCtbY,numOfCuInCtuWidth)-1; 

% CABAC Initialization %
load contextTables.mat;
load rangeTabLps.mat 
load stateTransIdx.mat
CabacInitialization();

upAvailableFlag =0;
leftAvailableFlag =0;
upRightAvailableFlag =0;
leftDownAvailableFlag =0;

%% CTU level loop 
for y = 1:ctuSize:h
    for x = 1:ctuSize:w
        xUV = (x-1)/2 + 1;
        yUV = (y-1)/2 + 1;
        currCtbOrigYSamples = Y(y:y+ctbSizeY-1,x:x+ctbSizeY-1);
        currCtbOrigUVSamples= UV(yUV:yUV+ctbSizeUV-1,xUV:xUV+ctbSizeUV-1,:);
        yCtbY = (y-1)/ctbSizeY;
        xCtbY = (x-1)/ctbSizeY;
        
        upRcNbsY = (zeros(2*ctbSizeY+1,1)-1);        % up neighbours
        upRcNbsUV = (zeros(2*ctbSizeUV+1,2)-1);
        upOrigNbsY = (zeros(2*ctbSizeY+1,1)-1);        
        leftRcNbsY = (zeros(2*ctbSizeY+1,1)-1);        % left neighbours
        leftRcNbsUV = (zeros(2*ctbSizeUV+1,2)-1);
        leftOrigNbsY = (zeros(2*ctbSizeY+1,1)-1);        
        
        if(yCtbY == 0)     % up CTUs
            upAvailableFlag = 0;
            upCtDepths = zeros(1,numOfCuInCtuWidth)-1;
        else
            upAvailableFlag = 1;
            upRcNbsY(2:ctbSizeY+1) = rcY(y-1,x:x+ctbSizeY-1);   % up samples
            upRcNbsUV(2:ctbSizeUV+1,:) = rcUV(yUV-1,xUV:xUV+ctbSizeUV-1,:);
            upOrigNbsY(2:ctbSizeY+1) = Y(y-1,x:x+ctbSizeY-1);
            upCtDepths = downCtbDepthsBuffer((x-1)/ctuSize+1,:);
            if(xCtbY==picWidthInCtbY-1)           % right ctbs
                upRightAvailableFlag = 0;
            else
                upRightAvailableFlag = 1;       % up-right is available
                upRcNbsY(ctbSizeY+2:2*ctbSizeY+1) = rcY(y-1,x+ctbSizeY:x+2*ctbSizeY-1);
                upOrigNbsY(ctbSizeY+2:2*ctbSizeY+1) = Y(y-1,x+ctbSizeY:x+2*ctbSizeY-1);
                upRcNbsUV(ctbSizeUV+2:2*ctbSizeUV+1,:) = rcUV(yUV-1,xUV+ctbSizeUV:xUV+2*ctbSizeUV-1,:); 
            end
        end    
        
        if(xCtbY == 0)     % left CTUs
            leftAvailableFlag = 0;
            leftCtuPrevIntraModes = zeros(1,numOfTuInCtuWidth) + 1;      % Intra_DC mode
            leftCtDepths = zeros(1,numOfCuInCtuWidth)-1;
        else
            leftAvailableFlag = 1;
            leftRcNbsY(2:ctbSizeY+1) = rcY(y:y+ctbSizeY-1,x-1);   % left samples
            leftOrigNbsY(2:ctbSizeY+1) = Y(y:y+ctbSizeY-1,x-1);
            leftRcNbsUV(2:ctbSizeUV+1,:) = rcUV(yUV:yUV+ctbSizeUV-1,xUV-1,:);
            
            if(yCtbY==picHeightInCtbY-1)               % down ctbs
                leftDownAvailableFlag = 0;
            else
                leftDownAvailableFlag = 1;           % left-down is available
                leftRcNbsY(ctbSizeY+2:2*ctbSizeY+1) = rcY(y+ctbSizeY:y+2*ctbSizeY-1,x-1);
                leftOrigNbsY(ctbSizeY+2:2*ctbSizeY+1) = Y(y+ctbSizeY:y+2*ctbSizeY-1,x-1);
                leftRcNbsUV(ctbSizeUV+2:2*ctbSizeUV+1,:) = rcUV(yUV+ctbSizeUV:yUV+2*ctbSizeUV-1,xUV-1,:);
            end
        end         
        if(leftAvailableFlag && upAvailableFlag)       % up-left sample
             leftRcNbsY(1)=rcY(y-1,x-1);
             leftOrigNbsY(1)=Y(y-1,x-1);
             upRcNbsY(1)=rcY(y-1,x-1);
             upOrigNbsY(1)=Y(y-1,x-1);
             leftRcNbsUV(1,:)=rcUV(yUV-1,xUV-1,:);
             upRcNbsUV(1,:)=rcUV(yUV-1,xUV-1,:);
        end
                 
        [rcY(y:y+ctbSizeY-1,x:x+ctbSizeY-1), rcUV(yUV:yUV+ctbSizeUV-1,xUV:xUV+ctbSizeUV-1,:), ctuBits,rightCtuCurrIntraModes,...
                                                rightCtDepths, downCtDepths] = Encode_CTU(currCtbOrigYSamples, currCtbOrigUVSamples,...
                                                                                          leftRcNbsY,leftRcNbsUV, upRcNbsY,upRcNbsUV,...
                                                                                          leftOrigNbsY,upOrigNbsY,leftCtuPrevIntraModes,...
                                                                                          leftCtDepths,upCtDepths);
        cnt = cnt+1;
        %% 9812 here check the end of frame
        if((xCtbY == picWidthInCtbY-1) && (yCtbY == picHeightInCtbY-1))
            endFlagBits = CabacEncode('end_of_slice_segment_flag', 1);
        else
            endFlagBits = CabacEncode('end_of_slice_segment_flag', 0);
        end
        
        
        seqBits = [seqBits ctuBits endFlagBits];
        leftCtuPrevIntraModes = rightCtuCurrIntraModes;
        downCtbDepthsBuffer((x-1)/ctuSize+1,:) = downCtDepths;
        leftCtDepths = rightCtDepths;
    end
end
end