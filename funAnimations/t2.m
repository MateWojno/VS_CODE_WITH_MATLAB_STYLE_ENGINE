%% ========================================================================
%  GNU OCTAVE NATIVE TANDEM DRIFT & REAL-TIME SENSOR TELEMETRY
%  Compatible with ALL GNU Octave versions (no 'gobjects', no external packages)
%  Uses standard numeric handle arrays (zeros(N, 1)) for 100% Octave safety.
%% ========================================================================

clear all; close all; clc;

% Select best available interactive graphics toolkit in GNU Octave
toolkits = available_graphics_toolkits();
if (any(strcmp(toolkits, 'qt')))
  graphics_toolkit('qt');
elseif (any(strcmp(toolkits, 'fltk')))
  graphics_toolkit('fltk');
endif

%% 1. TRACK GEOMETRY & 4 SCORED DRIFT CLIPPING ZONES
N_track = 600;
theta_t = linspace(0, 2*pi, N_track)';

% Smooth technical drift circuit (figure-8 inspired asymmetric sweepers)
rx = 95 * cos(theta_t) + 22 * sin(2 * theta_t);
ry = 58 * sin(theta_t) + 18 * cos(3 * theta_t);

% Compute track tangents, normals, and curvature
dx = gradient(rx);
dy = gradient(ry);
ds = hypot(dx, dy);
tx = dx ./ ds;
ty = dy ./ ds;
nx = -ty;
ny = tx;

road_half_w = 13.5;
left_x  = rx + nx * road_half_w;
left_y  = ry + ny * road_half_w;
right_x = rx - nx * road_half_w;
right_y = ry - ny * road_half_w;

% Curvature (used to trigger realistic drift slip angles)
dtx = gradient(tx) ./ ds;
dty = gradient(ty) ./ ds;
curvature = (tx .* dty - ty .* dtx);

% 4 Clipping Zones around major corners
zone_indices = [65, 205, 365, 515];
zone_radius  = 15.0;
zone_names   = {'ZONE 1: OUTER SWEEPER', 'ZONE 2: HAIRPIN APEX', ...
                'ZONE 3: S-TRANSITION', 'ZONE 4: FINAL CLIP'};

%% 2. FIGURE & DASHBOARD LAYOUT (PURE OCTAVE HANDLES)
fig = figure('Name', 'GNU Octave Tandem Drift & Sensor Telemetry', ...
             'Color', [0.06 0.07 0.09], ...
             'Position', [60, 60, 1280, 740]);

% Left Subplot: Main Drift Arena & Sensors
ax_track = subplot('Position', [0.04, 0.07, 0.56, 0.86]);
hold(ax_track, 'on');
set(ax_track, 'Color', [0.10 0.14 0.11], 'XColor', [0.6 0.65 0.7], ...
    'YColor', [0.6 0.65 0.7], 'Box', 'on', 'DataAspectRatio', [1 1 1]);
axis(ax_track, [-140 140 -95 95]);
title(ax_track, 'TANDEM DRIFT ARENA & LIDAR / RADAR SENSORS', ...
      'Color', [0.95 0.97 1.0], 'FontSize', 12, 'FontWeight', 'bold');
xlabel(ax_track, 'Track X Position (m)');
ylabel(ax_track, 'Track Y Position (m)');

% Draw Asphalt Surface Polygon
asphalt_x = [left_x; flipud(right_x)];
asphalt_y = [left_y; flipud(right_y)];
patch(ax_track, asphalt_x, asphalt_y, [0.18 0.19 0.22], 'EdgeColor', 'none');

% Draw Track Borders & Centerline
plot(ax_track, left_x, left_y, '-', 'Color', [0.90 0.25 0.25], 'LineWidth', 2.2);
plot(ax_track, right_x, right_y, '-', 'Color', [0.95 0.95 0.95], 'LineWidth', 2.2);
plot(ax_track, rx, ry, '--', 'Color', [0.45 0.48 0.52], 'LineWidth', 1.0);

