% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved
% p : 154

% Input : 
%                 pL_Y          ->   Left Neighbours for Luma
%                 pU_Y          ->   Up Neighbours for Luma
%                 nTbS          ->   Transform block size
%                 cIdx          ->   Colour component
%                 pL_UV         ->   Left Neighbours for Luma
%                 pU_UV         ->   Up Neighbours for Luma

% OutPuts :
%                 pLS_Y         ->  Left Substitution Neighbours
%                 pUS_Y         ->  Up Substitution Neighbours
%                 pLS_UV        ->  Left Substitution Neighbours
%                 pUS_UV        ->  Up Substitution Neighbours
%%

function [pLS_Y, pUS_Y, pLS_UV, pUS_UV] = ReferenceSubstitution(pL_Y, pU_Y, nTbS, cIdx, pL_UV, pU_UV)

% If cIdx == 0, bitDepth is set equal to BitDepthY;
% If cIdx == 1, bitDepth is set equal to BitDepthc
% if( cIdx == 0)
%     bitDepth = 8;
% else
%     bitDepth = 4;
% end

pLS_Y = pL_Y;
pUS_Y = pU_Y;

if(cIdx == 1)
    pLS_UV = pL_UV;
    pUS_UV = pU_UV;
end

%%%% luma samples %%%%
tmpFlag=0;
if(pL_Y(2*nTbS+1)==-1)
    for i=2*nTbS:-1:1
        if(pL_Y(i)~=-1)
            pLS_Y(2*nTbS+1)=pL_Y(i);
            tmpFlag=1;
            break;
        end
    end
    if(~tmpFlag)
        for i=1:2*nTbS+1
            if(pU_Y(i)~=-1)
                pLS_Y(2*nTbS+1)=pU_Y(i);
                tmpFlag=1;
                break
            end
        end
    end
    if(~tmpFlag)
        pLS_Y(:) = 128;
        pUS_Y(:) = 128;
        if(cIdx==1)
            pLS_UV(:) = 128;
            pUS_UV(:) = 128;
        end
        return;
    end
end

for i=2*nTbS:-1:1
    if(pL_Y(i)==-1)
        pLS_Y(i)=pLS_Y(i+1);
    end
end
pUS_Y(1)=pLS_Y(1);
for i=2:2*nTbS+1
    if(pU_Y(i)==-1)
        pUS_Y(i)=pUS_Y(i-1);
    end
end

%%% chroma samples %%%
if( cIdx == 1)
    pLS_UV = pL_UV;
    pUS_UV = pU_UV;
    tmpFlag=0;
    if(pL_UV(nTbS+1,1)==-1)
        for i=nTbS:-1:1
            if(pL_UV(i,1)~=-1)
                pLS_UV(nTbS+1,:)=pL_UV(i,:);
                tmpFlag=1;
                break;
            end
        end
        if(~tmpFlag)
            for i=1:nTbS+1
                if(pU_UV(i,1)~=-1)
                    pLS_UV(nTbS+1,:)=pU_UV(i,:);
                    tmpFlag=1;
                    break
                end
            end
        end
    end

    for i=nTbS:-1:1
        if(pL_UV(i,1)==-1)
            pLS_UV(i,:)=pLS_UV(i+1,:);
        end
    end
    pUS_UV(1,:)=pLS_UV(1,:);
    for i=2:nTbS+1
        if(pU_UV(i,1)==-1)
            pUS_UV(i,:)=pUS_UV(i-1,:);
        end
    end
end


end    