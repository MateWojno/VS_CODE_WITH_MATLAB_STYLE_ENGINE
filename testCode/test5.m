%% ========================================================================
%% TEST 5: Real-Time 2D Wave Interference Animation (test05_wave_animation.m)
%% ========================================================================
clear; clc; close all;
x = linspace(0, 4*pi, 400);
figure('Name', 'Test 5: 2D Wave Animation', 'NumberTitle', 'off');
h1 = plot(x, sin(x), 'b--', 'LineWidth', 1); hold on;
h2 = plot(x, sin(x), 'g--', 'LineWidth', 1);
h3 = plot(x, 2*sin(x), 'r-', 'LineWidth', 2.5);
ylim([-2.5, 2.5]); xlim([0, 4*pi]); grid on;
title('Real-Time Traveling Wave Interference');
xlabel('Position x'); ylabel('Displacement');
legend('Wave 1 (Right)', 'Wave 2 (Left)', 'Superposition');

for frame = 1:15000
    t = frame * 0.08;
    w1 = sin(2*x - 3*t);
    w2 = sin(2.3*x + 2.5*t);
    set(h1, 'YData', w1);
    set(h2, 'YData', w2);
    set(h3, 'YData', w1 + w2);
    drawnow;
    pause(0.02);
end