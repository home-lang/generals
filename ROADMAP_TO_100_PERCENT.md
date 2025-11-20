# C&C Generals - Complete Roadmap to 100% Accuracy

## 🎯 Goal: Achieve Feature Parity with Original C&C Generals

**Current Progress:** 12% → **Target:** 100%

This document outlines the complete path to recreate C&C Generals with full accuracy based on the Thyme source code analysis.

**Reference:** `~/Code/Thyme` (C&C Generals reimplementation in C++)

---

## 📊 Current Status vs Target

| System | Current | Target | Gap |
|--------|---------|--------|-----|
| **Graphics** | 2D sprites (5%) | 3D W3D engine (100%) | 95% |
| **Combat** | Basic damage (15%) | Full armor/pierce (100%) | 85% |
| **Weapons** | Simple stats (10%) | WeaponSets + bonuses (100%) | 90% |
| **AI** | Auto-target (5%) | Full AI (100%) | 95% |
| **Particles** | 2D sprites (20%) | 3D W3D particles (100%) | 80% |
| **Pathfinding** | Basic A* (40%) | Formations + dynamic (100%) | 60% |
| **UI** | Layout only (30%) | Full functionality (100%) | 70% |
| **Production** | Structure exists (5%) | Full system (100%) | 95% |
| **Audio** | None (0%) | 3D audio + music (100%) | 100% |
| **Multiplayer** | Code exists (0%) | Lockstep network (100%) | 100% |
| **Terrain** | Flat 2D (0%) | 3D heightmap (100%) | 100% |
| **Powers** | None (0%) | All general powers (100%) | 100% |
| **Overall** | **~12%** | **100%** | **88%** |

---

## Phase 1: Foundation & Graphics Engine (12% → 30%)
**Priority:** CRITICAL
**Estimated Time:** 6-8 months full-time
**Code:** ~60,000 lines

### 1.1 W3D 3D Graphics Engine ⭐ HIGHEST PRIORITY

**Why Critical:** Everything depends on this - units, buildings, terrain, particles all use W3D

**Current State:**
- `src/engine/w3d_loader.zig` - Partial W3D mesh parsing exists
- Only loads basic structure, not usable for rendering

**Target State:**
- Full W3D model loading and rendering
- All animations working
- All materials and textures applied

**Tasks:**

- [ ] **Complete W3D Loader** (`src/engine/w3d_loader.zig`)
  - [x] Basic mesh structure (DONE)
  - [ ] W3D_CHUNK_HIERARCHY - Bone hierarchy for animations
  - [ ] W3D_CHUNK_ANIMATION - Animation data
  - [ ] W3D_CHUNK_COMPRESSED_ANIMATION - Optimized animations
  - [ ] W3D_CHUNK_HLOD - Hierarchical LOD
  - [ ] W3D_CHUNK_MATERIAL_INFO - Material definitions
  - [ ] W3D_CHUNK_SHADER - Shader parameters
  - [ ] W3D_CHUNK_TEXTURES - Texture references
  - [ ] W3D_CHUNK_VERTICES - Vertex positions
  - [ ] W3D_CHUNK_VERTEX_NORMALS - Normal vectors
  - [ ] W3D_CHUNK_VERTEX_INFLUENCES - Skinning weights
  - [ ] W3D_CHUNK_TRIANGLES - Triangle indices
  - [ ] W3D_CHUNK_VERTEX_SHADE_INDICES - Color indices

**Reference Files:**
- `~/Code/Thyme/src/w3d/renderer/w3d.h` - W3D format specification
- `~/Code/Thyme/src/w3d/renderer/w3dformat.h` - Chunk definitions
- `~/Code/Thyme/src/w3d/lib/chunkio.cpp` - Chunk reading

**Test:** Load and render `AVCrusaderTank.W3D` from assets

---

- [ ] **3D Renderer with Metal** (`src/renderer/w3d_renderer.zig` - NEW FILE, ~3,000 lines)
  - [ ] Replace `macos_sprite_renderer.zig` 2D system with 3D
  - [ ] Vertex buffer objects (VBOs) for mesh data
  - [ ] Index buffer objects (IBOs) for triangles
  - [ ] Shader program management (vertex + fragment shaders)
  - [ ] Uniform buffers (view, projection, model matrices)
  - [ ] Texture binding and sampling
  - [ ] Multi-pass rendering (opaque, then transparent)
  - [ ] Z-buffering and depth testing
  - [ ] Alpha blending for transparency
  - [ ] Backface culling

**Shaders to Create:**
- `shaders/model_vertex.metal` - Transform vertices to screen space
- `shaders/model_fragment.metal` - Apply textures and lighting
- `shaders/skinned_vertex.metal` - Bone-based animation
- `shaders/terrain_vertex.metal` - Terrain with multi-texturing
- `shaders/terrain_fragment.metal` - Blend terrain textures

**Reference Files:**
- `~/Code/Thyme/src/w3d/renderer/render.cpp` - Main rendering loop
- `~/Code/Thyme/src/w3d/renderer/dx8renderer.cpp` - DirectX 8 renderer (adapt to Metal)

**Test:** Render rotating Crusader tank at 60 FPS

---

- [ ] **Lighting System** (`src/renderer/lighting.zig` - NEW FILE, ~1,500 lines)
  - [ ] Directional light (sun) with position and color
  - [ ] Point lights (up to 8 active at once)
  - [ ] Ambient lighting (base illumination)
  - [ ] Diffuse lighting (Lambert model)
  - [ ] Specular highlights (Phong model)
  - [ ] Light attenuation for point lights (distance falloff)
  - [ ] Per-pixel lighting in fragment shader
  - [ ] Normal mapping support

**Light Types from Thyme:**
```cpp
enum LightType {
    LIGHT_DIRECTIONAL,  // Sun
    LIGHT_POINT,        // Explosion, muzzle flash
    LIGHT_SPOT,         // Searchlight
};
```

**Reference Files:**
- `~/Code/Thyme/src/w3d/renderer/light.cpp`
- `~/Code/Thyme/src/w3d/renderer/dx8wrapper.cpp` (lighting setup)

**Test:** Crusader tank lit by sun + explosion point light

---

