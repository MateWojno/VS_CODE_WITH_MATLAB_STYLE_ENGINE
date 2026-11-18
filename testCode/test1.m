% =========================================================================
% GNU OCTAVE CAPABILITIES SHOWCASE (10 SELF-CONTAINED TEST SCRIPTS)
% Split at each '%% ===' header into individual .m files to run separately.
% Uses core GNU Octave functions (no external packages required).
% =========================================================================

%% ========================================================================
%% TEST 1: 2D Multi-Plot with Error Bars & Envelopes (test01_2d_multiplot.m)
%% ========================================================================
clear; clc; close all;
t = linspace(0, 10, 500);
y = exp(-0.35 * t) .* cos(4 * t);
env_upper = exp(-0.35 * t);
env_lower = -exp(-0.35 * t);

% Simulated noisy sensor samples
t_samp = linspace(0.2, 9.8, 25);
y_samp = exp(-0.35 * t_samp) .* cos(4 * t_samp) + 0.05 * randn(size(t_samp));
err = 0.08 * ones(size(t_samp));

figure('Name', 'Test 1: 2D Multi-Plot', 'NumberTitle', 'off');
subplot(2, 1, 1);
plot(t, y, 'b-', 'LineWidth', 2); hold on;
plot(t, env_upper, 'r--', 'LineWidth', 1.2);
plot(t, env_lower, 'r--', 'LineWidth', 1.2);
grid on;
title('Damped Harmonic Oscillation with Decay Envelope');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Signal', 'Upper Envelope', 'Lower Envelope');

subplot(2, 1, 2);
errorbar(t_samp, y_samp, err, 'ko', 'MarkerFaceColor', 'g', 'MarkerSize', 5);
grid on;
title('Simulated Experimental Measurements with Error Bars');
xlabel('Time (s)'); ylabel('Measured Value');

