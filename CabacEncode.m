% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved

%%
% This function encodes the input syntax element and forms the bit-stream based on CABAC
% Inputs :  
%           seType      ->  the type of the syntax element
%           se          ->  the input syntax element
%           ctxIdx      ->  context index must be used for encoding the current syntax element (some of them are specified inside of this function)
%           parameter   ->  a parameter used for cabac encoding
%           cIdx        ->  determines the input component 'luma' or 'chroma
% Outputs:
%           bitStream   ->  encoded bit-stream
%%
function bitStream = CabacEncode(seType, se, ctxIdx, parameter, cIdx)
%     global bitCntr seCntr;
    
    switch seType
        case 'split_cu_flag'
            binVals = Binarization(se,'FL',1);
            ctxTable = 1;
            bypassFlag = 0;
        case 'part_mode'
            if(se == "2Nx2N")    
                binVals = '1';
            else
                binVals = '0';  
            end
            ctxTable = 2;
            bypassFlag = 0;
        case 'prev_intra_luma_pred_flag'
            binVals = Binarization(se,'FL',1);
            ctxTable = 3;
            bypassFlag = 0;
        case 'mpm_idx'
            binVals = Binarization(se,'TrU',2);
            bypassFlag = 1;
        case 'rem_intra_luma_pred_mode'
            binVals = Binarization(se,'FL',5);
            bypassFlag = 1;
        case 'intra_chroma_pred_mode'
            binVals = se;       % this syntax element is already binarized in IntraModeCoding function
            ctxTable = 4;
            bypassFlag = 1;     % 1st bit is regular and 2nd and 3rd bits are bypassed
        case 'split_transform_flag'
            binVals = Binarization(se,'FL',1);
            ctxTable = 5;
            bypassFlag = 0;
        case 'cbf_luma'
            binVals = Binarization(se,'FL',1);
            ctxTable = 6;
            bypassFlag = 0;
        case 'cbf_cb'
            binVals = Binarization(se,'FL',1);
            ctxTable = 7;
            bypassFlag = 0;
        case 'cbf_cr'
            binVals = Binarization(se,'FL',1);
            ctxTable = 7;
            bypassFlag = 0;
        case 'last_sig_coeff_x_prefix'
            binVals = Binarization(se,'TrU',2*parameter-1);
            ctxTable = 8;
            bypassFlag = 0;
        case 'last_sig_coeff_y_prefix'
            binVals = Binarization(se,'TrU',2*parameter-1);
            ctxTable = 9;
            bypassFlag = 0;
        case 'last_sig_coeff_x_suffix'
            binVals = Binarization(se,'FL',parameter);
            bypassFlag = 1;
        case 'last_sig_coeff_y_suffix'
            binVals = Binarization(se,'FL',parameter);
            bypassFlag = 1;
        case 'coded_sub_block_flag'
            binVals = Binarization(se,'FL',1);
            ctxTable = 10;
            bypassFlag = 0;
        case 'sig_coeff_flag'
            binVals = Binarization(se,'FL',1);
            ctxTable = 11;
            bypassFlag = 0;
        case 'coeff_abs_level_greater1_flag'
            binVals = Binarization(se,'FL',1);
            ctxTable = 12;
            bypassFlag = 0;
        case 'coeff_abs_level_greater2_flag'
            binVals = Binarization(se,'FL',1);
            ctxTable = 13;
            bypassFlag = 0;
        case 'coeff_abs_level_remaining'
            binVals = Binarization(se,'Rem',parameter);
            bypassFlag = 1;
        case 'coeff_sign_flag'
            binVals = Binarization(se,'FL',1);
            bypassFlag = 1;
        case 'end_of_slice_segment_flag'
            binVals = Binarization(se,'FL',1);
            bypassFlag = 0;
            ctxTable = 0;
            ctxIdx = 0;
    end
    
    bitStream = [];
    binNum = length(binVals);
%     bin2dec(flip(binVals));
    for binIdx=1:binNum
        binVal = bin2dec(binVals(binIdx));
        switch seType
            case {'last_sig_coeff_x_prefix','last_sig_coeff_y_prefix'}
                if(cIdx==0)     % luma
                    ctxOffset = 3*(parameter-2)+floor((parameter-1)/4);
                    ctxShift = floor((parameter+1)/4);
                else
                    ctxOffset = 15;
                    ctxShift = parameter-2;
                end
                ctxInc = floor((binIdx-1)/(2^ctxShift))+ctxOffset;
                ctxIdx = ctxInc+0;
        end
             
        if(binIdx==1 && strcmp(seType,'intra_chroma_pred_mode'))
            bits = EncodeDecision(binVal,ctxTable,ctxIdx+1);
        else
            if(bypassFlag)
                bits = EncodeBypass(binVal);
            elseif(ctxTable==0 && ctxIdx==0)
                bits = EncodeTerminate(binVal);
            else
                bits = EncodeDecision(binVal,ctxTable,ctxIdx+1);
            end
        end
        bitStream = [bitStream bits];
    end