- [ ] **Camera System 3D** (`src/renderer/camera_3d.zig` - NEW FILE, ~800 lines)
  - [ ] Replace `src/engine/camera.zig` 2D camera
  - [ ] Perspective projection matrix
  - [ ] View matrix (position + look-at direction)
  - [ ] Frustum culling (don't render off-screen objects)
  - [ ] Camera controls:
    - WASD pan
    - Mouse edge scrolling
    - Mouse wheel zoom
    - Middle-mouse rotate camera angle
  - [ ] Height constraints (min/max camera altitude)
  - [ ] Angle constraints (RTS-style isometric view)
  - [ ] Smooth interpolation (no jerky movement)

**Reference Files:**
- `~/Code/Thyme/src/game/client/view.cpp`

**Test:** Camera smoothly pans, zooms, rotates around map

---

### 1.2 Terrain System ⭐ HIGH PRIORITY

**Why Critical:** Without terrain, units float in space. Pathfinding needs terrain.

**Current State:**
- Flat 2D plane (0% complete)
- No heightmap, no textures, no features

**Target State:**
- 3D terrain from heightmaps (.tga files in assets/maps/)
- Multi-texture blending (grass, sand, roads, water)
- Cliffs, rivers, roads all rendered

**Tasks:**

- [ ] **Heightmap Loading** (`src/engine/heightmap.zig` - NEW FILE, ~800 lines)
  - [ ] Load .TGA heightmap files (16-bit grayscale)
  - [ ] Convert pixel values to height values
  - [ ] Configurable height scale
  - [ ] Border clamping
  - [ ] Bilinear filtering for smooth terrain

**Heightmap Format:**
- 256x256 pixels or 512x512 pixels
- Each pixel = height value (0-65535)
- Stored in `assets/maps/<mapname>/height.tga`

**Reference Files:**
- `~/Code/Thyme/src/game/client/terrainvisual.cpp` (line 150+)

**Test:** Load `assets/maps/Tournament Desert/height.tga`

---

- [ ] **Terrain Mesh Generation** (`src/engine/terrain.zig` - NEW FILE, ~4,000 lines)
  - [ ] Generate triangle mesh from heightmap
  - [ ] Calculate vertex normals for lighting
  - [ ] Generate texture coordinates (UV mapping)
  - [ ] LOD system (Level of Detail):
    - Full detail near camera
    - Lower detail far away
    - Reduces triangles from 500K to 50K
  - [ ] Terrain chunking (split large maps into tiles)
  - [ ] Chunk frustum culling (don't render off-screen chunks)

**LOD Levels:**
- Level 0: Full resolution (1 triangle per heightmap pixel)
- Level 1: Half resolution (1 triangle per 2x2 pixels)
- Level 2: Quarter resolution (1 triangle per 4x4 pixels)

**Reference Files:**
- `~/Code/Thyme/src/game/client/terrainvisual.cpp`

**Test:** Generate mesh for Tournament Desert map

---

- [ ] **Terrain Texturing** (`src/engine/terrain_renderer.zig` - NEW FILE, ~2,500 lines)
  - [ ] Load terrain texture atlas (8 textures: grass, sand, cliff, etc.)
  - [ ] Texture blending (smooth transitions between textures)
  - [ ] Multi-texturing (up to 4 textures per pixel)
  - [ ] Detail textures (add fine grain up close)
  - [ ] Road rendering (separate texture layer)
  - [ ] Water rendering with animation
  - [ ] Cliff rendering with edge detection

**Texture Types from Map Files:**
- Base textures: grass, sand, dirt, rock
- Detail textures: grass detail, sand detail
- Road textures: asphalt, dirt road
- Water texture: animated water surface

**Reference Files:**
- `~/Code/Thyme/src/game/client/terraintex.cpp`

**Test:** Render textured Tournament Desert map

---

- [ ] **Water System** (`src/engine/water.zig` - NEW FILE, ~1,200 lines)
  - [ ] Water plane rendering
  - [ ] Water UV scrolling (animated waves)
  - [ ] Water reflection (mirror camera view)
  - [ ] Water refraction (distort underwater objects)
  - [ ] Shoreline blending (fade water near land)
  - [ ] Water transparency (alpha blending)

**Reference Files:**
- `~/Code/Thyme/src/game/client/water.cpp`

**Test:** Animated water on River Raid map

---

### 1.3 W3D Particle System ⭐ MEDIUM PRIORITY

**Why Important:** Visual feedback for combat. Current 2D particles look wrong.

**Current State:**
- `src/renderer/particle_system.zig` - 2D sprite particles (20% complete)
- Works but not authentic to original game

**Target State:**
- Full 3D W3D particle system with all effect types
- Billboard particles (camera-facing quads)
- Mesh particles (3D debris chunks)

**Tasks:**

- [ ] **W3D Particle Emitters** (`src/renderer/w3d_particles.zig` - REPLACE particle_system.zig, ~3,500 lines)
  - [ ] Emitter types:
    - Burst (one-time spawn, e.g., explosion)
    - Continuous (constant spawn, e.g., flame)
    - Area (spawn in volume, e.g., smoke cloud)
  - [ ] Particle spawn patterns:
    - Point (from single location)
    - Line (along a line)
    - Sphere (in all directions)
    - Cone (directional spray)
  - [ ] Velocity inheritance (particles move with emitter)
  - [ ] Emission rate curves (spawn rate changes over time)
  - [ ] Particle lifetime management
  - [ ] Emitter attachments (follow unit bones)

**Reference Files:**
- `~/Code/Thyme/src/w3d/renderer/particlesys.cpp`
- `~/Code/Thyme/src/game/client/particle/particlesys.cpp`

**Test:** Explosion emits 50 particles in sphere pattern

---

- [ ] **Particle Rendering** (`src/renderer/particle_emitter.zig` - NEW FILE, ~2,000 lines)
  - [ ] Billboard particles (always face camera)
  - [ ] Oriented particles (align to velocity vector)
  - [ ] Mesh particles (use 3D models)
  - [ ] Beam particles (laser beams)
  - [ ] Ribbon particles (missile trails)
  - [ ] Particle sorting (render far-to-near for transparency)
  - [ ] Additive blending (bright explosions)
  - [ ] Alpha blending (smoke fadeout)

**Reference Files:**
- `~/Code/Thyme/src/w3d/renderer/particleemitter.cpp`

**Test:** 1000 billboard particles render correctly

---

- [ ] **Particle Physics** (integrate into `w3d_particles.zig`)
  - [ ] Gravity (particles fall)
  - [ ] Wind (particles drift)
  - [ ] Turbulence/noise (particles wobble)
  - [ ] Terrain collision (particles bounce off ground)
  - [ ] Particle fade-out curves (alpha over lifetime)
  - [ ] Size curves (grow or shrink over lifetime)
  - [ ] Color curves (change color over lifetime)

**Test:** Smoke particles rise then drift with wind

---

- [ ] **Particle Effects Library** (`src/renderer/particle_effects.zig` - NEW FILE, ~1,800 lines)
  - [ ] Load particle effects from INI files
  - [ ] Effect presets:
    - Explosions (small, medium, large, nuclear)
    - Muzzle flashes (rifle, cannon, rocket)
    - Projectile trails (bullet tracers, rocket smoke)
    - Smoke (black, white, colored)
    - Fire (campfire, building fire, napalm)
    - Dust clouds (vehicle movement)
    - Water splashes
    - Building destruction debris
    - Unit death effects
    - Special ability effects (A-10 strike, SCUD)

**INI Files to Parse:**
- `assets/data/ParticleSystem.ini` - Effect definitions
- Each effect has emitters, particles, physics parameters

**Reference Files:**
- `~/Code/Thyme/src/game/client/particle/particlesysinfo.cpp`

**Test:** Load and spawn "FX_TankDeathExplosion" effect

---

## Phase 2: Weapon & Combat Systems (30% → 50%)
**Priority:** HIGH
**Estimated Time:** 4-6 months full-time
**Code:** ~25,000 lines

### 2.1 Weapon System ⭐ HIGHEST PRIORITY

**Why Critical:** Combat is core gameplay. Current system is 90% incomplete.

**Current State:**
- `src/engine/combat.zig` - Simple damage value (10% complete)
- No weapon bonuses, no anti-types, no damage types

**Target State:**
- Full weapon system matching Thyme's complexity
- WeaponSets, bonuses, conditions, anti-types all working

**Tasks:**

- [ ] **Weapon Template System** (`src/engine/weapon_system.zig` - NEW FILE, ~5,000 lines)
  - [ ] Load weapon definitions from `assets/data/Weapon.ini`
  - [ ] WeaponTemplate structure:
    ```zig
    pub const WeaponTemplate = struct {
        name: []const u8,
        damage: f32,
        damage_type: DamageType,
        damage_radius: f32,
        clip_size: u32,
        reload_time: f32,
        range_min: f32,
        range_max: f32,
        rate_of_fire: f32,
        accuracy: f32,
        scatter_radius: f32,
        projectile_template: *ProjectileTemplate,
        damage_nuggets: []DamageNugget,
        anti_categories: []AntiType,
        bonus_conditions: []WeaponBonusCondition,
    };
    ```
  - [ ] Parse all 150+ weapon definitions from INI

**Example Weapon INI:**
```ini
Weapon AVCrusaderTankGun
  AttackRange = 200.0
  RadiusDamageAffects = ENEMIES
  DelayBetweenShots = 2000  ; milliseconds
  WeaponSpeed = 400  ; projectile speed
  MinWeaponSpeed = 400
  MaxWeaponSpeed = 600
  FireFX = WeaponFX_GenericTankGunNoTracer
  VeterancyFireFX = HEROIC WeaponFX_HeroicTankGunNoTracer
  ProjectileNugget
    ProjectileTemplateName = AVCrusaderTankShell
    WarheadTemplateName = AVCrusaderTankShellWarhead
  End
  DamageNugget
    Damage = 50
    Radius = 0
    DelayTime = 0
    DamageType = ARMOR_PIERCING
    DeathType = NORMAL
  End
End
```

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/weapon.h` - Weapon class definition
- `~/Code/Thyme/src/game/logic/object/weaponset.cpp` - WeaponSet handling
- `~/Code/Thyme/src/game/common/ini/weapon.ini` - All weapon stats

**Test:** Load "AVCrusaderTankGun" weapon from INI

---

- [ ] **Damage Types** (add to `weapon_system.zig`)
  - [ ] Enum:
    ```zig
    pub const DamageType = enum {
        ARMOR_PIERCING,  // Good vs tanks
        HOLLOW_POINT,    // Good vs infantry
        SMALL_ARMS,      // Infantry weapons
        EXPLOSION,       // Explosives
        FIRE,            // Flame weapons
        LASER,           // Laser weapons
        POISON,          // Chemical weapons
        INFANTRY_MISSILE, // Stinger missiles
        TANK_CANNON,     // Tank shells
        ARTILLERY,       // Artillery shells
    };
    ```
  - [ ] Damage type affects armor penetration

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/weapon.h` (line 89)

---

- [ ] **Anti-Type System** (add to `weapon_system.zig`)
  - [ ] Enum:
    ```zig
    pub const AntiType = enum {
        ANTI_GROUND,
        ANTI_AIR,
        ANTI_BUILDING,
        ANTI_INFANTRY,
        ANTI_TANK,
        ANTI_AIRCRAFT,
        ANTI_MINE,
    };
    ```
  - [ ] Damage multipliers per anti-type:
    - ANTI_TANK vs Vehicle: 125% damage
    - ANTI_INFANTRY vs Infantry: 150% damage
    - ANTI_BUILDING vs Building: 200% damage
  - [ ] Multiple anti-types per weapon allowed

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/weapon.h` (line 67)

**Test:** Tank Hunter (ANTI_TANK) deals 150% vs tanks, 50% vs infantry

---

- [ ] **Weapon Bonus Conditions** (add to `weapon_system.zig`)
  - [ ] Enum:
    ```zig
    pub const WeaponBonusType = enum {
        PLAYER_UPGRADE,   // Tech upgrade applied
        VETERAN,          // Unit is veteran
        ELITE,            // Unit is elite
        HEROIC,           // Unit is heroic
        HORDE,            // In a large group
        CONTINUOUS_FIRE,  // Gatling gun spin-up
        ENTHUSIASTIC,     // High morale
        ENEMY_CAPTURED,   // Captured enemy building
    };
    ```
  - [ ] Bonus values:
    ```zig
    pub const WeaponBonus = struct {
        condition: WeaponBonusType,
        damage_multiplier: f32,      // 1.25 = +25% damage
        range_multiplier: f32,
        rate_of_fire_multiplier: f32,
    };
    ```
  - [ ] Bonuses stack multiplicatively

**Example:**
- Base damage: 50
- Veteran bonus: 1.25x → 62.5 damage
- + Player upgrade: 1.15x → 71.875 damage

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/weapon.h` (line 42)

**Test:** Elite Crusader tank deals 156% damage vs base

---

- [ ] **Weapon Sets** (add to `weapon_system.zig`)
  - [ ] Units can have multiple weapons
  - [ ] WeaponSet struct:
    ```zig
    pub const WeaponSet = struct {
        weapons: [8]*WeaponTemplate,  // Up to 8 weapons
        weapon_count: u8,
        conditions: []WeaponSetCondition,
        preferred_target_type: TargetType,
    };
    ```
  - [ ] Weapon selection logic:
    - Check each weapon's conditions
    - Pick best weapon for target type
    - Example: Overlord tank uses Gatling vs infantry, Cannon vs tanks

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/weaponset.cpp`

**Test:** Overlord automatically switches weapons based on target

---

- [ ] **Projectile System** (`src/engine/projectile.zig` - NEW FILE, ~2,500 lines)
  - [ ] Projectile types:
    - Ballistic (artillery shells with gravity arc)
    - Straight (bullets, lasers)
    - Guided (tracking missiles)
  - [ ] Projectile struct:
    ```zig
    pub const Projectile = struct {
        position: Vec3,
        velocity: Vec3,
        acceleration: Vec3,
        target_id: ?u32,
        weapon: *WeaponTemplate,
        lifetime: f32,
        model: *W3DModel,
        trail_emitter: ?*ParticleEmitter,
    };
    ```
  - [ ] Projectile physics:
    - Gravity (for ballistic)
    - Air resistance
    - Homing (for guided missiles)
    - Collision detection vs terrain/units
  - [ ] Impact effects:
    - Spawn explosion particles
    - Apply damage in radius
    - Create decal (scorch mark)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/projectile.cpp`

**Test:** Fire tank shell, watch it arc and explode on impact

---

### 2.2 Combat & Damage System

**Current State:**
- `src/engine/combat.zig` - Simple health subtraction (15% complete)

**Target State:**
- Full damage calculations with armor, pierce, overkill, splash

**Tasks:**

- [ ] **Armor System** (`src/engine/armor_system.zig` - NEW FILE, ~1,500 lines)
  - [ ] Armor types:
    ```zig
    pub const ArmorType = enum {
        NONE,              // Unarmored (buildings mid-construction)
        INFANTRY,          // Soldiers
        INFANTRY_HERO,     // Special forces
        VEHICLE_LIGHT,     // Humvees
        VEHICLE_MEDIUM,    // Crusader tanks
        VEHICLE_HEAVY,     // Overlord tanks
        AIRCRAFT,          // Planes and helicopters
        BUILDING,          // Structures
        STRUCTURE_HEAVY,   // Bunkers
    };
    ```
  - [ ] Armor values per type (damage reduction %)
  - [ ] Load from `assets/data/Armor.ini`
  - [ ] Veterancy armor bonuses:
    - Veteran: +25% effective armor
    - Elite: +50% effective armor
    - Heroic: +75% effective armor

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/armorset.cpp`
- `~/Code/Thyme/src/game/common/ini/armor.ini`

**Test:** Infantry takes 150% damage from ANTI_INFANTRY weapons

---

- [ ] **Damage Calculator** (`src/engine/damage_calculator.zig` - NEW FILE, ~2,000 lines)
  - [ ] Main damage calculation function:
    ```zig
    pub fn calculateDamage(
        weapon: *WeaponTemplate,
        attacker: *Entity,
        target: *Entity,
    ) f32 {
        var damage = weapon.damage;

        // Apply weapon bonuses
        for (weapon.bonus_conditions) |bonus| {
            if (checkBonusCondition(bonus, attacker)) {
                damage *= bonus.damage_multiplier;
            }
        }

        // Apply anti-type bonuses
        for (weapon.anti_categories) |anti_type| {
            if (targetMatchesAntiType(anti_type, target)) {
                damage *= 1.25; // +25% vs preferred target
            }
        }

        // Apply armor mitigation
        const armor_reduction = target.unit_data.armor_value;
        damage *= (1.0 - armor_reduction);

        // Apply damage type modifiers
        damage *= getDamageTypeModifier(weapon.damage_type, target.armor_type);

        // Randomization (±10%)
        damage *= randomRange(0.9, 1.1);

        return damage;
    }
    ```
  - [ ] Damage type vs armor type matrix:
    - ARMOR_PIERCING vs VEHICLE_HEAVY: 100% damage
    - HOLLOW_POINT vs INFANTRY: 150% damage
    - SMALL_ARMS vs VEHICLE_HEAVY: 25% damage
  - [ ] Pierce calculation (armor penetration)
  - [ ] Critical hit system (5% chance for 2x damage)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/update/clientupdate.cpp` (damage handling)

**Test:** Tank shell does 50 damage to infantry, 100 to tank

---

- [ ] **Splash Damage** (add to `damage_calculator.zig`)
  - [ ] Damage falloff with distance:
    ```zig
    pub fn applySplashDamage(
        position: Vec3,
        radius: f32,
        max_damage: f32,
        entities: []Entity,
    ) void {
        for (entities) |*entity| {
            const distance = entity.position.distance(position);
            if (distance > radius) continue;

            // Linear falloff: full damage at center, 0 at edge
            const damage_percent = 1.0 - (distance / radius);
            const damage = max_damage * damage_percent;

            applyDamage(entity, damage);
        }
    }
    ```
  - [ ] Friendly fire toggle (some weapons hurt friendlies)
  - [ ] Building vs unit splash (buildings take less splash)

**Test:** Tank shell explosion damages 3 nearby infantry for 50/30/10 damage

---

- [ ] **Overkill Damage** (add to `damage_calculator.zig`)
  - [ ] Excess damage transfers to nearby units:
    ```zig
    // Tank has 50 HP, shell does 100 damage
    // Tank dies, 50 excess damage
    // Nearby infantry takes 25 splash damage (50% of excess)
    ```
  - [ ] Only for explosive weapons (not bullets)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/weapon.cpp` (line 234)

**Test:** Overlord tank shell overkills Humvee, damages nearby Ranger

---

- [ ] **Combat Manager** (`src/engine/combat_manager.zig` - REPLACE combat.zig, ~3,000 lines)
  - [ ] Target acquisition:
    - Scan for enemies in weapon range
    - Prioritize targets by threat level
    - Prefer targets unit is effective against
    - Remember last target until dead
  - [ ] Attack commands:
    - Attack-move (attack anything in path)
    - Force-attack (attack specific target)
    - Hold ground (don't chase enemies)
    - Guard (protect specific unit/building)
  - [ ] Attack logic:
    ```zig
    pub fn updateCombat(entity: *Entity, entities: []Entity, dt: f32) void {
        // Update weapon cooldowns
        entity.weapon.cooldown -= dt;

        // Find target if none
        if (entity.target_id == null) {
            entity.target_id = findBestTarget(entity, entities);
        }

        // Validate target (in range, alive, visible)
        if (!isValidTarget(entity, entity.target_id)) {
            entity.target_id = null;
            return;
        }

        // Rotate to face target
        rotateToFaceTarget(entity, getTarget(entity.target_id));

        // Fire if cooldown ready and facing target
        if (entity.weapon.cooldown <= 0 and isFacingTarget(entity)) {
            fireWeapon(entity, getTarget(entity.target_id));
            entity.weapon.cooldown = entity.weapon.rate_of_fire;
        }
    }
    ```
  - [ ] Threat assessment (prioritize dangerous enemies)
  - [ ] Morale system (units flee when morale low)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/update/aiupdate.cpp`

**Test:** Tank automatically targets and kills 5 infantry in sequence

---

### 2.3 Veterancy & Experience

**Current State:**
- Not implemented (0% complete)

**Target State:**
- Full veterancy system with 3 ranks and bonuses

**Tasks:**

- [ ] **Experience System** (`src/engine/veterancy.zig` - NEW FILE, ~1,200 lines)
  - [ ] XP tracking per unit:
    ```zig
    pub const VeterancyData = struct {
        xp: u32,              // Current experience points
        rank: VeterancyRank,  // Current rank
        xp_for_next_rank: u32,
    };

    pub const VeterancyRank = enum {
        REGULAR,   // 0 stars
        VETERAN,   // 1 star - 4 kills worth of XP
        ELITE,     // 2 stars - 8 kills
        HEROIC,    // 3 stars - 16 kills
    };
    ```
  - [ ] XP gain formula:
    - Kill XP = target cost / 4
    - Example: Kill $600 tank → gain 150 XP
  - [ ] XP requirements:
    - Veteran: 100 XP (usually 4 kills)
    - Elite: 300 XP (8 kills total)
    - Heroic: 700 XP (16 kills total)
  - [ ] XP sharing in groups (nearby units get 25% XP)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/experience.cpp`

**Test:** Tank gains veteran rank after 4 kills

---

- [ ] **Veterancy Bonuses** (add to `veterancy.zig`)
  - [ ] Health bonuses:
    - Veteran: +25% max health
    - Elite: +50% max health
    - Heroic: +100% max health
  - [ ] Damage bonuses:
    - Veteran: +25% damage
    - Elite: +50% damage
    - Heroic: +100% damage
  - [ ] Other bonuses:
    - Vision range: +10% per rank
    - Rate of fire: +10% per rank
    - Armor: +10% per rank
  - [ ] Special abilities:
    - Heroic: Self-heal (1% HP per second)
    - Heroic: Inspire nearby units (+10% damage)

**Reference Files:**
- `~/Code/Thyme/src/game/common/ini/veterancy.ini`

**Test:** Heroic tank has 2x health and 2x damage

---

- [ ] **Veterancy UI** (add to `src/engine/ui.zig`)
  - [ ] Rank stars above unit (1-3 gold stars)
  - [ ] XP bar in unit info panel
  - [ ] Chevron glow effect for heroic units
  - [ ] Rank display in selection panel

**Test:** Veteran tank shows 1 star above it

---

## Phase 3: AI & Pathfinding (50% → 65%)
**Priority:** HIGH
**Estimated Time:** 5-7 months full-time
**Code:** ~30,000 lines

### 3.1 Advanced Pathfinding

**Current State:**
- `src/engine/pathfinding.zig` - Basic A* (40% complete)
- Works for single units, no formations

**Target State:**
- Full pathfinding with formations, dynamic avoidance, multi-unit coordination

**Tasks:**

- [ ] **Hierarchical Pathfinding** (`src/engine/pathfinding_advanced.zig` - REPLACE pathfinding.zig, ~4,000 lines)
  - [ ] HPA* (Hierarchical Path A*):
    - Level 0: High-level path (region to region)
    - Level 1: Low-level path (tile to tile within region)
    - Reduces path calculations by 90%
  - [ ] Path caching (reuse paths for similar requests)
  - [ ] Path smoothing (remove unnecessary waypoints)
  - [ ] Dynamic replanning (repath if blocked)
  - [ ] Multi-unit path coordination (avoid path conflicts)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/ai/pathfind/pathfind.cpp`

**Test:** 100 units path across map in <100ms

---

- [ ] **Navigation Mesh** (`src/engine/navmesh.zig` - NEW FILE, ~3,000 lines)
  - [ ] Generate NavMesh from terrain:
    - Walkable polygons (flat ground)
    - Non-walkable areas (cliffs, water)
    - Portal connections (bridges, ramps)
  - [ ] Off-mesh links (teleporters, jump points)
  - [ ] NavMesh updates when buildings destroyed
  - [ ] Pathing costs per terrain type:
    - Road: 1.0 (fast)
    - Grass: 1.2 (normal)
    - Sand: 1.5 (slow)
    - Water: 10.0 (very slow, amphibious only)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/ai/pathfind/pathfindlayer.cpp`

**Test:** Tank paths around cliff via bridge

---

- [ ] **Formation Movement** (`src/engine/formations.zig` - NEW FILE, ~2,500 lines)
  - [ ] Formation types:
    ```zig
    pub const FormationType = enum {
        LINE,        // Horizontal line
        COLUMN,      // Vertical column
        WEDGE,       // V-shape (tanks in front)
        BOX,         // Rectangle
        SCATTER,     // Loose formation
    };
    ```
  - [ ] Formation spacing (based on unit size)
  - [ ] Formation rotation (maintain facing direction)
  - [ ] Dynamic formation adjustment (units fill gaps)
  - [ ] Leader-follower system (leader paths, followers maintain formation)
  - [ ] Formation preservation during combat
  - [ ] Formation splitting/merging

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/locomotor/`

**Test:** 10 tanks move in wedge formation

---

- [ ] **Movement Controller** (`src/engine/movement_controller.zig` - NEW FILE, ~2,000 lines)
  - [ ] Acceleration/deceleration curves (no instant speed changes)
  - [ ] Turn rate constraints (tanks turn slowly)
  - [ ] Collision avoidance between units:
    - Predict future positions
    - Adjust path to avoid collision
    - Slow down if blocked
  - [ ] Waypoint following (smooth path traversal)
  - [ ] Move-to-target with attack (move then auto-attack)
  - [ ] Garrison movement (enter building)
  - [ ] Transport loading/unloading paths

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/locomotor/locomotor.cpp`

**Test:** Tank smoothly accelerates, turns, decelerates to stop

---

### 3.2 Unit AI

**Current State:**
- `src/engine/combat.zig` - Auto-target only (5% complete)

**Target State:**
- Full AI with state machines, tactics, behaviors

**Tasks:**

- [ ] **AI State Machine** (`src/ai/state_machine.zig` - NEW FILE, ~3,000 lines)
  - [ ] AI states:
    ```zig
    pub const AIState = enum {
        IDLE,           // Standing still
        MOVING,         // Moving to destination
        ATTACKING,      // Attacking target
        FLEEING,        // Running away
        GUARDING,       // Protecting location/unit
        PATROLLING,     // Moving between waypoints
        GATHERING,      // Collecting resources
        REPAIRING,      // Repairing damaged unit
        BUILDING,       // Constructing building
        GARRISONED,     // Inside building
        CAPTURING,      // Capturing building (Black Lotus)
    };
    ```
  - [ ] State transitions:
    - IDLE → MOVING (move order)
    - MOVING → ATTACKING (enemy in range)
    - ATTACKING → FLEEING (health < 25%)
    - FLEEING → IDLE (reached safety)
  - [ ] State update logic (run every frame)
  - [ ] State entry/exit callbacks

**Reference Files:**
- `~/Code/Thyme/src/game/logic/ai/aiupdate.cpp`

**Test:** Tank transitions from IDLE to ATTACKING when enemy appears

---

- [ ] **Unit AI Behaviors** (`src/ai/unit_ai.zig` - NEW FILE, ~4,500 lines)
  - [ ] Target prioritization:
    - Threat level (dangerous units first)
    - Unit effectiveness (target units weapon is good against)
    - Distance (prefer close targets)
    - Health (prefer low-health targets for easy kills)
  - [ ] Kiting behavior (hit and run):
    - Attack target
    - Retreat while cooldown
    - Return and attack again
  - [ ] Flanking tactics (approach from sides/rear)
  - [ ] Focus fire (all units attack same target)
  - [ ] Retreat when low health:
    - Health < 25% → flee to base
    - Health < 50% → retreat while firing
  - [ ] Auto-repair damaged units (repair vehicles)
  - [ ] Auto-heal nearby units (medics, Helix)
  - [ ] Garrison in buildings when threatened
  - [ ] Use abilities automatically:
    - Ranger flashbang when outnumbered
    - Pathfinder laser designator on tanks
    - Terrorist detonation near enemies

**Reference Files:**
- `~/Code/Thyme/src/game/logic/ai/ai.cpp`

**Test:** Ranger uses flashbang, then retreats when low health

---

- [ ] **Squad AI** (`src/ai/squad_ai.zig` - NEW FILE, ~2,500 lines)
  - [ ] Squad structure:
    ```zig
    pub const Squad = struct {
        units: []u32,         // Entity IDs
        formation: FormationType,
        rally_point: Vec3,
        leader_id: u32,
        state: SquadState,
    };
    ```
  - [ ] Squad formation movement
  - [ ] Squad target assignment (divide targets among units)
  - [ ] Squad member roles:
    - Tank: Front line
    - Scout: Lead formation, reveal enemies
    - Support: Back line, heal/repair
  - [ ] Squad tactics:
    - Pincer (surround enemy)
    - Ambush (hide then attack)
    - Retreat (all units flee together)
  - [ ] Squad reinforcement (add new units to squad)
  - [ ] Squad retreat coordination (no unit left behind)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/ai/aigroup.cpp`

**Test:** Squad of 10 units surrounds enemy base in pincer formation

---

- [ ] **Strategic AI** (`src/ai/strategic_ai.zig` - NEW FILE, ~6,000 lines) **VERY COMPLEX**
  - [ ] Base building AI:
    - Build order (power plant → barracks → war factory → ...)
    - Placement planning (don't block expansion)
    - Defenses (turrets at entrances)
  - [ ] Resource management AI:
    - Build supply structures when low money
    - Build power plants when low power
    - Expand to new supply docks
  - [ ] Tech progression AI:
    - Research upgrades when affordable
    - Unlock advanced units
    - Balance economy vs military
  - [ ] Army composition AI:
    - Mixed army (infantry + tanks + aircraft)
    - Counter enemy army (build anti-air if enemy has planes)
    - Adjust composition over time
  - [ ] Attack wave coordination:
    - Build attack force (10-20 units)
    - Wait for full army before attacking
    - Send in waves every 5-10 minutes
  - [ ] Defense positioning:
    - Garrison buildings near enemy
    - Position tanks at chokepoints
    - Repair damaged defenses
  - [ ] Scouting patterns:
    - Send scout unit to enemy base
    - Reveal map systematically
    - Track enemy army movement
  - [ ] Expansion AI:
    - Identify expansion locations
    - Secure expansion with defenses
    - Defend expansion from attacks

**Reference Files:**
- `~/Code/Thyme/src/game/logic/ai/aiplayer.cpp`
- `~/Code/Thyme/src/game/logic/ai/aistrategic.cpp`

**This is MONTHS of work. Start simple, iterate.**

**Test:** AI builds base, trains army, attacks player every 5 minutes

---

## Phase 4: Production & Economy (65% → 75%)
**Priority:** MEDIUM
**Estimated Time:** 3-4 months full-time
**Code:** ~15,000 lines

### 4.1 Building System

**Current State:**
- `src/engine/production.zig` - Basic queue structure (5% complete)
- Not connected to game, no placement, no construction

**Target State:**
- Full building placement, construction, repair, selling

**Tasks:**

- [ ] **Building Placement** (`src/engine/build_placement.zig` - NEW FILE, ~2,000 lines)
  - [ ] Build grid system:
    - Divide map into 10x10 meter cells
    - Mark cells as buildable/non-buildable
    - Update grid when buildings placed/destroyed
  - [ ] Placement validation:
    ```zig
    pub fn canPlaceBuilding(
        building_type: *BuildingTemplate,
        position: Vec3,
        team: u8,
    ) bool {
        // Check terrain (flat enough?)
        if (!isTerrainFlat(position, building_type.size)) return false;

        // Check existing buildings (overlapping?)
        if (isCellOccupied(position, building_type.size)) return false;

        // Check proximity requirements
        if (building_type.requires_power) {
            if (!isNearPowerSource(position, team)) return false;
        }

        // Check exclusion zones (too close to enemy?)
        if (isNearEnemyBase(position, team)) return false;

        return true;
    }
    ```
  - [ ] Ghost building preview (transparent building model before placement)
  - [ ] Rotation control (R key rotates 90°)
  - [ ] Foundation checking (red if invalid, green if valid)
  - [ ] Placement sounds (click to place)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/update/productionupdate.cpp`

**Test:** Place barracks, see green foundation, click to build

---

- [ ] **Construction System** (`src/engine/construction.zig` - NEW FILE, ~2,500 lines)
  - [ ] Construction worker assignment:
    - Dozer/Worker moves to build site
    - Dozer starts construction
    - Multiple dozers speed up construction (+50% per extra dozer)
  - [ ] Construction progress visualization:
    - Building model fades in from transparent to opaque
    - Percentage text above building
    - Construction particles (sparks, dust)
  - [ ] Construction time calculations:
    ```zig
    pub fn getConstructionTime(
        building: *BuildingTemplate,
        num_workers: u8,
    ) f32 {
        const base_time = building.build_time;
        const speed_bonus = 1.0 + (num_workers - 1) * 0.5;  // +50% per extra worker
        return base_time / speed_bonus;
    }
    ```
  - [ ] Construction cost deduction (pay when placing foundation)
  - [ ] Cancel construction refund (get 80% money back)
  - [ ] Construction pause/resume
  - [ ] Construction sound effects

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/update/doupdate.cpp` (construction logic)

**Test:** Dozer builds barracks in 20 seconds, 2 dozers in 13 seconds

---

- [ ] **Building Repair** (add to `construction.zig`)
  - [ ] Repair logic:
    - Worker moves to damaged building
    - Pays repair cost (50% of damage in $)
    - Restores health over time
  - [ ] Auto-repair toggle (buildings auto-repair when damaged)
  - [ ] Repair priority (critical buildings first)

**Test:** Worker repairs damaged power plant from 50% to 100%

---

- [ ] **Building Selling** (add to `construction.zig`)
  - [ ] Sell animation (building collapses)
  - [ ] Refund (50% of build cost)
  - [ ] Instant demolition
  - [ ] Clear build grid cells

**Test:** Sell barracks, get $500 refund

---

- [ ] **Building States** (add to `src/engine/entity.zig`)
  - [ ] States:
    ```zig
    pub const BuildingState = enum {
        UNDER_CONSTRUCTION,  // Being built
        ACTIVE,              // Fully operational
        DAMAGED,             // Health < 75%
        CRITICALLY_DAMAGED,  // Health < 25%
        ON_FIRE,             // Health < 10%
        UNPOWERED,           // No electricity
        GARRISONED,          // Contains units
        SELLING,             // Being demolished
        DESTROYED,           // Rubble
    };
    ```
  - [ ] State effects:
    - ON_FIRE: Spawn fire particles, lose health slowly
    - UNPOWERED: Disabled, can't produce units
    - DAMAGED: Reduced efficiency

**Test:** Power plant on fire smokes and loses health

---

### 4.2 Production System

**Current State:**
- `src/engine/production.zig` - Empty structure (5% complete)

**Target State:**
- Full production queue with prerequisites, timers, bonuses

**Tasks:**

- [ ] **Production Queue** (REWRITE `src/engine/production.zig`, ~3,500 lines)
  - [ ] Queue structure:
    ```zig
    pub const ProductionQueue = struct {
        building_id: u32,
        queue: ArrayList(ProductionItem),
        current_item: ?*ProductionItem,
        paused: bool,
    };

    pub const ProductionItem = struct {
        template: *UnitTemplate,
        progress: f32,        // 0.0 to 1.0
        build_time: f32,
        cost: u32,
        rally_point: Vec3,
    };
    ```
  - [ ] Queue management:
    - Add to queue (click unit button)
    - Remove from queue (right-click)
    - Reorder queue (drag and drop)
    - Infinite queue (hold Shift while clicking)
  - [ ] Queue UI display (show 5 queued units)
  - [ ] Production priority (barracks before war factory)
  - [ ] Pause/resume production
  - [ ] Cancel refund (100% refund if not started, 50% if in progress)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/production.cpp`

**Test:** Queue 5 tanks, see progress bar for first tank

---

- [ ] **Production Logic** (add to `production.zig`)
  - [ ] Production update:
    ```zig
    pub fn updateProduction(queue: *ProductionQueue, dt: f32) void {
        if (queue.paused) return;
        if (queue.current_item == null) {
            // Start next item in queue
            if (queue.queue.items.len > 0) {
                queue.current_item = &queue.queue.items[0];
            } else {
                return;
            }
        }

        // Update progress
        const item = queue.current_item.?;
        item.progress += dt / item.build_time;

        // Spawn unit when complete
        if (item.progress >= 1.0) {
            spawnUnit(item.template, item.rally_point, queue.building_id);
            _ = queue.queue.orderedRemove(0);  // Remove from queue
            queue.current_item = null;
        }
    }
    ```
  - [ ] Unit/building prerequisites:
    - Can't build Paladin tank without Strategy Center
    - Can't build Airfield without Barracks
    - Gray out buttons if prerequisites not met
  - [ ] Tech tree requirements
  - [ ] Cost validation (can't build if not enough money)
  - [ ] Production timers (each unit has build time)
  - [ ] Veterancy for produced units:
    - Buildings with veterancy produce veteran units
    - Heroic War Factory produces Elite tanks
  - [ ] Production bonuses:
    - Upgrades reduce build time (-25%)
    - General powers reduce cost (-20%)

**Reference Files:**
- `~/Code/Thyme/src/game/common/ini/object/` (unit prerequisites)

**Test:** Can't build Comanche without Airfield

---

- [ ] **Rally Points** (add to `production.zig`)
  - [ ] Set rally point (right-click on map while building selected)
  - [ ] Rally point visual (flag on ground)
  - [ ] Units auto-move to rally point when spawned
  - [ ] Rally on unit (newly built units guard that unit)

**Test:** Set barracks rally point, infantry spawn and walk there

---

- [ ] **Unit Spawning** (`src/engine/spawn_manager.zig` - NEW FILE, ~1,500 lines)
  - [ ] Exit point calculation:
    - Find building exit door position
    - Offset based on building rotation
  - [ ] Spawn collision avoidance:
    - Check if exit blocked
    - Find nearby free position
  - [ ] Formation spawning (multiple units spawn in formation)
  - [ ] Auto-rally to waypoint
  - [ ] Aircraft runway spawning (planes take off from airfield)
  - [ ] Naval spawning from docks (ships spawn in water)

**Test:** Tank spawns from War Factory exit, drives to rally point

---

### 4.3 Resource System

**Current State:**
- `src/engine/resource.zig` + `resource_manager.zig` - Basic supplies/power (25% complete)

**Target State:**
- Full resource gathering, income, power consumption

**Tasks:**

- [ ] **Resource Types** (update `resource.zig`)
  - [ ] Supplies (money):
    - Starting amount: $5000 (can configure in INI)
    - Max amount: $999,999
  - [ ] Power (electricity):
    - Power production (from power plants)
    - Power consumption (from buildings)
    - Low power penalty (buildings disabled at 50% efficiency)
  - [ ] Resource crates (pickup on map for instant money)
  - [ ] Salvage (gain money from destroyed enemy units)

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/supply.cpp`

**Test:** Start with $5000, build power plant for +10 power

---

- [ ] **Resource Gathering** (`src/engine/resource_gathering.zig` - NEW FILE, ~2,500 lines)
  - [ ] Supply Docks:
    - Generate income every 1 second
    - Base income: $10/sec
    - Upgrade bonus: +$5/sec
  - [ ] Supply Trucks (China Hackers, GLA Workers):
    - Periodic income: +$20 every 10 seconds
  - [ ] Black Market income (GLA):
    - Passive income based on number of markets
    - 1 market: +$5/sec
    - 2 markets: +$8/sec each (+$16/sec total)
    - 3 markets: +$10/sec each (+$30/sec total)
  - [ ] General's powers income bonuses:
    - Cash Hack (China Hacker General): +$1000 instant
    - Supply Drop Upgrade: +20% income
  - [ ] Salvage system:
    - Destroyed enemy units drop money crates
    - Amount = 25% of unit cost
    - Crates despawn after 30 seconds

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/update/supplyupdate.cpp`

**Test:** Supply Dock generates $10/sec income

---

- [ ] **Resource Management UI** (update `src/engine/ui.zig`)
  - [ ] Top bar display:
    - Supplies: $5,230 (+$45/sec)
    - Power: 12 / 20 (60% used)
  - [ ] Income breakdown tooltip:
    - Supply Docks: +$30/sec
    - Black Market: +$15/sec
    - Total: +$45/sec
  - [ ] Low power warning (red text if < 0 power)
  - [ ] Resource alerts:
    - "Low Power" voice line
    - "Supplies Running Low" at $500

**Test:** Hover over money, see income tooltip

---

- [ ] **Power System** (add to `resource.zig`)
  - [ ] Power production:
    - Power Plant: +10 power
    - Nuclear Reactor: +15 power
  - [ ] Power consumption:
    - Barracks: -2 power
    - War Factory: -3 power
    - Airfield: -4 power
    - Base Defense: -3 power
  - [ ] Low power effects:
    - Power < 0: All buildings at 50% efficiency
    - Production takes 2x time
    - Defenses fire at 0.5x rate
  - [ ] Power priority (critical buildings get power first)

**Test:** Destroy power plant, buildings go offline

---

## Phase 5: Special Abilities & Powers (75% → 82%)
**Priority:** MEDIUM
**Estimated Time:** 4-5 months full-time
**Code:** ~15,000 lines

### 5.1 General Powers

**Current State:**
- Not implemented (0% complete)

**Target State:**
- All 27 general powers from all 9 generals

**Tasks:**

- [ ] **Power Point System** (`src/engine/general_powers.zig` - NEW FILE, ~5,000 lines)
  - [ ] Power point accumulation:
    - Gain 1 point every 60 seconds
    - Gain points for destroying enemies (1 point per $1000 destroyed)
  - [ ] Power rank system:
    - Rank 1 (0 points): Level 1 power unlocked
    - Rank 3 (5 points): Level 3 power unlocked
    - Rank 5 (15 points): Level 5 superweapon unlocked
  - [ ] Power activation:
    - Click power button
    - Click target location on map
    - Power triggers
    - Cooldown starts
  - [ ] Power UI:
    - Power bar (shows points)
    - Power buttons (gray if not enough points)
    - Cooldown timers

**Reference Files:**
- `~/Code/Thyme/src/game/logic/specialpower/specialpower.cpp`

**Test:** Gain 5 power points, unlock Level 3 power

---

- [ ] **USA General Powers** (add to `general_powers.zig`)
  - [ ] **Level 1: Emergency Repair** ($500 cost)
    - Repairs all friendly vehicles in 100m radius
    - Heals 50% health instantly
    - Cooldown: 120 seconds
  - [ ] **Level 1: A-10 Strike** ($800 cost)
    - A-10 plane flies over target area
    - Fires Gatling gun in line
    - Deals 100 damage per hit to vehicles
    - Cooldown: 180 seconds
  - [ ] **Level 3: Pathfinder Drop** ($1200 cost)
    - 4 Pathfinders paradrop at location
    - Elite rank
    - Cooldown: 240 seconds
  - [ ] **Level 3: Paratroopers** ($1000 cost)
    - 8 Rangers paradrop at location
    - Veteran rank
    - Cooldown: 180 seconds
  - [ ] **Level 5: Fuel Air Bomb** ($2500 cost)
    - Massive explosion at target
    - 500 damage in 100m radius
    - Destroys infantry instantly
    - Cooldown: 360 seconds

**Superweapon General (USA):**
  - [ ] **Level 1: Particle Cannon**
    - Laser beam from sky
    - 1000 damage per second for 5 seconds
    - Player controls beam direction
    - Cooldown: 600 seconds

**Laser General (USA):**
  - [ ] **Level 1: Laser Turrets**
    - Upgrades Patriot missiles to lasers
    - Infinite ammo, faster firing
    - One-time unlock

**Test:** Call A-10 strike, see plane strafe target

---

- [ ] **China General Powers** (add to `general_powers.zig`)
  - [ ] **Level 1: Artillery Barrage** ($1000 cost)
    - 10 artillery shells rain down
    - 150 damage each in 20m radius
    - Cooldown: 180 seconds
  - [ ] **Level 3: MiG Strike** ($1500 cost)
    - 2 MiGs drop napalm bombs
    - 300 damage each
    - Fire effect lasts 10 seconds
    - Cooldown: 240 seconds
  - [ ] **Level 3: Carpet Bomb** ($2000 cost)
    - B-52 drops 20 bombs in line
    - 200 damage each
    - Destroys buildings
    - Cooldown: 300 seconds
  - [ ] **Level 5: Nuclear Missile** ($5000 cost)
    - Nuclear warhead
    - 2000 damage in 200m radius
    - Radiation lingers (10 damage/sec for 60 sec)
    - Cooldown: 600 seconds

**Nuke General (China):**
  - [ ] **Level 1: Tactical Nuke MiGs**
    - MiGs drop mini-nukes instead of napalm
    - 500 damage + radiation
    - Cooldown: 240 seconds

**Hacker General (China):**
  - [ ] **Level 1: Cash Hack** ($0 cost!)
    - Gain $1000 instantly
    - Cooldown: 120 seconds
  - [ ] **Level 3: EMP Blast**
    - Disables all vehicles in 100m radius
    - Lasts 30 seconds
    - Cooldown: 300 seconds

**Test:** Launch nuke, see mushroom cloud and radiation

---

- [ ] **GLA General Powers** (add to `general_powers.zig`)
  - [ ] **Level 1: Sneak Attack** ($800 cost)
    - 4 Rebels spawn from tunnel
    - Veteran rank
    - Cooldown: 180 seconds
  - [ ] **Level 1: Anthrax Bomb** ($1000 cost)
    - Plane drops chemical bomb
    - 50 damage/sec to infantry in 50m radius
    - Lasts 30 seconds
    - Cooldown: 240 seconds
  - [ ] **Level 3: Rebel Ambush** ($1500 cost)
    - 10 Rebels spawn from 3 tunnels
    - Surround enemy
    - Cooldown: 240 seconds
  - [ ] **Level 5: SCUD Storm** ($3000 cost)
    - 9 SCUD missiles rain down
    - 500 damage each in 30m radius
    - Cooldown: 600 seconds

**Demo General (GLA):**
  - [ ] **Level 1: Demo Traps**
    - Place 5 explosive traps on ground
    - Explode when enemies walk over
    - 300 damage each
    - Cooldown: 180 seconds

**Toxin General (GLA):**
  - [ ] **Level 1: Anthrax Gamma**
    - Upgrades all toxins to Gamma (stronger)
    - 2x damage
    - One-time unlock

**Test:** SCUD Storm rains missiles on enemy base

---

- [ ] **Power Effects** (`src/engine/power_effects.zig` - NEW FILE, ~3,000 lines)
  - [ ] Effect types:
    - Airstrike (spawn plane, path to target, drop ordnance)
    - Paradrop (spawn parachute units)
    - Area-of-effect damage (explosion, artillery)
    - Buff (repair, speed boost)
    - Debuff (EMP, toxin)
  - [ ] Visual effects:
    - Airstrike plane model
    - Parachute models
    - Explosion particles (huge for nukes)
    - Laser beam (particle cannon)
  - [ ] Audio effects:
    - Plane engine sounds
    - Explosion sounds
    - Radiation geiger counter
  - [ ] Camera shake on big explosions

**Test:** Particle Cannon laser beam visible from space

---

### 5.2 Unit Abilities

**Current State:**
- Not implemented (0% complete)

**Target State:**
- All unit-specific abilities working

**Tasks:**

- [ ] **Active Abilities** (`src/engine/abilities.zig` - NEW FILE, ~4,000 lines)
  - [ ] Ability system:
    ```zig
    pub const Ability = struct {
        name: []const u8,
        cooldown: f32,
        range: f32,
        cost: u32,           // Some abilities cost money
        requires_target: bool,
        effect: AbilityEffect,
    };

    pub const AbilityEffect = union(enum) {
        Damage: struct { damage: f32, radius: f32 },
        Heal: struct { heal: f32, radius: f32 },
        Capture: struct { capture_time: f32 },
        Disable: struct { disable_time: f32 },
        Snipe: struct { instant_kill: bool },
        Detonate: struct { explosion_damage: f32 },
    };
    ```
  - [ ] Ability activation:
    - Click ability button
    - Click target (if requires target)
    - Ability fires
    - Cooldown starts
  - [ ] Ability UI:
    - Ability buttons in command panel
    - Cooldown timers
    - Ability icons

**USA Abilities:**
  - [ ] **Ranger Flashbang**
    - Stuns all infantry in 20m radius
    - Lasts 5 seconds
    - Cooldown: 30 seconds
  - [ ] **Pathfinder Laser Designator**
    - Calls laser-guided missile
    - 500 damage to target building
    - Cooldown: 60 seconds
  - [ ] **Colonel Burton Timed Demo Charges**
    - Places explosive on building
    - Explodes after 10 seconds
    - 1000 damage
    - Cooldown: 45 seconds
  - [ ] **Colonel Burton Knife Attack**
    - Instant-kill infantry in melee
    - Cooldown: 5 seconds

**China Abilities:**
  - [ ] **Hacker Disable Building**
    - Shuts down target building
    - Lasts 30 seconds
    - Cooldown: 60 seconds
  - [ ] **Black Lotus Capture Building**
    - Takes over enemy building
    - Capture time: 15 seconds
    - Cooldown: 120 seconds
  - [ ] **Black Lotus Disable Vehicle**
    - Steals vehicle
    - Permanent control
    - Cooldown: 60 seconds

**GLA Abilities:**
  - [ ] **Jarmen Kell Snipe Driver**
    - Kills vehicle driver
    - Vehicle becomes neutral (can be captured)
    - Cooldown: 10 seconds
  - [ ] **Tank Hunter TNT Attack**
    - Throws TNT at building
    - 300 damage
    - Cooldown: 20 seconds
  - [ ] **Terrorist Bomb Detonation**
    - Suicide explosion
    - 500 damage in 30m radius
    - Kills terrorist

**Reference Files:**
- `~/Code/Thyme/src/game/logic/object/specialability.cpp`

**Test:** Ranger flashbang stuns 5 enemy infantry

---

- [ ] **Passive Abilities** (add to `abilities.zig`)
  - [ ] **Stealth Detection**
    - Units can see stealth units in range
    - Burton, Pathfinder, Lotus can see stealth
  - [ ] **Self-Healing**
    - Heroic units heal 1% HP/sec
  - [ ] **Regeneration**
    - GLA units heal when garrisoned
  - [ ] **Inspire**
    - General unit boosts nearby units (+10% damage)
  - [ ] **Booby Trap**
    - Unit explodes on death
    - Terrorist: 100 damage
    - Bomb Truck: 500 damage
  - [ ] **Salvage Crates**
    - Unit drops money crate on death
  - [ ] **Cargo Transport**
    - Chinook, Helix can carry units
  - [ ] **Amphibious Movement**
    - Hovercraft can cross water

**Test:** Heroic tank auto-heals to full after battle

---

- [ ] **Upgrades** (`src/engine/upgrades.zig` - NEW FILE, ~3,000 lines)
  - [ ] Upgrade system:
    ```zig
    pub const Upgrade = struct {
        name: []const u8,
        cost: u32,
        research_time: f32,
        effects: []UpgradeEffect,
    };

    pub const UpgradeEffect = union(enum) {
        WeaponDamage: struct { multiplier: f32 },
        Armor: struct { bonus: f32 },
        Speed: struct { multiplier: f32 },
        VisionRange: struct { bonus: f32 },
        UnlockUnit: struct { unit_name: []const u8 },
    };
    ```
  - [ ] Global upgrades (affect all units):
    - Composite Armor (USA): +25% armor to all vehicles
    - Uranium Shells (USA): +25% damage to tank cannons
    - Black Napalm (China): +25% damage to flame weapons
    - Anthrax Gamma (GLA): 2x toxin damage
  - [ ] Unit-specific upgrades:
    - Drone Armor (China tanks): +50 HP
    - Horde Bonus (GLA): +25% damage when in groups
  - [ ] Upgrade UI (research buttons in buildings)

**Reference Files:**
- `~/Code/Thyme/src/game/common/ini/upgrade.ini`

**Test:** Research Composite Armor, tanks gain +25% armor

---

## Phase 6: Audio System (82% → 87%)
**Priority:** LOW (playable without audio, but immersion matters)
**Estimated Time:** 2-3 months full-time
**Code:** ~8,000 lines

### 6.1 Sound Effects

**Current State:**
- Not implemented (0% complete)

**Target State:**
- Full 3D positional audio with OpenAL

**Tasks:**

- [ ] **OpenAL Integration** (`src/audio/audio_engine.zig` - NEW FILE, ~3,000 lines)
  - [ ] Use existing Home FFI bindings (`~/Code/home/packages/graphics/src/openal.zig`)
  - [ ] Audio device initialization:
    ```zig
    const device = alcOpenDevice(null);
    const context = alcCreateContext(device, null);
    alcMakeContextCurrent(context);
    ```
  - [ ] Buffer management:
    - Load audio files (WAV format from assets)
    - Create OpenAL buffers
    - Pool buffers (reuse instead of reloading)
  - [ ] Source management:
    - Create audio sources (one per sound)
    - Set source position (3D audio)
    - Set source velocity (Doppler effect)
    - Set source gain (volume)
  - [ ] Listener (camera):
    - Update listener position to camera position
    - Update listener orientation to camera facing
  - [ ] 3D audio positioning:
    - Sound volume fades with distance
    - Sound pans left/right based on position
    - Doppler effect (pitch changes with velocity)

**Reference Files:**
- `~/Code/Thyme/src/game/client/audiomanager.cpp`
- Home: `~/Code/home/packages/graphics/src/openal.zig`

**Test:** Tank engine sound gets quieter as camera moves away

---

- [ ] **Sound Categories** (`src/audio/sound_manager.zig` - NEW FILE, ~2,000 lines)
  - [ ] Sound types:
    ```zig
    pub const SoundCategory = enum {
        UNIT_VOICE,      // "Yes sir!" "Move out!"
        WEAPON,          // Gunfire, explosions
        BUILDING,        // Construction, destruction
        AMBIENT,         // Wind, birds, environmental
        UI,              // Button clicks, notifications
        ABILITY,         // Powers, special abilities
        MUSIC,           // Background music (separate system)
    };
    ```
  - [ ] Sound loading:
    - Load from `assets/audio/sounds/` folder
    - Sounds mapped to events in `assets/data/AudioEvents.ini`
  - [ ] Sound playback:
    ```zig
    pub fn playSound(
        sound_name: []const u8,
        position: Vec3,
        category: SoundCategory,
    ) void {
        const buffer = getSoundBuffer(sound_name);
        const source = getAvailableSource();

        alSourcei(source, AL_BUFFER, buffer);
        alSource3f(source, AL_POSITION, position.x, position.y, position.z);
        alSourcef(source, AL_GAIN, getCategoryVolume(category));
        alSourcePlay(source);
    }
    ```
  - [ ] Sound priorities:
    - Important sounds (voice, combat) interrupt less important sounds
    - Max 32 simultaneous sounds (hardware limit)

**Sound Files from Assets:**
- Unit voices: `GSTHeroicCrusaderTankSelectMS.wav`
- Weapon sounds: `GWECrussdrMoveMS.wav`
- Explosions: `GEXTankD.wav`

**Reference Files:**
- `~/Code/Thyme/src/game/common/ini/audioevents.ini`

**Test:** Click Crusader tank, hear "Ready!" voice

---

- [ ] **Audio Management** (add to `sound_manager.zig`)
  - [ ] Sound pooling:
    - Preallocate 32 audio sources
    - Reuse sources instead of creating new
  - [ ] Priority system:
    - Voice > Weapon > Ambient > UI
    - Stop lowest priority sound if all 32 sources used
  - [ ] Volume controls:
    - Master volume (0-100%)
    - SFX volume (0-100%)
    - Music volume (0-100%)
    - Voice volume (0-100%)
  - [ ] Audio ducking:
    - Lower music volume when voice plays
    - Restore music volume when voice ends
  - [ ] Simultaneous sound limits:
    - Max 8 of same sound at once (no spam)
    - Cooldown between identical sounds (0.1 sec)

**Test:** 100 tanks firing, only hear 32 sounds

---

### 6.2 Music & Voice

**Tasks:**

- [ ] **Music System** (`src/audio/music_system.zig` - NEW FILE, ~1,500 lines)
  - [ ] Background music playback:
    - Stream music files (don't load entire file)
    - Use OpenAL streaming buffers
  - [ ] Music tracks:
    - Menu music: `MenuTheme.mp3`
    - USA music: `USATheme1.mp3`, `USATheme2.mp3`
    - China music: `ChinaTheme1.mp3`, `ChinaTheme2.mp3`
    - GLA music: `GLATheme1.mp3`, `GLATheme2.mp3`
  - [ ] Dynamic music:
    - Calm music during peace
    - Combat music during battles
    - Victory music when winning
    - Defeat music when losing
  - [ ] Music crossfading (smooth transition between tracks)
  - [ ] Music looping (seamless loop)

**Music Files from Assets:**
- `assets/audio/music/` folder (10-15 tracks)

**Test:** Hear USA theme when playing USA faction

---

- [ ] **Voice Acting** (`src/audio/voice_manager.zig` - NEW FILE, ~1,200 lines)
  - [ ] Unit response voices:
    - Selection: "Yes?" "Waiting"
    - Move: "Moving out" "On our way"
    - Attack: "Engaging" "Firing"
    - Death: "Ahhh!" screams
  - [ ] Mission briefing voices (campaign only)
  - [ ] General voices:
    - Taunts: "Your base is under attack!"
    - Notifications: "Construction complete"
  - [ ] EVA announcements:
    - "Building captured"
    - "Unit lost"
    - "Low power"
  - [ ] Faction-specific accents:
    - USA: American accent
    - China: Chinese accent
    - GLA: Middle Eastern accent

**Voice Files from Assets:**
- `assets/audio/voices/` folder (600+ voice lines)
- Defined in `assets/data/Eva.ini`

**Reference Files:**
- `~/Code/Thyme/src/game/common/ini/eva.ini`

**Test:** Select tank, hear "Yes, sir!" in appropriate accent

---

## Phase 7: Multiplayer & Networking (87% → 90%)
**Priority:** MEDIUM
**Estimated Time:** 4-5 months full-time
**Code:** ~15,000 lines

### 7.1 Networking

**Current State:**
- `src/game/multiplayer.zig` - Code exists but not integrated (0% complete)

**Target State:**
- Full multiplayer with lockstep networking

**Tasks:**

- [ ] **Network Layer** (update `src/game/multiplayer.zig`, ~5,000 lines)
  - [ ] TCP/UDP sockets (use Zig std.net)
  - [ ] Packet structure:
    ```zig
    pub const NetworkPacket = struct {
        packet_type: PacketType,
        turn_number: u32,
        player_id: u8,
        data: []u8,
        checksum: u32,
    };

    pub const PacketType = enum {
        COMMAND,        // Player command (move, attack, etc.)
        CHAT,           // Chat message
        SYNC,           // Synchronization check
        PING,           // Latency check
        JOIN,           // Join lobby
        START,          // Start game
    };
    ```
  - [ ] Packet serialization (convert structs to bytes)
  - [ ] Packet compression (zlib, reduce bandwidth)
  - [ ] Encryption (prevent cheating, AES-256)
  - [ ] NAT traversal (hole punching for peer-to-peer)
  - [ ] Connection management:
    - Connect to server/peer
    - Disconnect handling
    - Reconnection after disconnect
  - [ ] Lag compensation:
    - Ping tracking
    - Command buffering
    - Prediction (guess what will happen)

**Reference Files:**
- Generals: `src/game/multiplayer.zig` (partial implementation)
- `~/Code/Thyme/src/game/network/`

**Test:** Two clients connect to server

---

- [ ] **Lockstep Networking** (`src/network/lockstep.zig` - NEW FILE, ~3,000 lines)
  - [ ] Lockstep algorithm:
    - All clients run same simulation
    - All clients execute commands on same turn
    - Game advances one turn only when all clients ready
  - [ ] Turn system:
    ```zig
    pub const Turn = struct {
        turn_number: u32,
        commands: ArrayList(Command),
        checksums: [8]u32,  // One per player
    };

    pub fn advanceTurn(game: *Game, turn: *Turn) void {
        // Execute all commands for this turn
        for (turn.commands.items) |cmd| {
            executeCommand(game, cmd);
        }

        // Update simulation
        game.update(TURN_TIME);

        // Calculate checksum
        const checksum = calculateGameChecksum(game);

        // Compare checksums across all players
        if (!checksumsMatch(turn.checksums)) {
            handleDesync();  // Out of sync!
        }
    }
    ```
  - [ ] Deterministic simulation:
    - Same input → same output (always!)
    - No randomness (use seeded RNG)
    - No floating-point inconsistencies (use fixed-point)
  - [ ] Command buffering:
    - Buffer commands for next turn
    - Send buffered commands to all clients
    - Wait for all clients before advancing
  - [ ] Out-of-sync detection:
    - Compare game state checksums
    - If mismatch, game is out of sync
    - Options: Pause and resync, or kick desynced player
  - [ ] Reconnection support:
    - Send full game state to reconnecting player
    - Resume from current turn

**This is VERY COMPLEX. Lockstep is hard.**

**Reference Files:**
- `~/Code/Thyme/src/game/network/replay.cpp` (similar to lockstep)

**Test:** Two players play game, stay in sync

---

- [ ] **Lobby System** (`src/network/lobby.zig` - NEW FILE, ~2,500 lines)
  - [ ] Server browser:
    - List available games
    - Show host name, map, players
    - Filter by map, mod, etc.
  - [ ] Room creation:
    ```zig
    pub const LobbyRoom = struct {
        host_player_id: u8,
        room_name: []const u8,
        map: []const u8,
        max_players: u8,
        players: [8]Player,
        player_count: u8,
        game_settings: GameSettings,
    };

    pub const GameSettings = struct {
        starting_money: u32,
        starting_power: u32,
        tech_level: u8,
        superweapons_enabled: bool,
        fog_of_war: bool,
    };
    ```
  - [ ] Player slots:
    - Assign players to slots
    - Set team (1-4)
    - Set color (red, blue, green, etc.)
    - Set faction (USA, China, GLA)
  - [ ] Map selection:
    - Show map preview
    - Display map info (size, players)
  - [ ] Game settings:
    - Starting resources
    - Tech level (1-3)
    - Superweapons on/off
  - [ ] Chat system:
    - Send chat messages
    - Display messages in lobby
  - [ ] Ready system:
    - Players mark themselves ready
    - Host starts game when all ready

**Test:** Create lobby, 4 players join, all ready, start game

---

### 7.2 Replay System

**Current State:**
- Not implemented (0% complete)

**Target State:**
- Full replay recording and playback

**Tasks:**

- [ ] **Replay Recording** (`src/engine/replay.zig` - NEW FILE, ~2,500 lines)
  - [ ] Replay structure:
    ```zig
    pub const Replay = struct {
        metadata: ReplayMetadata,
        turns: ArrayList(Turn),
        random_seed: u64,
    };

    pub const ReplayMetadata = struct {
        map: []const u8,
        players: [8]PlayerInfo,
        timestamp: i64,
        version: []const u8,
        game_settings: GameSettings,
    };

    pub const Turn = struct {
        turn_number: u32,
        commands: ArrayList(Command),
    };
    ```
  - [ ] Command recording:
    - Record every player command
    - Store turn number for each command
  - [ ] Random seed recording:
    - Use same random seed for determinism
  - [ ] Metadata (players, map, settings)
  - [ ] Compression (zlib, reduce file size)
  - [ ] File format (.rep):
    - Header (metadata)
    - Turn data (commands)
    - Footer (checksum)

**Test:** Play game, save replay to file

---

- [ ] **Replay Playback** (add to `replay.zig`)
  - [ ] Load replay from file
  - [ ] Recreate game state from metadata
  - [ ] Execute commands turn-by-turn
  - [ ] Time controls:
    - Play (normal speed)
    - Pause (freeze simulation)
    - Fast-forward (2x, 4x, 8x speed)
    - Rewind (restart replay, skip to turn)
  - [ ] Camera free movement (not locked to player)
  - [ ] Fog of war toggle (see all or player perspective)
  - [ ] Player perspective switching (view from any player's POV)
  - [ ] Statistics overlay (APM, resources, units)

**Test:** Watch replay of previous game

---

## Phase 8: Campaign & Missions (90% → 95%)
**Priority:** LOW (multiplayer is more important)
**Estimated Time:** 6-8 months full-time
**Code:** ~20,000 lines

### 8.1 Mission System

**Current State:**
- Not implemented (0% complete)

**Target State:**
- Full campaign with all 21 missions

**Tasks:**

- [ ] **Mission Framework** (`src/campaign/mission_system.zig` - NEW FILE, ~4,000 lines)
  - [ ] Mission structure:
    ```zig
    pub const Mission = struct {
        name: []const u8,
        map: []const u8,
        description: []const u8,
        objectives: ArrayList(Objective),
        scripts: ArrayList(MissionScript),
        initial_units: ArrayList(InitialUnit),
        rewards: MissionRewards,
    };

    pub const Objective = struct {
        id: u32,
        description: []const u8,
        type: ObjectiveType,
        completed: bool,
        failed: bool,
        trigger: Trigger,
    };

    pub const ObjectiveType = enum {
        DESTROY,         // Destroy all enemy buildings
        SURVIVE,         // Survive for X minutes
        CAPTURE,         // Capture target building
        ESCORT,          // Protect unit to destination
        COLLECT,         // Collect resource crates
    };
    ```
  - [ ] Mission loading:
    - Load from `assets/maps/<mission>/mission.ini`
    - Parse objectives
    - Load scripts
  - [ ] Objective tracking:
    - Check objective triggers every frame
    - Mark complete when trigger met
    - Display objective updates
  - [ ] Mission success/failure:
    - Win condition: All objectives complete
    - Lose condition: Any objective failed
  - [ ] Mission progression:
    - Unlock next mission on success
    - Save campaign progress

**Test:** Load USA Mission 1, complete objectives, win mission

---

- [ ] **Campaign Structure** (add to `mission_system.zig`)
  - [ ] **USA Campaign** (7 missions):
    1. Operation Final Justice (Destroy GLA base in Baghdad)
    2. Operation Desperate Union (Defend toxin facility)
    3. Operation Last Call (Destroy GLA airfield)
    4. Operation Desperate Alliance (Escort convoy)
    5. Operation Blistering Trial (Survive nuke attack)
    6. Operation Final Justice (Destroy GLA palace)
    7. Operation Last Call (Final mission)

  - [ ] **China Campaign** (7 missions):
    1. Operation Red Dragon (Defend Hong Kong)
    2. Operation Inferno (Destroy GLA base)
    3. Operation Dark Night (Capture nuclear plant)
    4. Operation Scorched Earth (Destroy GLA)
    5. Operation Red Alliance (Team with USA)
    6. Operation Nuclear Winter (Defend missile)
    7. Operation Final Thunder (Final mission)

  - [ ] **GLA Campaign** (7 missions):
    1. Operation Black Rain (Steal supplies)
    2. Operation Desert Fury (Destroy USA base)
    3. Operation Sabotage (Destroy Chinese dam)
    4. Operation Scorpion (Defend territory)
    5. Operation Final Assault (Attack USA)
    6. Operation Toxin (Spread toxins)
    7. Operation Final Crusade (Final mission)

**This is MONTHS of work to create all mission scripts.**

**Reference Files:**
- `~/Code/Thyme/src/game/logic/scriptengine/`
- Mission maps in `assets/maps/`

**Test:** Complete all 21 missions

---

### 8.2 Scripting System

**Tasks:**

- [ ] **Script Engine** (`src/scripting/script_engine.zig` - NEW FILE, ~3,500 lines)
  - [ ] Script parser (read mission scripts from files)
  - [ ] Script interpreter (execute script commands)
  - [ ] Event system:
    ```zig
    pub const ScriptEvent = enum {
        ON_TIMER,           // Trigger after X seconds
        ON_UNIT_DESTROYED,  // Trigger when unit dies
        ON_AREA_ENTERED,    // Trigger when unit enters area
        ON_BUILDING_BUILT,  // Trigger when building complete
        ON_OBJECTIVE_COMPLETE, // Trigger when objective done
    };
    ```
  - [ ] Condition evaluation:
    ```zig
    pub const Condition = union(enum) {
        Timer: struct { time: f32 },
        UnitDead: struct { unit_id: u32 },
        AreaEntered: struct { area: Rect, team: u8 },
        ObjectiveComplete: struct { objective_id: u32 },
    };
    ```
  - [ ] Action execution:
    ```zig
    pub const Action = union(enum) {
        SpawnUnits: struct { type: []const u8, count: u8, position: Vec3 },
        MoveUnits: struct { unit_ids: []u32, destination: Vec3 },
        AttackTarget: struct { attacker_ids: []u32, target_id: u32 },
        ShowDialog: struct { text: []const u8, speaker: []const u8 },
        SetObjective: struct { objective_id: u32, description: []const u8 },
        WinMission: struct {},
        LoseMission: struct {},
    };
    ```
  - [ ] Timer system (countdown timers, delays)
  - [ ] Variable storage (mission-specific variables)

**Example Mission Script:**
```ini
ScriptGroup MissionStart
  OnTimer 0  ; At mission start
    SpawnUnits "Ranger" 10 at (100, 100, 0)
    ShowDialog "Move to the objective!" speaker "Colonel Burton"
    SetObjective 1 "Capture the GLA base"
  End
End

ScriptGroup ObjectiveComplete
  OnAreaEntered area (500,500,100,100) team 0
    ShowDialog "Objective complete!" speaker "EVA"
    WinMission
  End
End
```

**Reference Files:**
- `~/Code/Thyme/src/game/logic/scriptengine/script.cpp`

**Test:** Run mission script, see units spawn and dialog appear

---

- [ ] **Script Commands** (`src/scripting/commands.zig` - NEW FILE, ~2,500 lines)
  - [ ] Unit commands:
    - SpawnUnits (create units at position)
    - MoveUnits (issue move order)
    - AttackUnits (issue attack order)
    - DestroyUnits (delete units)
  - [ ] Dialog commands:
    - ShowDialog (display message with portrait)
    - HideDialog (close dialog)
  - [ ] Objective commands:
    - SetObjective (create new objective)
    - CompleteObjective (mark objective done)
    - FailObjective (mark objective failed)
  - [ ] Win/Lose commands:
    - WinMission
    - LoseMission
  - [ ] Trigger area commands:
    - CreateTriggerArea (define area on map)
    - RemoveTriggerArea
  - [ ] Camera commands:
    - MoveCamera (pan to position)
    - LockCamera (prevent player control)
    - UnlockCamera

**Test:** Spawn 10 tanks, move them to location via script

---

## Phase 9: Content & Assets (95% → 98%)
**Priority:** CRITICAL (need all units to match original)
**Estimated Time:** 3-4 months full-time
**Data:** ~300 unit definitions, 1000+ models, 2.8GB assets

### 9.1 All Units

**Current State:**
- 5 test units (2% of target)

**Target State:**
- All 300+ units from all factions

**Tasks:**

- [ ] **USA Units** (50+ units)

  **Infantry:**
  - [ ] Ranger (basic soldier, rifle)
  - [ ] Missile Defender (Stinger missiles)
  - [ ] Pathfinder (stealth, laser designator)
  - [ ] Colonel Burton (hero, knife attack, demo charges)

  **Vehicles:**
  - [ ] Humvee (transport, TOW missile upgrade)
  - [ ] Crusader Tank (main battle tank)
  - [ ] Paladin Tank (self-propelled artillery)
  - [ ] Tomahawk Missile (long-range missiles)
  - [ ] Avenger (anti-aircraft)
  - [ ] Ambulance (heals infantry)

  **Aircraft:**
  - [ ] Comanche (gunship helicopter)
  - [ ] Raptor (fighter jet)
  - [ ] Aurora (stealth bomber)
  - [ ] Chinook (transport)

  **Buildings:**
  - [ ] Command Center (main base)
  - [ ] Barracks (trains infantry)
  - [ ] Supply Center (income)
  - [ ] War Factory (builds vehicles)
  - [ ] Airfield (builds aircraft)
  - [ ] Power Plant (electricity)
  - [ ] Strategy Center (upgrades)
  - [ ] Patriot Missile (base defense)
  - [ ] Fire Base (garrisonable bunker)

**Reference Files:**
- `~/Code/Thyme/src/game/common/ini/object/americanunitinfo.ini`

**Test:** Train Ranger from Barracks, builds Crusader from War Factory

---

- [ ] **China Units** (50+ units)

  **Infantry:**
  - [ ] Red Guard (basic soldier, AK-47)
  - [ ] Tank Hunter (RPG anti-tank)
  - [ ] Hacker (disables buildings, generates income)
  - [ ] Black Lotus (hero, captures buildings)

  **Vehicles:**
  - [ ] Battlemaster Tank (main battle tank)
  - [ ] Overlord Tank (heavy tank, Gatling + Cannon)
  - [ ] Gatling Tank (anti-aircraft/infantry)
  - [ ] Nuke Cannon (artillery with nuke shells)
  - [ ] Troop Crawler (mobile barracks)
  - [ ] Dragon Tank (flamethrower)

  **Aircraft:**
  - [ ] MiG (fighter jet, napalm bombs)
  - [ ] Helix (gunship helicopter, troops + upgrades)

  **Buildings:**
  - [ ] Command Center
  - [ ] Barracks
  - [ ] Supply Dock (income)
  - [ ] War Factory
  - [ ] Airfield
  - [ ] Nuclear Reactor (power)
  - [ ] Propaganda Center (upgrades)
  - [ ] Gatling Cannon (base defense)
  - [ ] Bunker (garrisonable)

**Reference Files:**
- `~/Code/Thyme/src/game/common/ini/object/chinaunitinfo.ini`

**Test:** Build Overlord tank, see Gatling gun spin up

---

- [ ] **GLA Units** (50+ units)

  **Infantry:**
  - [ ] Rebel (basic soldier, AK-47)
  - [ ] RPG Trooper (anti-tank/aircraft)
  - [ ] Terrorist (suicide bomber)
  - [ ] Jarmen Kell (hero, snipes vehicle drivers)

  **Vehicles:**
  - [ ] Technical (truck with gun)
  - [ ] Scorpion Tank (light tank, stealth)
  - [ ] Marauder Tank (medium tank)
  - [ ] SCUD Launcher (long-range missiles)
  - [ ] Rocket Buggy (anti-aircraft)
  - [ ] Bomb Truck (suicide vehicle, massive explosion)

  **Buildings:**
  - [ ] Command Center (Palace)
  - [ ] Barracks
  - [ ] Supply Stash (income)
  - [ ] Arms Dealer (builds vehicles)
  - [ ] Black Market (upgrades)
  - [ ] SCUD Storm (superweapon)
  - [ ] Stinger Site (base defense)
  - [ ] Tunnel Network (underground transport)

**Reference Files:**
- `~/Code/Thyme/src/game/common/ini/object/glaunitinfo.ini`

**Test:** Terrorist suicide bombs tank

---

- [ ] **Unit Stats for All Units**

  For EACH of the 150+ units, define in INI files:
  - [ ] Health (how much damage before death)
  - [ ] Armor type (INFANTRY, VEHICLE, etc.)
  - [ ] Weapon (reference to Weapon.ini)
  - [ ] Movement speed
  - [ ] Turn rate
  - [ ] Build cost
  - [ ] Build time
  - [ ] Prerequisites (what buildings required)
  - [ ] Vision range
  - [ ] Stealth (yes/no)
  - [ ] Special abilities

**Files to Create:**
- `assets/data/units/usa/*.ini` (50 files)
- `assets/data/units/china/*.ini` (50 files)
- `assets/data/units/gla/*.ini` (50 files)

**This is tedious but necessary data entry work.**

**Reference Files:**
- All unit INI files in `~/Code/Thyme/src/game/common/ini/object/`
- Can copy/paste from original game assets

**Test:** All 150+ units have correct stats

---

### 9.2 Assets - Models, Textures, Sounds

**Current State:**
- Assets exist in `~/Code/generals/assets` (1.1GB)
- Not all loaded/rendered yet

**Target State:**
- All assets loaded and working in-game

**Tasks:**

- [ ] **3D Models (W3D format)**

  **Source:** Original game assets at `~/Code/generals/assets/`

  **Tasks:**
  - [ ] Verify all W3D models exist:
    - Unit models (150+ files)
    - Building models (80+ files)
    - Terrain props (rocks, trees, etc.)
    - Particle effects (explosion sprites, etc.)
  - [ ] Test load all models with W3D loader
  - [ ] Verify animations work (walk, attack, death)
  - [ ] Verify LOD models (multiple detail levels)

**Estimated:** 1000+ W3D model files

**Test:** Load all unit models, render on screen

---

- [ ] **Textures**

  **Formats:** TGA, DDS

  **Categories:**
  - [ ] Unit textures (diffuse, normal, specular)
    - Each unit has 3-5 textures
    - Example: `AVCrusaderTank_D.tga` (diffuse), `AVCrusaderTank_N.tga` (normal)
  - [ ] Building textures
  - [ ] Terrain textures (grass, sand, cliff, water, road)
  - [ ] UI textures (buttons, icons, backgrounds)
  - [ ] Effect textures (explosion sprites, particle textures)

**Tasks:**
  - [ ] Verify all textures exist in `assets/textures/`
  - [ ] Convert any missing textures from original game
  - [ ] Load textures into renderer
  - [ ] Apply textures to models

**Estimated:** 2000+ texture files

**Test:** All units have correct textures

---

- [ ] **Sounds**

  **Formats:** WAV, MP3

  **Categories:**
  - [ ] Weapon sounds (gunfire, explosions, missiles)
  - [ ] Voice lines (unit responses, EVA announcements)
  - [ ] Music tracks (menu, USA, China, GLA)
  - [ ] UI sounds (button clicks, notifications)
  - [ ] Ambient sounds (wind, birds, environmental)

**Tasks:**
  - [ ] Verify all sounds exist in `assets/audio/`
  - [ ] Load sounds into OpenAL
  - [ ] Map sounds to events in AudioEvents.ini
  - [ ] Test playback

**Estimated:** 5000+ audio files

**Test:** Hear tank engine, gunfire, explosion sounds

---

## Phase 10: Polish & Optimization (98% → 100%)
**Priority:** MEDIUM (make it ship-ready)
**Estimated Time:** 2-3 months full-time
**Code:** ~10,000 lines tweaks/optimizations

### 10.1 Performance Optimization

**Target:** 60 FPS on 10-year-old hardware

**Tasks:**

- [ ] **Rendering Optimization**
  - [ ] Frustum culling (don't render off-screen objects)
    - Test each object's bounding box against camera frustum
    - Skip rendering if outside frustum
    - Saves 50%+ render time
  - [ ] Occlusion culling (don't render objects behind other objects)
    - Complex, may not be worth it
  - [ ] LOD system tuning (adjust distance thresholds)
    - Near objects: Full detail
    - Medium distance: Half detail
    - Far distance: Quarter detail
  - [ ] Batch rendering (combine draw calls)
    - Render all tanks in one draw call
    - Render all terrain chunks in one call
    - Reduces CPU overhead
  - [ ] Texture atlas optimization (reduce texture binds)
    - Combine small textures into one large texture
    - Use texture arrays
  - [ ] Shader optimization (reduce GPU work)
    - Profile shaders, find hotspots
    - Simplify lighting calculations
    - Use lower precision (half-float instead of float)
  - [ ] GPU profiling:
    - Use Metal Performance HUD
    - Identify bottlenecks
    - Fix slowest shaders/draw calls

**Test:** 1000 units on screen at 60 FPS

---

- [ ] **Simulation Optimization**
  - [ ] Spatial partitioning (quadtree/octree)
    - Divide map into grid cells
    - Only check nearby units for collision/combat
    - Reduces O(n²) to O(n log n)
  - [ ] Entity pooling (reuse entities instead of create/destroy)
    - Preallocate 1000 entities
    - Mark as inactive instead of deleting
    - Reactivate instead of creating new
  - [ ] Lazy updates (only update visible/active entities)
    - Off-screen units: Update every 5 frames
    - On-screen units: Update every frame
  - [ ] Multithreading:
    - Pathfinding in background thread
    - AI updates in background thread
    - Main thread only for rendering
  - [ ] Cache optimization (reduce cache misses)
    - Store frequently-accessed data together
    - Use arrays instead of linked lists
  - [ ] CPU profiling:
    - Use Instruments on macOS
    - Find hot functions
    - Optimize slowest code paths

**Test:** 2000 units pathfinding at 60 FPS

---

- [ ] **Memory Optimization**
  - [ ] Asset streaming (load/unload assets on demand)
    - Don't load all textures at once
    - Load when needed, unload when not visible
  - [ ] Memory pooling (reuse allocations)
    - Pool particles, projectiles, effects
    - Reduces malloc/free overhead
  - [ ] Garbage collection tuning (reduce pauses)
    - If using GC, tune for low latency
    - Or avoid GC entirely (manual memory)
  - [ ] Memory leak fixes:
    - Use AddressSanitizer (ASan)
    - Fix all leaks
  - [ ] Memory profiling:
    - Use Instruments memory profiler
    - Find largest allocations
    - Reduce memory usage

**Target:** <2GB RAM usage

**Test:** Play 1-hour game, memory usage stays stable

---

### 10.2 UI/UX Polish

**Tasks:**

- [ ] **UI Improvements**
  - [ ] High-res UI textures (2x resolution for 4K displays)
  - [ ] Smooth animations (fade in/out, slide)
  - [ ] Tooltips (hover over units/buttons to see info)
  - [ ] Hotkeys display (show "Q" on button when "Q" pressed)
  - [ ] Control groups UI (show numbers on selected units)
  - [ ] Minimap improvements:
    - Unit icons more visible
    - Attack notifications (red ping)
    - Click-to-navigate
  - [ ] Statistics screen:
    - Units built
    - Units lost
    - Resources collected
    - APM (actions per minute)
  - [ ] Victory/defeat screens:
    - Show final scores
    - Play victory/defeat music
    - Replay button

**Test:** UI looks professional and polished

---

- [ ] **Visual Effects**
  - [ ] Screen shake on explosions (camera wobble)
  - [ ] Camera zoom on important events (general power activated)
  - [ ] Bloom effect (bright lights glow)
  - [ ] Motion blur (fast-moving objects blur)
  - [ ] Color grading (adjust colors for mood)
  - [ ] Weather effects:
    - Rain (particle system)
    - Snow (particle system)
    - Sandstorms (particle fog)

**Test:** Nuke explosion shakes screen and blooms

---

- [ ] **Quality of Life**
  - [ ] Auto-queue production (infinite queue with Shift-click)
  - [ ] Smart selection:
    - Double-click selects all units of same type on screen
    - Ctrl-click adds to selection
    - Box select (drag rectangle)
  - [ ] Context menus (right-click for options)
  - [ ] Pathfinding visualization (show path on ground)
  - [ ] Attack-move indicator (red X on ground)
  - [ ] Range indicators:
    - Show weapon range when hovering attack button
    - Show build radius for base defenses

**Test:** Double-click selects all tanks on screen

---

### 10.3 Testing & Bug Fixing

**Tasks:**

- [ ] **Unit Testing**
  - [ ] Pathfinding tests (verify A* finds correct path)
  - [ ] Combat calculation tests (verify damage formula)
  - [ ] Production system tests (verify queue works)
  - [ ] Networking tests (verify lockstep sync)
  - [ ] Replay determinism tests (replay matches original game)

**Create:** `tests/pathfinding_test.zig`, etc.

**Test:** All unit tests pass

---

- [ ] **Integration Testing**
  - [ ] Full mission playthroughs (play all 21 missions, verify completion)
  - [ ] Multiplayer stress tests (8 players, 1 hour game)
  - [ ] Performance benchmarks (measure FPS, memory, load times)
  - [ ] Cross-platform testing (macOS + Windows)

**Test:** Game is stable and performant

---

- [ ] **Balance Testing**
  - [ ] Unit balance validation (compare to original game stats)
  - [ ] Power balance validation (A-10 strike not too strong)
  - [ ] Economy balance validation (income rates match original)
  - [ ] Adjust stats if needed to match original

**Test:** Game feels like original C&C Generals

---

- [ ] **Bug Fixing**
  - [ ] Crash fixes (no crashes under any circumstances)
  - [ ] Desync fixes (multiplayer stays in sync)
  - [ ] Visual glitches (units render correctly)
  - [ ] Audio issues (sounds play correctly)
  - [ ] Pathfinding bugs (units don't get stuck)
  - [ ] AI bugs (AI builds bases correctly)

**Test:** Zero known bugs

---

## Summary

### Code Breakdown

| Phase | System | Lines of Code | Files |
|-------|--------|--------------|-------|
| 1 | Graphics & Rendering | ~50,000 | 15 |
| 2 | Weapon & Combat | ~25,000 | 8 |
| 3 | AI & Pathfinding | ~30,000 | 10 |
| 4 | Production & Economy | ~15,000 | 7 |
| 5 | Special Abilities | ~15,000 | 5 |
| 6 | Audio | ~8,000 | 4 |
| 7 | Networking | ~15,000 | 5 |
| 8 | Campaign | ~20,000 | 6 |
| 9 | Content (data entry) | ~5,000 | 300+ INI files |
| 10 | Polish | ~10,000 | Various |
| **Total** | **~193,000 lines** | **~375 files** |

**Current:** ~8,750 lines (4.5% of target)

### Asset Requirements

- **3D Models:** 1,000+ W3D files (already have these!)
- **Textures:** 2,000+ TGA/DDS files (already have these!)
- **Sounds:** 5,000+ WAV/MP3 files (already have these!)
- **Unit Definitions:** 300+ INI files (need to create from Thyme reference)
- **Total Asset Size:** ~2.8GB (already have 1.1GB!)

### Development Timeline

| Phase | Duration | Cumulative | Priority |
|-------|----------|------------|----------|
| Phase 1: Graphics | 6-8 months | 8 months | CRITICAL |
| Phase 2: Combat | 4-6 months | 14 months | HIGH |
| Phase 3: AI | 5-7 months | 21 months | HIGH |
| Phase 4: Economy | 3-4 months | 25 months | MEDIUM |
| Phase 5: Abilities | 4-5 months | 30 months | MEDIUM |
| Phase 6: Audio | 2-3 months | 33 months | LOW |
| Phase 7: Multiplayer | 4-5 months | 38 months | MEDIUM |
| Phase 8: Campaign | 6-8 months | 46 months | LOW |
| Phase 9: Content | 3-4 months | 50 months | CRITICAL |
| Phase 10: Polish | 2-3 months | **53 months** | MEDIUM |

**Total: 53 months (4.4 years) solo full-time**

**With AI assistance:** ~2-3 years

**With team of 3:** ~1.5-2 years

---

## Getting Started

### Recommended Order

**Year 1: Core Engine**
1. Phase 1: Graphics (W3D renderer, terrain, particles) - 8 months
2. Phase 2: Combat (weapons, damage, veterancy) - 5 months

**Year 2: Gameplay**
3. Phase 3: AI (pathfinding, unit AI, strategic AI) - 6 months
4. Phase 4: Economy (buildings, production, resources) - 4 months
5. Phase 5: Abilities (general powers, unit abilities) - 4 months

**Year 3: Content & Polish**
6. Phase 9: Content (all units, stats, testing) - 4 months
7. Phase 6: Audio (sound effects, music) - 3 months
8. Phase 7: Multiplayer (networking, lobby, replay) - 5 months
9. Phase 10: Polish (optimization, bug fixes) - 3 months

**Optional:** Phase 8 (Campaign) - Do this last or skip for multiplayer-only release

---

## Next Steps

**Start TODAY:**

1. **Read Thyme W3D code:**
   ```bash
   cd ~/Code/Thyme/src/w3d/renderer
   vim w3d.h  # Understand W3D format
   ```

2. **Complete W3D loader:**
   ```bash
   cd ~/Code/generals/src/engine
   vim w3d_loader.zig  # Implement missing chunks
   ```

3. **Create 3D renderer:**
   ```bash
   vim src/renderer/w3d_renderer.zig  # New file
   ```

4. **Test with single unit:**
   ```bash
   zig build && ./zig-out/bin/generals
   # See Crusader tank in 3D!
   ```

---

## Resources

- **Thyme Source:** `~/Code/Thyme`
- **Original Assets:** `~/Code/generals/assets` (1.1GB)
- **Current Code:** `~/Code/generals/src`
- **INI Files:** `~/Code/generals/assets/data/*.ini`

**Good luck, Commander!** 🎮

This is a massive undertaking, but with the Thyme source code as reference and the assets already extracted, you have everything you need to build the real thing.

**The path is clear. The choice is yours.**