% Draw 4 Clipping Zones (numeric handle array - no gobjects!)
h_zones = zeros(4, 1);
phi_c = linspace(0, 2*pi, 48);
for z = 1:4
  idx_z = zone_indices(z);
  zx = rx(idx_z) + nx(idx_z) * 5.5;
  zy = ry(idx_z) + ny(idx_z) * 5.5;
  h_zones(z) = patch(ax_track, zx + zone_radius*cos(phi_c), zy + zone_radius*sin(phi_c), ...
                     [1.0 0.65 0.0], 'FaceAlpha', 0.18, ...
                     'EdgeColor', [1.0 0.75 0.1], 'LineWidth', 1.8);
  text(ax_track, zx, zy + zone_radius + 3.5, zone_names{z}, ...
       'Color', [1.0 0.85 0.3], 'FontSize', 8, 'FontWeight', 'bold', ...
       'HorizontalAlignment', 'center');
endfor

% Pre-allocated Skidmark & Smoke Buffers (NaN-separated for single-line speed)
MAX_SKID = 280;
skid1_x = nan(MAX_SKID, 1); skid1_y = nan(MAX_SKID, 1);
skid2_x = nan(MAX_SKID, 1); skid2_y = nan(MAX_SKID, 1);

h_skid1 = plot(ax_track, skid1_x, skid1_y, '-', 'Color', [0.05 0.05 0.06], 'LineWidth', 2.4);
h_skid2 = plot(ax_track, skid2_x, skid2_y, '-', 'Color', [0.05 0.05 0.06], 'LineWidth', 2.4);

MAX_SMOKE = 90;
smoke_x = nan(MAX_SMOKE, 1);
smoke_y = nan(MAX_SMOKE, 1);
h_smoke = plot(ax_track, smoke_x, smoke_y, 'o', 'MarkerSize', 6, ...
               'MarkerFaceColor', [0.85 0.88 0.92], 'MarkerEdgeColor', 'none');

% Sensor Overlays: Tandem Radar Link, Chase LiDAR Rays, Velocity Vectors
h_radar_line = plot(ax_track, [0 0], [0 0], '--', 'Color', [0.1 1.0 0.6], 'LineWidth', 1.8);
h_radar_txt  = text(ax_track, 0, 0, '', 'Color', [0.2 1.0 0.7], 'FontSize', 8.5, 'FontWeight', 'bold');

N_lidar = 5;
h_lidar = zeros(N_lidar, 1);
for k = 1:N_lidar
  h_lidar(k) = plot(ax_track, [0 0], [0 0], '-', 'Color', [0.0 0.85 1.0], 'LineWidth', 1.1);
endfor

h_vel1 = plot(ax_track, [0 0], [0 0], '-', 'Color', [1.0 0.4 0.3], 'LineWidth', 2.0);
h_vel2 = plot(ax_track, [0 0], [0 0], '-', 'Color', [0.3 0.7 1.0], 'LineWidth', 2.0);

% Car Polygon Geometry (Local coordinates: length 6.2m, width 2.8m)
car_L = 3.1; car_W = 1.4;
body_local = [-car_L, -car_W;
               car_L, -car_W;
               car_L*1.12, 0;
               car_L,  car_W;
              -car_L,  car_W]';
windshield_local = [0.2, -car_W*0.75;
                    1.5, -car_W*0.65;
                    1.5,  car_W*0.65;
                    0.2,  car_W*0.75]';

% Car 1 (Lead - Crimson Red) & Car 2 (Chase - Electric Cyan)
h_car1_body = patch(ax_track, body_local(1,:), body_local(2,:), [0.95 0.18 0.22], ...
                    'EdgeColor', [1 1 1], 'LineWidth', 1.2);
h_car1_glass = patch(ax_track, windshield_local(1,:), windshield_local(2,:), [0.1 0.15 0.25], ...
                     'EdgeColor', 'none');

h_car2_body = patch(ax_track, body_local(1,:), body_local(2,:), [0.12 0.65 0.98], ...
                    'EdgeColor', [1 1 1], 'LineWidth', 1.2);
h_car2_glass = patch(ax_track, windshield_local(1,:), windshield_local(2,:), [0.1 0.15 0.25], ...
                     'EdgeColor', 'none');

% Top-Right Subplot: Live IMU Drift Slip Angle Waveform
ax_slip = subplot('Position', [0.64, 0.70, 0.33, 0.23]);
hold(ax_slip, 'on');
set(ax_slip, 'Color', [0.09 0.11 0.14], 'XColor', [0.7 0.75 0.8], ...
    'YColor', [0.7 0.75 0.8], 'Box', 'on', 'YLim', [-55 55]);
grid(ax_slip, 'on');
title(ax_slip, 'IMU SENSOR: DRIFT SLIP ANGLE (deg)', 'Color', [1 1 1], 'FontSize', 10);
ylabel(ax_slip, 'Slip (deg)');

