# Decision Tree AI Platformer (GNU Octave)

A real-time, interactive 2D platformer and live **Decision Tree AI visualization sandbox** 
engineered specifically for **GNU Octave** (`octave_dtree_platformer.m`). 
Control the runner in real time while watching an autonomous guard drone evaluate 
a binary decision tree at **60+ FPS**.

---

## Key Features

* **Real-Time 60+ FPS Gameplay**: Deterministic fixed-timestep simulation (`dt = 1/60 s`) coupled with a dirty-flag graphics pipeline.
* **Live Decision Tree Execution Visualizer**: Side-by-side schematic showing every decision node, branch edge, and active leaf action (`PATROL`, `CHASE`, `ATTACK`, `EVADE`, `STUNNED`) highlighted on the exact frame it executes.
* **Pure GNU Octave Compatibility**: Zero external Octave-Forge packages required, zero global variables, and full compatibility across `qt` and `fltk` graphics toolkits (avoiding MATLAB-only constructs such as `gobjects`).
* **Interactive Arena Mechanics**:
  * **One-Way Platforms**: Jump up through elevated ledges and drop down using crouch/fast-fall (`S`).
  * **EMP Terminal Hack**: Interact with the upper-center terminal (`ENTER`) to trigger a localized EMP shockwave that stuns the guard drone and unlocks the exit gate.
  * **Dynamic AI States**: The drone reacts to line-of-sight range, attack proximity, EMP stun timers, and low-integrity retreat thresholds.
* **Modular, Decoupled Architecture**: Every subsystem communicates strictly through plain Octave structs (`cfg`, `state`, `tree`, `gfx`), allowing effortless splitting into separate `.m` files or adding new game modules.

---

## Requirements & Compatibility

* **Runtime**: GNU Octave **6.x, 7.x, 8.x, or 9.x+** (tested with core built-in functions only).
* **Graphics Toolkit**: `qt` (recommended for highest frame rates) or `fltk`.
* **External Dependencies**: None.

### Quick Start

1. Place `octave_dtree_platformer.m` in your GNU Octave working directory.
2. Run the simulation from the Octave Command Window:
   ```octave
   graphics_toolkit('qt'); % Optional: ensures fastest hardware-accelerated rendering
   octave_dtree_platformer
   ```
3. **Click inside the figure window** once it opens so keyboard events register properly.

---

## Controls

| Key | Action | Description |
| :--- | :--- | :--- |
| **`A`** / **`D`** | Move Left / Right | Applies horizontal velocity with ground/air acceleration damping. |
| **`W`** / **`SPACE`** | Jump | Applies vertical launch impulse when grounded (with coyote-time tolerance). |
| **`S`** | Crouch / Fast-Fall | Increases downward gravity acceleration and drops through one-way platforms. |
| **`ENTER`** | Interact / Hack / Exit | Hacks the upper terminal when in range (stuns drone + unlocks gate) or completes the level at the unlocked exit gate. |
| **`R`** | Reset Level | Resets player, drone, terminal, gate, and decision trace to initial state. |

---

## Decoupled Software Architecture

The codebase is organized into **6 isolated functional layers** inside `octave_dtree_platformer.m`. 
No function mutates hidden state or relies on `global` declarations:

```text
+------------------+      +------------------+      +-------------------+
|   cfg_init()     | ---> |   state_init()   | ---> |   dtree_build()   |
| (Immutable Tunables)    | (World & Entities) |    | (Declarative Tree)|
+------------------+      +------------------+      +-------------------+
                                   |                          |
                                   v                          v
                          +------------------+      +-------------------+
                          |   world_step()   | <--- | dtree_evaluate()  |
                          | (Physics & Input)|      | (Pure Traversal)  |
                          +------------------+      +-------------------+
                                   |
                                   v
                    +-----------------------------+
                    | renderer_init() / _update() |
                    |  (60+ FPS Handle Pipeline)  |
                    +-----------------------------+
```

### Module Breakdown

1. **`cfg_init()` — Configuration Layer**
   * Stores immutable simulation constants: timestep (`dt`), gravity, jump velocity, platform bounding boxes, sensor radii, and frame-rate target.
2. **`state_init(cfg)` — Single Source of Truth**
   * Initializes all mutable runtime structs: `player` (`x, y, vx, vy, hp, grounded`), `drone` (`x, y, vx, stun_timer, hp, ai_action`), `terminal_hacked`, `gate_open`, and input bitflags.
3. **`dtree_build()` — Declarative Behavior Graph**
   * Defines the AI brain as a pure struct array of nodes (`id`, `label`, `is_leaf`, `cond_fn`, `true_id`, `false_id`, `action`, `pos`). Adding new AI rules requires zero changes to the physics or rendering engines.
4. **`dtree_evaluate(tree, state, cfg)` — Pure Decision Engine**
   * Traverses from `root_id` down to a terminal action leaf in $O(h)$ time (where $h$ is tree depth), returning both the winning action string and `trace_ids` (the exact array of visited node IDs).
5. **`world_step(state, input, cfg)` & `ai_apply_action(...)` — Physics & Actuation**
   * Executes semi-implicit Euler integration, AABB and one-way ledge collision resolution, EMP stun countdowns, and actuator velocity commands.
6. **`renderer_init(...)` & `renderer_update(...)` — High-Speed Graphics Layer**
   * Pre-allocates all `patch`, `line`, and `text` handles once at startup and updates only changed `XData`/`YData`/`FaceColor` properties per frame.

---

## Algorithms & 60+ FPS Optimization Techniques

### 1. Binary Decision Tree Traversal & Trace Instrumentation
* Each internal node holds an anonymous predicate handle `@(s, c) ...` evaluated against the current world snapshot.
* Traversal records every visited node index into `trace_ids`, enabling the right-hand schematic viewport to highlight active decision branches in real time without duplicating logic.

### 2. Semi-Implicit Euler Kinematics & Swept One-Way Platform Resolution
* Velocities are updated prior to positions ($v_{t+\Delta t} = v_t + a \Delta t$, $x_{t+\Delta t} = x_t + v_{t+\Delta t} \Delta t$) for energy stability at 60 Hz.
* One-way platforms check previous-frame foot height ($y_{	ext{prev}} \ge y_{	ext{plat}}$) against current-frame foot height ($y_{	ext{curr}} \le y_{	ext{plat}}$) so the player can jump upward unimpeded while landing cleanly on top.

### 3. GNU Octave 60+ FPS Rendering Optimizations
* **Zero Object Recreation**: No `cla`, `plot`, or `fill` calls occur inside the main `while` loop; all geometry is mutated via `set(h, 'XData', ..., 'YData', ...)`.
* **Numeric Handle Arrays**: Uses standard `zeros(N, 1)` handle vectors instead of `gobjects` for 100% Octave compatibility and minimal memory overhead.
* **Dirty-State Tree Redraws**: Decision tree edge and node colors are only re-styled when `trace_ids` changes from the previous frame, eliminating redundant GUI property flushes.
* **Frame-Paced Accumulator Loop**: Uses `tic`/`toc` wall-clock deltas to step physics deterministically and throttle `drawnow` to maintain smooth 60+ FPS pacing without saturating CPU threads.

---

## Extending the Project

To split this single file into a multi-file package:
1. Create a folder named `dtree_platformer/`.
2. Move `cfg_init`, `state_init`, `dtree_build`, `dtree_evaluate`, `world_step`, and `renderer_*` into individual `.m` files matching each function name.
3. Keep `octave_dtree_platformer.m` as the lightweight entry-point orchestrator.
