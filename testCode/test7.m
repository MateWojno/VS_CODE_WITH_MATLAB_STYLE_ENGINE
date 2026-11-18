%% ========================================================================
%% TEST 7: Vector Field & Particle Streamlines (test07_vector_field_streamlines.m)
%% ========================================================================
clear; clc; close all;
[x, y] = meshgrid(linspace(-2, 2, 20), linspace(-2, 2, 20));
% Rotational vortex + saddle flow
u = -y + 0.3 * x;
v = x - 0.3 * y;

figure('Name', 'Test 7: Vector Field & Streamlines', 'NumberTitle', 'off');
quiver(x, y, u, v, 'b'); hold on;
[sx, sy] = meshgrid(linspace(-1.8, 1.8, 7), linspace(-1.8, 1.8, 7));
h_stream = streamline(x, y, u, v, sx(:), sy(:));
set(h_stream, 'Color', 'r', 'LineWidth', 1.2);
axis tight equal; grid on;
title('2D Fluid Velocity Vector Field (Quiver) & Streamlines');
xlabel('X Position'); ylabel('Y Position');