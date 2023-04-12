% This code is an implementation of H.265/HEVC encoder based on "Algorithm and Architecture Design of the H.265/HEVC Intra Encoder" by "Grzegorz Pastuszak and Andrzej Abramowski"
% Author :      Bardia Azizian
% Developer :      Marzieh Hosseinkhani
% Copyright :   (c) 2018, All Rights Reserved


% Intra Angular Prediction Matlab Model
% Inputs:
%           predModeIntra           ->  Candidate mode numbers
%           pLS                     ->  Left Neighbours
%           pUS                     ->  Top Neighbours
%           pLSF                    ->  Left Smoothing Neighbours
%           pUSF                    ->  Top Smoothing Neighbours
%           nTbS                    ->  Block Size
%           cIdx                    ->  color component

%           Top_Pixels              : Top  neighboring pixels
%           Left_Pixels             : Left neighboring pixels
%           Top_Filtered_Pixels     : Top  neighboring pixels after smoothing filter
%           Left_Filtered_Pixels    : Left  neighboring pixels after smoothing filter
%           nTbS                    : Prediction unit size

% Outputs:
%   iFact                   : Multiplication Factor (iFact)
%   Intra_Angular           : Intra Angular Predicted Pixels (In order to display Intra_Angular{1}  celldisp(Intra_Angular))




function Intra_Angular    =   Intra_Angular_Model(CandidModes, pLS, pUS, nTbS, cIdx, pLSF, pUSF)

intra_mode      = [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34];                          % intra prediction mode
intra_angle     = [32 26 21 17 13 9 5 2 0 -2 -5 -9 -13 -17 -21 -26 -32 -26 -21 -17 -13 -9 -5 -2 0 2 5 9 13 17 21 26 32];                 % intra prediction angle
intra_inv_angle = [0 0 0 0 0 0 0 0 0 -4096 -1638 -910 -630 -482 -390 -315 -256 -315 -390 -482 -630 -910 -1638 -4096 0 0 0 0 0 0 0 0 0];  % intra prediction inverse angle
% n_mode=33;
n_mode=length(CandidModes);

% if(strcmp(cIdx,'chroma'))
%     n_mode=1;
% end


% find refmain
% for i= 1:n_mode 
for i= CandidModes   %p:159
    i= i-1;
    refmain=0;
    if(strcmp(cIdx,'luma'))
        if(nTbS == 4)
           py = pLS;
           px = pUS;
        end

        if((nTbS == 8) && ((intra_mode(i) == 2) || (intra_mode(i) == 18) || (intra_mode(i) == 34)))
           py = pLSF;
           px = pUSF;
        elseif(nTbS == 8)
           py = pLS;
           px = pUS;
        end

        if((nTbS == 16) && ((intra_mode(i) == 9) || (intra_mode(i) == 10) || (intra_mode(i) == 11) || (intra_mode(i) == 25) || (intra_mode(i) == 26) || (intra_mode(i) == 27)))
           py = pLS; 
           px = pUS; 
        elseif(nTbS == 16)
           py = pLSF;
           px = pUSF;
        end

        if((nTbS == 32) && ((intra_mode(i) == 10) || (intra_mode(i) == 26)))
           py = pLS; 
           px = pUS; 
        elseif(nTbS == 32)
           py = pLSF;
           px = pUSF;
        end
    else    % for chroma
        py = pLS;
        px = pUS;
    end
    


    % Reference Main Array Selection   
    if(intra_mode(i) < 18) 
       for j=(nTbS+1):(3*nTbS+1)     %9:17 for 8x8     
           refmain(j) = py(j-nTbS); 
       end

       if(intra_angle(i) < 0)                 
               x = nTbS*intra_angle(i);
               x_s = floor(x/32);         

               if(x_s < -1)
                  for x_ss = x_s:-1
                      refmain(x_ss+(nTbS+1)) = px(1+(floor(((x_ss)*intra_inv_angle(i)+128)/256))); 
                  end
               end
       else
    %             for j=(2*nTbS+2):(3*nTbS+1)          
    %                 refmain(i,j) = py(j-nTbS); 
    %             end
       end
    else
       for j=(nTbS+1):(3*nTbS+1)                 
           refmain(j) = px(j-nTbS);           
       end
       if(intra_angle(i) < 0)                 
               x = nTbS*intra_angle(i);
               x_s = floor(x/32);

            if(x_s < -1)
               for x_ss = x_s:-1
                   refmain(x_ss+(nTbS+1)) = py(1+(floor(((x_ss)*intra_inv_angle(i)+128)/256)));
               end
            end
       else
    %             for j=(2*nTbS+2):(3*nTbS+1)           
    %                 refmain(i,j) = px(j-nTbS); 
    %             end
       end
    end

    % Calculate Prediction EquationTbS           
    for y=1:nTbS   
      for x=1:nTbS
         if(intra_mode(i) >= 18)
           iIdx = floor(y*intra_angle(i)/32);
           iFact= mod(y*intra_angle(i),32);
           if(iFact == 0)
               predSamples(y,x) = (refmain(((x-1)+iIdx+1)+(nTbS+1))); 
           else                                         
               predSamples(y,x) = (floor(((32-iFact)*refmain(((x-1)+iIdx+1)+(nTbS+1)) + iFact*refmain(((x-1)+iIdx+2)+(nTbS+1)) + 16) / 32));
           end
           if((intra_mode(i) ==26) && (nTbS<32) && strcmp(cIdx,'luma'))  %vertical post-processing filter
               if(x==1)
                   predSamples(y,x) = (uint8(px(x+1)+floor((py(y+1)-py(1))/2)));
               end
           end
         else  
           iIdx = floor(x*intra_angle(i)/32);
           iFact= mod(x*intra_angle(i),32);
           if(iFact == 0)
               predSamples(y,x) = (refmain(((y-1)+iIdx+1)+(nTbS+1)));
           else                                         
               predSamples(y,x) = (floor(((32-iFact)*refmain(((y-1)+iIdx+1)+(nTbS+1)) + iFact*refmain(((y-1)+iIdx+2)+(nTbS+1)) + 16)/32)); 
           end 
           if((intra_mode(i)==10) && (nTbS<32) && strcmp(cIdx,'luma'))  %horizontal post-processing filter
               if(y==1)
                   predSamples(y,x) = (uint8(py(y+1)+floor((px(x+1)-px(1))/2)));
               end
           end
         end
      end
    end
    Intra_Angular(i) = {predSamples};    
end

if(length(CandidModes) == 1)
    Intra_Angular = Intra_Angular(CandidModes-1);
end

