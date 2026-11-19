function varargout = octave_dtree_platformer_v5(varargin)
%% ========================================================================
%  DECOUPLED 2D DECISION-TREE PLATFORMER & LIVE AI DEBUGGER (GNU OCTAVE)
%  v5.0: Command-Dispatcher Entry Point for %!test + Windows 11 FLTK CLI
% =========================================================================
%  ARCHITECTURE OVERVIEW (Pure Data-Driven & Decoupled Subsystems):
%    1. cfg_init()                 -> Immutable physics & sensor parameters
%    2. state_init()               -> Single source of truth for world state
%    3. display_select_toolkit()   -> Windows 11 --no-gui FLTK/Qt negotiation
%    4. dtree_build()/evaluate()   -> Declarative Decision Tree & live trace
%    5. input_buffer_*/reduce()    -> Pure event-driven input reducer
%    6. world_step()               -> Semi-implicit Euler physics & collisions
%    7. renderer_init()/update()   -> Zero-allocation 60+ FPS handle updates
%
%  USAGE IN GNU OCTAVE (--no-gui or GUI):
%    test octave_dtree_platformer_v5       % Runs all 4 built-in unit tests
%    octave_dtree_platformer_v5()          % Launches interactive game
%    source('octave_dtree_platformer_v5.m')% Also launches interactive game
% =========================================================================

  % Internal dispatcher: allows %!test blocks to invoke private subfunctions
  % cleanly in GNU Octave (where %!test executes in base workspace scope).
  if nargin >= 1 && ischar(varargin{1}) && strncmp(varargin{1}, '__call__', 8)
    fn_name = varargin{1}(9:end);
    fn_handle = str2func(fn_name);
    [varargout{1:nargout}] = fn_handle(varargin{2:end});
    return;
  end

  tk = display_select_toolkit({'fltk', 'qt'});
  graphics_toolkit(tk);

  cfg   = cfg_init();
  tree  = dtree_build();
  state = state_init(cfg);
  gfx   = renderer_init(tk, cfg, state, tree);

  input_attach_listeners(gfx.fig);
  sim_loop_run(cfg, state, tree, gfx);
end

%% ========================================================================
%  1. DISPLAY TOOLKIT BOOTSTRAP (Windows 11 --no-gui FLTK Priority)
% =========================================================================
function tk = display_select_toolkit(preferred_order)
  if nargin < 1 || isempty(preferred_order)
    preferred_order = {'fltk', 'qt'};
  end
  avail = available_graphics_toolkits();

  % In --no-gui mode (especially Windows 11 CLI), Qt lacks a running
  % QApplication loop and fails __go_figure__. Prioritize FLTK first.
  if ~isguirunning() && any(strcmp(preferred_order, 'fltk'))
    preferred_order = [{'fltk'}, preferred_order(~strcmp(preferred_order, 'fltk'))];
  end

  tk = '';
  for i = 1:numel(preferred_order)
    cand = preferred_order{i};
    if any(strcmp(avail, cand))
      try
        graphics_toolkit(cand);
        probe = figure('Visible', 'off');
        if ishandle(probe)
          close(probe);
          tk = cand;
          return;
        end
      catch
        % Try next candidate toolkit
      end
    end
  end

  error('display_select_toolkit:NoInteractiveToolkit', ...
        'Unable to initialize an interactive graphics toolkit (tried: %s).', ...
        strjoin(preferred_order, ', '));
end

function fig = renderer_create_figure(tk, win_title, visible_flag)
  if nargin < 3
    visible_flag = 'on';
  end
  graphics_toolkit(tk);
  fig = figure('Visible', visible_flag);
  set(fig, ...
    'Name', win_title, ...
    'NumberTitle', 'off', ...
    'Color', [0.08 0.09 0.12], ...
    'Position', [80 80 1280 680], ...
    'MenuBar', 'none', ...
    'ToolBar', 'none');
end

