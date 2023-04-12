%% Needs To Fix

%%
function [ Quantization , dist] = HEVC_Quantization( transformedC, Quant_Mat , QP, B )
%   p : 193 !
    transformedC = double(transformedC);
    Usize = size(transformedC);
    NVal = Usize(1);
    
    M = log2 (NVal);
    
%     Scaling_Mat = Quant_Mat;
    Scaling_Mat = zeros(NVal)+16;       % just for now

    tmp = rem(QP,6);
    switch(tmp)
        case 0
            FQP = (26214);
        case 1
            FQP = (23302);
        case 2
            FQP = (20560);
        case 3
            FQP = (18396);
        case 4
            FQP = (16384);
        case 5
            FQP = (14564);
    end

    QPby6 = (floor(QP/6));
    Shift2 = 29 - M - B;
    offset = (171*(2^(QPby6+Shift2-9)));

%  Quantization1 = int16(sign(transformedC) .* round((((abs (transformedC) .* FQP .*  (16 ./ Scaling_Mat)) ./ (2 ^ QPby6)) ./ (2 ^ Shift2))));
 Quantization = double(int16(sign(transformedC).* floor(((abs(transformedC).*FQP.*(16./Scaling_Mat)) + offset) ./ (2^(QPby6+Shift2)))));
 
 f = offset/(2^(QPby6+Shift2));
 deltaP = (abs(transformedC).*FQP )./(2^(QPby6+Shift2));
 deltaP = deltaP - floor(deltaP);
 delta = deltaP;
 delta(deltaP>=1-f) = 1-delta(deltaP>=1-f);
 dist = 12*sum(sum(delta.^2));

end




% del = zeros(B,B);
% for i=1:B
%     for j=1:B
%         if(rem(i,2)==1 && rem(j,2)==1)
%             PF = 1/4;   % a^2
%         elseif(rem(i,2)==0 && rem(j,2)==0)
%             PF = 0.1;   % b^2 /4
%         else
%             PF = 0.25 * sqrt(2/5);  % ab/2
%         end
%         MF = (2^qbits)* PF /QStep ;
%         deltP =1/(abs(ScaledMatrix(i,j)) * MF *x);
%         if( deltP < f)
%             del(i,j) = deltP;
%         else
%             del(i,j)= (1-deltP);
%         end
%     end
% end
% dist2 = 11 * landa * sum(sum(power(del,2)));