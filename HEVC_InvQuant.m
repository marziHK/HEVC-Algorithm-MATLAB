function [ InvQuant ] = HEVC_InvQuant(Quantization,Quant_Mat, QP, B)

    Quantization = double(Quantization);
    Usize = size(Quantization);
    NVal = Usize(1);
    M = log2 (NVal);
    
    %scalingMat=Quant_Mat;   
    scalingMat=zeros(NVal)+16;  %just for now

    Temp = rem(QP,6);
    switch(Temp)
        case 0
            GQP = 40;
        case 1
            GQP = 45;
        case 2
            GQP = 51;
        case 3
            GQP = 57;
        case 4
            GQP = 64;
        case 5
            GQP = 72;
    end
     
    QPby6 = floor(QP/6);
    Shift1 = M -5 + B;
    Offset = M-6+B;
    OffsetIQ = 1 * (2 ^ Offset);

%  Quantization = round( sign (ScaledMatrix) .* (((abs (ScaledMatrix) .* FQP .*  (16 ./ Quant4_Mat) ) ./ 2 ^ QPby6)./2 ^ Shift2));
 
 InvQuant = (floor((Quantization .* scalingMat .* (GQP .* (2^QPby6)) + (OffsetIQ)) ./ (2 ^ Shift1)));
 %InvQuant = int16(fix((Quantization .* Quant_Mat .* (GQP .* (2^QPby6)) ) ./ (2 ^ Shift1)));

end

