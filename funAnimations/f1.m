function octave_f35_combat_sim()
% =========================================================================
% F-35A LIGHTNING II - TACTICAL COMBAT FLIGHT & SENSOR FUSION SIMULATION
% 100% Pure GNU Octave Compatible (No gobjects, no external toolboxes)
% Run directly by typing: octave_f35_combat_sim
% =========================================================================

  clear all;
  close all;
  clc;

  % Prefer qt or fltk for smooth real-time OpenGL rendering
  toolkits = available_graphics_toolkits();
  if any(strcmp(toolkits, 'qt'))
    graphics_toolkit('qt');
  elseif any(strcmp(toolkits, 'fltk'))
    graphics_toolkit('fltk');
  end

  % --- SIMULATION PARAMETERS ---
  dt = 0.04;                  % 25 FPS physics & render step
  t_max = 120.0;              % 2-minute sortie loop
  N_steps = round(t_max / dt);

  % --- CREATE DARK TACTICAL COCKPIT / C2 DISPLAY ---
  fig = figure('Name', 'F-35A Lightning II - AN/APG-81 AESA & DAS Combat Sim', ...
               'Color', [0.03 0.04 0.05], ...
               'Position', [40 40 1380 820], ...
               'NumberTitle', 'off');

  % =========================================================================
  % SUBPLOT 1: 3D TACTICAL BATTLESPACE (TERRAIN + F-35 + BANDITS + SAM + MISSILES)
  % =========================================================================
  ax3d = subplot('Position', [0.04 0.08 0.56 0.86]);
  set(ax3d, 'Color', [0.02 0.03 0.05], ...
            'XColor', [0.2 0.8 0.4], 'YColor', [0.2 0.8 0.4], 'ZColor', [0.2 0.8 0.4], ...
            'GridColor', [0.1 0.35 0.2], 'GridAlpha', 0.4);
  hold(ax3d, 'on');
  grid(ax3d, 'on');
  axis(ax3d, [-4500 4500 -4500 4500 0 3200]);
  view(ax3d, [-42 24]);
  xlabel(ax3d, 'EAST [m]', 'FontWeight', 'bold', 'Color', [0.3 0.9 0.5]);
  ylabel(ax3d, 'NORTH [m]', 'FontWeight', 'bold', 'Color', [0.3 0.9 0.5]);
  zlabel(ax3d, 'ALTITUDE MSL [m]', 'FontWeight', 'bold', 'Color', [0.3 0.9 0.5]);
  title(ax3d, '3D TACTICAL BATTLESPACE // LINK-16 & DAS SENSOR FUSION', ...
        'Color', [0.3 1.0 0.6], 'FontSize', 11, 'FontWeight', 'bold');

  % Generate procedural mountain canyon terrain mesh
  [Xg, Yg] = meshgrid(linspace(-4500, 4500, 38), linspace(-4500, 4500, 38));
  Zg = 420 * sin(Xg / 1100) .* cos(Yg / 1100) + ...
       260 * cos((Xg + Yg) / 750) + ...
       180 * exp(-((Xg - 1800).^2 + (Yg - 1500).^2) / 1.8e6) + 380;
  Zg(Zg < 20) = 20;

  surf(ax3d, Xg, Yg, Zg, ...
       'FaceColor', [0.04 0.11 0.08], ...
       'EdgeColor', [0.08 0.32 0.18], ...
       'FaceAlpha', 0.85);

  % --- SAM SITE (SA-20 GARGOYLE THREAT RING) ---
  sam_pos = [1600, 1400, 520];
  sam_r = 2100;
  theta_s = linspace(0, 2*pi, 60);
  plot3(ax3d, sam_pos(1) + sam_r*cos(theta_s), ...
              sam_pos(2) + sam_r*sin(theta_s), ...
              ones(size(theta_s))*sam_pos(3), ...
              '--', 'Color', [1.0 0.2 0.2], 'LineWidth', 1.2);
  plot3(ax3d, sam_pos(1), sam_pos(2), sam_pos(3), '^', ...
        'MarkerSize', 9, 'MarkerFaceColor', [1 0.15 0.15], 'MarkerEdgeColor', 'w');
  text(sam_pos(1)+120, sam_pos(2), sam_pos(3)+180, 'SAM SA-20 [WEZ]', ...
       'Color', [1.0 0.35 0.35], 'FontSize', 8, 'FontWeight', 'bold', 'Parent', ax3d);

  % --- F-35A 3D WIREFRAME / PATCH MODEL (LOCAL BODY COORDS, SCALED FOR VISIBILITY) ---
  % Nose = +X, Right Wing = +Y, Up = +Z
  S = 260; % Visual scale factor so aircraft attitude (roll/pitch/yaw) is super clear
  f35_verts_local = [
     1.35,  0.00,  0.02;   % 1: Radome Nose (chine)
     0.55,  0.22,  0.06;   % 2: Forward Fuselage Right
     0.55, -0.22,  0.06;   % 3: Forward Fuselage Left
     0.15,  1.15, -0.02;   % 4: Right Wingtip Leading
    -0.35,  1.15, -0.02;   % 5: Right Wingtip Trailing
    -0.45,  0.28,  0.04;   % 6: Right Wing Root Trailing
    -0.85,  0.55,  0.00;   % 7: Right Horizontal Stabilator
    -0.95,  0.18,  0.02;   % 8: Right Nozzle / Tail
    -0.95, -0.18,  0.02;   % 9: Left Nozzle / Tail
    -0.85, -0.55,  0.00;   % 10: Left Horizontal Stabilator
    -0.45, -0.28,  0.04;   % 11: Left Wing Root Trailing
    -0.35, -1.15, -0.02;   % 12: Left Wingtip Trailing
     0.15, -1.15, -0.02;   % 13: Left Wingtip Leading
     0.35,  0.00,  0.22;   % 14: Canopy Apex
    -0.75,  0.34,  0.42;   % 15: Right Canted Vertical Tail Tip
    -0.75, -0.34,  0.42    % 16: Left Canted Vertical Tail Tip
  ] * S;

  % Main planform polygon + twin canted vertical tails
  f35_body_idx = [1 2 4 5 6 7 8 9 10 11 12 13 3];
  h_f35_body = patch('XData', f35_verts_local(f35_body_idx, 1), ...
                     'YData', f35_verts_local(f35_body_idx, 2), ...
                     'ZData', f35_verts_local(f35_body_idx, 3), ...
                     'FaceColor', [0.38 0.43 0.48], ...
                     'EdgeColor', [0.2 1.0 0.9], ...
                     'LineWidth', 1.4, 'Parent', ax3d);

  h_f35_vtail_r = patch('XData', f35_verts_local([6 8 15], 1), ...
                        'YData', f35_verts_local([6 8 15], 2), ...
                        'ZData', f35_verts_local([6 8 15], 3), ...
                        'FaceColor', [0.30 0.35 0.40], ...
                        'EdgeColor', [0.2 1.0 0.9], ...
                        'LineWidth', 1.1, 'Parent', ax3d);

  h_f35_vtail_l = patch('XData', f35_verts_local([11 9 16], 1), ...
                        'YData', f35_verts_local([11 9 16], 2), ...
                        'ZData', f35_verts_local([11 9 16], 3), ...
                        'FaceColor', [0.30 0.35 0.40], ...
                        'EdgeColor', [0.2 1.0 0.9], ...
                        'LineWidth', 1.1, 'Parent', ax3d);

  % F135 Afterburner Plume
  h_ab = plot3(ax3d, [0 0], [0 0], [0 0], '-', 'Color', [1.0 0.55 0.05], 'LineWidth', 4.5);

  % AN/APG-81 AESA Radar Scanning Cone Lines (4 rays)
  h_radar = zeros(4, 1);
  for k = 1:4
    h_radar(k) = plot3(ax3d, [0 0], [0 0], [0 0], '-', 'Color', [0.1 0.95 0.5], 'LineWidth', 1.0);
  end

  % Flight Trail Buffer (NaN-safe fixed ring buffer)
  N_trail = 140;
  trail_x = nan(N_trail, 1);
  trail_y = nan(N_trail, 1);
  trail_z = nan(N_trail, 1);
  h_trail = plot3(ax3d, trail_x, trail_y, trail_z, '-', 'Color', [0.15 0.85 1.0], 'LineWidth', 1.4);

  % --- 2 HOSTILE BANDITS (SU-57 / MIG-35) ---
  h_b1 = plot3(ax3d, 0, 0, 0, 'd', 'MarkerSize', 9, 'MarkerFaceColor', [1 0.2 0.2], 'MarkerEdgeColor', 'y', 'LineWidth', 1.3);
  h_b2 = plot3(ax3d, 0, 0, 0, 'd', 'MarkerSize', 9, 'MarkerFaceColor', [1 0.2 0.2], 'MarkerEdgeColor', 'y', 'LineWidth', 1.3);
  h_b1_txt = text(0, 0, 0, 'BANDIT-1', 'Color', [1 0.35 0.35], 'FontSize', 8, 'FontWeight', 'bold', 'Parent', ax3d);
  h_b2_txt = text(0, 0, 0, 'BANDIT-2', 'Color', [1 0.35 0.35], 'FontSize', 8, 'FontWeight', 'bold', 'Parent', ax3d);

  % --- AIM-120D AMRAAM MISSILE & FLARE DECOYS ---
  h_msl = plot3(ax3d, nan, nan, nan, 'o', 'MarkerSize', 6, 'MarkerFaceColor', [1 1 0.2], 'MarkerEdgeColor', 'r');
  N_msl_tr = 35;
  msl_tx = nan(N_msl_tr, 1);
  msl_ty = nan(N_msl_tr, 1);
  msl_tz = nan(N_msl_tr, 1);
  h_msl_tr = plot3(ax3d, msl_tx, msl_ty, msl_tz, '-', 'Color', [1 0.9 0.3], 'LineWidth', 1.8);

  % Chaff / IR Flare Burst Handles
  N_flares = 18;
  flare_pos = nan(N_flares, 3);
  flare_vel = zeros(N_flares, 3);
  flare_life = zeros(N_flares, 1);
  h_flares = plot3(ax3d, flare_pos(:,1), flare_pos(:,2), flare_pos(:,3), '*', ...
                   'Color', [1.0 0.85 0.2], 'MarkerSize', 7);

  % =========================================================================
  % SUBPLOT 2: HELMET-MOUNTED DISPLAY (HMDS) PITCH LADDER & BORESIGHT HUD
  % =========================================================================
  ax_hud = subplot('Position', [0.63 0.63 0.34 0.31]);
  set(ax_hud, 'Color', [0.01 0.05 0.02], ...
              'XColor', [0.2 1.0 0.3], 'YColor', [0.2 1.0 0.3], ...
              'XTick', [], 'YTick', []);
  hold(ax_hud, 'on');
  axis(ax_hud, [-1.2 1.2 -1.0 1.0]);
  title(ax_hud, 'GEN-III HMDS // BORESIGHT & TARGET DESIGNATOR', ...
        'Color', [0.25 1.0 0.35], 'FontSize', 9.5, 'FontWeight', 'bold');

  % Fixed aircraft boresight reticle (-W-)
  plot(ax_hud, [-0.22 -0.08 -0.04 0 0.04 0.08 0.22], ...
               [0 0 -0.06 0 -0.06 0 0], '-', 'Color', [0.2 1.0 0.3], 'LineWidth', 1.8);
  % Compass heading tape frame
  plot(ax_hud, [-0.8 0.8], [0.82 0.82], '-', 'Color', [0.2 1.0 0.3], 'LineWidth', 1.0);
  h_hud_hdg = text(0, 0.90, 'HDG 000', 'Color', [0.2 1.0 0.3], 'FontSize', 9, ...
                   'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Parent', ax_hud);
  h_hud_spd = text(-1.12, 0.0, 'M 1.15', 'Color', [0.2 1.0 0.3], 'FontSize', 9, ...
                   'FontWeight', 'bold', 'Parent', ax_hud);
  h_hud_alt = text(0.72, 0.0, 'ALT 1800', 'Color', [0.2 1.0 0.3], 'FontSize', 9, ...
                   'FontWeight', 'bold', 'Parent', ax_hud);
  h_hud_g   = text(-1.12, -0.78, 'G: +1.0', 'Color', [0.2 1.0 0.3], 'FontSize', 8.5, ...
                   'FontWeight', 'bold', 'Parent', ax_hud);
  h_hud_aoa = text(-1.12, -0.90, 'AOA: 4.2', 'Color', [0.2 1.0 0.3], 'FontSize', 8.5, ...
                   'FontWeight', 'bold', 'Parent', ax_hud);
  h_hud_wpn = text(0.35, -0.85, 'ARM: AIM-120D [4]', 'Color', [1.0 0.9 0.2], 'FontSize', 8.5, ...
                   'FontWeight', 'bold', 'Parent', ax_hud);

  % Artificial Horizon Line + Pitch Ladder Rungs
  h_horizon = plot(ax_hud, [-0.9 0.9], [0 0], '-', 'Color', [0.2 1.0 0.3], 'LineWidth', 1.6);
  h_pitch_up = plot(ax_hud, [-0.35 0.35], [0.25 0.25], '--', 'Color', [0.2 1.0 0.3], 'LineWidth', 1.0);
  h_pitch_dn = plot(ax_hud, [-0.35 0.35], [-0.25 -0.25], '--', 'Color', [0.2 1.0 0.3], 'LineWidth', 1.0);

  % Target Designation Box (TD Box) in HUD
  h_td_box = plot(ax_hud, nan(5,1), nan(5,1), '-', 'Color', [1.0 0.25 0.25], 'LineWidth', 1.8);
  h_td_lbl = text(0, 0, '', 'Color', [1.0 0.35 0.35], 'FontSize', 8, 'FontWeight', 'bold', 'Parent', ax_hud);

  % =========================================================================
  % SUBPLOT 3: AN/APG-81 AESA RADAR & RWR TACTICAL SITUATION DISPLAY (TSD)
  % =========================================================================
  ax_tsd = subplot('Position', [0.63 0.33 0.16 0.25]);
  set(ax_tsd, 'Color', [0.01 0.04 0.06], ...
              'XColor', [0.2 0.8 1.0], 'YColor', [0.2 0.8 1.0], ...
              'XTick', [], 'YTick', []);
  hold(ax_tsd, 'on');
  axis(ax_tsd, [-1.15 1.15 -1.15 1.15]);
  axis(ax_tsd, 'equal');
  title(ax_tsd, 'AESA TSD / RWR', 'Color', [0.3 0.9 1.0], 'FontSize', 9, 'FontWeight', 'bold');

  % Radar range rings & azimuth cone
  rc = linspace(0, 2*pi, 60);
  plot(ax_tsd, cos(rc), sin(rc), '-', 'Color', [0.15 0.45 0.65], 'LineWidth', 1.0);
  plot(ax_tsd, 0.5*cos(rc), 0.5*sin(rc), ':', 'Color', [0.15 0.45 0.65], 'LineWidth', 0.9);
  plot(ax_tsd, [0 -sin(pi/3)], [0 cos(pi/3)], '--', 'Color', [0.1 0.7 0.4], 'LineWidth', 0.9);
  plot(ax_tsd, [0  sin(pi/3)], [0 cos(pi/3)], '--', 'Color', [0.1 0.7 0.4], 'LineWidth', 0.9);
  plot(ax_tsd, [0 -0.1 0.1 0], [0.08 -0.06 -0.06 0.08], '-', 'Color', [0.2 1.0 0.4], 'LineWidth', 1.5);

  h_tsd_sweep = plot(ax_tsd, [0 0], [0 1], '-', 'Color', [0.2 1.0 0.5], 'LineWidth', 1.2);
  h_tsd_b1 = plot(ax_tsd, nan, nan, 'v', 'MarkerSize', 7, 'MarkerFaceColor', [1 0.2 0.2], 'MarkerEdgeColor', 'y');
  h_tsd_b2 = plot(ax_tsd, nan, nan, 'v', 'MarkerSize', 7, 'MarkerFaceColor', [1 0.2 0.2], 'MarkerEdgeColor', 'y');
  h_tsd_sam = plot(ax_tsd, nan, nan, '^', 'MarkerSize', 7, 'MarkerFaceColor', [1 0.5 0.1], 'MarkerEdgeColor', 'r');

  % =========================================================================
  % SUBPLOT 4: F135 ENGINE, AVIONICS & EW TELEMETRY CONSOLE
  % =========================================================================
  ax_txt = subplot('Position', [0.80 0.33 0.17 0.25]);
  set(ax_txt, 'Color', [0.02 0.03 0.04], 'XTick', [], 'YTick', [], ...
              'XColor', [0.2 0.8 0.4], 'YColor', [0.2 0.8 0.4]);
  axis(ax_txt, [0 1 0 1]);
  title(ax_txt, 'F135 / EW BUS', 'Color', [0.3 1.0 0.6], 'FontSize', 9, 'FontWeight', 'bold');
  h_telem = text(0.05, 0.94, 'BOOTING AVIONICS...', ...
                 'Color', [0.75 1.0 0.80], 'FontName', 'FixedWidth', ...
                 'FontSize', 7.8, 'VerticalAlignment', 'top', 'Parent', ax_txt);

  % =========================================================================
  % SUBPLOT 5: LIVE FLIGHT DYNAMICS WAVEFORMS (G-LOAD, MACH, RCS dBsm)
  % =========================================================================
  ax_wave = subplot('Position', [0.63 0.08 0.34 0.19]);
  set(ax_wave, 'Color', [0.02 0.03 0.05], ...
               'XColor', [0.2 0.8 0.4], 'YColor', [0.2 0.8 0.4], ...
               'GridColor', [0.1 0.3 0.2]);
  hold(ax_wave, 'on');
  grid(ax_wave, 'on');
  N_win = 100;
  w_t = linspace(-N_win*dt, 0, N_win);
  buf_g   = ones(N_win, 1);
  buf_aoa = zeros(N_win, 1);
  buf_rcs = -35 * ones(N_win, 1);

  h_wg   = plot(ax_wave, w_t, buf_g, '-', 'Color', [0.2 1.0 0.4], 'LineWidth', 1.4);
  h_waoa = plot(ax_wave, w_t, buf_aoa / 5, '-', 'Color', [0.2 0.85 1.0], 'LineWidth', 1.3);
  h_wrcs = plot(ax_wave, w_t, (buf_rcs + 40)/5, '-', 'Color', [1.0 0.45 0.2], 'LineWidth', 1.2);
  ylim(ax_wave, [-2 9]);
  xlim(ax_wave, [-N_win*dt 0]);
  title(ax_wave, 'TELEMETRY: G-LOAD [G] | AOA/5 [DEG] | LO-RCS INDEX', ...
        'Color', [0.3 1.0 0.6], 'FontSize', 8.5, 'FontWeight', 'bold');

  % =========================================================================
  % INITIALIZE COMBAT STATE VECTORS
  % =========================================================================
  pos = [-2600, -2400, 1650];   % F-35 initial position [m]
  vel_mag = 340;                % ~Mach 1.05 [m/s]
  yaw = pi/4;                   % Heading [rad]
  pitch = 0.05;                 % Pitch [rad]
  roll = 0.0;                   % Bank [rad]

  % Bandit 1 & Bandit 2 states
  b1_pos = [2200, 2400, 1950];
  b1_alive = true;
  b2_pos = [2800, -1600, 1800];
  b2_alive = true;

  % Missile & Weapon state
  amraam_count = 4;
  msl_active = false;
  msl_pos = [0 0 0];
  msl_vel = [0 0 0];
  msl_target = 1;
  last_fire_t = -10;
  last_flare_t = -10;
  kills = 0;

  % =========================================================================
  % MAIN REAL-TIME SIMULATION LOOP
  % =========================================================================
  for step = 1:N_steps
    if ~ishandle(fig)
      break;
    end

    t = step * dt;

    % --- 1. TACTICAL GUIDANCE & MANEUVERING LAW (TERRAIN MASKING + INTERCEPT) ---
    if b1_alive
      tgt_pos = b1_pos;
      tgt_id = 1;
    elseif b2_alive
      tgt_pos = b2_pos;
      tgt_id = 2;
    else
      % Respawn wave if both bandits splashed
      b1_pos = [2600*cos(t), 2600*sin(t), 1900];
      b2_pos = [-2400*sin(t), 2400*cos(t), 1850];
      b1_alive = true;
      b2_alive = true;
      tgt_pos = b1_pos;
      tgt_id = 1;
    end

    % Lead pursuit vector toward active target + sinusoidal barrel-roll weave
    to_tgt = tgt_pos - pos;
    dist_tgt = norm(to_tgt);
    desired_yaw = atan2(to_tgt(2), to_tgt(1)) + 0.28 * sin(0.45 * t);

    % Terrain-following altitude floor check
    local_ground = 420 * sin(pos(1)/1100)*cos(pos(2)/1100) + ...
                   260 * cos((pos(1)+pos(2))/750) + 420;
    safe_alt = max(tgt_pos(3), local_ground + 550);
    desired_pitch = atan2(safe_alt - pos(3), max(dist_tgt, 600)) + 0.14 * cos(0.7 * t);
    desired_pitch = max(min(desired_pitch, 0.55), -0.45);

    % Shortest angular error for yaw
    yaw_err = atan2(sin(desired_yaw - yaw), cos(desired_yaw - yaw));
    desired_roll = max(min(2.4 * yaw_err, 1.25), -1.25);

    % Smooth aerodynamic actuator response
    yaw_rate = 1.35 * yaw_err;
    yaw = yaw + yaw_rate * dt;
    pitch = pitch + 2.2 * (desired_pitch - pitch) * dt;
    roll = roll + 3.5 * (desired_roll - roll) * dt;

    % Speed & G-load calculation (F135 afterburner modulation)
    ab_active = (dist_tgt > 1800) || (abs(yaw_err) > 0.45);
    target_spd = 310 + 95 * ab_active - 35 * abs(roll);
    vel_mag = vel_mag + 1.5 * (target_spd - vel_mag) * dt;

    % Kinematic velocity vector in world coordinates
    vx = vel_mag * cos(pitch) * cos(yaw);
    vy = vel_mag * cos(pitch) * sin(yaw);
    vz = vel_mag * sin(pitch);
    pos = pos + [vx, vy, vz] * dt;

    % Aerodynamic telemetry: G-load, AoA, and Dynamic Stealth RCS (dBsm)
    turn_g = (vel_mag * abs(yaw_rate)) / 9.81;
    g_load = cos(pitch)/max(cos(roll), 0.35) + 0.65 * turn_g;
    g_load = min(max(g_load, -1.5), 9.0);
    aoa_deg = 2.5 + 2.1 * (g_load - 1.0) + 1.5 * abs(sin(0.9*t));
    % Stealth RCS degrades slightly when banking hard (exposing planform) or weapon bay open
    bay_open = (t - last_fire_t) < 1.2;
    rcs_dbsm = -40.0 + 9.5 * abs(sin(roll)) + 14.0 * bay_open;

    % --- 2. BANDIT KINEMATICS (EVASIVE DEFENSIVE SPLITS) ---
    if b1_alive
      b1_ang = 0.32 * t + 0.6;
      b1_pos = [1900 * cos(b1_ang) + 400*sin(0.5*t), ...
                2100 * sin(b1_ang), ...
                1850 + 280 * sin(0.4 * t)];
    end
    if b2_alive
      b2_ang = -0.28 * t + 2.1;
      b2_pos = [2300 * cos(b2_ang), ...
                2200 * sin(b2_ang) - 400*cos(0.4*t), ...
                1720 + 240 * cos(0.35 * t)];
    end

    % --- 3. WEAPONS RELEASE (AIM-120D AMRAAM) & PROPORTIONAL NAVIGATION ---
    in_wez = (dist_tgt < 3400) && (abs(yaw_err) < 0.48);
    if ~msl_active && in_wez && (amraam_count > 0) && ((t - last_fire_t) > 5.5)
      msl_active = true;
      msl_target = tgt_id;
      msl_pos = pos + [0 0 -40];
      msl_vel = [vx, vy, vz] * 1.4;
      amraam_count = amraam_count - 1;
      last_fire_t = t;
      msl_tx(:) = nan; msl_ty(:) = nan; msl_tz(:) = nan;
    end

    if msl_active
      if msl_target == 1 && b1_alive
        m_tgt = b1_pos;
      elseif msl_target == 2 && b2_alive
        m_tgt = b2_pos;
      else
        msl_active = false;
      end

      if msl_active
        r_vec = m_tgt - msl_pos;
        r_dist = norm(r_vec);
        if r_dist < 140
          % Splash bandit!
          if msl_target == 1
            b1_alive = false;
          else
            b2_alive = false;
          end
          kills = kills + 1;
          msl_active = false;
          set(h_msl, 'XData', nan, 'YData', nan, 'ZData', nan);
        else
          % Mach 3.5 Proportional Navigation pursuit
          m_dir = r_vec / r_dist;
          msl_vel = 980 * m_dir;
          msl_pos = msl_pos + msl_vel * dt;
          msl_tx = [msl_tx(2:end); msl_pos(1)];
          msl_ty = [msl_ty(2:end); msl_pos(2)];
          msl_tz = [msl_tz(2:end); msl_pos(3)];
          set(h_msl, 'XData', msl_pos(1), 'YData', msl_pos(2), 'ZData', msl_pos(3));
          set(h_msl_tr, 'XData', msl_tx, 'YData', msl_ty, 'ZData', msl_tz);
        end
      end
    end

    % --- 4. SAM THREAT WARNING & AUTOMATIC IR FLARE COUNTERMEASURES ---
    sam_dist = norm(pos - sam_pos);
    rwr_spike = (sam_dist < sam_r);
    if rwr_spike && ((t - last_flare_t) > 3.2)
      last_flare_t = t;
      for f = 1:N_flares
        flare_pos(f, :) = pos - 80*[cos(yaw) sin(yaw) 0];
        flare_vel(f, :) = [vx vy vz]*0.3 + 95*randn(1,3) + [0 0 -75];
        flare_life(f) = 1.6;
      end
    end

    % Update falling flare decoys
    alive_f = flare_life > 0;
    if any(alive_f)
      flare_pos(alive_f, :) = flare_pos(alive_f, :) + flare_vel(alive_f, :) * dt;
      flare_vel(alive_f, 3) = flare_vel(alive_f, 3) - 25 * dt;
      flare_life(alive_f) = flare_life(alive_f) - dt;
      flare_pos(~alive_f, :) = nan;
      set(h_flares, 'XData', flare_pos(:,1), 'YData', flare_pos(:,2), 'ZData', flare_pos(:,3));
    end

    % --- 5. ROTATE & UPDATE 3D F-35A MESH, AFTERBURNER & AESA RADAR CONE ---
    R_yaw   = [cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1];
    R_pitch = [cos(pitch) 0 sin(pitch); 0 1 0; -sin(pitch) 0 cos(pitch)];
    R_roll  = [1 0 0; 0 cos(roll) -sin(roll); 0 sin(roll) cos(roll)];
    R_wb = R_yaw * R_pitch * R_roll;

    V_world = (R_wb * f35_verts_local')' + pos;

    set(h_f35_body, 'XData', V_world(f35_body_idx, 1), ...
                    'YData', V_world(f35_body_idx, 2), ...
                    'ZData', V_world(f35_body_idx, 3));
    set(h_f35_vtail_r, 'XData', V_world([6 8 15], 1), ...
                       'YData', V_world([6 8 15], 2), ...
                       'ZData', V_world([6 8 15], 3));
    set(h_f35_vtail_l, 'XData', V_world([11 9 16], 1), ...
                       'YData', V_world([11 9 16], 2), ...
                       'ZData', V_world([11 9 16], 3));

    % Afterburner flame plume behind F135 nozzle
    ab_len = (1.1 + 0.5*ab_active + 0.25*rand()) * S;
    nozzle_pt = (R_wb * [-0.95*S; 0; 0.02*S])' + pos;
    flame_pt  = (R_wb * [-(0.95*S + ab_len); 0; 0.02*S])' + pos;
    set(h_ab, 'XData', [nozzle_pt(1) flame_pt(1)], ...
              'YData', [nozzle_pt(2) flame_pt(2)], ...
              'ZData', [nozzle_pt(3) flame_pt(3)]);

    % AN/APG-81 AESA Radar Cone (sweeping azimuth & elevation rays)
    nose_pt = V_world(1, :);
    scan_az = 0.55 * sin(5.5 * t);
    cone_dirs = [ 1800,  750 + 300*sin(5.5*t),  420;
                  1800, -750 + 300*sin(5.5*t),  420;
                  1800, -750 + 300*sin(5.5*t), -420;
                  1800,  750 + 300*sin(5.5*t), -420 ];
    for k = 1:4
      ray_end = (R_wb * cone_dirs(k, :)')' + nose_pt;
      set(h_radar(k), 'XData', [nose_pt(1) ray_end(1)], ...
                      'YData', [nose_pt(2) ray_end(2)], ...
                      'ZData', [nose_pt(3) ray_end(3)]);
    end

    % Update Wingtip Contrail History
    trail_x = [trail_x(2:end); pos(1)];
    trail_y = [trail_y(2:end); pos(2)];
    trail_z = [trail_z(2:end); pos(3)];
    set(h_trail, 'XData', trail_x, 'YData', trail_y, 'ZData', trail_z);

    % Update Bandit Markers
    if b1_alive
      set(h_b1, 'XData', b1_pos(1), 'YData', b1_pos(2), 'ZData', b1_pos(3));
      set(h_b1_txt, 'Position', b1_pos + [0 0 160], 'String', sprintf('BANDIT-1 [%.0fm]', norm(b1_pos-pos)));
    else
      set(h_b1, 'XData', nan, 'YData', nan, 'ZData', nan);
      set(h_b1_txt, 'String', '');
    end
    if b2_alive
      set(h_b2, 'XData', b2_pos(1), 'YData', b2_pos(2), 'ZData', b2_pos(3));
      set(h_b2_txt, 'Position', b2_pos + [0 0 160], 'String', sprintf('BANDIT-2 [%.0fm]', norm(b2_pos-pos)));
    else
      set(h_b2, 'XData', nan, 'YData', nan, 'ZData', nan);
      set(h_b2_txt, 'String', '');
    end

    % Gentle orbital tactical camera tracking
    view(ax3d, [-40 + 18*sin(0.12*t), 23 + 5*cos(0.15*t)]);

    % --- 6. UPDATE GEN-III HMDS (HELMET-MOUNTED DISPLAY HUD) ---
    hdg_deg = mod(round(90 - rad2deg(yaw)), 360);
    mach_num = vel_mag / 316.0;
    set(h_hud_hdg, 'String', sprintf('HDG %03d', hdg_deg));
    set(h_hud_spd, 'String', sprintf('M %.2f', mach_num));
    set(h_hud_alt, 'String', sprintf('ALT %04.0f', pos(3)));
    set(h_hud_g,   'String', sprintf('G: %+4.1f', g_load));
    set(h_hud_aoa, 'String', sprintf('AOA: %4.1f', aoa_deg));
    set(h_hud_wpn, 'String', sprintf('AIM-120D [%d] KILLS:%d', amraam_count, kills));

    % Rotate & shift pitch ladder with aircraft roll and pitch
    p_off = -pitch * 1.1;
    c_r = cos(-roll); s_r = sin(-roll);
    pts_h  = [c_r -s_r; s_r c_r] * [-0.85 0.85; p_off p_off];
    pts_pu = [c_r -s_r; s_r c_r] * [-0.32 0.32; p_off+0.25 p_off+0.25];
    pts_pd = [c_r -s_r; s_r c_r] * [-0.32 0.32; p_off-0.25 p_off-0.25];
    set(h_horizon,  'XData', pts_h(1,:),  'YData', pts_h(2,:));
    set(h_pitch_up, 'XData', pts_pu(1,:), 'YData', pts_pu(2,:));
    set(h_pitch_dn, 'XData', pts_pd(1,:), 'YData', pts_pd(2,:));

    % Project active target into Helmet-Mounted Sight TD Box
    rel_body = R_wb' * (tgt_pos - pos)';
    if rel_body(1) > 100
      az_hud = max(min(atan2(rel_body(2), rel_body(1)) * 1.3, 0.95), -0.95);
      el_hud = max(min(atan2(rel_body(3), rel_body(1)) * 1.3, 0.75), -0.75);
      bx = 0.09;
      set(h_td_box, 'XData', [az_hud-bx az_hud+bx az_hud+bx az_hud-bx az_hud-bx], ...
                    'YData', [el_hud-bx el_hud-bx el_hud+bx el_hud+bx el_hud-bx]);
      set(h_td_lbl, 'Position', [az_hud+0.11, el_hud], ...
                    'String', sprintf('LOCK %.1fkm', dist_tgt/1000));
    else
      set(h_td_box, 'XData', nan(5,1), 'YData', nan(5,1));
      set(h_td_lbl, 'String', '');
    end

    % --- 7. UPDATE AESA TSD / RWR RADAR SCOPE ---
    set(h_tsd_sweep, 'XData', [0 sin(scan_az)], 'YData', [0 cos(scan_az)]);
    max_rng = 6500;
    if b1_alive
      b1_loc = R_yaw' * (b1_pos - pos)';
      set(h_tsd_b1, 'XData', -b1_loc(2)/max_rng, 'YData', b1_loc(1)/max_rng);
    else
      set(h_tsd_b1, 'XData', nan, 'YData', nan);
    end
    if b2_alive
      b2_loc = R_yaw' * (b2_pos - pos)';
      set(h_tsd_b2, 'XData', -b2_loc(2)/max_rng, 'YData', b2_loc(1)/max_rng);
    else
      set(h_tsd_b2, 'XData', nan, 'YData', nan);
    end
    sam_loc = R_yaw' * (sam_pos - pos)';
    set(h_tsd_sam, 'XData', -sam_loc(2)/max_rng, 'YData', sam_loc(1)/max_rng);

    % --- 8. UPDATE F135 / EW AVIONICS BUS READOUT ---
    if rwr_spike
      ew_str = 'RWR: SA-20 LOCK! [FLARE]';
    else
      ew_str = 'RWR: SEARCH / LO-MASKED';
    end
    if msl_active
      msl_str = 'FOX-3: PITBULL ACTIVE';
    elseif in_wez
      msl_str = 'WPN: IN-RANGE SHOOT';
    else
      msl_str = 'WPN: AESA TWS TRACK';
    end

    telem_str = sprintf([ ...
      'SYS : F-35A BLK-4\n' ...
      'ENG : F135 %s\n' ...
      'EGT : %4.0f C\n' ...
      'RCS : %5.1f dBsm\n' ...
      'ROLL: %+5.1f deg\n' ...
      'PTCH: %+5.1f deg\n' ...
      '%s\n' ...
      '%s'], ...
      ternary(ab_active, 'MAX A/B', 'MIL 96%'), ...
      790 + 185*ab_active + 12*sin(t), ...
      rcs_dbsm, rad2deg(roll), rad2deg(pitch), ew_str, msl_str);
    set(h_telem, 'String', telem_str);

    % --- 9. UPDATE TELEMETRY WAVEFORMS ---
    buf_g   = [buf_g(2:end); g_load];
    buf_aoa = [buf_aoa(2:end); aoa_deg];
    buf_rcs = [buf_rcs(2:end); rcs_dbsm];
    set(h_wg,   'YData', buf_g);
    set(h_waoa, 'YData', buf_aoa / 5);
    set(h_wrcs, 'YData', (buf_rcs + 40) / 5);

    drawnow;
  end
end

function out = ternary(cond, a, b)
  if cond
    out = a;
  else
    out = b;
  end
end
