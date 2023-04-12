% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved

%% 
% This function encodes the residual of a TU
% Inputs :
%           coeffs      ->  input QDCT coefficients
%           scanType    ->  type of the scaning ("diogonal" , "vertical" , "horizontal")
%           cIdx        ->  the component index ("luma" is 0 and "chroma"s are 1 and 2)
% Outputs:
%           bitStream   ->  output encoded bit-stream
%%

function bitStream = Encode_TU(coeffs,scanType,cIdx)
                
global cLastAbsLevel cLastRiceParam
bitStream = [];
tbSize = size(coeffs,1);
subBlkSize = 4;
subBlkScanOrder = ScanOrderArrayInitialization(subBlkSize,scanType);
blkSize = tbSize/subBlkSize;
blkScanOrder = ScanOrderArrayInitialization(blkSize,scanType);
lastSubBlock = blkSize*blkSize-1;
lastScanPos = 15;
while(1)    
    xS = blkScanOrder(lastSubBlock+1,1);
    yS = blkScanOrder(lastSubBlock+1,2);
    xC = (xS*4)+subBlkScanOrder(lastScanPos+1,1);
    yC = (yS*4)+subBlkScanOrder(lastScanPos+1,2);
    if(coeffs(yC+1,xC+1)~=0)
        lastSignificantCoeffX=xC;
        lastSignificantCoeffY=yC;
        break;
    end
    if(lastScanPos==0)
        lastScanPos=15;
        lastSubBlock=lastSubBlock-1;
    else
        lastScanPos=lastScanPos-1;
    end
end
%% determining the last_sig_coeffs %%
if(strcmp(scanType,'vertical'))     % swap if vertical scanType
    tmp = lastSignificantCoeffX;
    lastSignificantCoeffX = lastSignificantCoeffY;
    lastSignificantCoeffY = tmp;
end

if(lastSignificantCoeffX<4)
    last_sig_coeff_x_prefix = lastSignificantCoeffX;
    xSuffixPresentFlag = 0;
elseif(lastSignificantCoeffX==4 || lastSignificantCoeffX==5)
    last_sig_coeff_x_prefix = 4;
    xSuffixPresentFlag = 1;
    last_sig_coeff_x_suffix = mod(lastSignificantCoeffX,2);
elseif(lastSignificantCoeffX==6 || lastSignificantCoeffX==7)
    last_sig_coeff_x_prefix = 5;
    xSuffixPresentFlag = 1;
    last_sig_coeff_x_suffix = mod(lastSignificantCoeffX,2);
elseif(lastSignificantCoeffX>=8 && lastSignificantCoeffX<12)
    last_sig_coeff_x_prefix = 6;
    xSuffixPresentFlag = 1;
    last_sig_coeff_x_suffix = mod(lastSignificantCoeffX,4);
elseif(lastSignificantCoeffX>=12 && lastSignificantCoeffX<16)
    last_sig_coeff_x_prefix = 7;
    xSuffixPresentFlag = 1;
    last_sig_coeff_x_suffix = mod(lastSignificantCoeffX,4);
elseif(lastSignificantCoeffX>=16 && lastSignificantCoeffX<24)
    last_sig_coeff_x_prefix = 8;
    xSuffixPresentFlag = 1;
    last_sig_coeff_x_suffix = mod(lastSignificantCoeffX,8);
elseif(lastSignificantCoeffX>=24 && lastSignificantCoeffX<32)
    last_sig_coeff_x_prefix = 9;
    xSuffixPresentFlag = 1;
    last_sig_coeff_x_suffix = mod(lastSignificantCoeffX,8);
else
    error('last_sig_coeff_x');
end

if(lastSignificantCoeffY<4)
    last_sig_coeff_y_prefix = lastSignificantCoeffY;
    ySuffixPresentFlag = 0;
elseif(lastSignificantCoeffY==4 || lastSignificantCoeffY==5)
    last_sig_coeff_y_prefix = 4;
    ySuffixPresentFlag = 1;
    last_sig_coeff_y_suffix = mod(lastSignificantCoeffY,2);
elseif(lastSignificantCoeffY==6 || lastSignificantCoeffY==7)
    last_sig_coeff_y_prefix = 5;
    ySuffixPresentFlag = 1;
    last_sig_coeff_y_suffix = mod(lastSignificantCoeffY,2);
elseif(lastSignificantCoeffY>=8 && lastSignificantCoeffY<12)
    last_sig_coeff_y_prefix = 6;
    ySuffixPresentFlag = 1;
    last_sig_coeff_y_suffix = mod(lastSignificantCoeffY,4);
