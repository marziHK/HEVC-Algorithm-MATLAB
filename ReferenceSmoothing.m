% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved


%%
% Input : 
%                 pL       ->   Left Neighbours
%                 pU       ->   Up Neighbours
%                 nTbS     ->   Block size

% OutPuts :
%                 pLS      ->  Left Smoothed Neighboring Pixels
%                 pUS      ->  Up Smoothed Neighboring Pixels
%%

function  [pFL, pFU]     =  ReferenceSmoothing(nTbS, pL, pU)

% Intra Smoothing Filter
% PU = 4x4      -> Not Available
% PU = 8x8      -> Only Planar, Angular(2,18,34)
% PU = 16x16    -> All modes except DC, Angular(10,26,9,11,25,27)
% PU = 32x32    -> All modex except DC, Angular(10,26)

% if(nTbS == 32)
% 
%     pFL(1) = pL(1);
%     pFU(1) = pU(1);
%     pFL(63) = pL(63);
%     pFU(63) = pU(63);
%     
%     for i = 2:2*nTbS
%         pFL(i) = uint8(((65-i)*pL(1) + (i+1)*pL(2*nTbS+1) + 32)/64);
%         pFU(i) = uint8(((65-i)*pU(1) + (i+1)*pU(2*nTbS+1) + 32)/64);
%     end
%     
% else    % 8x8 16x16
%     pFL(1) = bitsrl(pL(2) + 2*pL(1) + pU(2) + 2 , 2);
%     pFU(1) = bitsrl(pL(2) + 2*pL(1) + pU(2) + 2 , 2);
    pFL(1) = floor((pL(2) + 2*pL(1) + pU(2) + 2)/4);
    pFU(1) = floor((pL(2) + 2*pL(1) + pU(2) + 2)/ 4);
    
    for i = 2:2*nTbS
%         pFL(i) = bitsrl(pL(i+1) + 2*pL(i) + pL(i-1) + 2 ,2);
%         pFU(i) = bitsrl(pU(i-1) + 2*pU(i) + pU(i+1) + 2 ,2);
        pFL(i) = floor((pL(i+1) + 2*pL(i) + pL(i-1) + 2 )/ 4);
        pFU(i) = floor((pU(i-1) + 2*pU(i) + pU(i+1) + 2 )/ 4);
    end
    
% end
    pFL(2*nTbS+1) = pL(2*nTbS+1);
    pFU(2*nTbS+1) = pU(2*nTbS+1);

end
