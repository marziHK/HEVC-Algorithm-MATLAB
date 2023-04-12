function  bitstream2file(bitstream,fileName)

len=length(bitstream);
cnt=0;
cnt2=1;
temp=0;
for i=1:len
   if(bitstream(i)=='1')
       temp=temp*2+1;
       cnt=cnt+1;
   else
       temp=temp*2;
       cnt=cnt+1;
   end
   if(cnt==8)
       Data(cnt2)=temp;
       cnt=0;
       cnt2=cnt2+1;
       temp=0;
   end
end
fileID = fopen(fileName,'w');
fwrite(fileID,Data);
fclose(fileID);