%% ========================================================================
%  2. CONFIGURATION MODULE (cfg_init)
% =========================================================================
function cfg = cfg_init()
  cfg.dt               = 1 / 60;      % Fixed 60 Hz physics timestep (s)
  cfg.max_frame_dt     = 0.05;        % Clamp spiral-of-death frame spikes
  cfg.world_w          = 100;         % Arena width (m)
  cfg.world_h          = 60;          % Arena height (m)

  % Player kinematics
  cfg.player_w         = 2.6;
  cfg.player_h_stand   = 4.8;
  cfg.player_h_crouch  = 2.6;
  cfg.player_speed     = 30.0;        % Horizontal velocity (m/s)
  cfg.jump_vel         = 38.0;        % Jump vertical impulse (m/s)
  cfg.gravity          = -88.0;       % Gravity acceleration (m/s^2)
  cfg.fast_fall_accel  = -70.0;       % Extra downward accel when crouching

  % Input event latch durations (compensates for OS key-repeat delay)
  cfg.hold_latch_sec   = 0.15;        % Keeps directional key active briefly
  cfg.edge_latch_sec   = 0.14;        % Buffers Jump/Interact edge presses

  % Enemy AI & Decision Tree sensor thresholds
  cfg.enemy_w          = 3.2;
  cfg.enemy_h          = 4.2;
  cfg.enemy_patrol_spd = 13.0;
  cfg.enemy_chase_spd  = 23.5;
  cfg.enemy_evade_spd  = 26.0;
  cfg.sight_range      = 34.0;
  cfg.attack_range     = 6.0;
  cfg.emp_stun_time    = 3.5;
end

%% ========================================================================
%  3. WORLD & ENTITY STATE MODULE (state_init)
% =========================================================================
function state = state_init(cfg)
  state.time        = 0.0;
  state.running     = true;
  state.won         = false;
  state.alert_msg   = 'CLICK WINDOW -> REACH UPPER TERMINAL [ENTER] TO HACK & UNLOCK EXIT';

  % Player state
  state.player.x         = 10.0;
  state.player.y         = 4.0;
  state.player.vx        = 0.0;
  state.player.vy        = 0.0;
  state.player.h         = cfg.player_h_stand;
  state.player.on_ground = true;
  state.player.crouching = false;
  state.player.hp        = 100;
  state.player.invuln    = 0.0;

  % Guard Drone (Decision Tree Agent)
  state.enemy.x          = 76.0;
  state.enemy.y          = 4.0;
  state.enemy.vx         = -cfg.enemy_patrol_spd;
  state.enemy.patrol_dir = -1;
  state.enemy.stun_timer = 0.0;
  state.enemy.action     = 'PATROL';
  state.enemy.trace_ids  = [1];

  % Interactive Objectives
  state.terminal.x       = 50.0;
  state.terminal.y       = 35.0;
  state.terminal.hacked  = false;

  state.gate.x           = 92.0;
  state.gate.y           = 4.0;
  state.gate.w           = 4.0;
  state.gate.h           = 9.0;
  state.gate.open        = false;

  % Static Platform Geometry: [x_min, x_max, y_top, thickness]
  state.platforms = [
     0.0, 100.0,  4.0, 4.0;   % Ground floor
    12.0,  36.0, 15.0, 1.8;   % Lower-left ledge
    64.0,  88.0, 15.0, 1.8;   % Lower-right ledge
    34.0,  66.0, 26.0, 1.8;   % Mid-center bridge
    40.0,  60.0, 35.0, 1.8;   % Upper terminal deck
    10.0,  28.0, 36.0, 1.8    % Upper-left overlook
  ];

  state.input_label = 'IDLE';
end

%% ========================================================================
%  4. PURE INPUT REDUCER & FLTK/QT EVENT LISTENER BRIDGE
% =========================================================================
function buf = input_buffer_init()
  buf = struct( ...
    'left_down',    false, 'left_ts',    -10, ...
    'right_down',   false, 'right_ts',   -10, ...
    'crouch_down',  false, 'crouch_ts',  -10, ...
    'jump_edge_ts', -10, ...
    'act_edge_ts',  -10, ...
    'reset_req',    false, ...
    'quit_req',     false, ...
    'last_key',     'NONE' ...
  );
end

function buf = input_reduce_key(buf, key_id, is_press, now_t)
  k = lower(strtrim(key_id));
  if isempty(k)
    return;
  end

  if is_press
    buf.last_key = upper(k);
    switch k
      case {'a', 'leftarrow'}
        buf.left_down = true;
        buf.left_ts   = now_t;
      case {'d', 'rightarrow'}
        buf.right_down = true;
        buf.right_ts   = now_t;
      case {'s', 'downarrow'}
        buf.crouch_down = true;
        buf.crouch_ts   = now_t;
      case {'w', 'uparrow', 'space'}
        buf.jump_edge_ts = now_t;
      case {'return', 'enter', 'e'}
        buf.act_edge_ts  = now_t;
      case 'r'
        buf.reset_req    = true;
      case 'escape'
        buf.quit_req     = true;
    end
  else
    switch k
      case {'a', 'leftarrow'}
        buf.left_down = false;
      case {'d', 'rightarrow'}
        buf.right_down = false;
      case {'s', 'downarrow'}
        buf.crouch_down = false;
    end
  end
