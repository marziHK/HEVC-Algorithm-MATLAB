% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Copyright :   (c) 2018, All Rights Reserved

%%
% This function appends '0' to the end of the input bit-stream until it reaches to byte alignment
% Inputs :
%           in   ->  input bit-stream
% Outputs:
%           out  ->  output bit-stram
%%

function out = ByteAlign(in)

out = in;
bitNum=length(out);
byteR=mod(bitNum,8);
while((byteR~=8) && (byteR~=0))
     out=[out '0'];
     byteR=byteR+1;
end

end