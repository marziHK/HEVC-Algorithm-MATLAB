load rcY
fid = fopen('crew_q22_4cif_s32_y4m_planar_704x576_8bit_final.yuv','r');
h = 576;
w = 704;


Y(:,:)=(fread(fid,[w h],'uint8')');
UV(:,:,1)=(fread(fid,[w/2 h/2],'uint8')');
UV(:,:,2)=(fread(fid,[w/2 h/2],'uint8')');
fclose(fid);



for y = 1:h
    for x = 1:w
        a = rcY(y,x);
        b = Y(y,x);
        if(a ~= b)
            disp(['y = ',num2str(y) , ' x = ',num2str(x), ' \ a=  ',num2str(a), '\ b= ',num2str(b)]);
        end
    end
end

for y = 1:h/2
    for x = 1:w/2
        a = rcUV(y,x,1);
        b = UV(y,x,1);
        if(a ~= b)
            disp(['y = ',num2str(y) , ' x = ',num2str(x), ' \ rcV=  ',num2str(a), '\ rcV_= ',num2str(b)]);
        end
    end
end

for y = 1:h/2
    for x = 1:w/2
        a = rcUV(y,x,2);
        b = UV(y,x,2);
        if(a ~= b)
            disp(['y = ',num2str(y) , ' x = ',num2str(x), ' \ rcV=  ',num2str(a), '\ rcV_= ',num2str(b)]);
        end
    end
end
