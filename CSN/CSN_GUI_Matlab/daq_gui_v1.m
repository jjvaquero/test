function varargout = daq_gui_v1(varargin)
% DAQ_GUI_V1 M-file for daq_gui_v1.fig
%      DAQ_GUI_V1, by itself, creates a new DAQ_GUI_V1 or raises the existing
%      singleton*.
%
%      H = DAQ_GUI_V1 returns the handle to a new DAQ_GUI_V1 or the handle to
%      the existing singleton*.
%
%      DAQ_GUI_V1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DAQ_GUI_V1.M with the given input arguments.
%
%      DAQ_GUI_V1('Property','Value',...) creates a new DAQ_GUI_V1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before daq_gui_v1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to daq_gui_v1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help daq_gui_v1

% Last Modified by GUIDE v2.5 21-Jun-2012 13:47:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @daq_gui_v1_OpeningFcn, ...
                   'gui_OutputFcn',  @daq_gui_v1_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before daq_gui_v1 is made visible.
function daq_gui_v1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to daq_gui_v1 (see VARARGIN)



% Choose default command line output for daq_gui_v1
handles.guifig = gcf;
handles.hist = zeros(4096,1);
handles.hist_corr = zeros(512,1); %para meter ceros en un array
handles.hist_save = zeros(512,35);
handles.hist_comp = zeros(512,1);
handles.aux_val = 0;
handles.aux_val2 = 0;
handles.tmp_hists = zeros(2500,100);
handles.output = hObject;
handles.quick = Quick_USB('mi_quick'); %{@TmrFcn,handles.guifig},'BusyMode','Queue',...
 %   'ExecutionMode','FixedRate','Period',2);
handles.timer = timer('TimerFcn',{@lectPeriodica,handles.guifig}, 'BusyMode','Queue',...
     'ExecutionMode','FixedRate','Period', 1);

  
guidata(handles.guifig,handles);


% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using daq_gui_v1.
if strcmp(get(hObject,'Visible'),'off')
    plot(rand(5));
end

% UIWAIT makes daq_gui_v1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = daq_gui_v1_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

 axes(handles.axes1);
 cla;
 

quick = handles.quick;  %instancio el quick creado antes
 timer = handles.timer; %timer para la lectura periodica
%inicializo el quick y demas

%lo configuro
QUSB_init(quick);
%configuro la FPGA
QUSB_FpgaInit(quick);
%programo la FPGA
QUSB_FpgaProgram(quick,'fpga_csn_v3_2.rbf'); %'CSN_edu3.rbf' %'CSN_detect_pico.rbf');%'CSN_edu2.rbf'); %'daq_fpga.rbf');

%aqui debo primero configurar la fpga y toda esa pelicula y luego activar
%el timer

 periodo = str2double(get(handles.edit2, 'string'));
 set(timer,'Period',periodo);
 %disp(periodo);

 
 start(timer);

 guidata(handles.guifig, handles);
guidata(hObject, handles);



% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

hist = handles.hist;
save histrograma.mat hist

delete(handles.figure1)



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton1.
function pushbutton1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lectPeriodica(src,event,handles) %Timer function
handles = guidata(handles);
%cla;
quick = handles.quick;  %instancio el quick creado antes
%hist = handles.hist; %esto no vale porque hist es temporal
%sin visibilidad para fuera
  %tic
 [data,nRead] = QUSB_ReadFpgaData(quick,5000);
 %toc   ...me da tiempos de 0.001 es decir vuelve enseguida
 %los datos son leidos a un array de caracteres
 %por ello realizo ahora la conversion necesaria
 dataConv = typecast(data,'uint16');
 set(handles.text1,'String',num2str(nRead));
 
 %actualizo ahora los datos de mi histograma
 temp = zeros(4096,1);
 aux_error = 0;
 
 %esto lo hago para evitar el relleno que mete en el bufferla FPGA
 %la posibilidad de que tres valores seguidos tengan el mismo valor
 %es casi nula por lo tanto...
 for i = 1:2498
     if dataConv(i) == dataConv(i+1) && dataConv(i)== dataConv(i+2)
         dataConv(i) = 0;
     end
 end 
 dataConv(2498:2500) = 0;
 
 for i = 1 : 2500 %valores de mi histograma
     if(dataConv(i)+1 < 4097) &&  (dataConv(i) ~= 0)
         temp(dataConv(i)+1) =temp(dataConv(i)+1)+1;
         %handles.hist(dataConv(i)+1) = handles.hist(dataConv(i)+1) +1;     

     end
      %if (temp(dataConv(i)+1) > nRead) %&&  (dataConv(i) ~= 0)
      %  disp('Error ')
      %  temp(dataConv(i)+1)
      %  dataConv(i)
      %  aux_error = 1;        
      %end
     
 end
 
