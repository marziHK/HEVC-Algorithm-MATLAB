% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved
% compelete

%%
% Find MPM and append them  to intra modes candidates
% Input : 
%                 leftMode                  ->  left CU modes
%                 upMode                    ->  top CU modes
%                 inList                    ->  list of selected modes
%                 numOfRdoCandidates        ->  Number of modes tjat should be in output List
% OutPut :
%                 outList                   ->  the final candidate modes(mpm + input)
%                 mpm                       ->  MPM modes 
%%

function [ outList, mpm ] = AppendMPM( leftMode, upMode, inList, numOfRdoCandidates)

% p:149 - part3
if(leftMode == upMode)
    if(leftMode<2)  
        mpm(1) = 0;
        mpm(2) = 1;
        mpm(3) = 26;
    else
        mpm(1) = leftMode;
        mpm(2) = 2 + (mod((leftMode+29),32));
        mpm(3) = 2 + (mod((leftMode-1),32));
    end
else
    mpm(1) = leftMode;
    mpm(2) = upMode;
    if(leftMode~=0 && upMode~=0)
        mpm(3) = 0;
    elseif(leftMode~=1 && upMode~=1)
        mpm(3) = 1;     
    else
        mpm(3) = 26;
    end
end

outList = inList;

%% check if mpm is in inlist or not
for i=1:3
    if(nnz(inList == mpm(i))==0)
        outList = [mpm(i); outList];
    else
        outList(outList == mpm(i)) = [];
        outList = [mpm(i); outList];
    end
end

%%sort final list
if(numOfRdoCandidates< length(outList))
    outList = outList(1:numOfRdoCandidates);
end
outList = sort(outList);

end