% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved
% completed at 981213

%% Intra DC Prediction
%p :136

% Input : 
%                 nTbS     ->   Block size
%                 pL       ->   Left Neighbours
%                 pU       ->   Top Neighbours
%                

% Output:
%                  Intra_DC : DC Predicted Output PU
%%


function  Intra_DC  =   DC_Model(nTbS, pL, pU, cIdx)

% dc_Val = bitsrl(int16((sum(pL(2:(nTbS+1))) + sum(pU(2:(nTbS+1))) + nTbS)),(log2(nTbS)+1));  
dc_Val = (floor(double(sum(pL(2:(nTbS+1))) + sum(pU(2:(nTbS+1))) + nTbS)/(2^(log2(nTbS)+1)))); 

if(nTbS < 32 && strcmp(cIdx,'luma'))
%     Intra_DC(1,1) = bitsrl((pL(2) + pU(2) + 2*dc_Val + 2),2);          
    Intra_DC(1,1) = (floor(double(pL(2) + pU(2) + 2*dc_Val + 2)/4));

    for i=2:nTbS
%         Intra_DC(i,1) = bitsrl((pL(i+1) + 3*dc_Val + 2),2);
%         Intra_DC(1,i) = bitsrl((pU(i+1) + 3*dc_Val + 2),2);
        Intra_DC(i,1) = (floor(double(pL(i+1) + 3*dc_Val + 2)/4));
        Intra_DC(1,i) = (floor(double(pU(i+1) + 3*dc_Val + 2)/4));
    end
    Intra_DC(2:nTbS,2:nTbS) = dc_Val;
   
else
    Intra_DC(1:nTbS,1:nTbS) = dc_Val;
end