%     bitCntr = bitCntr + length(bitStream);
%     if(bitCntr>=2660)
%        bitCntr = bitCntr ;
%     end
%     seCntr = seCntr + 1;
end


%%
% This function is for regular cabac encoding
% Inputs :
%           binVal      ->  a single input bin shoud be encoded
%           ctxTable    ->  the context table must be used
%           ctxIdx      ->  the context index must be used
% Outputs:
%           bits        ->  the output bit sequence
%%
function bits = EncodeDecision(binVal,ctxTable,ctxIdx)

    global ivlLow ivlCurrRange binCountsInNalUnits contextTables rangeTabLps stateTransIdx
    
    pStateIdx = contextTables{ctxTable}(2,ctxIdx);
    valMps = contextTables{ctxTable}(3,ctxIdx);
    qRangeIdx = bitand(bitsrl(ivlCurrRange,6),3);
    ivlLpsRange = rangeTabLps(pStateIdx+1,qRangeIdx+1);
    ivlMpsRange = ivlCurrRange-ivlLpsRange;
    if(binVal ~= valMps)
        ivlLow = ivlLow + ivlMpsRange;
        ivlCurrRange = ivlLpsRange;
    else
        ivlCurrRange = ivlMpsRange;
    end    
    %%% state transition %%%
    if(binVal == valMps)
        pStateIdx = stateTransIdx(2,pStateIdx+1);     % 2nd row of the transition table represents MPS
    else
        if(pStateIdx == 0)
            valMps = 1-valMps;
        end
        pStateIdx = stateTransIdx(1,pStateIdx+1);     % 1st row of the transition table represents LPS
    end    
    %%%% update table %%%%
    contextTables{ctxTable}(2,ctxIdx) = pStateIdx;
    contextTables{ctxTable}(3,ctxIdx) = valMps;
    
    bits = Renormalization();
    binCountsInNalUnits = binCountsInNalUnits+1;
end

%%
% This function is for bypassed cabac encoding
% Inputs :
%           binVal -> a single input bin shoud be encoded
% Outputs:
%           bits   -> the output bit sequence
%%
function bits = EncodeBypass(binVal)

    global ivlLow ivlCurrRange bitsOutstanding binCountsInNalUnits
    
    ivlLow = ivlLow*2;
    if(binVal ~= 0)
        ivlLow = ivlLow + ivlCurrRange;
    end
    if(ivlLow>=1024)
        bits = PutBit(1);
        ivlLow = ivlLow-1024;
    elseif(ivlLow<512)
        bits = PutBit(0);
    else
        bits = [];
        ivlLow = ivlLow-512;
        bitsOutstanding = bitsOutstanding+1;
    end
    binCountsInNalUnits = binCountsInNalUnits+1;        
end

%%
% This function is for terminate cabac encoding
% Inputs :
%           binVal -> a single input bin shoud be encoded
% Outputs:
%           bits   -> the output bit sequence
%%
function bits = EncodeTerminate(binVal)

    global ivlLow ivlCurrRange binCountsInNalUnits
    
    ivlCurrRange = ivlCurrRange-2;
    if(binVal == 1)
        ivlLow = ivlLow + ivlCurrRange;
        bits = EncodeFlush();
    else
        bits = Renormalization();
    end
    binCountsInNalUnits = binCountsInNalUnits+1;
end

%% 
% The rest of the functions are some sub-functions used in the process of CABAC encoding
%%
function bits = EncodeFlush()

    global ivlLow ivlCurrRange
    
    bits = [];
    ivlCurrRange = 2;
    tmpBits = Renormalization();
    bits = [bits tmpBits];
    tmpBits = PutBit(bitand((bitsrl(ivlLow,9)),1));
    bits = [bits tmpBits];
    tmpBits = dec2bin((bitand((bitsrl(ivlLow,7)),3))~=0);
    bits = [bits tmpBits];
%     bits = [bits '1'];  this is the stop bit and handled in the main
end

function bits = Renormalization()

    global ivlLow ivlCurrRange bitsOutstanding
    bits = [];
    
    while(ivlCurrRange<256)
        if(ivlLow<256)
            tmpBits = PutBit(0);
        elseif(ivlLow>=512)
            ivlLow = ivlLow-512;
            tmpBits = PutBit(1);
        else
            tmpBits = [];
            ivlLow = ivlLow-256;
            bitsOutstanding = bitsOutstanding+1;
        end
        ivlCurrRange = ivlCurrRange*2;
        ivlLow = ivlLow*2;
        bits = [bits tmpBits];       
    end
end

function bits = PutBit(B)
    
    global firstBitFlag bitsOutstanding
    bits = [];
    
    if(firstBitFlag ~= 0)
        firstBitFlag = 0;
    else
        bits = [bits dec2bin(B)];
    end
    while(bitsOutstanding>0)
        bits = [bits dec2bin(1-B)];
        bitsOutstanding = bitsOutstanding-1;
    end
%     test=[test,length(bits)];
end