end

function [cmd, buf, label] = input_consume_buffer(buf, now_t, cfg)
  cmd = struct('left', false, 'right', false, 'crouch', false, ...
               'jump', false, 'interact', false, 'reset', false, 'quit', false);

  cmd.left   = buf.left_down   || ((now_t - buf.left_ts)   <= cfg.hold_latch_sec);
  cmd.right  = buf.right_down  || ((now_t - buf.right_ts)  <= cfg.hold_latch_sec);
  cmd.crouch = buf.crouch_down || ((now_t - buf.crouch_ts) <= cfg.hold_latch_sec);

  if (now_t - buf.jump_edge_ts) <= cfg.edge_latch_sec
    cmd.jump = true;
    buf.jump_edge_ts = -10;
  end
  if (now_t - buf.act_edge_ts) <= cfg.edge_latch_sec
    cmd.interact = true;
    buf.act_edge_ts = -10;
  end
  if buf.reset_req
    cmd.reset = true;
    buf.reset_req = false;
  end
  if buf.quit_req
    cmd.quit = true;
  end

  active_tags = {};
  if cmd.left,     active_tags{end+1} = 'LEFT(A)';     end
  if cmd.right,    active_tags{end+1} = 'RIGHT(D)';    end
  if cmd.jump,     active_tags{end+1} = 'JUMP(W/SPC)'; end
  if cmd.crouch,   active_tags{end+1} = 'CROUCH(S)';   end
  if cmd.interact, active_tags{end+1} = 'ACT(ENT)';    end
  if isempty(active_tags)
    label = sprintf('IDLE (Last: %s)', buf.last_key);
  else
    label = strjoin(active_tags, '+');
  end
end

function input_attach_listeners(fig)
  setappdata(fig, 'input_buf', input_buffer_init());
  set(fig, 'WindowKeyPressFcn',   @on_key_press);
  set(fig, 'WindowKeyReleaseFcn', @on_key_release);
  set(fig, 'KeyPressFcn',         @on_key_press);
  set(fig, 'KeyReleaseFcn',       @on_key_release);
  set(fig, 'WindowButtonDownFcn', @(src, ~) figure(src));
  set(fig, 'CloseRequestFcn',     @on_close_request);
end

function key_id = normalize_key_event(evt)
  key_id = '';
  if isfield(evt, 'Key') && ~isempty(evt.Key)
    key_id = lower(strtrim(evt.Key));
  end
  if (isempty(key_id) || strcmp(key_id, 'unknown')) && isfield(evt, 'Character') && ~isempty(evt.Character)
    ch = evt.Character;
    if ch == ' '
      key_id = 'space';
    elseif double(ch) == 13 || double(ch) == 10
      key_id = 'return';
    elseif double(ch) == 27
      key_id = 'escape';
    else
      key_id = lower(ch);
    end
  end
end

function on_key_press(src, evt)
  fig = ancestor(src, 'figure');
  if isempty(fig) || ~ishandle(fig), return; end
  buf = getappdata(fig, 'input_buf');
  if isempty(buf), return; end
  buf = input_reduce_key(buf, normalize_key_event(evt), true, tic_seconds());
  setappdata(fig, 'input_buf', buf);
end

function on_key_release(src, evt)
  fig = ancestor(src, 'figure');
  if isempty(fig) || ~ishandle(fig), return; end
  buf = getappdata(fig, 'input_buf');
  if isempty(buf), return; end
  buf = input_reduce_key(buf, normalize_key_event(evt), false, tic_seconds());
  setappdata(fig, 'input_buf', buf);
end

function on_close_request(src, ~)
  if ishandle(src)
    buf = getappdata(src, 'input_buf');
    if ~isempty(buf)
      buf.quit_req = true;
      setappdata(src, 'input_buf', buf);
    end
    delete(src);
  end
end

function t = tic_seconds()
  persistent t0;
  if isempty(t0)
    t0 = tic();
  end
  t = toc(t0);
end

function [cmd, state] = input_sample_and_consume(fig, cfg, state)
  if isempty(fig) || ~ishandle(fig)
    cmd = struct('left', false, 'right', false, 'crouch', false, ...
                 'jump', false, 'interact', false, 'reset', false, 'quit', true);
    return;
  end
  buf = getappdata(fig, 'input_buf');
  if isempty(buf)
    buf = input_buffer_init();
  end
  [cmd, buf, state.input_label] = input_consume_buffer(buf, tic_seconds(), cfg);
  setappdata(fig, 'input_buf', buf);
end

