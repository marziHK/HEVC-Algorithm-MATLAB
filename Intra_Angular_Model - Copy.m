function Intra_Angular    =   Intra_Angular_Model(Left_Pixels,Top_Pixels, Left_Filtered_Pixels, Top_Filtered_Pixels, nS, enforcedMode)

% Intra Angular Prediction Matlab Model
% Inputs:
%   Top_Pixels              : Top  neighboring pixels
%   Left_Pixels             : Left neighboring pixels
%   Top_Filtered_Pixels     : Top  neighboring pixels after smoothing filter
%   Top_Filtered_Pixels     : Left  neighboring pixels after smoothing filter
%   nS                      : Prediction unit size

% Outputs:
%   iFact                   : Multiplication Factor (iFact)
%   Intra_Angular           : Intra Angular Predicted Pixels (In order to display Intra_Angular{1}  celldisp(Intra_Angular))

intra_mode      = [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34];                          % intra prediction mode
intra_angle     = [32 26 21 17 13 9 5 2 0 -2 -5 -9 -13 -17 -21 -26 -32 -26 -21 -17 -13 -9 -5 -2 0 2 5 9 13 17 21 26 32];                 % intra prediction angle
intra_inv_angle = [0 0 0 0 0 0 0 0 0 -4096 -1638 -910 -630 -482 -390 -315 -256 -315 -390 -482 -630 -910 -1638 -4096 0 0 0 0 0 0 0 0 0];  % intra prediction inverse angle
n_mode=1;
% if (nS == 4)
%     n_mode = 33;
%     twos_angle = 256;
% elseif(nS == 8) 
%     n_mode = 33;
%     twos_angle = 256;
% elseif(nS == 16)
%     n_mode = 33;
%     twos_angle = 512;
% else
%     n_mode = 33;
%     twos_angle = 1024;
% end
% 
% % calculate iFact multiplication factor
% for i = 1:n_mode                    
%     for j = 1:nS
%         if(j*intra_angle(i) < 0)
%             twos_cmp_angle = twos_angle + (j*intra_angle(i));
%             iFact(((i-1)*nS)+j) = bitand(twos_cmp_angle,31);
%         else
%             iFact(((i-1)*nS)+j) = bitand((j*intra_angle(i)),31);
%         end
%     end
% end

% find refmain
for i=1:n_mode
   i=enforcedMode-1;
   refmain=0;
   if(nS == 4)
       py = Left_Pixels;
       px = Top_Pixels;
   end
   
   if((nS == 8) && ((intra_mode(i) == 2) || (intra_mode(i) == 18) || (intra_mode(i) == 34)))
       py = Left_Filtered_Pixels;
       px = Top_Filtered_Pixels;
   elseif(nS == 8)
       py = Left_Pixels;
       px = Top_Pixels;
   end
   
   if((nS == 16) && ((intra_mode(i) == 9) || (intra_mode(i) == 10) || (intra_mode(i) == 11) || (intra_mode(i) == 25) || (intra_mode(i) == 26) || (intra_mode(i) == 27)))
       py = Left_Pixels; 
       px = Top_Pixels; 
   elseif(nS == 16)
       py = Left_Filtered_Pixels;
       px = Top_Filtered_Pixels;
   end
   
   if((nS == 32) && ((n_mode == 10) || (n_mode == 26)))
       py = Left_Pixels; 
       px = Top_Pixels; 
   elseif(nS == 32)
       py = Left_Filtered_Pixels;
       px = Top_Filtered_Pixels;
   end
   
   
   % Reference Main Array Selection
   if(intra_mode(i) < 18) 
       for j=(nS+1):(3*nS+1)                 
           refmain(j) = py(j-nS); 
       end
       
       if(intra_angle(i) < 0)                 
               x = nS*intra_angle(i);
               x_s = floor(x/32);         
               
               if(x_s < -1)
                  for x_ss = x_s:-1
                      refmain(x_ss+(nS+1)) = px(1+(floor(((x_ss)*intra_inv_angle(i)+128)/256))); 
                  end
               end
       else
%             for j=(2*nS+2):(3*nS+1)          
%                 refmain(i,j) = py(j-nS); 
%             end
       end
   else
       for j=(nS+1):(3*nS+1)                 
           refmain(j) = px(j-nS);           
       end
       if(intra_angle(i) < 0)                 
               x = nS*intra_angle(i);
               x_s = floor(x/32);
            
            if(x_s < -1)
               for x_ss = x_s:-1
                   refmain(x_ss+(nS+1)) = py(1+(floor(((x_ss)*intra_inv_angle(i)+128)/256)));
               end
            end
       else
%             for j=(2*nS+2):(3*nS+1)           
%                 refmain(i,j) = px(j-nS); 
%             end
       end
   end

% Calculate Prediction Equations
           
   for y=1:nS   
      for x=1:nS
         if(intra_mode(i) >= 18)
           iIdx = floor(y*intra_angle(i)/32);
           iFact= mod(y*intra_angle(i),32);
           if(iFact == 0)
               predSamples(y,x) = int16(refmain(((x-1)+iIdx+1)+(nS+1))); 
           else                                         
               predSamples(y,x) = int16(floor(((32-iFact)*refmain(((x-1)+iIdx+1)+(nS+1)) + iFact*refmain(((x-1)+iIdx+2)+(nS+1)) + 16) / 32));
           end
           if((intra_mode(i)==26) && (nS<32))  %vertical post-processing filter
               if(x==1)
                   predSamples(y,x) = int16(uint8(px(x+1)+floor((py(y+1)-py(1))/2)));
               end
           end
         else
           iIdx = floor(x*intra_angle(i)/32);
           iFact= mod(x*intra_angle(i),32);
           if(iFact == 0)
               predSamples(y,x) = int16(refmain(((y-1)+iIdx+1)+(nS+1)));
           else                                         
               predSamples(y,x) = int16(floor(((32-iFact)*refmain(((y-1)+iIdx+1)+(nS+1)) + iFact*refmain(((y-1)+iIdx+2)+(nS+1)) + 16)/32)); 
           end 
           if((intra_mode(i)==10) && (nS<32))  %horizontal post-processing filter
               if(y==1)
                   predSamples(y,x) = int16(uint8(py(y+1)+floor((px(x+1)-px(1))/2)));
               end
           end
         end
      end
   end
   Intra_Angular = {predSamples};    
%    Intra_Angular = double(Intra_Angular);   
end


  
