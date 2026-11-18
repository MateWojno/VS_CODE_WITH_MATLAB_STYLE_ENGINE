%% ========================================================================
%% TEST 8: FFT Signal Processing & Spectrum (test08_fft_signal_spectrogram.m)
%% ========================================================================
clear; clc; close all;
Fs = 1000;              % Sampling frequency (Hz)
T = 1/Fs;               % Sampling period
L = 1500;               % Signal length
t = (0:L-1)*T;          % Time vector

% Clean signal: 50 Hz + 120 Hz + 280 Hz sinusoids + white noise
S = 0.8*sin(2*pi*50*t) + 1.2*sin(2*pi*120*t) + 0.5*sin(2*pi*280*t);
X = S + 1.5*randn(size(t));

% Fast Fourier Transform
Y = fft(X);
P2 = abs(Y/L);
P1 = P2(1:floor(L/2)+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:floor(L/2))/L;

figure('Name', 'Test 8: FFT Frequency Analysis', 'NumberTitle', 'off');
subplot(2, 1, 1);
plot(1000*t(1:150), X(1:150), 'b-');
grid on;
title('Noisy Time-Domain Signal (First 150 ms)');
xlabel('Time (ms)'); ylabel('Amplitude');

subplot(2, 1, 2);
plot(f, P1, 'r-', 'LineWidth', 1.5);
grid on;
title('Single-Sided Amplitude Spectrum via FFT');
xlabel('Frequency (Hz)'); ylabel('|P1(f)|');