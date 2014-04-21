%analizar los primeros datos obtenidos con el artemis

load Artemis1.mat

%la variable que me interesa es DataGuard;
%para ello la convierto en una matriz fila
data = zeros(512000,1);
for i = 1 : 100
    data(((i-1)*512+1):(i*512)) = DataGuard(i,:);
end

%pongo ahora a 0 los valores consecutivos e iguales
%un problema que tiene la FIFO de la FPGA
%cuando no le quedan datos, devuelve muchas veces el �ltimo almacenado
for i = 1: 511999 %10239
    %if (mean([data(i-1),data(i),data(i+1)])-data(i) == 0) 
    %no deberian haber nunca dos valores seguids por lo que...
    if (data(i) - data(i+1) == 0)
        data(i) = 0;
    end
end

%ahora analizo los datos y los meto en el canal correspondiente
ind1 = 1; ind2 = 1; ind3 = 1; ind4 = 1; 
canal1 = zeros(1,100000); histo1 = zeros(1,4096);
canal2 = zeros(1,100000); histo2 = zeros(1,4096);
canal3 = zeros(1,100000); histo3 = zeros(1,4096);
canal4 = zeros(1,100000); histo4 = zeros(1,4096);


for i = 1 : 512000
    if (data(i) ~=0 ) %me aseguro de que no es un valor repetido
        if( data(i) >= 32768) %se trata del cuarto canal
            canal4(ind4) = data(i)-32768;
            histo4(canal4(ind4)+1) = histo4(canal4(ind4)+ 1) + 1; %el mas uno del hist...es porque matlab empieza en 1 y no en 0
            ind4 = ind4+1;
        elseif (data(i) >= 16384)
            canal3(ind3) = data(i)-16384;
            histo3(canal3(ind3)+1) = histo3(canal3(ind3)+ 1) + 1; %el mas uno del hist...es porque matlab empieza en 1 y no en 0
            ind3 = ind3+1;
        elseif (data(i) >= 8192)
            canal2(ind2) = data(i)- 8192;
            histo2(canal2(ind2)+1) = histo2(canal2(ind2)+ 1) + 1; %el mas uno del hist...es porque matlab empieza en 1 y no en 0
            ind2 = ind2+1;
        elseif (data(i) >= 4096)
            canal1(ind1) = data(i)- 4096;
            histo1(canal1(ind1)+1) = histo1(canal1(ind1)+ 1) + 1; %el mas uno del hist...es porque matlab empieza en 1 y no en 0
            ind1 = ind1+1;
        else
            data(i)
        end
    end
end

%ahora genero la imagen, para eso leo los datos de cada canal
%para eso asigno los valores
img = zeros (512,512);
menor = min([ind1,ind2,ind3,ind4]);
for i = 1: menor
    XA = canal1(i)/4; XB = canal2(i)/4;
    YA = canal3(i)/4; YB = canal4(i)/4;
    
    energia = (XA + XB +YA + YB) / 8; %hago un cutre escalado...
    
    X = 256*(XA-XB) + 256;
    Y = 256*(YA-YB) + 256;
    if (X>0 && X<513) && (Y>0 && Y<513)
        img(X,Y) = img(X,Y) + energia;
    end
end
imshow(mat2gray(img));
imagesc(img);

    

            
          


