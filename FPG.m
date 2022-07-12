clc
clear all
close all

[ir, red, flt_ECG, Fs, ap] = readpwdata('Test.bin');

flt_ECG = flt_ECG(1,103000:end);
ir = ir(1,103000:end);
red = red(1,103000:end);
ap = -ap(1,103000:end);

signal = red;

t = GetTime(signal, Fs);

coeff = ones(1,250); % fir 250 sample filter

filt = filtfilt(coeff/30,1,signal); % forward and backward signal filtering

diff_test = diff(filt); % 

counter = 1;

for i = 1:length(diff_test)
    if abs(diff_test(i)) <= 0.05
        try
            if abs(diff_test(i)) < abs(diff_test(i + 1)) && abs(diff_test(i)) < abs(diff_test(i - 1))
                test_array(counter) = t(i);
                counter = counter + 1;
            end
        catch
        end
    end
end

%find index of t based on positions of zero-points
counter = 1;
for i = 1:length(test_array)
    test_index(counter) = find(t == test_array(i));
    counter = counter + 1;
end

[P_peak_index,N_peak_index,D_peak_index,T_peak_index] = GetPeaks(signal,t,test_index);

tiledlayout(3,1)

% First plot
ax1 = nexttile;
plot(t,filt)
hold on
for i = 1:length(test_index)
    plot(t(test_index(i)),filt(test_index(i)),'rv');
    hold on
end

% Second plot
ax2 = nexttile;
plot(t(1,2:end),diff_test)
hold on
for i = 1:length(test_array)
    plot(test_array(i),0,'rv');
    hold on
end

ax3 = nexttile;
plot(t,signal)
hold on
for i = 1:length(P_peak_index)
    plot(t(P_peak_index(i)),signal(P_peak_index(i)),'bv');
    hold on
end
for i = 1:length(D_peak_index)
    plot(t(D_peak_index(i)),signal(D_peak_index(i)),'go');
    hold on
end
for i = 1:length(N_peak_index)
    plot(t(N_peak_index(i)),signal(N_peak_index(i)),'ro');
    hold on
end
for i = 1:length(T_peak_index)
    plot(t(T_peak_index(i)),signal(T_peak_index(i)),'ko');
    hold on
end
linkaxes([ax1 ax2 ax3],'x')

function [P_peak_index,N_peak_index,D_peak_index,T_peak_index] = GetPeaks(signal,time,zeroPointIndex)
counter = 1;
D_counter = 1;
T_counter = 1;
N_counter = 1;
signalAndtime(1,:) = signal; 
signalAndtime(2,:) = time;

for i = 1 :2: length(zeroPointIndex)
    clear vector_1
    clear vector_2
    try
        vector_1(1,:) = signalAndtime(1,zeroPointIndex(i):zeroPointIndex(i+1));
        vector_1(2,:) = signalAndtime(2,zeroPointIndex(i):zeroPointIndex(i+1));
        vector_2(1,:) = signalAndtime(1,zeroPointIndex(i+1):zeroPointIndex(i+2));
        vector_2(2,:) = signalAndtime(2,zeroPointIndex(i+1):zeroPointIndex(i+2));
    catch
        continue;
    end
    
    max_peak1 = max(findpeaks(vector_1(1,:)));
    max_peak2 = max(findpeaks(vector_2(1,:)));
    
    if isempty(max_peak1) && isempty(max_peak2)
        continue;
    elseif isempty(max_peak2)
        P_peak_index(counter) = GetIndex(time,vector_1,max_peak1);
        counter = counter + 1;
    elseif isempty(max_peak1)
        P_peak_index(counter) = GetIndex(time,vector_2,max_peak2);
        counter = counter + 1;
    elseif (max_peak1 > max_peak2)
        P_peak_index(counter) = GetIndex(time,vector_1,max_peak1);
        counter = counter + 1;
        
        if vector_2(1) > vector_2(length(vector_2))
             vector_2 = fliplr(vector_2);
        end
         
        try
            [N_peak,N_index] = findpeaks(-vector_2(1,:),'MinPeakWidth',5);%"-" - flip the signla to find N notch
            N_peak_index(N_counter) = GetIndex(time,vector_2,-max(N_peak));
            N_counter = N_counter + 1;
            
            D_peak = max(findpeaks(vector_2(1,:),'MinPeakWidth',5));
            D_peak_index(D_counter) = GetIndex(time,vector_2,D_peak);
            D_counter = D_counter + 1;
            
            T_period = vector_2(1,max(N_index)+100:length(vector_2));
            T_peak = max(T_period); %max or max(findpeaks)?
            T_peak_index(T_counter) = GetIndex(time,vector_2,T_peak);
            T_counter = T_counter + 1;
        catch
        end 
    else
        buff = vector_1;
        clear vector_1
        vector_1 = vector_2;
        clear vector_2
        vector_2 = buff;
        clear buff
        
        P_peak_index(counter) = GetIndex(time,vector_1,max_peak2);
        counter = counter + 1;
        
        if vector_2(1) > vector_2(length(vector_2))
            vector_2 = fliplr(vector_2);
        end
        try
           [N_peak,N_index] = findpeaks(-vector_2(1,:),'MinPeakWidth',5); %"-" - flip the signla to find N notch
           N_peak_index(N_counter) = GetIndex(time,vector_2,-max(N_peak));
           N_counter = N_counter + 1;
           
           D_peak = max(findpeaks(vector_2(1,:),'MinPeakWidth',5));
           D_peak_index(D_counter) = GetIndex(time,vector_2,D_peak);
           D_counter = D_counter + 1;
           
           T_period = vector_2(1,max(N_index)+100:length(vector_2));
           T_peak = max(T_period);
           T_peak_index(T_counter) = GetIndex(time,vector_2,T_peak);
           T_counter = T_counter + 1;
        catch
        end
        
    end
    
end
end

function t = GetTime(signal,Fs)
    N = length(signal);
    T = 1/Fs;
    tmax = T*N;
    t = 0:T:tmax-T;
end

function  index = GetIndex(time,vector,peak)
    indexOfmax = find(vector(1,:) == peak(1));
    index = find(time == vector(2,indexOfmax(1,1)));
end