%% ========================================================================
%  5. INDEPENDENT SIMULATION SCHEDULER (Decoupled Input, Physics & Render)
% =========================================================================
function sim_loop_run(cfg, state, tree, gfx)
  accumulator = 0.0;
  prev_t = tic_seconds();

  while state.running && ishandle(gfx.fig)
    % Service FLTK/Qt GUI event loop so keyboard callbacks execute immediately
    drawnow();
    if ~ishandle(gfx.fig)
      break;
    end

    curr_t = tic_seconds();
    frame_dt = curr_t - prev_t;
    prev_t = curr_t;
    if frame_dt > cfg.max_frame_dt
      frame_dt = cfg.max_frame_dt;
    end
    accumulator = accumulator + frame_dt;

    [cmd, state] = input_sample_and_consume(gfx.fig, cfg, state);
    if cmd.quit
      state.running = false;
      break;
    end
    if cmd.reset
      state = state_init(cfg);
      accumulator = 0.0;
    end

    while accumulator >= cfg.dt
      [action, trace_ids] = dtree_evaluate(tree, state, cfg);
      state.enemy.action    = action;
      state.enemy.trace_ids = trace_ids;

      state = world_step(state, cmd, cfg);

      cmd.jump     = false;
      cmd.interact = false;
      accumulator  = accumulator - cfg.dt;
    end

    renderer_update(gfx, state, tree, cfg);
    pause(0.002);
  end

  if ishandle(gfx.fig)
    close(gfx.fig);
  end
end

%% ========================================================================
%  6. DECLARATIVE DECISION TREE MODULE (dtree_build & dtree_evaluate)
% =========================================================================
function tree = dtree_build()
  nodes(1) = struct( ...
    'id', 1, 'label', 'Stunned?', 'is_leaf', false, ...
    'cond_fn', @(s, c) s.enemy.stun_timer > 0, ...
    'true_id', 2, 'false_id', 3, 'action', '', 'pos', [0.50, 0.90]);

  nodes(2) = struct( ...
    'id', 2, 'label', 'STUNNED', 'is_leaf', true, ...
    'cond_fn', [], 'true_id', 0, 'false_id', 0, ...
    'action', 'STUNNED', 'pos', [0.18, 0.68]);

  nodes(3) = struct( ...
    'id', 3, 'label', 'Player in Sight?', 'is_leaf', false, ...
    'cond_fn', @(s, c) hypot(s.player.x - s.enemy.x, s.player.y - s.enemy.y) <= c.sight_range, ...
    'true_id', 5, 'false_id', 4, 'action', '', 'pos', [0.72, 0.68]);

  nodes(4) = struct( ...
    'id', 4, 'label', 'PATROL', 'is_leaf', true, ...
    'cond_fn', [], 'true_id', 0, 'false_id', 0, ...
    'action', 'PATROL', 'pos', [0.88, 0.44]);

  nodes(5) = struct( ...
    'id', 5, 'label', 'Terminal Hacked?', 'is_leaf', false, ...
    'cond_fn', @(s, c) s.terminal.hacked, ...
    'true_id', 6, 'false_id', 7, 'action', '', 'pos', [0.52, 0.44]);

  nodes(6) = struct( ...
    'id', 6, 'label', 'EVADE', 'is_leaf', true, ...
    'cond_fn', [], 'true_id', 0, 'false_id', 0, ...
    'action', 'EVADE', 'pos', [0.24, 0.20]);

  nodes(7) = struct( ...
    'id', 7, 'label', 'In Attack Range?', 'is_leaf', false, ...
    'cond_fn', @(s, c) hypot(s.player.x - s.enemy.x, s.player.y - s.enemy.y) <= c.attack_range, ...
    'true_id', 8, 'false_id', 9, 'action', '', 'pos', [0.68, 0.20]);

  nodes(8) = struct( ...
    'id', 8, 'label', 'ATTACK', 'is_leaf', true, ...
    'cond_fn', [], 'true_id', 0, 'false_id', 0, ...
    'action', 'ATTACK', 'pos', [0.52, 0.05]);

  nodes(9) = struct( ...
    'id', 9, 'label', 'CHASE', 'is_leaf', true, ...
    'cond_fn', [], 'true_id', 0, 'false_id', 0, ...
    'action', 'CHASE', 'pos', [0.84, 0.05]);

  tree.root_id = 1;
  tree.nodes   = nodes;
end

