% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved
% completed in 981213

% Intra Planar Prediction
% Inputs :
%   nTbS = Prediction Unit Size
%   PY = Left Neighboring Pixels
%   PX = Up Neighboring Pixels

% Output:
%   Intra_Planar : Planar Predicted Output PU
%%
function  Intra_Planar =   Planar_Model(nTbS, PY, PX)

for y=0:nTbS-1
    for x=0:nTbS-1
      
%         Intra_Planar(y+1,x+1) = bitsrl(((nTbS-1-x)*PY(y+2) + (x+1)*PX(nTbS+2) + (nTbS-1-y)*PX(x+2) + (y+1)*PY(nTbS+2) + nTbS),(log2(nTbS)+1));        
        Intra_Planar(y+1,x+1) = (floor(double(((nTbS-1-x)*PY(y+2) + (x+1)*PX(nTbS+2) + (nTbS-1-y)*PX(x+2) + (y+1)*PY(nTbS+2) + nTbS)) / (2^(log2(nTbS)+1))));
    end
end