WIN_LEN = 120;
t_hist = (-WIN_LEN+1:0)';
slip1_hist = zeros(WIN_LEN, 1);
slip2_hist = zeros(WIN_LEN, 1);
h_plot_slip1 = plot(ax_slip, t_hist, slip1_hist, '-', 'Color', [0.98 0.28 0.32], 'LineWidth', 1.8);
h_plot_slip2 = plot(ax_slip, t_hist, slip2_hist, '-', 'Color', [0.20 0.78 1.00], 'LineWidth', 1.8);
legend(ax_slip, {'Car 1 (Lead)', 'Car 2 (Chase)'}, 'TextColor', [1 1 1], ...
       'Color', [0.12 0.14 0.18], 'Location', 'northwest');

% Middle-Right Subplot: Live Lateral G-Force Accelerometer
ax_g = subplot('Position', [0.64, 0.41, 0.33, 0.22]);
hold(ax_g, 'on');
set(ax_g, 'Color', [0.09 0.11 0.14], 'XColor', [0.7 0.75 0.8], ...
    'YColor', [0.7 0.75 0.8], 'Box', 'on', 'YLim', [-2.2 2.2]);
grid(ax_g, 'on');
title(ax_g, 'ACCELEROMETER: LATERAL G-LOAD (g)', 'Color', [1 1 1], 'FontSize', 10);
ylabel(ax_g, 'Lat G');
xlabel(ax_g, 'Rolling Sensor Frame');

latg1_hist = zeros(WIN_LEN, 1);
latg2_hist = zeros(WIN_LEN, 1);
h_plot_g1 = plot(ax_g, t_hist, latg1_hist, '-', 'Color', [0.98 0.28 0.32], 'LineWidth', 1.8);
h_plot_g2 = plot(ax_g, t_hist, latg2_hist, '-', 'Color', [0.20 0.78 1.00], 'LineWidth', 1.8);

% Bottom-Right Panel: Live Digital Sensor Readout & Drift Scoreboard
ax_hud = subplot('Position', [0.64, 0.07, 0.33, 0.28]);
set(ax_hud, 'Color', [0.08 0.09 0.12], 'XTick', [], 'YTick', [], 'Box', 'on');
axis(ax_hud, [0 1 0 1]);
title(ax_hud, 'REAL-TIME VEHICLE CAN-BUS & ZONE TELEMETRY', 'Color', [0.3 1.0 0.7], 'FontSize', 10);

h_hud_text = text(ax_hud, 0.04, 0.92, 'Initializing sensors...', ...
                  'Color', [0.92 0.96 1.0], 'FontName', 'FixedWidth', ...
                  'FontSize', 9.2, 'VerticalAlignment', 'top');

%% 3. MAIN REAL-TIME SIMULATION LOOP
s1 = 45.0;          % Lead car track index
s2 = 28.0;          % Chase car track index (trailing closely)
total_score = 0;
tire_temp1 = 88.0;
tire_temp2 = 90.0;
lidar_angles = linspace(-0.42, 0.42, N_lidar);
lidar_max_range = 34.0;