function [action, trace_ids] = dtree_evaluate(tree, state, cfg)
  curr_id   = tree.root_id;
  trace_ids = curr_id;
  max_hops  = numel(tree.nodes) + 2;
  hops      = 0;

  while hops < max_hops
    node = tree.nodes(curr_id);
    if node.is_leaf
      action = node.action;
      return;
    end
    if node.cond_fn(state, cfg)
      curr_id = node.true_id;
    else
      curr_id = node.false_id;
    end
    trace_ids(end + 1) = curr_id; %#ok<AGROW>
    hops = hops + 1;
  end
  action = 'PATROL';
end

%% ========================================================================
%  7. PHYSICS, COLLISION & AI ACTUATION MODULE (world_step)
% =========================================================================
function state = world_step(state, cmd, cfg)
  dt = cfg.dt;
  state.time = state.time + dt;

  if state.player.invuln > 0
    state.player.invuln = max(0, state.player.invuln - dt);
  end

  move_dir = double(cmd.right) - double(cmd.left);
  state.player.vx = move_dir * cfg.player_speed;

  state.player.crouching = cmd.crouch;
  if cmd.crouch
    state.player.h = cfg.player_h_crouch;
    if ~state.player.on_ground
      state.player.vy = state.player.vy + cfg.fast_fall_accel * dt;
    end
  else
    state.player.h = cfg.player_h_stand;
  end

  if cmd.jump && state.player.on_ground
    state.player.vy        = cfg.jump_vel;
    state.player.on_ground = false;
  end

  prev_y = state.player.y;
  state.player.vy = state.player.vy + cfg.gravity * dt;
  state.player.x  = state.player.x + state.player.vx * dt;
  state.player.y  = state.player.y + state.player.vy * dt;

  half_w = cfg.player_w * 0.5;
  state.player.x = max(half_w, min(cfg.world_w - half_w, state.player.x));

  state.player.on_ground = false;
  if state.player.vy <= 0
    for i = 1:size(state.platforms, 1)
      px1  = state.platforms(i, 1);
      px2  = state.platforms(i, 2);
      ptop = state.platforms(i, 3);
      if (state.player.x + half_w >= px1) && (state.player.x - half_w <= px2)
        if (prev_y >= ptop - 0.15) && (state.player.y <= ptop)
          state.player.y         = ptop;
          state.player.vy        = 0.0;
          state.player.on_ground = true;
          break;
        end
      end
    end
  end

  if cmd.interact
    dist_term = hypot(state.player.x - state.terminal.x, ...
                      (state.player.y + state.player.h * 0.5) - (state.terminal.y + 1.5));
    if ~state.terminal.hacked && dist_term < 7.5
      state.terminal.hacked  = true;
      state.gate.open        = true;
      state.enemy.stun_timer = cfg.emp_stun_time;
      state.alert_msg        = 'EMP TRIGGERED! DRONE STUNNED & EXIT GATE UNLOCKED!';
    end

    dist_gate = hypot(state.player.x - (state.gate.x + state.gate.w * 0.5), ...
                      state.player.y - state.gate.y);
    if state.gate.open && dist_gate < 8.5
      state.won       = true;
      state.alert_msg = 'MISSION COMPLETE! PRESS [R] TO PLAY AGAIN';
    end
  end

  state = ai_apply_action(state, cfg, dt);
end

function state = ai_apply_action(state, cfg, dt)
  if state.enemy.stun_timer > 0
    state.enemy.stun_timer = max(0, state.enemy.stun_timer - dt);
  end

  dx = state.player.x - state.enemy.x;
  dir_to_player = sign(dx);
  if dir_to_player == 0
    dir_to_player = 1;
  end

  switch state.enemy.action
    case 'STUNNED'
      state.enemy.vx = 0.0;

    case 'PATROL'
      state.enemy.vx = state.enemy.patrol_dir * cfg.enemy_patrol_spd;
      if state.enemy.x <= 12.0
        state.enemy.patrol_dir = 1;
      elseif state.enemy.x >= 88.0
        state.enemy.patrol_dir = -1;
      end

    case 'CHASE'
      state.enemy.vx = dir_to_player * cfg.enemy_chase_spd;

    case 'EVADE'
      state.enemy.vx = -dir_to_player * cfg.enemy_evade_spd;

    case 'ATTACK'
      state.enemy.vx = 0.0;
      if state.player.invuln <= 0 && abs(state.player.y - state.enemy.y) < 4.5
        state.player.hp     = max(0, state.player.hp - 20);
        state.player.invuln = 1.0;
        state.player.vx     = -dir_to_player * 24.0;
        state.player.vy     = 18.0;
        state.alert_msg     = 'DRONE HIT! USE [ENTER] AT UPPER TERMINAL TO STUN!';
        if state.player.hp == 0
          state.alert_msg = 'HP DEPLETED! PRESS [R] TO RESTART';
        end
      end
  end

  state.enemy.x = state.enemy.x + state.enemy.vx * dt;
  state.enemy.x = max(4.0, min(cfg.world_w - 4.0, state.enemy.x));