elseif(lastSignificantCoeffY>=12 && lastSignificantCoeffY<16)
    last_sig_coeff_y_prefix = 7;
    ySuffixPresentFlag = 1;
    last_sig_coeff_y_suffix = mod(lastSignificantCoeffY,4);
elseif(lastSignificantCoeffY>=16 && lastSignificantCoeffY<24)
    last_sig_coeff_y_prefix = 8;
    ySuffixPresentFlag = 1;
    last_sig_coeff_y_suffix = mod(lastSignificantCoeffY,8);
elseif(lastSignificantCoeffY>=24 && lastSignificantCoeffY<32)
    last_sig_coeff_y_prefix = 9;
    ySuffixPresentFlag = 1;
    last_sig_coeff_y_suffix = mod(lastSignificantCoeffY,8);
else
    error('last_sig_coeff_y');
end

tmpBits = CabacEncode('last_sig_coeff_x_prefix',last_sig_coeff_x_prefix,0,log2(tbSize),cIdx);
bitStream = [bitStream tmpBits];
tmpBits = CabacEncode('last_sig_coeff_y_prefix',last_sig_coeff_y_prefix,0,log2(tbSize),cIdx);
bitStream = [bitStream tmpBits];
if(xSuffixPresentFlag)
    binNum = floor(last_sig_coeff_x_prefix/2)-1;
    tmpBits = CabacEncode('last_sig_coeff_x_suffix',last_sig_coeff_x_suffix,0,binNum);
    bitStream = [bitStream tmpBits];
end
if(ySuffixPresentFlag)
    binNum = floor(last_sig_coeff_y_prefix/2)-1;
    tmpBits = CabacEncode('last_sig_coeff_y_suffix',last_sig_coeff_y_suffix,0,binNum);
    bitStream = [bitStream tmpBits];
end

if(strcmp(scanType,'vertical'))     % return to their original values
    tmp = lastSignificantCoeffX;
    lastSignificantCoeffX = lastSignificantCoeffY;
    lastSignificantCoeffY = tmp;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

coded_sub_block_flag = zeros(blkSize,blkSize);
lastGreater1Ctx = -1;
for i=lastSubBlock:-1:0
    xS = blkScanOrder(i+1,1);
    yS = blkScanOrder(i+1,2);
