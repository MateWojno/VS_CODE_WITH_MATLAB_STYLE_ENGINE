function octave_6dof_sorting_robot()
  % OCTAVE_6DOF_SORTING_ROBOT
  % 6-DOF Articulated Sorting Robot Simulation with Conveyor, Optical Sensors & Live Telemetry
  % Strictly GNU Octave compatible (no gobjects, no local function scoping issues)

  close all;
  clc;

  %% 1. ROBOT KINEMATICS & WORKCELL PARAMETERS
  L1 = 1.15; % Base to Shoulder height (m)
  L2 = 1.45; % Upper arm length (m)
  L3 = 1.30; % Forearm length (m)
  L4 = 0.42; % Wrist pitch to TCP length (m)

  % Conveyor & Pick Zone
  conv_y_pick = 1.55;
  conv_z_top  = 0.55;
  pick_pos    = [0.00, conv_y_pick, conv_z_top + 0.14];
  home_pos    = [0.00, 1.10, 1.85];

  % 4 Color-Coded Sorting Bins: [x, y, z_drop]
  bin_coords = [
    -1.65, -0.75, 0.85;  % Bin 1: Red
    -0.60, -1.45, 0.85;  % Bin 2: Green
     0.60, -1.45, 0.85;  % Bin 3: Blue
     1.65, -0.75, 0.85   % Bin 4: Yellow
  ];
  bin_colors = [
    0.92, 0.22, 0.22;
    0.18, 0.78, 0.35;
    0.20, 0.50, 0.95;
    0.95, 0.78, 0.15
  ];
  bin_names = {'RED', 'GREEN', 'BLUE', 'YELLOW'};
  bin_counts = [0, 0, 0, 0];

  %% 2. FIGURE & SUBPLOT SETUP
  fig = figure('Name', 'GNU Octave 6-DOF Sorting Robot Cell', ...
               'Color', [0.08, 0.09, 0.12], ...
               'Position', [60, 60, 1280, 740], ...
               'NumberTitle', 'off');

  % Left Panel: 3D Workcell Viewport
  ax3d = subplot('Position', [0.04, 0.08, 0.56, 0.85]);
  hold(ax3d, 'on');
  grid(ax3d, 'on');
  axis(ax3d, 'equal');
  xlim(ax3d, [-2.4, 2.4]);
  ylim(ax3d, [-2.2, 2.3]);
  zlim(ax3d, [0.0, 3.2]);
  view(ax3d, 38, 26);
  set(ax3d, 'Color', [0.11, 0.13, 0.17], ...
            'XColor', [0.75, 0.78, 0.82], ...
            'YColor', [0.75, 0.78, 0.82], ...
            'ZColor', [0.75, 0.78, 0.82], ...
            'GridColor', [0.28, 0.32, 0.38]);
  xlabel(ax3d, 'X (m)');
  ylabel(ax3d, 'Y (m)');
  zlabel(ax3d, 'Z (m)');
  title(ax3d, '6-DOF Articulated Sorting Cell & Optical Inspection', ...
        'Color', [0.95, 0.96, 0.98], 'FontSize', 12, 'FontWeight', 'bold');

  %% 3. BUILD STATIC WORKCELL ENVIRONMENT
  % Floor grid tile
  patch(ax3d, [-2.3, 2.3, 2.3, -2.3], [-2.1, -2.1, 2.2, 2.2], [0, 0, 0, 0], ...
        [0.14, 0.16, 0.20], 'EdgeColor', [0.25, 0.28, 0.34]);

  % Robot Pedestal Base
  draw_static_box(ax3d, [0, 0, 0.15], [0.55, 0.55, 0.30], [0.25, 0.28, 0.33], [0.5, 0.55, 0.6]);

  % Conveyor Belt Structure
  draw_static_box(ax3d, [0, conv_y_pick, conv_z_top/2], [3.8, 0.68, conv_z_top], ...
                  [0.20, 0.22, 0.26], [0.45, 0.48, 0.52]);
  % Conveyor top belt surface
  patch(ax3d, [-1.9, 1.9, 1.9, -1.9], ...
        [conv_y_pick-0.32, conv_y_pick-0.32, conv_y_pick+0.32, conv_y_pick+0.32], ...
        [conv_z_top+0.005, conv_z_top+0.005, conv_z_top+0.005, conv_z_top+0.005], ...
        [0.12, 0.13, 0.15], 'EdgeColor', 'none');

  % Animated Conveyor Belt Slats (to show belt motion)
  num_slats = 12;
  slat_x = linspace(-1.75, 1.75, num_slats);
  h_slats = zeros(num_slats, 1);
  for i = 1:num_slats
    h_slats(i) = plot3(ax3d, [slat_x(i), slat_x(i)], ...
                       [conv_y_pick-0.30, conv_y_pick+0.30], ...
                       [conv_z_top+0.01, conv_z_top+0.01], ...
                       'Color', [0.35, 0.38, 0.42], 'LineWidth', 1.5);
  end

  % Optical Break-Beam Laser Sensor Posts & Beam
  draw_static_box(ax3d, [0.0, conv_y_pick-0.38, conv_z_top+0.15], [0.08, 0.08, 0.30], ...
                  [0.9, 0.6, 0.1], [0.2, 0.2, 0.2]);
  draw_static_box(ax3d, [0.0, conv_y_pick+0.38, conv_z_top+0.15], [0.08, 0.08, 0.30], ...
                  [0.9, 0.6, 0.1], [0.2, 0.2, 0.2]);
  h_laser = plot3(ax3d, [0, 0], [conv_y_pick-0.34, conv_y_pick+0.34], ...
                  [conv_z_top+0.14, conv_z_top+0.14], ...
                  'Color', [0.1, 1.0, 0.3], 'LineWidth', 2.2);

  % Overhead RGB Vision Camera Arch & Scan Cone
  draw_static_box(ax3d, [0.0, conv_y_pick+0.42, conv_z_top+0.65], [0.10, 0.10, 1.30], ...
                  [0.32, 0.35, 0.40], [0.5, 0.5, 0.5]);
  draw_static_box(ax3d, [0.0, conv_y_pick+0.20, conv_z_top+1.25], [0.14, 0.50, 0.10], ...
                  [0.32, 0.35, 0.40], [0.5, 0.5, 0.5]);
  draw_static_box(ax3d, [0.0, conv_y_pick, conv_z_top+1.16], [0.18, 0.18, 0.14], ...
                  [0.15, 0.55, 0.85], [0.8, 0.9, 1.0]);
  h_cam_cone = patch(ax3d, [0, -0.22, 0.22], [conv_y_pick, conv_y_pick-0.22, conv_y_pick-0.22], ...
                     [conv_z_top+1.10, conv_z_top+0.02, conv_z_top+0.02], ...
                     [0.2, 0.8, 1.0], 'FaceAlpha', 0.08, 'EdgeColor', [0.2, 0.8, 1.0], ...
                     'EdgeAlpha', 0.25, 'LineStyle', ':');

  % 4 Sorting Bins
  for b = 1:4
    bx = bin_coords(b, 1);
    by = bin_coords(b, 2);
    bc = bin_colors(b, :);
    % Bin walls (4 sides)
    draw_static_box(ax3d, [bx, by-0.26, 0.24], [0.56, 0.04, 0.48], bc*0.75, bc);
    draw_static_box(ax3d, [bx, by+0.26, 0.24], [0.56, 0.04, 0.48], bc*0.75, bc);
    draw_static_box(ax3d, [bx-0.26, by, 0.24], [0.04, 0.52, 0.48], bc*0.75, bc);
    draw_static_box(ax3d, [bx+0.26, by, 0.24], [0.04, 0.52, 0.48], bc*0.75, bc);
    % Bin floor pad
    patch(ax3d, [bx-0.24, bx+0.24, bx+0.24, bx-0.24], ...
          [by-0.24, by-0.24, by+0.24, by+0.24], [0.03, 0.03, 0.03, 0.03], ...
          bc*0.45, 'EdgeColor', 'none');
    text(ax3d, bx, by, 0.58, bin_names{b}, 'Color', bc, ...
         'FontWeight', 'bold', 'FontSize', 9, 'HorizontalAlignment', 'center');
  end

  %% 4. ROBOT ARM & GRIPPER GRAPHICS HANDLES
  % Thick structural links + joint spheres
  h_link1 = plot3(ax3d, [0, 0], [0, 0], [0.3, L1], 'Color', [0.88, 0.45, 0.12], 'LineWidth', 10);
  h_link2 = plot3(ax3d, [0, 0], [0, 0], [L1, L1], 'Color', [0.95, 0.55, 0.15], 'LineWidth', 8);
  h_link3 = plot3(ax3d, [0, 0], [0, 0], [L1, L1], 'Color', [0.85, 0.88, 0.92], 'LineWidth', 6);
  h_link4 = plot3(ax3d, [0, 0], [0, 0], [L1, L1], 'Color', [0.30, 0.70, 0.95], 'LineWidth', 4.5);

  h_joints = plot3(ax3d, zeros(1,5), zeros(1,5), zeros(1,5), 'o', ...
                   'MarkerSize', 9, 'MarkerFaceColor', [0.18, 0.20, 0.25], ...
                   'MarkerEdgeColor', [0.95, 0.95, 0.98], 'LineWidth', 1.8);

  % Parallel-jaw gripper handles
  h_grip_bar  = plot3(ax3d, [0, 0], [0, 0], [0, 0], 'Color', [0.85, 0.90, 0.95], 'LineWidth', 4);
  h_grip_jaw1 = plot3(ax3d, [0, 0], [0, 0], [0, 0], 'Color', [0.20, 0.92, 0.75], 'LineWidth', 3.5);
  h_grip_jaw2 = plot3(ax3d, [0, 0], [0, 0], [0, 0], 'Color', [0.20, 0.92, 0.75], 'LineWidth', 3.5);

  % TCP Trajectory Trail (ring buffer)
  trail_len = 45;
  trail_pts = nan(trail_len, 3);
  h_trail = plot3(ax3d, trail_pts(:,1), trail_pts(:,2), trail_pts(:,3), ...
                  '-', 'Color', [0.25, 0.85, 0.95], 'LineWidth', 1.3);

  % Active Package Patch (6 faces of a 3D cube)
  pkg_faces = [
    1 2 3 4;
    5 6 7 8;
    1 2 6 5;
    2 3 7 6;
    3 4 8 7;
    4 1 5 8
  ];
  h_pkg = patch(ax3d, 'Vertices', zeros(8, 3), 'Faces', pkg_faces, ...
                'FaceColor', bin_colors(1, :), 'EdgeColor', [0.1, 0.1, 0.1], ...
                'LineWidth', 1.0);

  %% 5. RIGHT PANELS: REAL-TIME JOINT ENCODERS & SENSOR TELEMETRY
  ax_q = subplot('Position', [0.64, 0.54, 0.33, 0.39]);
  hold(ax_q, 'on');
  grid(ax_q, 'on');
  set(ax_q, 'Color', [0.11, 0.13, 0.17], ...
            'XColor', [0.75, 0.78, 0.82], ...
            'YColor', [0.75, 0.78, 0.82], ...
            'GridColor', [0.25, 0.28, 0.34]);
  ylim(ax_q, [-185, 185]);
  xlim(ax_q, [1, 100]);
  ylabel(ax_q, 'Joint Angle (deg)');
  title(ax_q, '6-DOF Joint Encoder Telemetry (q1 - q6)', ...
        'Color', [0.95, 0.96, 0.98], 'FontSize', 10, 'FontWeight', 'bold');

  hist_len = 100;
  q_hist = zeros(hist_len, 6);
  q_colors = [
    0.98, 0.35, 0.35;
    0.98, 0.70, 0.20;
    0.30, 0.88, 0.45;
    0.25, 0.75, 0.98;
    0.75, 0.45, 0.98;
    0.95, 0.95, 0.40
  ];
  h_q_lines = zeros(6, 1);
  for j = 1:6
    h_q_lines(j) = plot(ax_q, 1:hist_len, q_hist(:, j), 'Color', q_colors(j, :), 'LineWidth', 1.6);
  end
  leg = legend(ax_q, {'J1 Base', 'J2 Shldr', 'J3 Elbow', 'J4 Roll', 'J5 Pitch', 'J6 Yaw'}, ...
               'Location', 'southwest', 'Orientation', 'horizontal');
  set(leg, 'TextColor', [0.9, 0.9, 0.9], 'Color', [0.15, 0.17, 0.22], 'FontSize', 7);

  % Bottom Right Panel: Digital Controller & Sensor Readout
  ax_txt = subplot('Position', [0.64, 0.08, 0.33, 0.40]);
  axis(ax_txt, 'off');
  patch(ax_txt, [0, 1, 1, 0], [0, 0, 1, 1], [0.11, 0.13, 0.17], ...
        'EdgeColor', [0.30, 0.35, 0.42], 'LineWidth', 1.5);
  h_hud = text(ax_txt, 0.04, 0.94, '', 'Color', [0.88, 0.94, 0.98], ...
               'FontName', 'FixedWidth', 'FontSize', 9.2, ...
               'VerticalAlignment', 'top');

  %% 6. SIMULATION STATE MACHINE & LOOP
  % States:
  % 1 = Conveyor feeding package to laser sensor
  % 2 = Vision camera scanning & classifying color
  % 3 = Robot moving to pre-pick & descending to pick
  % 4 = Closing gripper & lifting package
  % 5 = Moving to target color bin
  % 6 = Opening gripper & releasing package into bin
  % 7 = Returning to home position

  state = 1;
  state_t = 0.0;
  dt = 0.035;

  pkg_size = 0.26;
  pkg_pos = [-1.75, conv_y_pick, conv_z_top + pkg_size/2];
  pkg_class = randi(4);
  set(h_pkg, 'FaceColor', bin_colors(pkg_class, :));

  tcp_curr = home_pos;
  tcp_start = home_pos;
  tcp_target = home_pos;
  grip_open = 0.18;     % jaw half-opening (m)
  grip_force = 0.0;     % N
  q_deg = [90, 45, -60, 0, -75, 0];
  belt_offset = 0.0;
  laser_triggered = false;
  cam_detected = 'WAITING';

  state_names = {
    '1: CONVEYOR FEED',
    '2: RGB VISION SCAN',
    '3: IK APPROACH PICK',
    '4: GRASP & LIFT',
    '5: TRANSIT TO BIN',
    '6: RELEASE PAYLOAD',
    '7: RETURN HOME'
  };

  step = 0;
  while ishandle(fig)
    step = step + 1;
    state_t = state_t + dt;

    % --- STATE MACHINE LOGIC ---
    switch state
      case 1  % Conveyor advancing package toward laser sensor
        belt_speed = 1.15; % m/s
        pkg_pos(1) = pkg_pos(1) + belt_speed * dt;
        belt_offset = mod(belt_offset + belt_speed * dt, 3.5 / (num_slats - 1));
        grip_open = 0.18;
        grip_force = 0.0;
        laser_triggered = false;
        cam_detected = 'SCANNING...';

        if pkg_pos(1) >= 0.0
          pkg_pos(1) = 0.0;
          laser_triggered = true;
          state = 2;
          state_t = 0.0;
        end

      case 2  % Optical Break-Beam & RGB Camera Classification
        laser_triggered = true;
        cam_detected = sprintf('%s (99.4%%)', bin_names{pkg_class});
        if state_t >= 0.45
          tcp_start = tcp_curr;
          tcp_target = pick_pos;
          state = 3;
          state_t = 0.0;
        end

      case 3  % IK Approach to Pick Position
        dur = 0.85;
        u = min(state_t / dur, 1.0);
        s = 10*u^3 - 15*u^4 + 6*u^5; % Quintic smoothstep
        tcp_curr = tcp_start + s * (tcp_target - tcp_start);
        % Add slight vertical arc so arm approaches from above
        tcp_curr(3) = tcp_curr(3) + 0.35 * sin(pi * u);

        if u >= 1.0
          state = 4;
          state_t = 0.0;
        end

      case 4  % Close Gripper & Lift Package
        dur = 0.55;
        u = min(state_t / dur, 1.0);
        grip_open = 0.18 - 0.05 * min(u * 2, 1.0);
        grip_force = 42.5 * min(u * 2, 1.0);
        if u > 0.4
          laser_triggered = false;
          lift_u = (u - 0.4) / 0.6;
          tcp_curr = pick_pos + [0, 0, 0.65 * (3*lift_u^2 - 2*lift_u^3)];
          pkg_pos = tcp_curr - [0, 0, 0.02];
        end
        if u >= 1.0
          tcp_start = tcp_curr;
          tcp_target = bin_coords(pkg_class, :);
          state = 5;
          state_t = 0.0;
        end

      case 5  % Transit Payload to Target Color Bin
        dur = 1.05;
        u = min(state_t / dur, 1.0);
        s = 10*u^3 - 15*u^4 + 6*u^5;
        tcp_curr = tcp_start + s * (tcp_target - tcp_start);
        tcp_curr(3) = tcp_curr(3) + 0.55 * sin(pi * u);
        pkg_pos = tcp_curr - [0, 0, 0.02];

        if u >= 1.0
          state = 6;
          state_t = 0.0;
        end

      case 6  % Open Gripper & Drop Package into Bin
        dur = 0.45;
        u = min(state_t / dur, 1.0);
        grip_open = 0.13 + 0.06 * u;
        grip_force = max(0, 42.5 * (1 - 3*u));
        % Package drops into bin
        pkg_pos(3) = max(0.18, tcp_curr(3) - 0.02 - 2.4 * u^2);

        if u >= 1.0
          bin_counts(pkg_class) = bin_counts(pkg_class) + 1;
          % Spawn next random colored package at conveyor start
          pkg_class = randi(4);
          pkg_pos = [-1.75, conv_y_pick, conv_z_top + pkg_size/2];
          set(h_pkg, 'FaceColor', bin_colors(pkg_class, :));
          cam_detected = 'WAITING';
          tcp_start = tcp_curr;
          tcp_target = home_pos;
          state = 7;
          state_t = 0.0;
        end

      case 7  % Return to Home Ready Pose
        dur = 0.70;
        u = min(state_t / dur, 1.0);
        s = 10*u^3 - 15*u^4 + 6*u^5;
        tcp_curr = tcp_start + s * (tcp_target - tcp_start);
        if u >= 1.0
          state = 1;
          state_t = 0.0;
        end
    end

    % --- 6-DOF ANALYTICAL INVERSE KINEMATICS ---
    % Enforce vertical downward tool approach orientation
    wrist_pos = tcp_curr + [0, 0, L4];
    wx = wrist_pos(1);
    wy = wrist_pos(2);
    wz = wrist_pos(3);

    % Joint 1: Base Yaw
    q1 = atan2(wy, wx);

    % Planar 2R IK for Shoulder (q2) and Elbow (q3)
    r = hypot(wx, wy);
    z_rel = wz - L1;
    D = (r^2 + z_rel^2 - L2^2 - L3^2) / (2 * L2 * L3);
    D = max(-1.0, min(1.0, D)); % Clamp for reach safety
    q3 = -atan2(sqrt(max(0, 1 - D^2)), D); % Elbow-up configuration
    q2 = atan2(z_rel, r) - atan2(L3 * sin(q3), L2 + L3 * cos(q3));

    % Joint 4: Forearm Roll (couples smoothly with base sweep)
    q4 = 0.35 * sin(q1);

    % Joint 5: Wrist Pitch (keeps tool pointing straight down: q2 + q3 + q5 = -pi/2)
    q5 = -pi/2 - (q2 + q3);

    % Joint 6: Tool Flange Yaw (aligns gripper jaws with conveyor / bin axes)
    q6 = -q1;

    q_deg = [q1, q2, q3, q4, q5, q6] * (180 / pi);

    % --- FORWARD KINEMATICS JOINT POSITIONS ---
    p0 = [0, 0, 0.30];
    p1 = [0, 0, L1];
    p2 = p1 + [L2 * cos(q2) * cos(q1), L2 * cos(q2) * sin(q1), L2 * sin(q2)];
    p3 = p2 + [L3 * cos(q2 + q3) * cos(q1), L3 * cos(q2 + q3) * sin(q1), L3 * sin(q2 + q3)];
    p4 = tcp_curr;

    % --- UPDATE 3D GRAPHICS ---
    set(h_link1, 'XData', [p0(1), p1(1)], 'YData', [p0(2), p1(2)], 'ZData', [p0(3), p1(3)]);
    set(h_link2, 'XData', [p1(1), p2(1)], 'YData', [p1(2), p2(2)], 'ZData', [p1(3), p2(3)]);
    set(h_link3, 'XData', [p2(1), p3(1)], 'YData', [p2(2), p3(2)], 'ZData', [p2(3), p3(3)]);
    set(h_link4, 'XData', [p3(1), p4(1)], 'YData', [p3(2), p4(2)], 'ZData', [p3(3), p4(3)]);

    pts = [p0; p1; p2; p3; p4];
    set(h_joints, 'XData', pts(:,1), 'YData', pts(:,2), 'ZData', pts(:,3));

    % Gripper Jaws oriented along X-axis
    g_top = p4 + [0, 0, 0.14];
    set(h_grip_bar,  'XData', [g_top(1)-grip_open, g_top(1)+grip_open], ...
                     'YData', [g_top(2), g_top(2)], 'ZData', [g_top(3), g_top(3)]);
    set(h_grip_jaw1, 'XData', [g_top(1)-grip_open, g_top(1)-grip_open], ...
                     'YData', [g_top(2), g_top(2)], 'ZData', [g_top(3), g_top(3)-0.16]);
    set(h_grip_jaw2, 'XData', [g_top(1)+grip_open, g_top(1)+grip_open], ...
                     'YData', [g_top(2), g_top(2)], 'ZData', [g_top(3), g_top(3)-0.16]);

    % Update Package Cube Vertices
    set(h_pkg, 'Vertices', get_cube_verts(pkg_pos, [pkg_size, pkg_size, pkg_size]));

    % Update Conveyor Slats
    for i = 1:num_slats
      sx = slat_x(i) + belt_offset;
      if sx > 1.80
        sx = sx - 3.60;
      end
      set(h_slats(i), 'XData', [sx, sx]);
    end

    % Update Laser Sensor & Vision Cone Visuals
    if laser_triggered
      set(h_laser, 'Color', [1.0, 0.15, 0.15], 'LineWidth', 3.0);
    else
      set(h_laser, 'Color', [0.15, 0.95, 0.35], 'LineWidth', 1.8);
    end
    if state == 2
      set(h_cam_cone, 'FaceAlpha', 0.28, 'EdgeAlpha', 0.85);
    else
      set(h_cam_cone, 'FaceAlpha', 0.06, 'EdgeAlpha', 0.20);
    end

    % Update TCP Trail
    trail_pts = [trail_pts(2:end, :); p4];
    set(h_trail, 'XData', trail_pts(:,1), 'YData', trail_pts(:,2), 'ZData', trail_pts(:,3));

    % --- UPDATE REAL-TIME TELEMETRY PLOTS & HUD ---
    q_hist = [q_hist(2:end, :); q_deg];
    for j = 1:6
      set(h_q_lines(j), 'YData', q_hist(:, j));
    end

    if laser_triggered
      laser_str = 'BLOCKED (PART AT PICK)';
    else
      laser_str = 'CLEAR';
    end

    hud_str = sprintf([ ...
      '=== 6-DOF CONTROLLER & SENSOR BUS ===\n' ...
      'STATE   : %s\n' ...
      'TCP POS : X=%+6.3fm  Y=%+6.3fm  Z=%+6.3fm\n' ...
      '-------------------------------------\n' ...
      'J1 BASE : %+6.1f deg | J4 ROLL : %+6.1f deg\n' ...
      'J2 SHLDR: %+6.1f deg | J5 PITCH: %+6.1f deg\n' ...
      'J3 ELBOW: %+6.1f deg | J6 YAW  : %+6.1f deg\n' ...
      '-------------------------------------\n' ...
      'GRIPPER : Gap=%5.1f mm | Force=%5.1f N\n' ...
      'LASER   : %s\n' ...
      'CAMERA  : %s\n' ...
      '-------------------------------------\n' ...
      'SORTED  : RED:%d  GRN:%d  BLU:%d  YEL:%d  (TOT:%d)' ], ...
      state_names{state}, ...
      p4(1), p4(2), p4(3), ...
      q_deg(1), q_deg(4), q_deg(2), q_deg(5), q_deg(3), q_deg(6), ...
      grip_open * 2000, grip_force, ...
      laser_str, ...
      cam_detected, ...
      bin_counts(1), bin_counts(2), bin_counts(3), bin_counts(4), sum(bin_counts));

    set(h_hud, 'String', hud_str);

    drawnow();
    pause(0.015);
  end
end

%% HELPER FUNCTIONS (Defined cleanly outside main function)
function verts = get_cube_verts(center, dims)
  cx = center(1); cy = center(2); cz = center(3);
  hx = dims(1) / 2; hy = dims(2) / 2; hz = dims(3) / 2;
  verts = [
    cx - hx, cy - hy, cz - hz;
    cx + hx, cy - hy, cz - hz;
    cx + hx, cy + hy, cz - hz;
    cx - hx, cy + hy, cz - hz;
    cx - hx, cy - hy, cz + hz;
    cx + hx, cy - hy, cz + hz;
    cx + hx, cy + hy, cz + hz;
    cx - hx, cy + hy, cz + hz
  ];
end

function draw_static_box(ax, center, dims, face_col, edge_col)
  verts = get_cube_verts(center, dims);
  faces = [
    1 2 3 4;
    5 6 7 8;
    1 2 6 5;
    2 3 7 6;
    3 4 8 7;
    4 1 5 8
  ];
  patch(ax, 'Vertices', verts, 'Faces', faces, ...
        'FaceColor', face_col, 'EdgeColor', edge_col, 'LineWidth', 0.8);
end