end

%% ========================================================================
%  8. GRAPHICS RENDERER MODULE (Zero-Allocation Handle Updates)
% =========================================================================
function gfx = renderer_init(tk, cfg, state, tree)
  gfx.fig = renderer_create_figure(tk, ...
    'GNU Octave Decision-Tree Platformer (FLTK Event-Driven)', 'on');

  gfx.ax_world = subplot('Position', [0.04 0.10 0.56 0.80]);
  hold(gfx.ax_world, 'on');
  set(gfx.ax_world, 'Color', [0.11 0.13 0.18], ...
      'XLim', [0 cfg.world_w], 'YLim', [0 cfg.world_h], ...
      'XColor', [0.6 0.65 0.75], 'YColor', [0.6 0.65 0.75], ...
      'Box', 'on', 'HitTest', 'off');
  title(gfx.ax_world, 'ARENA: [A/D] Move | [W/Space] Jump | [S] Crouch | [Enter] Hack/Exit | [R] Reset', ...
        'Color', [0.92 0.95 1.0], 'FontSize', 10, 'FontWeight', 'bold');

  for i = 1:size(state.platforms, 1)
    px1  = state.platforms(i, 1);
    px2  = state.platforms(i, 2);
    ptop = state.platforms(i, 3);
    pthk = state.platforms(i, 4);
    patch(gfx.ax_world, [px1 px2 px2 px1], [ptop-pthk ptop-pthk ptop ptop], ...
          [0.24 0.30 0.40], 'EdgeColor', [0.45 0.58 0.75], 'LineWidth', 1.2, 'HitTest', 'off');
  end

  tx = state.terminal.x; ty = state.terminal.y;
  gfx.h_term = patch(gfx.ax_world, [tx-1.6 tx+1.6 tx+1.6 tx-1.6], [ty ty ty+3.4 ty+3.4], ...
                     [1.0 0.75 0.15], 'EdgeColor', 'w', 'LineWidth', 1.2, 'HitTest', 'off');
  text(gfx.ax_world, tx, ty + 4.8, 'TERMINAL', 'Color', [1.0 0.85 0.35], ...
       'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold', 'HitTest', 'off');

  gx = state.gate.x; gy = state.gate.y; gw = state.gate.w; gh = state.gate.h;
  gfx.h_gate = patch(gfx.ax_world, [gx gx+gw gx+gw gx], [gy gy gy+gh gy+gh], ...
                     [0.85 0.22 0.25], 'EdgeColor', 'w', 'LineWidth', 1.5, 'HitTest', 'off');
  text(gfx.ax_world, gx + gw*0.5, gy + gh + 1.6, 'EXIT', 'Color', [0.9 0.9 0.9], ...
       'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold', 'HitTest', 'off');

  theta = linspace(0, 2*pi, 48);
  gfx.h_sight = plot(gfx.ax_world, ...
    state.enemy.x + cfg.sight_range * cos(theta), ...
    (state.enemy.y + 2) + cfg.sight_range * sin(theta), ...
    '--', 'Color', [0.95 0.35 0.35], 'LineWidth', 1.0, 'HitTest', 'off');
  gfx.sight_cos = cos(theta);
  gfx.sight_sin = sin(theta);

  gfx.h_player = patch(gfx.ax_world, [0 1 1 0], [0 0 1 1], ...
                       [0.20 0.85 0.95], 'EdgeColor', 'w', 'LineWidth', 1.4, 'HitTest', 'off');
  gfx.h_enemy  = patch(gfx.ax_world, [0 1 1 0], [0 0 1 1], ...
                       [0.95 0.30 0.35], 'EdgeColor', 'w', 'LineWidth', 1.4, 'HitTest', 'off');

  gfx.h_hud = text(gfx.ax_world, 2.0, cfg.world_h - 2.5, '', ...
                   'Color', [0.95 0.98 1.0], 'FontSize', 9.5, 'FontWeight', 'bold', 'HitTest', 'off');
  gfx.h_alert = text(gfx.ax_world, cfg.world_w * 0.5, cfg.world_h - 6.2, state.alert_msg, ...
                     'Color', [1.0 0.88 0.35], 'HorizontalAlignment', 'center', ...
                     'FontSize', 9, 'FontWeight', 'bold', 'HitTest', 'off');

  gfx.ax_tree = subplot('Position', [0.63 0.10 0.34 0.80]);
  hold(gfx.ax_tree, 'on');
  set(gfx.ax_tree, 'Color', [0.10 0.11 0.15], ...
      'XLim', [0 1], 'YLim', [-0.05 1.0], ...
      'XTick', [], 'YTick', [], 'Box', 'on', 'HitTest', 'off');
  title(gfx.ax_tree, 'LIVE DECISION TREE EXECUTION TRACE', ...
        'Color', [0.92 0.95 1.0], 'FontSize', 10, 'FontWeight', 'bold');

  n_nodes = numel(tree.nodes);
  gfx.h_edges = zeros(n_nodes, 2);
  gfx.h_nodes = zeros(n_nodes, 1);

  for i = 1:n_nodes
    nd = tree.nodes(i);
    if ~nd.is_leaf
      t_pos = tree.nodes(nd.true_id).pos;
      f_pos = tree.nodes(nd.false_id).pos;
      gfx.h_edges(i, 1) = plot(gfx.ax_tree, [nd.pos(1) t_pos(1)], [nd.pos(2) t_pos(2)], ...
                               '-', 'Color', [0.35 0.40 0.48], 'LineWidth', 1.6, 'HitTest', 'off');
      gfx.h_edges(i, 2) = plot(gfx.ax_tree, [nd.pos(1) f_pos(1)], [nd.pos(2) f_pos(2)], ...
                               '-', 'Color', [0.35 0.40 0.48], 'LineWidth', 1.6, 'HitTest', 'off');
      text(gfx.ax_tree, (nd.pos(1)+t_pos(1))*0.5 - 0.03, (nd.pos(2)+t_pos(2))*0.5 + 0.02, ...
           'T', 'Color', [0.4 0.95 0.55], 'FontSize', 8, 'FontWeight', 'bold', 'HitTest', 'off');
      text(gfx.ax_tree, (nd.pos(1)+f_pos(1))*0.5 + 0.03, (nd.pos(2)+f_pos(2))*0.5 + 0.02, ...
           'F', 'Color', [0.95 0.45 0.45], 'FontSize', 8, 'FontWeight', 'bold', 'HitTest', 'off');
    end
  end

  for i = 1:n_nodes
    nd = tree.nodes(i);
    w_box = 0.24; h_box = 0.075;
    if nd.is_leaf
      w_box = 0.20; h_box = 0.068;
    end
    gfx.h_nodes(i) = patch(gfx.ax_tree, ...
      [nd.pos(1)-w_box*0.5 nd.pos(1)+w_box*0.5 nd.pos(1)+w_box*0.5 nd.pos(1)-w_box*0.5], ...
      [nd.pos(2)-h_box*0.5 nd.pos(2)-h_box*0.5 nd.pos(2)+h_box*0.5 nd.pos(2)+h_box*0.5], ...
      [0.20 0.23 0.30], 'EdgeColor', [0.55 0.62 0.72], 'LineWidth', 1.3, 'HitTest', 'off');
    text(gfx.ax_tree, nd.pos(1), nd.pos(2), nd.label, ...
         'Color', 'w', 'HorizontalAlignment', 'center', ...
         'FontSize', 8, 'FontWeight', 'bold', 'HitTest', 'off');
  end

  figure(gfx.fig);
