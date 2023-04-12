function encModeBits = IntraModeCoding(currModeY,currModeUV,leftMode,upMode)

%%%%%%%% Luma Coding %%%%%%%    %%%%p150-632
if(leftMode==upMode)
    if(leftMode<2)
        candModeList(1) = 0;    %planar
        candModeList(2) = 1;    %DC
        candModeList(3) = 26;   %vertical
    else
        candModeList(1) = leftMode;
        candModeList(2) = 2 + (mod((leftMode+29),32));
        candModeList(3) = 2 + (mod((leftMode- 1),32));
    end
else
    candModeList(1) = leftMode;
    candModeList(2) = upMode;
    if(leftMode~=0 && upMode~=0)
        candModeList(3) = 0;
    elseif(leftMode~=1 && upMode~=1)
        candModeList(3) = 1;
    else
        candModeList(3) = 26;
    end
end

%%  if 'prev_intra_luma_pred_flag'==1 the pred mode is in MPM, else should code 'rem_intra_luma_pred_mode'
prev_intra_luma_pred_flag = 0; 
for i=1:3
    if(currModeY == candModeList(i))   
        prev_intra_luma_pred_flag = 1;
        mpm_idx = i-1;
        break;
    end
end
encModeBits = [];
tmpBits = CabacEncode('prev_intra_luma_pred_flag', prev_intra_luma_pred_flag, 0);
encModeBits = [encModeBits tmpBits];
if(prev_intra_luma_pred_flag)
    tmpBits = CabacEncode('mpm_idx', mpm_idx, 0);
    encModeBits = [encModeBits tmpBits];
else %'prev_intra_luma_pred_flag'=0     %%%%% p:150?!!
    candModeList = sort(candModeList);
    rem_intra_luma_pred_mode = currModeY;
    for i=1:3
        if(currModeY>candModeList(i))
            rem_intra_luma_pred_mode = rem_intra_luma_pred_mode-1;
        end
    end
    assert(rem_intra_luma_pred_mode<32);
    tmpBits = CabacEncode('rem_intra_luma_pred_mode', rem_intra_luma_pred_mode, 0);
    encModeBits = [encModeBits tmpBits];
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%% Chroma Coding %%%%%%%%%%
if(currModeY==currModeUV)
    intra_chroma_pred_mode = 'INTRA_DERIVED';
elseif(currModeUV==0)
    intra_chroma_pred_mode = 'INTRA_PLANAR';
elseif(currModeUV==1)
    intra_chroma_pred_mode = 'INTRA_DC';
elseif(currModeUV==10)
    intra_chroma_pred_mode = 'INTRA_ANGULAR_10';
elseif(currModeUV==26)
    intra_chroma_pred_mode = 'INTRA_ANGULAR_26';
elseif(currModeUV==34)
    if(currModeY==0)
        intra_chroma_pred_mode = 'INTRA_PLANAR';
    elseif(currModeY==1)
        intra_chroma_pred_mode = 'INTRA_DC';
    elseif(currModeY==26)
        intra_chroma_pred_mode = 'INTRA_ANGULAR_26';
    elseif(currModeY==10)
        intra_chroma_pred_mode = 'INTRA_ANGULAR_10';
    end
end
%%% Binarization %%%    %%%%%p:242
switch intra_chroma_pred_mode
    case 'INTRA_DERIVED'
        binarized_intra_chroma_pred_mode = '0';
    case 'INTRA_PLANAR'
        binarized_intra_chroma_pred_mode = '100';
    case 'INTRA_ANGULAR_26'
        binarized_intra_chroma_pred_mode = '101';
    case 'INTRA_ANGULAR_10'
        binarized_intra_chroma_pred_mode = '110';
    case 'INTRA_DC'
        binarized_intra_chroma_pred_mode = '111';
end
tmpBits = CabacEncode('intra_chroma_pred_mode', binarized_intra_chroma_pred_mode, 0);
encModeBits = [encModeBits tmpBits];

end
        