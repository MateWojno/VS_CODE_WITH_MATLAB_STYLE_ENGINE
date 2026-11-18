%% ========================================================================
%% TEST 9: Polar Rose, Histogram & Grouped Bars (test09_polar_and_bar_charts.m)
%% ========================================================================
clear; clc; close all;
figure('Name', 'Test 9: Statistical & Polar Charts', 'NumberTitle', 'off');

% Polar plot
subplot(1, 3, 1);
theta = linspace(0, 2*pi, 400);
rho = abs(cos(3 * theta));
polar(theta, rho, 'm-');
title('Polar Rose Curve');

% Normal distribution histogram
subplot(1, 3, 2);
data = randn(2000, 1) * 15 + 100;
hist(data, 25);
grid on;
title('Gaussian Histogram');
xlabel('Value'); ylabel('Frequency');

% Grouped bar chart
subplot(1, 3, 3);
categories = [12 18 25; 15 22 30; 19 28 35; 24 31 42];
bar(categories);
grid on;
title('Grouped Benchmark Metrics');
xlabel('Quarter'); ylabel('Score');
legend('Model A', 'Model B', 'Model C', 'Location', 'northwest');