end

function renderer_update(gfx, state, tree, cfg)
  pw = cfg.player_w * 0.5;
  px = state.player.x;
  py = state.player.y;
  ph = state.player.h;
  set(gfx.h_player, 'XData', [px-pw px+pw px+pw px-pw], 'YData', [py py py+ph py+ph]);
  if state.player.invuln > 0 && mod(floor(state.time * 16), 2) == 0
    set(gfx.h_player, 'FaceColor', [1.0 1.0 1.0]);
  else
    set(gfx.h_player, 'FaceColor', [0.20 0.85 0.95]);
  end

  ew = cfg.enemy_w * 0.5;
  ex = state.enemy.x;
  ey = state.enemy.y;
  eh = cfg.enemy_h;
  set(gfx.h_enemy, 'XData', [ex-ew ex+ew ex+ew ex-ew], 'YData', [ey ey ey+eh ey+eh]);
  set(gfx.h_sight, 'XData', ex + cfg.sight_range * gfx.sight_cos, ...
                   'YData', (ey + eh*0.5) + cfg.sight_range * gfx.sight_sin);

  if state.enemy.stun_timer > 0
    set(gfx.h_enemy, 'FaceColor', [0.55 0.55 0.65]);
  elseif strcmp(state.enemy.action, 'EVADE')
    set(gfx.h_enemy, 'FaceColor', [0.95 0.65 0.20]);
  else
    set(gfx.h_enemy, 'FaceColor', [0.95 0.30 0.35]);
  end

  if state.terminal.hacked
    set(gfx.h_term, 'FaceColor', [0.25 0.90 0.45]);
  else
    set(gfx.h_term, 'FaceColor', [1.0 0.75 0.15]);
  end
  if state.gate.open
    set(gfx.h_gate, 'FaceColor', [0.20 0.85 0.45]);
  else
    set(gfx.h_gate, 'FaceColor', [0.85 0.22 0.25]);
  end

  set(gfx.h_hud, 'String', sprintf( ...
    'HP: %d | AI: %s | INPUT: %s | POS: (%.1f, %.1f)', ...
    state.player.hp, state.enemy.action, state.input_label, state.player.x, state.player.y));
  set(gfx.h_alert, 'String', state.alert_msg);

  trace = state.enemy.trace_ids;
  n_nodes = numel(tree.nodes);
  for i = 1:n_nodes
    nd = tree.nodes(i);
    in_trace = any(trace == nd.id);
    if in_trace
      if nd.is_leaf
        set(gfx.h_nodes(i), 'FaceColor', [0.18 0.72 0.38], 'EdgeColor', 'w', 'LineWidth', 2.2);
      else
        set(gfx.h_nodes(i), 'FaceColor', [0.22 0.52 0.88], 'EdgeColor', 'w', 'LineWidth', 2.0);
      end
    else
      set(gfx.h_nodes(i), 'FaceColor', [0.20 0.23 0.30], 'EdgeColor', [0.55 0.62 0.72], 'LineWidth', 1.2);
    end

    if ~nd.is_leaf
      t_active = in_trace && any(trace == nd.true_id);
      f_active = in_trace && any(trace == nd.false_id);
      if t_active
        set(gfx.h_edges(i, 1), 'Color', [0.30 0.95 0.50], 'LineWidth', 3.0);
      else
        set(gfx.h_edges(i, 1), 'Color', [0.35 0.40 0.48], 'LineWidth', 1.4);
      end
      if f_active
        set(gfx.h_edges(i, 2), 'Color', [0.95 0.75 0.25], 'LineWidth', 3.0);
      else
        set(gfx.h_edges(i, 2), 'Color', [0.35 0.40 0.48], 'LineWidth', 1.4);
      end
    end
  end
