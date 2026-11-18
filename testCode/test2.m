%% ========================================================================
%% TEST 2: 3D Shaded Surface & Contour Projection (test02_3d_surfaces.m)
%% ========================================================================
clear; clc; close all;
[X, Y] = meshgrid(linspace(-3, 3, 60));
Z = 3*(1 - X).^2 .* exp(-(X.^2) - (Y + 1).^2) ...
    - 10*(X/5 - X.^3 - Y.^5) .* exp(-X.^2 - Y.^2) ...
    - 1/3 * exp(-(X + 1).^2 - Y.^2);

figure('Name', 'Test 2: 3D Surfaces', 'NumberTitle', 'off');
subplot(1, 2, 1);
surfc(X, Y, Z);
shading interp;
colormap('viridis');
colorbar;
title('3D Surface with Contour Projection');
xlabel('X'); ylabel('Y'); zlabel('Z');
view(-35, 30);

subplot(1, 2, 2);
contourf(X, Y, Z, 20);
colorbar;
title('2D Filled Contour Map');
xlabel('X'); ylabel('Y');
axis square;

