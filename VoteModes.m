% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved
% compelete


%%
% Gets a list of modes an selected some modes with better score based linear func
% Input : 
%                 inlist            ->  input rank list
% OutPut :
%                 candidate         ->  sorted selected modes
%%

function candidate  = VoteModes( inlist )

[listLen, listNum] = size(inlist);


sortlist=[];
for i = 1:listNum
    for j = 1:listLen
        if(inlist(j,i) ~= -1)
            if(isempty(sortlist))
                sortlist(1,1) = inlist(j,i);
                sortlist(1,2) = listLen+1 - j;
            else
                tmp = find(sortlist(:,1)==inlist(j,i));
                if(isempty(tmp))
                    tmp = size(sortlist,1); 
                    sortlist(tmp+1,1) = inlist(j,i);
                    sortlist(tmp+1,2) = listLen+1 - j;
                else
                    sortlist(tmp,2) = sortlist(tmp,2)+ listLen+1 - j;
                end
            end
        else
            break;
        end
    end
end


[ tmp , order] = sort(sortlist(:,2),'descend'); %sort based on scores
sortlist = sortlist(order,:);
candidate = sortlist(:,1);

end

