%% ========================================================================
%% TEST 3: 3D Parametric Torus & Helical Curve (test03_parametric_3d.m)
%% ========================================================================
clear; clc; close all;
R = 3; r = 1;
[u, v] = meshgrid(linspace(0, 2*pi, 60), linspace(0, 2*pi, 30));
X = (R + r * cos(v)) .* cos(u);
Y = (R + r * cos(v)) .* sin(u);
Z = r * sin(v);

% Helical trajectory wrapped around the torus
t = linspace(0, 2*pi, 400);
hx = (R + (r + 0.08) * cos(8 * t)) .* cos(t);
hy = (R + (r + 0.08) * cos(8 * t)) .* sin(t);
hz = (r + 0.08) * sin(8 * t);

figure('Name', 'Test 3: 3D Parametric Geometry', 'NumberTitle', 'off');
surf(X, Y, Z, 'FaceAlpha', 0.65, 'EdgeColor', 'none'); hold on;
plot3(hx, hy, hz, 'r-', 'LineWidth', 2.5);
colormap('ocean');
light; lighting gouraud;
axis equal; grid on;
title('Parametric 3D Torus with Wrapped Helical Trajectory');
xlabel('X'); ylabel('Y'); zlabel('Z');
