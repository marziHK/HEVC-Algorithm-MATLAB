% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved

%% 
% This function is for binarization of the different syntax elements
% Inputs :
%           se          ->  input syntax element
%           type        ->  the type of the binarization must be used for the current syntax element
%           parameter1  ->  a parameter used for binarization
%           parameter2  ->  a parameter used for binarization
% Outputs:
%           bins        ->  the output bins sequence
%%

function [bins] = Binarization(se,type,parameter1,parameter2)
    switch(type)
        case 'TrU'      % truncated unary
            bins = TrU(se,parameter1);
        case 'FL'       % fixed length
            bins = dec2bin(se,parameter1);
        case 'TR'       % truncated rice
            bins = TR(se,parameter1,parameter2);    % 1st parameter is cMax and 2nd is riceParam
        case 'EGk'      % Exp-golomb k-th order
            bins = EGk(se,parameter1);
        case 'Rem'       % a specific binarization
            bins = CALR(se,parameter1);
    end
end

function bins = TrU(synVal, cMax)
    bins = [];
    if(synVal==0)
        bins = '0';
    else
        for i=1:min(synVal,cMax)
            bins = [bins '1'];
        end
        if(synVal<cMax)
            bins = [bins '0'];
        end
    end
end

function bins = TR(synVal,cMax,cRiceParam)
    %synVal=uint16(synVal);
    %cMax=uint16(cMax);
    %cRiceParam=uint16(cRiceParam);    
    %prefixVal = bitsrl(synVal,cRiceParam);
    prefixVal = floor(synVal/(2^cRiceParam));
    %maxPrefixLen = bitsrl(cMax,cRiceParam);
    maxPrefixLen = floor(cMax/(2^cRiceParam));
    prefix = TrU(prefixVal,maxPrefixLen);
    if(synVal<cMax)
        %suffixVal = synVal - bitsll(prefixVal,cRiceParam);
        suffixVal = synVal - prefixVal*(2^cRiceParam);
        suffix = dec2bin(suffixVal,cRiceParam);
    else
        suffix = [];
    end
    bins = [prefix suffix];
end

function bins = EGk(symbolVal,k)
    bins = [];
    %absV = uint8(abs(symbolVal));
    absV = abs(symbolVal);
    while(1)
        if(absV>=(2^k))
            bins = [bins '1'];
            absV = absV - (2^k);
            k = k+1;
        else
            bins = [bins '0'];
            while(k>0)
                k = k-1;
                %tmpBit = bitand(bitsrl(absV,k),1);
                tmpBit = mod(floor(absV/(2^k)),2);
                bins = [bins dec2bin(tmpBit)];
            end
            break
        end
    end            
end

function bins = CALR(synVal,baseLevel)
    global cLastAbsLevel cLastRiceParam
    cAbsLevel = baseLevel+synVal;
    if(cLastAbsLevel>(3*(2^cLastRiceParam)))
        cRiceParam = min(cLastRiceParam+1,4);
    else
        cRiceParam = min(cLastRiceParam,4);
    end
    cMax = 2^(2+cRiceParam);
    prefixVal = min(cMax,synVal);
    prefix = TR(prefixVal,cMax,cRiceParam);
    if(strcmp(prefix,'1111'))
        suffixVal = synVal-cMax;
        suffix = EGk(suffixVal,cRiceParam+1);
    else
        suffix = [];
    end
    bins = [prefix suffix];
    cLastAbsLevel = cAbsLevel;
    cLastRiceParam = cRiceParam;
end