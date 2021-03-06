classdef Quick_USB < handle
    %QuickUSB Module Class
    %   This class is the the Matlab translation of the QuickUSB module
    properties
        hDevice = NaN;
        isOpened = false;
        isOpenedPolitely = false;
        openCount = 0;
        ModuleName = '';
    end
    
    
    methods (Static = true) 
        function LoadLib()
            if not(libisloaded('QuickUSB'))
               loadlibrary('QuickUSB', 'QuickUSB.h');
            end
        end
        
        function UnloadLib()
            if libisloaded('QuickUSB')
               unloadlibrary('QuickUSB');
            end
        end
        
        function delete()
            Quick_USB.UnloadLib();
        end
 
        function obj = FindModules()
            Quick_USB.LoadLib();

            % Allocate a buffer for the module names
            buffer = blanks(1024);
            len = length(buffer);
            
            [namelist] = calllib('QuickUSB', 'QuickUsbFindModules', buffer, len);
            if result == 1
                obj = textscan(namelist, '%s', 'delimiter', char(0));
            end
        end
    end
    
    
    methods (Access = private)
        function Open(obj, name)
            % If the user supplies a name, use that name instead
            if (nargin == 2)
                obj.ModuleName = name;
            end
            
            % Load the library if it hasn't been already loaded
            Quick_USB.LoadLib();
            
            % Call the library function
            qhnd = -1;
            [result, obj.hDevice] = calllib('QuickUSB', 'QuickUSBOpen', qhnd, obj.ModuleName);
            obj.isOpened = true;
            obj.openCount = obj.openCount + 1;
        end
        
        function Close(obj)
            calllib('QuickUSB', 'QuickUSBClose', obj.hDevice);
            if obj.isOpenedPolitely
                obj.isOpenedPolitely = false;
            else                
                obj.openCount = obj.openCount - 1;
            end
            obj.hDevice = NaN;
            obj.isOpened = false;
        end
                
        function OpenPolitely(obj)
            if obj.isOpened 
                return;
            end            
            obj.isOpenedPolitely = true;
            obj.Open(obj);
        end
        
        function ClosePolitely(obj)
            if obj.isOpened
                obj.Close();
            end
        end
    end
    
    
    methods
        %a continuacion vienen las funciones desarrolladas por mi 
        function  QUSB_init(obj)
            %primero uso el find module para encontrar los perifericos
            %disponibles
              % Allocate a buffer for the module names
            buffer = blanks(1024);
            len = length(buffer);
            
            [result, namelist] = calllib('QuickUSB', 'QuickUsbFindModules', buffer, len);
            if result == 1
                namelist = textscan(namelist, '%s', 'delimiter', char(0));
            end
            obj.ModuleName = namelist{1,1};
            
            %una vez encontrado el dispositivo ahora abro la comunicacion
            %con el mismo
             % Call the library function
            qhnd = -1;
            [result, obj.hDevice] = calllib('QuickUSB', 'QuickUsbOpen', qhnd, obj.ModuleName);
            obj.isOpened = true;
            obj.openCount = obj.openCount + 1;
            %tendre en hDevice el puntero al objeto abierto
            cad_sal =strcat('Encontrado y abierto ',obj.ModuleName);
            disp(cad_sal);
        end
        
        %%funcion para Inicializar la FPGA
        function QUSB_FpgaInit(obj)
            portA = uint16(0);
            data = uint8(128);
            result = calllib('QuickUSB', 'QuickUsbWritePortDir', obj.hDevice, portA, data);
            if result == 1 
                disp(' Configurada puerta A para salida ');
            end
            %activo la FPGA
            dataLength = uint16(1); 
            result = calllib('QuickUSB', 'QuickUsbWritePort', obj.hDevice, portA, data, dataLength);
             if result == 1 
                disp(' FPGA Activada ');
             end
            
             %indico la FPGA que voy a utilizar
             %#define SETTING_FPGATYPE                        4
             address = uint16(4); 
             value = uint16(0);
             result = calllib('QuickUSB', 'QuickUsbWriteSetting',obj.hDevice,address, value);
              if result == 1 
                disp(' FPGA configurada en el QuickUsb ');
              end
        end
        
        %funcion para llevar a cabo la escritura (programacion ) de la FPGA
        %fileName contendra el nombre del fichero programar a la FPGA, si
        %dicho fichero no esta en el Path de Matlab sera necesario indicar
        %la direccion del mismo 
        function QUSB_FpgaProgram(obj, fileName)
            %comienzo por configurar el quick para programar la FPGA
            result = calllib('QuickUSB', 'QuickUsbStartFpgaConfiguration', obj.hDevice);
            if result == 0
                disp(' Error en la configuración de la FPGA ');
            end
            
            %fileName = 'Counter.rbf';
            fileData = dir(fileName); %util para obtener datos del archivo como por ejemplo su tamanno
            filePtr = fopen(fileName,'r'); %abro el archivo del que leer los datos
            
            %ahora tengo que hacer un bucle para leer el archivo .rbf a
            %trozos para luego poder programarlo en la FPGA
            nRead = 64; %para controlar el bucle de lectura
            while (nRead == 64)
                %leo los datos a un array
                [fpgaData,nRead] = fread(filePtr,64,'uchar');
                %ahora escribo los datos leidos en la FPGA
                fpgaData = uint8(fpgaData);
                nread = uint32(nRead); %ulong(nRead);
                result = calllib('QuickUSB','QuickUsbWriteFpgaData',obj.hDevice, fpgaData, nread);
                if result == 0
                    disp(' Error escribiendo datos a la FPGA ');
                end
            end
            
            %por ultimo compruebo que la FPGA este correctamente programada
            vPtr = -1; 
            fpgaConfigOk = uint16(1);
            
            [result,vPtr,fgpaConfigOk] = calllib('QuickUSB','QuickUsbIsFpgaConfigured',obj.hDevice,fpgaConfigOk);
            
            if fpgaConfigOk == 1 
                disp('FPGA Configurada y Lista '); 
                fclose(filePtr);
                
            end
        end
        
        %funcion encargada de la lectura de datos de la FPGA
        
        function [data,nRead] = QUSB_ReadFpgaData(obj,dataLength)
            %la funcion a llamar es 
            datalength = uint32(dataLength); %ulong(dataLength);
            vPtr = -1; 
            data = uint8(zeros(dataLength,1));
            
            [result,vPtr,data,nRead] = calllib('QuickUSB','QuickUsbReadData',obj.hDevice,data,datalength);
            if result == 0 
                disp(' Error en la lectura ' );
            end
        end
        
        
            
            
        
        
            
        
        function set.ModuleName(obj, name)
            % Handle different name classes
            switch class(name)
                case 'char'
                    obj.ModuleName = name;
                case 'cell'
                    obj.ModuleName = name{1,1};
            end
        end
        
        function obj = Quick_USB(name)
            if (nargin == 1)
                obj.ModuleName = name;
            end
             % Load the library if it hasn't been already loaded
            Quick_USB.LoadLib();
        end
        
        function WriteSpiBytes(obj, portnum, data)
            obj.OpenPolitely();
            len = min(length(data), 64);
            calllib('QuickUSB', 'QuickUSBWriteSpi', obj.hDevice, portnum, data, len);
            obj.ClosePolitely();
        end
        
        function obj = ReadSpiBytes(obj, portnum, length)
            obj.OpenPolitely();
            data = ones(1, min(length, 64), 'uint8');
            len = length(data);
           result = calllib('QuickUSB', 'QuickUSBReadSpi', obj.hDevice, portnum, data, len);     
            obj.ClosePolitely();
            obj = values;
        end
        
        function obj = WriteReadSpiBytes(obj, portnum, data)
            obj.OpenPolitely();
            len = min(length(data), 64);
            [result,values] = calllib('QuickUSB', 'QuickUSBWriteReadSpi', obj.hDevice, portnum, data, len);     
            obj.ClosePolitely();
            obj = values;
        end
    end
    
end