clc
clear all
close all

[ir, red, flt_ECG, Fs, ap] = readpwdata('Test.bin');

flt_ECG = flt_ECG(1,100000:end);
ir = ir(1,100000:end);
red = red(1,100000:end);
ap = ap(1,100000:end);

[SPM,FFF] = periodogram(flt_ECG,hamming(length(flt_ECG)),2048,Fs);

N = length(flt_ECG);
T = 1/Fs;
tmax = T*N;
t = 0:T:tmax-T;

subplot(2,3,1);
plot(t,flt_ECG);
xlim([0 1]);
title('flt ECG');

subplot(2,3,2);
plot(t,ir);
xlim([0 1]);
title('ir');

subplot(2,3,3);
plot(t,red);
xlim([0 1]);
title('red');

subplot(2,3,4);
plot(t,ap);
xlim([0 1]);
title('ap');

subplot(2,3,5);
plot(FFF,SPM);
xlim([0 25]);
title('SPM');