max_frames = 1400;
for frame = 1:max_frames
  if (!ishandle(fig))
    break;
  endif

  % Wrap track indices smoothly
  idx1 = mod(floor(s1) - 1, N_track) + 1;
  idx2 = mod(floor(s2) - 1, N_track) + 1;

  % Local curvature drives realistic drift angle and speed modulation
  k1 = curvature(idx1);
  k2 = curvature(idx2);

  speed1 = 1.65 - 8.5 * abs(k1);   % Track index step per frame
  speed1 = max(1.05, min(1.85, speed1));

  % Chase car actively regulates gap to stay in tight tandem
  gap_idx = mod(s1 - s2, N_track);
  target_gap = 16.0;
  speed2 = speed1 + 0.045 * (gap_idx - target_gap);
  speed2 = max(1.00, min(1.95, speed2));

  s1 = mod(s1 + speed1, N_track);
  s2 = mod(s2 + speed2, N_track);

  % Lateral racing line offset (swinging wide into clipping zones)
  lat_off1 = -4.2 * tanh(k1 * 45);
  lat_off2 = -4.8 * tanh(k2 * 45) + 1.2 * sin(frame * 0.07);

  x1 = rx(idx1) + nx(idx1) * lat_off1;
  y1 = ry(idx1) + ny(idx1) * lat_off1;
  x2 = rx(idx2) + nx(idx2) * lat_off2;
  y2 = ry(idx2) + ny(idx2) * lat_off2;

  % Velocity heading vs. Body yaw (Slip Angle = Drift!)
  vel_ang1 = atan2(ty(idx1), tx(idx1));
  vel_ang2 = atan2(ty(idx2), tx(idx2));

  slip_rad1 = 0.72 * atan(k1 * 55);
  slip_rad2 = 0.78 * atan(k2 * 55) + 0.04 * sin(frame * 0.12);

  yaw1 = vel_ang1 + slip_rad1;
  yaw2 = vel_ang2 + slip_rad2;

  % Rotate & translate car polygons
  R1 = [cos(yaw1), -sin(yaw1); sin(yaw1), cos(yaw1)];
  R2 = [cos(yaw2), -sin(yaw2); sin(yaw2), cos(yaw2)];

  b1 = R1 * body_local + [x1; y1];
  g1 = R1 * windshield_local + [x1; y1];
  b2 = R2 * body_local + [x2; y2];
  g2 = R2 * windshield_local + [x2; y2];

  set(h_car1_body, 'XData', b1(1,:), 'YData', b1(2,:));
  set(h_car1_glass, 'XData', g1(1,:), 'YData', g1(2,:));
  set(h_car2_body, 'XData', b2(1,:), 'YData', b2(2,:));
  set(h_car2_glass, 'XData', g2(1,:), 'YData', g2(2,:));

  % Velocity direction vectors
  set(h_vel1, 'XData', [x1, x1 + 11*cos(vel_ang1)], 'YData', [y1, y1 + 11*sin(vel_ang1)]);
  set(h_vel2, 'XData', [x2, x2 + 11*cos(vel_ang2)], 'YData', [y2, y2 + 11*sin(vel_ang2)]);

  % Update Rear-Tire Skidmarks & Tire Smoke during high slip
  rear1 = R1 * [-car_L; 0] + [x1; y1];
  rear2 = R2 * [-car_L; 0] + [x2; y2];

  if (abs(slip_rad1) > 0.14)
    skid1_x = [skid1_x(2:end); rear1(1)];
    skid1_y = [skid1_y(2:end); rear1(2)];
    smoke_x = [smoke_x(3:end); rear1(1) + randn()*0.9; rear2(1) + randn()*0.9];
    smoke_y = [smoke_y(3:end); rear1(2) + randn()*0.9; rear2(2) + randn()*0.9];
  else
    skid1_x = [skid1_x(2:end); NaN];
    skid1_y = [skid1_y(2:end); NaN];
  endif

  if (abs(slip_rad2) > 0.14)
    skid2_x = [skid2_x(2:end); rear2(1)];
    skid2_y = [skid2_y(2:end); rear2(2)];
  else
    skid2_x = [skid2_x(2:end); NaN];
    skid2_y = [skid2_y(2:end); NaN];
  endif

  set(h_skid1, 'XData', skid1_x, 'YData', skid1_y);
  set(h_skid2, 'XData', skid2_x, 'YData', skid2_y);
  set(h_smoke, 'XData', smoke_x, 'YData', smoke_y);

  % Tandem Proximity Radar Sensor
  tandem_dist = hypot(x1 - x2, y1 - y2);
  set(h_radar_line, 'XData', [x1 x2], 'YData', [y1 y2]);
  set(h_radar_txt, 'Position', [(x1+x2)/2, (y1+y2)/2 + 2.5, 0], ...
      'String', sprintf('RADAR: %.1fm', tandem_dist));

  % Chase Car 5-Beam LiDAR Scanner (detects Lead Car proximity)
  for k = 1:N_lidar
    ray_ang = yaw2 + lidar_angles(k);
    ray_dx = cos(ray_ang);
    ray_dy = sin(ray_ang);
    % Project Lead Car position onto LiDAR beam
    rel_x = x1 - x2;
    rel_y = y1 - y2;
    proj = rel_x * ray_dx + rel_y * ray_dy;
    perp = abs(-rel_x * ray_dy + rel_y * ray_dx);
    if (proj > 0 && proj < lidar_max_range && perp < 3.6)
      hit_dist = max(3.5, proj - 2.8);
      set(h_lidar(k), 'XData', [x2, x2 + hit_dist*ray_dx], ...
                      'YData', [y2, y2 + hit_dist*ray_dy], ...
                      'Color', [1.0 0.25 0.25]);
    else
      set(h_lidar(k), 'XData', [x2, x2 + lidar_max_range*ray_dx], ...
                      'YData', [y2, y2 + lidar_max_range*ray_dy], ...
                      'Color', [0.0 0.85 1.0]);
    endif
  endfor

  % Check Clipping Zone Activation & Award Drift Points
  active_zone_str = 'NONE (TRANSIT)';
  for z = 1:4
    idx_z = zone_indices(z);
    zx = rx(idx_z) + nx(idx_z) * 5.5;
    zy = ry(idx_z) + ny(idx_z) * 5.5;
    d1_z = hypot(x1 - zx, y1 - zy);
    d2_z = hypot(x2 - zx, y2 - zy);
    if (d1_z < zone_radius || d2_z < zone_radius)
      set(h_zones(z), 'FaceColor', [0.15 1.0 0.45], 'FaceAlpha', 0.42, ...
                      'EdgeColor', [0.3 1.0 0.6]);
      active_zone_str = zone_names{z};
      total_score = total_score + round(abs(rad2deg(slip_rad1)) + abs(rad2deg(slip_rad2)));
    else
      set(h_zones(z), 'FaceColor', [1.0 0.65 0.0], 'FaceAlpha', 0.18, ...
                      'EdgeColor', [1.0 0.75 0.1]);
    endif
  endfor

  % Compute Realistic Telemetry Metrics
  gps_kmh1 = speed1 * 68.0;
  gps_kmh2 = speed2 * 68.0;
  slip_deg1 = rad2deg(slip_rad1);
  slip_deg2 = rad2deg(slip_rad2);
  steer_deg1 = -slip_deg1 * 0.82;
  steer_deg2 = -slip_deg2 * 0.85;
  lat_g1 = (gps_kmh1 / 3.6)^2 * k1 / 9.81 * 1.65;
  lat_g2 = (gps_kmh2 / 3.6)^2 * k2 / 9.81 * 1.65;
  rpm1 = round(4200 + abs(slip_deg1)*85 + gps_kmh1*18);
  rpm2 = round(4350 + abs(slip_deg2)*88 + gps_kmh2*18);
  tire_temp1 = 0.98 * tire_temp1 + 0.02 * (84 + abs(slip_deg1)*1.4);
  tire_temp2 = 0.98 * tire_temp2 + 0.02 * (85 + abs(slip_deg2)*1.5);

  % Update Rolling Sensor Plots
  slip1_hist = [slip1_hist(2:end); slip_deg1];
  slip2_hist = [slip2_hist(2:end); slip_deg2];
  latg1_hist = [latg1_hist(2:end); lat_g1];
  latg2_hist = [latg2_hist(2:end); lat_g2];

  set(h_plot_slip1, 'YData', slip1_hist);
  set(h_plot_slip2, 'YData', slip2_hist);
  set(h_plot_g1, 'YData', latg1_hist);
  set(h_plot_g2, 'YData', latg2_hist);

  % Update Live Digital Sensor Readout
  hud_str = sprintf([ ...
    'ACTIVE CLIPPING : %s\n' ...
    'TANDEM SCORE    : %06d pts   | RADAR GAP: %4.1f m\n' ...
    '-------------------------------------------------------\n' ...
    'SENSOR METRIC         CAR 1 (LEAD)      CAR 2 (CHASE)\n' ...
    'GPS Speed (km/h)   :    %6.1f             %6.1f\n' ...
    'IMU Slip Angle     :    %+6.1f deg         %+6.1f deg\n' ...
    'Counter-Steer      :    %+6.1f deg         %+6.1f deg\n' ...
    'Lateral Accel      :    %+6.2f g           %+6.2f g\n' ...
    'Rear Wheel RPM     :    %6d             %6d\n' ...
    'IR Tire Temp (C)   :    %6.1f             %6.1f'], ...
    active_zone_str, total_score, tandem_dist, ...
    gps_kmh1, gps_kmh2, ...
    slip_deg1, slip_deg2, ...
    steer_deg1, steer_deg2, ...
    lat_g1, lat_g2, ...
    rpm1, rpm2, ...
    tire_temp1, tire_temp2);

  set(h_hud_text, 'String', hud_str);

  drawnow;
  pause(0.015);
endfor
