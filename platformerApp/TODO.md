# TODO & Modular Development Roadmap

This roadmap outlines prioritized next steps and self-contained expansion modules designed to plug directly into the decoupled `cfg` / `state` / `tree` / `gfx` architecture of **Decision Tree AI Platformer**.

---

## Phase 1: Package Refactoring & Core Engine Hardening

- [ ] **Split into Multi-File Module Directory (`src/`)**
  - Extract `cfg_init.m`, `state_init.m`, `dtree_build.m`, `dtree_evaluate.m`, `world_step.m`, and `renderer_init.m` / `renderer_update.m` into standalone `.m` files.
  - Add a `run_game.m` entry point that configures `addpath('src')` and selects the fastest available toolkit (`qt` or `fltk`).
- [ ] **Frame-Time Profiler & FPS HUD Overlay**
  - Add a rolling 60-sample frame-time ring buffer (`dt_render`, `dt_physics`, `dt_ai`) inside `state.metrics`.
  - Display live FPS and frame budget utilization (`ms / 16.67 ms`) in the top telemetry bar to verify 60+ FPS performance across machines.
- [ ] **Input Buffering & Variable Jump Height**
  - Add a `jump_buffer_timer` (`0.10 s`) so pressing `W`/`SPACE` slightly before landing triggers an immediate jump on touchdown.
  - Cut upward vertical velocity (`vy = vy * 0.5`) when `W`/`SPACE` is released early for tighter platforming control.

---

## Phase 2: Combat, Projectiles & Sensor Modules

- [ ] **Module: `combat_step.m` (Ranged & Melee Mechanics)**
  - Add player EMP pulse / plasma bolt firing (`F` or `J` key) with cooldown timers and pre-allocated projectile handle pools (`MAX_PROJ = 16`).
  - Add drone laser telegraphing (0.4 s warning beam before firing) so the player can dodge using platforms or crouch.
- [ ] **Module: `sensors_update.m` (Raycasting & Line-of-Sight)**
  - Implement 2D segment-vs-AABB raycasting between the drone and player so solid walls/platforms block drone vision.
  - Add a visual perception cone (`patch` with `FaceAlpha = 0.15`) that shifts color from cyan (`PATROL`) to amber (`SEARCH`) to red (`LOCKED`).
- [ ] **Sound Effects via Pure Octave Audio (`audio_fx.m`)**
  - Synthesize lightweight procedural 8-bit waveforms (`sin`, `square`, white noise envelopes) for jump, EMP hack, laser fire, and gate unlock using `audioplayer` (with silent fallback if audio hardware is unavailable).

---

## Phase 3: Multi-Agent AI & Data-Driven Decision Trees

- [ ] **Multi-Enemy Wave & Archetype Manager (`spawner_step.m`)**
  - Support multiple simultaneous AI entities (`state.enemies(1:N)`), each referencing either a shared decision tree or specialized archetype trees:
    - **Interceptor Drone**: Aggressive chase and flanking behavior.
    - **Shield Turret**: Stationary area-denial unit requiring terminal hacks or rear attacks.
    - **Medic Bot**: Prioritizes repairing damaged allied drones over attacking the player.
- [ ] **ID3 / CART Offline Decision Tree Trainer (`dtree_train_id3.m`)**
  - Log player gameplay state-action pairs `(distance_x, distance_y, player_hp, drone_hp, emp_active) -> optimal_action` to a `.csv` dataset.
  - Implement an Information Gain (Entropy / Gini impurity) induction module in pure GNU Octave that compiles trained `.csv` behavioral logs directly into a `tree` struct compatible with `dtree_evaluate()`.
- [ ] **JSON / CSV Level Loader (`level_load.m`)**
  - Externalize platform coordinates, terminal locations, hazard zones, and enemy spawn points into `levels/level_01.csv` and `levels/level_02.csv` for rapid stage design without modifying Octave code.

---

## Phase 4: Visual Polish & Replay System

- [ ] **Object-Pooled Particle System (`particles_step.m`)**
  - Pre-allocate a fixed 64-particle `scatter` or `patch` pool for jump dust, EMP shockwave rings, spark bursts, and jet exhaust trails while keeping frame times under 8 ms.
- [ ] **Deterministic Replay Recorder (`replay_io.m`)**
  - Record per-frame input bitmasks (`uint8`) and initial RNG seed so entire runs can be saved to `.mat` / `.bin` files and replayed deterministically for AI debugging.