%apanno temporal...pero debe ser algo malo con la fifo de la fpga
%[val,pos] = max(temp);
%if (pos>1)
%    temp(pos) = (temp(pos+1) + temp(pos-1))/2;
%end

plot(handles.axes2,1:4096, temp(1:4096),'*');
xlim(handles.axes2,[1 4096]);
title(handles.axes2,'Antes');

%todo esto ya no haria falta

% %version 2.0 del cutre apanno anterior
% vals = find(temp>25); 
% %el 100 lo he puesto a ojo...50 creo que tb valdria
% %100 va bien para 0.5 de tiempo
% %pero para 0.1 de tiempo es mejor poner 25
% tam = size(vals,1);
% if tam >0 
%     for i=1: tam
%         if vals(i)> 0
%             %temp(vals(i)) = temp(vals(i));
%             temp(vals(i)) = round((temp(vals(i)+1) + temp(vals(i)-1))/2);
%         end
%     end
% end

 n_events = sum(temp)/0.5; %algo mejor seria
 %sum(temp)/(str2num(get(handles.edit2,'String'))
 set(handles.text2,'String',num2str(n_events));

    

 %cutre solucion, si hay lecturas erroneas, descarto la lectura
 if (aux_error == 0) 
     handles.hist = handles.hist +temp;
     handles.hist_corr = handles.hist_corr + blkproc(temp,[8 1],'mean2');
 end
 
%handles.aux_val = handles.aux_val+1;
%guidata(handles, aux_v);
%handles.aux_val

%todo esto es para el clasificador...me lo pulo
% handles.aux_val = handles.aux_val +1;
% if  handles.aux_val >= 200
%     hists_temp = handles.tmp_hists;
%     save('hist_temporales.mat','hists_temp');
%     handles.aux_val = 0;
%     %guardo el histograma corregido (rebineado a 512)
%     handles.aux_val2 = handles.aux_val2 +1;
%     if handles.aux_val2 < 31
%        handles.hist_save(:,handles.aux_val2) = handles.hist_corr(1:512);
%        handles.hist_comp = handles.hist_corr(1:512);
%        %lo pongo todo a cero
%        handles.hist = zeros(4096,1);
%        handles.hist_corr = zeros(512,1); %para meter ceros en un array
%        hist_save = handles.hist_save;
%        save('histograma_comp.mat','hist_save');
%        disp('guardado');
%     else
%         disp('todo almacenado');
%     end
% else
%     handles.tmp_hists(:,handles.aux_val)= dataConv;
% end
 
 %genero ahora mi histograma
%axes(handles.axes1);
%plot(handles.axes1, dataConv);
plot(handles.axes3,1:4096, handles.hist(1:4096));
xlim(handles.axes3,[1 4096]);
%lo pongo en escala logaritmica
%set(handles.axes3,'XScale','log');

plot(handles.axes1,1:512, handles.hist_corr(1:512));
xlim(handles.axes1,[5 510]);
%set(handles.axes1,'YScale','log');
title(handles.axes3,'Despues');

%plot(handles.axes1,temp,'*');
%set(handles.edit1,'string',num2str(dataConv(1)));
guidata(handles.guifig, handles);




% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 timer = handles.timer; %timer para la lectura periodica
%inicializo el quick y demas

 stop(timer);
 guidata(handles.guifig, handles);
guidata(hObject, handles);


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.hist = zeros(4096,1);
handles.hist_corr = zeros(512,1); %para meter ceros en un array

guidata(handles.guifig, handles);
guidata(hObject, handles);


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% load red_prueba_13_6;
% val1 = sim(net,handles.hist_comp)
% [valor,clase] = max(val1);
% switch clase
%     case 1
%         str_tmp ='Bario 133';
%     case 2 
%         str_tmp ='Cobalto 60';
%     case 3
%         str_tmp ='Cesio 137';
%     case 4
%         str_tmp ='Manganeso 54';
%     case 5 
%         str_tmp ='Sodio 22';
% end
% disp(str_tmp);
str_tmp = clasifica_cutre(handles.hist_comp);
set(handles.text3,'String',str_tmp);
guidata(handles.guifig, handles);
guidata(hObject, handles);


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
histog_corr = handles.hist_corr;
histog_tot = handles.hist;
save histrograma.mat histog_tot histog_corr
guidata(handles.guifig, handles);
guidata(hObject, handles);