end

%% ========================================================================
%  9. AUTOMATED UNIT TESTS (Run via: test octave_dtree_platformer_v5)
% =========================================================================
%!test
%! % 1. Toolkit negotiation in --no-gui mode
%! tk = octave_dtree_platformer_v5('__call__display_select_toolkit', {'fltk', 'qt'});
%! assert(ischar(tk) && any(strcmp(tk, {'fltk', 'qt'})));

%!test
%! % 2. Offscreen figure handle creation under --no-gui
%! tk = octave_dtree_platformer_v5('__call__display_select_toolkit', {'fltk', 'qt'});
%! fig = octave_dtree_platformer_v5('__call__renderer_create_figure', tk, 'Test Window', 'off');
%! assert(ishandle(fig));
%! close(fig);

%!test
%! % 3. Pure input reducer latch & player physics displacement
%! cfg = octave_dtree_platformer_v5('__call__cfg_init');
%! st  = octave_dtree_platformer_v5('__call__state_init', cfg);
%! x0  = st.player.x;
%! buf = octave_dtree_platformer_v5('__call__input_buffer_init');
%! buf = octave_dtree_platformer_v5('__call__input_reduce_key', buf, 'd', true, 1.0);
%! [inp, buf] = octave_dtree_platformer_v5('__call__input_consume_buffer', buf, 1.01, cfg);
%! assert(inp.right == true);
%! st  = octave_dtree_platformer_v5('__call__world_step', st, inp, cfg);
%! assert(st.player.x > x0);

%!test
%! % 4. Decision Tree PATROL -> CHASE transition when player enters sight range
%! cfg  = octave_dtree_platformer_v5('__call__cfg_init');
%! tree = octave_dtree_platformer_v5('__call__dtree_build');
%! st   = octave_dtree_platformer_v5('__call__state_init', cfg);
%! [act1, ~] = octave_dtree_platformer_v5('__call__dtree_evaluate', tree, st, cfg);
%! assert(strcmp(act1, 'PATROL'));
%! st.player.x = st.enemy.x - 10.0;
%! [act2, trace] = octave_dtree_platformer_v5('__call__dtree_evaluate', tree, st, cfg);
%! assert(strcmp(act2, 'CHASE'));
%! assert(isequal(trace, [1, 3, 5, 7, 9]));
