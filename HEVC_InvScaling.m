function [ ReconstructMatx ] = HEVC_InvScaling(InvQuant, M_Mat, BitDepth_B)
    
    InvQuant = double(InvQuant);
    DTrans = M_Mat';
    INvstage1 = DTrans * InvQuant;
    
    SIT1 = 2^7;
    
%     INvstage2 = fix((INvstage1+64) ./ SIT1);
    INvstage2 = floor((INvstage1+64) ./ SIT1);
    
    Invstage3 = INvstage2 * M_Mat;
    
    SIT2 = 2^(20-BitDepth_B);
    
%     RoundedFinal = fix((Invstage3+(SIT2/2)) ./ SIT2);
    RoundedFinal = floor((Invstage3+(SIT2/2)) ./ SIT2);
    
    ReconstructMatx = (RoundedFinal);
%     ReconstructMatx =  (RoundedFinal);
end