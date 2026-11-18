%% ========================================================================
%% TEST 6: Real-Time 3D Surface Ripple Animation (test06_3d_ripple_animation.m)
%% ========================================================================
clear; clc; close all;
[X, Y] = meshgrid(linspace(-8, 8, 50));
R = sqrt(X.^2 + Y.^2) + eps;

figure('Name', 'Test 6: 3D Ripple Animation', 'NumberTitle', 'off');
h_surf = surf(X, Y, sin(R)./R);
shading interp;
colormap('cool');
zlim([-0.5, 1.1]);
title('3D Animated Radial Wave & Camera Orbit');
xlabel('X'); ylabel('Y'); zlabel('Z');

for frame = 1:120000
    t = frame * 0.15;
    Z = sin(R - t) ./ (0.5 * R + 1);
    set(h_surf, 'ZData', Z);
    view(-35 + frame * 0.8, 30);
    drawnow;
    pause(0.02);
end