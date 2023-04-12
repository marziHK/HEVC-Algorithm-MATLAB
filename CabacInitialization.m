% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved

%%
% This function initializes the parameters and context tables of the CABAC engine
%%

function CabacInitialization()

global QP contextTables
global ivlLow ivlCurrRange firstBitFlag bitsOutstanding binCountsInNalUnits

ivlLow = uint16(0);
ivlCurrRange = uint16(510);
firstBitFlag = 1; 
bitsOutstanding = 0;
binCountsInNalUnits = 0;

%%%% ctxIdx for different syntax elements %%%%
% --- split_cu_flag                    1 --- %
% --- part_mode                        2 --- %
% --- prev_intra_luma_pred_flag        3 --- %
% --- intra_chroma_pred_mode           4 --- %
% --- split_transform_flag             5 --- %
% --- cbf_luma                         6 --- %
% --- cbf_cb/cbf_cr                    7 --- %
% --- last_sig_coeff_x_prefix          8 --- %
% --- last_sig_coeff_y_prefix          9 --- %
% --- coded_sub_block_flag            10 --- %
% --- sig_coeff_flag                  11 --- %
% --- coeff_abs_level_greater1_flag   12 --- %
% --- coeff_abs_level_greater2_flag   13 --- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load contextTables.mat;
for i=1:13
    contextVariable = contextTables{i};
    l = size(contextVariable,2);
    for ctxIdx=1:l
        initValue = contextVariable(1,ctxIdx);
        slopeIdx = int16(bitsrl(initValue,4));
        offsetIdx = int16(bitand(initValue,15));
        m = slopeIdx*5-45;
        n = offsetIdx*8-16;
        a = bitsra(m*QP,4)+n;
        if(a<1)
            preCtxState = 1;
        elseif(a>126)
            preCtxState = 126;
        else
            preCtxState = a;
        end
        if(preCtxState<=63)
            valMps = 0;
        else
            valMps = 1;
        end
        if(valMps==1)
            pStateIdx = preCtxState-64;
        else
            pStateIdx = 63-preCtxState;
        end
        contextVariable(2,ctxIdx) = pStateIdx;
        contextVariable(3,ctxIdx) = valMps;
    end
    contextTables{i}(2:3,:)=contextVariable(2:3,:);
end