%% determining the coded_sub_block_flag %%
    inferSbDcSigCoeffFlag=0;
    coded_sub_block_flag(yS+1,xS+1)=1;    
    if((i<lastSubBlock) && (i>0))   %% CSBF of the lastSubBlock and DCblock are inferred to be 1
        inferSbDcSigCoeffFlag=1;
        xC=xS*4;
        yC=yS*4;
        coded_sub_block_flag(yS+1,xS+1)=0;
        for x=xC+1:xC+4
            for y=yC+1:yC+4
                if(coeffs(y,x)~=0)
                    coded_sub_block_flag(yS+1,xS+1)=1;
                    break;
                end
            end
            if(coded_sub_block_flag(yS+1,xS+1))
                break;
            end
        end
        %%% determining ctxIdx %%%
        csbfCtx=0;
        if(xS < ((2^(log2(tbSize)-2))-1))
            csbfCtx = csbfCtx + coded_sub_block_flag(yS+1,xS+1+1);
        end
        if(yS < ((2^(log2(tbSize)-2))-1))
            csbfCtx = csbfCtx + coded_sub_block_flag(yS+1+1,xS+1);
        end
        if(cIdx==0)
            ctxInc = min(csbfCtx,1);
        else
            ctxInc = 2 + min(csbfCtx,1);
        end
        ctxIdx = ctxInc + 0;
        tmpBits = CabacEncode('coded_sub_block_flag',coded_sub_block_flag(yS+1,xS+1),ctxIdx);
        bitStream = [bitStream tmpBits];
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% determining the sig_coeff_flags %%
    sig_coeff_flag = zeros(1,16);   % in case of inferrence all the coefficients are 0 except the DC one
    sig_coeff_flag(1) = 1;          % in case of inferrence it is 1 and otherwise it is going to be set
    if(i==lastSubBlock)
        N=lastScanPos-1;
        sig_coeff_flag(lastScanPos+1)=1;
    else
        N=15;
    end
    if(coded_sub_block_flag(yS+1,xS+1))
        for n=N:-1:0
            xC = xS*4 + subBlkScanOrder(n+1,1);
            yC = yS*4 + subBlkScanOrder(n+1,2);
            if((n>0) || (~inferSbDcSigCoeffFlag))
                if(coeffs(yC+1,xC+1)~=0)
                    sig_coeff_flag(n+1)=1;
                    inferSbDcSigCoeffFlag=0;
                else
                    sig_coeff_flag(n+1)=0;
                end
                %%% determining ctxIdx %%%
                if(tbSize==4)
                    load ctxIdxMap.mat
                    sigCtx = ctxIdxMap(yC*4+xC+1);
                elseif(xC+yC==0)
                    sigCtx = 0;
                else
                    prevCsbf = 0;
                    if(xS < ((2^(log2(tbSize)-2))-1))
                        prevCsbf = prevCsbf + coded_sub_block_flag(yS+1,xS+1+1);
                    end
                    if(yS < ((2^(log2(tbSize)-2))-1))
                        prevCsbf = prevCsbf + 2*coded_sub_block_flag(yS+1+1,xS+1);
                    end
                    xP = subBlkScanOrder(n+1,1);
                    yP = subBlkScanOrder(n+1,2);
                    if(prevCsbf==0)
                        if(xP+yP==0)
                           sigCtx = 2;
                        elseif(xP+yP<3)
                           sigCtx = 1;
                        else
                           sigCtx = 0;
                        end
                    elseif(prevCsbf==1)
                        if(yP==0)
                           sigCtx = 2;
                        elseif(yP==1)
                           sigCtx = 1;
                        else
                           sigCtx = 0;
                        end
                    elseif(prevCsbf==2)
                        if(xP==0)
                           sigCtx = 2;
                        elseif(xP==1)
                           sigCtx = 1;
                        else
                           sigCtx = 0;
                        end
                    else
                        assert(prevCsbf==3);
                        sigCtx = 2;
                    end
                    if(cIdx==0)
                        if(xS+yS>0)
                            sigCtx = sigCtx+3;
                        end
                        if(tbSize==8)
                            if(strcmp(scanType,'diagonal'))
                                sigCtx = sigCtx+9;
                            else
                                sigCtx = sigCtx+15;
                            end
                        else
                            sigCtx = sigCtx+21;
                        end
                    else
                        if(tbSize==8)
                            sigCtx = sigCtx+9;
                        else
                            sigCtx = sigCtx+12;
                        end
                    end
                end
                if(cIdx==0)
                    ctxInc = sigCtx;
                else
                    ctxInc = sigCtx + 27;
                end
                ctxIdx = ctxInc+0;
                tmpBits = CabacEncode('sig_coeff_flag',sig_coeff_flag(n+1),ctxIdx);
                bitStream = [bitStream tmpBits];
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% determining coeff_abs_level_greater1_flag %%
        lastSigScanPos=-1;
        numGreater1Flag=0;
        lastGreater1ScanPos=-1;
        coeff_abs_level_greater2_flag=0;
        coeff_abs_level_remaining=zeros(1,16);
        coeff_abs_level_remaining_present_flag=zeros(1,16);
        baseLevel=zeros(1,16);
        firstTimeFlag=1;
        for n=15:-1:0
            baseLevel(n+1)=1;
            remBaseLevelConstraint=1;
            xC = xS*4 + subBlkScanOrder(n+1,1);
            yC = yS*4 + subBlkScanOrder(n+1,2);
            if(sig_coeff_flag(n+1))
                if(numGreater1Flag<8)
                    remBaseLevelConstraint=remBaseLevelConstraint+1;
                    numGreater1Flag=numGreater1Flag+1;
                    if(abs(coeffs(yC+1,xC+1))>1)
                        coeff_abs_level_greater1_flag=1;
                        baseLevel(n+1)=baseLevel(n+1)+1;
                    else
                        coeff_abs_level_greater1_flag=0;
                    end
                    %%% determining the ctxIdx %%%
                    if(firstTimeFlag)
                        firstTimeFlag=0;
                        if(i==0 || cIdx>0)
                            ctxSet=0;
                        else
                            ctxSet=2;
                        end
                        if(lastGreater1Ctx == -1)   % for 1st sub-block
                            lastGreater1Ctx=1;
                        else
                            if(lastGreater1Ctx>0)
                                lastGreater1Flag = prev_coeff_abs_level_greater1_flag;
                                if(lastGreater1Flag==1)
                                    lastGreater1Ctx=0;
                                else
                                    lastGreater1Ctx = lastGreater1Ctx+1;
                                end
                            end
                        end
                        if(lastGreater1Ctx==0)
                            ctxSet = ctxSet+1;
                        end
                        greater1Ctx = 1;
                    else
                        ctxSet = prevCtxSet;
                        greater1Ctx = lastGreater1Ctx;
                        if(greater1Ctx>0)
                            lastGreater1Flag = prev_coeff_abs_level_greater1_flag;
                            if(lastGreater1Flag==1)
                                greater1Ctx=0;
                            else
                                greater1Ctx = greater1Ctx+1;
                            end
                        end
                    end
                    lastGreater1Ctx = greater1Ctx;
                    prev_coeff_abs_level_greater1_flag = coeff_abs_level_greater1_flag;
                    prevCtxSet = ctxSet;
                    ctxInc = (ctxSet*4) + min(3,greater1Ctx);
                    if(cIdx>0)
                        ctxInc = ctxInc + 16;
                    end
                    ctxIdx = ctxInc+0;
                    tmpBits = CabacEncode('coeff_abs_level_greater1_flag',coeff_abs_level_greater1_flag,ctxIdx);
                    bitStream = [bitStream tmpBits];
                    if(coeff_abs_level_greater1_flag && (lastGreater1ScanPos==-1))
                        remBaseLevelConstraint=remBaseLevelConstraint+1;
                        lastGreater1ScanPos=n;
                        if(abs(coeffs(yC+1,xC+1))>2)
                            coeff_abs_level_greater2_flag=1;
                            baseLevel(n+1)=baseLevel(n+1)+1;
                        else
                            coeff_abs_level_greater2_flag=0;
                        end
                    end
                end
                if(lastSigScanPos==-1)
                    lastSigScanPos=n;
                end
                
                if(remBaseLevelConstraint==baseLevel(n+1))
                    coeff_abs_level_remaining_present_flag(n+1)=1;
                    coeff_abs_level_remaining(n+1)=abs(coeffs(yC+1,xC+1))-baseLevel(n+1);
                end
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% determining coeff_abs_level_greater2_flag %%
        if(lastGreater1ScanPos ~= -1)
            ctxInc = ctxSet;
            if(cIdx>0)
                ctxInc = ctxInc+4;
            end
            ctxIdx = ctxInc+0;
            tmpBits = CabacEncode('coeff_abs_level_greater2_flag',coeff_abs_level_greater2_flag,ctxIdx);
            bitStream = [bitStream tmpBits];
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% determining coeff_sign_flags %%
        for n=15:-1:0
            xC = xS*4 + subBlkScanOrder(n+1,1);
            yC = yS*4 + subBlkScanOrder(n+1,2);
            if(sig_coeff_flag(n+1))
                assert(sign(coeffs(yC+1,xC+1))~=0);
                if(sign(coeffs(yC+1,xC+1))==1)
                    coeff_sign_flags=0;
                else
                    coeff_sign_flags=1;
                end
                tmpBits = CabacEncode('coeff_sign_flag',coeff_sign_flags,0);
                bitStream = [bitStream tmpBits];
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% determining coeff_abs_level_remaining %%
        firstTimeFlag=1;
        for n=15:-1:0
            if(sig_coeff_flag(n+1))
                if(coeff_abs_level_remaining_present_flag(n+1))
                    if(firstTimeFlag)
                        cLastAbsLevel=0;
                        cLastRiceParam=0;
                        tmpBits = CabacEncode('coeff_abs_level_remaining',coeff_abs_level_remaining(n+1),0,baseLevel(n+1));
                        bitStream = [bitStream tmpBits];
                        firstTimeFlag=0;
                    else
                        tmpBits = CabacEncode('coeff_abs_level_remaining',coeff_abs_level_remaining(n+1),0,baseLevel(n+1));
                        bitStream = [bitStream tmpBits];
                    end
                end
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    end
end



end




%%
% This function determines the x and y of a squared 2D array based on the scanType in order
% Inputs :
%           size      ->  size of the array
%           scanType  ->  type of the scaning ("diogonal" , "vertical" , "horizontal")
% Outputs:
%           scanOrder ->  its 1st column is x and 2nd is y
%%
function scanOrder = ScanOrderArrayInitialization(size,scanType)

switch scanType
    case 'diagonal'
        i=0;
        x=0;
        y=0;
        stopLoopFlag=0;
        while(~stopLoopFlag)
            while(y>=0)
                if(x<size && y<size)
                    scanOrder(i+1,1)=x;
                    scanOrder(i+1,2)=y;
                    i=i+1;
                end
                y=y-1;
                x=x+1;
            end
            y=x;
            x=0;
            if(i>=size*size)
                stopLoopFlag=1;
            end
        end
    case 'horizontal'
        i=0;
        for y=0:size-1
            for x=0:size-1
                scanOrder(i+1,1)=x;
                scanOrder(i+1,2)=y;
                i=i+1;
            end
        end
    case 'vertical'
        i=0;
        for x=0:size-1
            for y=0:size-1
                scanOrder(i+1,1)=x;
                scanOrder(i+1,2)=y;
                i=i+1;
            end
        end
end
end