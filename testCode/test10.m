%% ========================================================================
%% TEST 10: Chaotic 3D Lorenz Attractor via ODE45 (test10_lorenz_attractor_ode.m)
%% ========================================================================
clear; clc; close all;
sigma = 10;
beta = 8/3;
rho = 28;

lorenz = @(t, x) [
    sigma * (x(2) - x(1));
    x(1) * (rho - x(3)) - x(2);
    x(1) * x(2) - beta * x(3)
];

tspan = [0, 40];
x0 = [1; 1; 1];
[t, sol] = ode45(lorenz, tspan, x0);

figure('Name', 'Test 10: 3D Lorenz Attractor', 'NumberTitle', 'off');
plot3(sol(:,1), sol(:,2), sol(:,3), 'b-', 'LineWidth', 1); hold on;
plot3(sol(1,1), sol(1,2), sol(1,3), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
plot3(sol(end,1), sol(end,2), sol(end,3), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
grid on;
title('Chaotic 3D Lorenz Attractor Solved via ode45');
xlabel('X(t)'); ylabel('Y(t)'); zlabel('Z(t)');
legend('Trajectory', 'Start Point', 'End Point');
view(45, 25);