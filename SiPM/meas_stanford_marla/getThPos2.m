%   RCP - 01 / 12 / 2015 
%   
%  function used to find the crossing point of the pulses
%
% tCrossing value in seconds
% event -- event that will be processed
% thVal -- threshold value to use
% medTh -- medium threshold if nothing is specified max/2 will be used
% tSample -- time between samples 50e-12 by default

function tCrossing = getThPos2(event, thVal, medTh,nDataIn,tSample)
if nargin < 4
    tSample = 50e-12;
end
if nargin < 3
    nDataIn = 3e-9;
end
if nargin < 2
    medTh = max(event)/2;
end
nData = nDataIn/tSample;
%first I need to find the crossing of medTh
medCross = find(event > medTh,1);
%take two nanoseconds before the crossing
%take only 500ps before the event
tBaseline = 500e-12/tSample;
baseLine = mean(event((medCross-nData-tBaseline):(medCross-nData)));
t = (medCross-nData):medCross;
%now interpolate the new data
t2 = linspace(t(1),t(end),nData*1000);
%first interpolation
interEvent = interp1(t,event(t),t2,'pchip'); %mismo que cubic
% if interEvent(1) > 0
%     interEvent = interEvent-interEvent(1);
% else
%     interEvent = interEvent+interEvent(1);
% end
%now find the crossing
fCross = 0;
% plot(t,event((medCross-nData):medCross),'.');
% hold on; 
% plot(t2,interEvent);
defCross = zeros(1,size(thVal,2));
for i = 1 : size(thVal,2)
    if baseLine > 0
        fCross= t2(find(interEvent< (thVal(i)-baseLine),1,'last'));
    else
        fCross= t2(find(interEvent< (thVal(i)+baseLine),1,'last'));
    end
%     fCross= t2(find(interEvent< (thVal(i)),1,'last'));
    if isempty(fCross)
        defCross(i) = nan(1);
    else
        defCross(i) = fCross;
    end
%     plot(defCross(i),thVal(i),'.');
end



%hold on; 
%plot(t2,interEvent);

%use a second interpolation from the first values to get a finer
% measurement
% t3 = (fCross-nData):(fCross+nData);
% t4 = linspace(t3(1),t3(end),1000);
% %second interpolation
% interEvent2 = interp1(t3,interEvent(t3),t4); 
% %find the crossing point again
% defCross = t4(find(interEvent2< thVal,1,'last'));
% % change the data from the sample domain to the time domain
%this fix is only needed when using uncorrected data, with the corrected
%data this should not be needed
%defCross = fCross;
tCrossing = defCross; %*tSample;