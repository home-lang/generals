// C&C Generals - AI Tactics System
// Implements combat AI, unit behavior, and tactical decisions

const std = @import("std");

/// Unit behavior state
pub const UnitState = enum {
    Idle,
    Moving,
    Attacking,
    Defending,
    Retreating,
    Patrolling,
    Guarding,
    Dead,
};

/// Unit combat role
pub const CombatRole = enum {
    Infantry,
    Tank,
    Artillery,
    AntiAir,
    AntiTank,
    Support,
    Scout,
    Builder,
};

/// Threat level assessment
pub const ThreatLevel = enum {
    None,
    Low,
    Medium,
    High,
    Critical,

    pub fn fromValue(value: f32) ThreatLevel {
        if (value >= 1.5) return .Critical;
        if (value >= 1.0) return .High;
        if (value >= 0.5) return .Medium;
        if (value > 0.0) return .Low;
        return .None;
    }
};

/// Tactical decision
pub const TacticalDecision = enum {
    Attack,
    Defend,
    Retreat,
    Flank,
    Pursue,
    HoldPosition,
    Regroup,
    CallReinforcements,
};

/// Unit combat stats
pub const CombatUnit = struct {
    id: usize,
    position: Vec2,
    health: f32,
    max_health: f32,
    damage: f32,
    armor: f32,
    range: f32,
    speed: f32,
    role: CombatRole,
    state: UnitState,
    target_id: ?usize,
    rally_point: ?Vec2,

    pub fn getHealthPercent(self: CombatUnit) f32 {
        return self.health / self.max_health;
    }

    pub fn getCombatValue(self: CombatUnit) f32 {
        return (self.damage * self.range) / @max(self.armor, 1.0) * self.getHealthPercent();
    }

    pub fn isAlive(self: CombatUnit) bool {
        return self.health > 0.0 and self.state != .Dead;
    }
};

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn distance(self: Vec2, other: Vec2) f32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        return @sqrt(dx * dx + dy * dy);
    }

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return Vec2{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: Vec2, other: Vec2) Vec2 {
        return Vec2{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn scale(self: Vec2, scalar: f32) Vec2 {
        return Vec2{ .x = self.x * scalar, .y = self.y * scalar };
    }

    pub fn normalize(self: Vec2) Vec2 {
        const len = @sqrt(self.x * self.x + self.y * self.y);
        if (len == 0) return Vec2{ .x = 0, .y = 0 };
        return Vec2{ .x = self.x / len, .y = self.y / len };
    }
};

/// Tactical AI system
pub const TacticalAI = struct {
    allocator: std.mem.Allocator,
    difficulty: AIDifficulty,

    pub const AIDifficulty = enum {
        Easy,
        Medium,
        Hard,
        Brutal,

        pub fn getReactionTime(self: AIDifficulty) f32 {
            return switch (self) {
                .Easy => 2.0,
                .Medium => 1.0,
                .Hard => 0.5,
                .Brutal => 0.1,
            };
        }

        pub fn getAccuracy(self: AIDifficulty) f32 {
            return switch (self) {
                .Easy => 0.6,
                .Medium => 0.75,
                .Hard => 0.9,
                .Brutal => 1.0,
            };
        }
    };

    pub fn init(allocator: std.mem.Allocator, difficulty: AIDifficulty) TacticalAI {
        return TacticalAI{
            .allocator = allocator,
            .difficulty = difficulty,
        };
    }

    /// Evaluate threat level from enemy forces
    pub fn evaluateThreat(self: *TacticalAI, friendly_units: []CombatUnit, enemy_units: []CombatUnit) ThreatLevel {
        _ = self;

        var friendly_strength: f32 = 0.0;
        var enemy_strength: f32 = 0.0;

        for (friendly_units) |unit| {
            if (unit.isAlive()) {
                friendly_strength += unit.getCombatValue();
            }
        }

        for (enemy_units) |unit| {
            if (unit.isAlive()) {
                enemy_strength += unit.getCombatValue();
            }
        }

        if (friendly_strength == 0.0) return .Critical;

        const threat_ratio = enemy_strength / friendly_strength;
        return ThreatLevel.fromValue(threat_ratio);
    }

    /// Make tactical decision based on situation
    pub fn makeTacticalDecision(
        self: *TacticalAI,
        friendly_units: []CombatUnit,
        enemy_units: []CombatUnit,
    ) TacticalDecision {
        const threat = self.evaluateThreat(friendly_units, enemy_units);

        // Count alive units
        var alive_friendly: usize = 0;
        var alive_enemy: usize = 0;
        for (friendly_units) |unit| {
            if (unit.isAlive()) alive_friendly += 1;
        }
        for (enemy_units) |unit| {
            if (unit.isAlive()) alive_enemy += 1;
        }

        // Decision logic based on threat and situation
        switch (threat) {
            .Critical, .High => {
                // Overwhelming enemy force - retreat or call reinforcements
                if (alive_friendly < 3) {
                    return .Retreat;
                } else {
                    return .CallReinforcements;
                }
            },
            .Medium => {
                // Even match - defend or flank
                if (self.difficulty == .Easy) {
                    return .Defend;
                } else {
                    return .Flank;
                }
            },
            .Low => {
                // We have advantage - attack or pursue
                if (alive_enemy > 0) {
                    return .Attack;
                } else {
                    return .Pursue;
                }
            },
            .None => {
                // No enemies - hold position or patrol
                return .HoldPosition;
            },
        }
    }

    /// Select best target for a unit
    pub fn selectTarget(self: *TacticalAI, unit: CombatUnit, enemies: []CombatUnit) ?usize {
        _ = self;

        var best_target: ?usize = null;
        var best_score: f32 = -std.math.inf(f32);

        for (enemies, 0..) |enemy, i| {
            if (!enemy.isAlive()) continue;

            const distance = unit.position.distance(enemy.position);

            // Skip if out of range
            if (distance > unit.range * 1.5) continue;

            // Calculate target priority score
            var score: f32 = 0.0;

            // Prefer closer targets
            score += 100.0 / @max(distance, 1.0);

            // Prefer wounded targets
            score += (1.0 - enemy.getHealthPercent()) * 50.0;

            // Role-based targeting priorities
            score += switch (unit.role) {
                .AntiAir => if (enemy.role == .Scout) 100.0 else 0.0,
                .AntiTank => if (enemy.role == .Tank) 100.0 else 0.0,
                .Artillery => if (enemy.role == .Infantry) 50.0 else 30.0,
                else => 25.0,
            };

            // Prefer high-value targets
            score += enemy.damage * 10.0;

            if (score > best_score) {
                best_score = score;
                best_target = i;
            }
        }

        return best_target;
    }

    /// Calculate retreat position
    pub fn calculateRetreatPosition(self: *TacticalAI, unit: CombatUnit, enemies: []CombatUnit) Vec2 {
        _ = self;

        // Calculate average enemy position
        var enemy_center = Vec2{ .x = 0, .y = 0 };
        var count: f32 = 0;

        for (enemies) |enemy| {
            if (enemy.isAlive()) {
                enemy_center = enemy_center.add(enemy.position);
                count += 1;
            }
        }

        if (count > 0) {
            enemy_center = enemy_center.scale(1.0 / count);
        }

        // Move away from enemy center
        const direction = unit.position.sub(enemy_center).normalize();
        const retreat_distance: f32 = 200.0;

        return unit.position.add(direction.scale(retreat_distance));
    }

    /// Calculate flank position
    pub fn calculateFlankPosition(self: *TacticalAI, unit: CombatUnit, target: CombatUnit) Vec2 {
        _ = self;

        // Move perpendicular to current position-target line
        const direction = target.position.sub(unit.position).normalize();
        const perpendicular = Vec2{ .x = -direction.y, .y = direction.x };
        const flank_distance: f32 = 100.0;

        return unit.position.add(perpendicular.scale(flank_distance));
    }

    /// Update unit behavior based on current state
    pub fn updateUnitBehavior(self: *TacticalAI, unit: *CombatUnit, enemies: []CombatUnit, delta_time: f32) void {
        _ = delta_time;

        switch (unit.state) {
            .Idle => {
                // Look for targets
                if (self.selectTarget(unit.*, enemies)) |target_id| {
                    unit.target_id = target_id;
                    unit.state = .Attacking;
                }
            },
            .Attacking => {
                // Check if target still valid
                if (unit.target_id) |tid| {
                    const target = enemies[tid];
                    if (!target.isAlive()) {
                        unit.target_id = null;
                        unit.state = .Idle;
                    }
                } else {
                    unit.state = .Idle;
                }

                // Check health - retreat if low
                if (unit.getHealthPercent() < 0.3) {
                    unit.state = .Retreating;
                }
            },
            .Defending => {
                // Hold position and attack nearby enemies
                if (self.selectTarget(unit.*, enemies)) |target_id| {
                    const target = enemies[target_id];
                    const distance = unit.position.distance(target.position);
                    if (distance <= unit.range) {
                        unit.target_id = target_id;
                        unit.state = .Attacking;
                    }
                }
            },
            .Retreating => {
                // Move away from combat
                if (unit.getHealthPercent() > 0.7) {
                    unit.state = .Idle;
                }
            },
            .Patrolling => {
                // Move between waypoints, attack if enemies found
                if (self.selectTarget(unit.*, enemies)) |target_id| {
                    unit.target_id = target_id;
                    unit.state = .Attacking;
                }
            },
            .Guarding => {
                // Protect a specific location
                if (self.selectTarget(unit.*, enemies)) |target_id| {
                    const target = enemies[target_id];
                    const distance = unit.position.distance(target.position);
                    if (distance <= unit.range * 1.2) {
                        unit.target_id = target_id;
                        unit.state = .Attacking;
                    }
                }
            },
            .Moving => {
                // Continue moving to destination
            },
            .Dead => {
                // Unit is dead, do nothing
            },
        }
    }
};

/// Squad formation manager
pub const FormationManager = struct {
    pub const FormationType = enum {
        Line,
        Column,
        Wedge,
        Box,
        Circle,
    };

    pub fn calculateFormationPositions(
        allocator: std.mem.Allocator,
        formation: FormationType,
        center: Vec2,
        unit_count: usize,
        spacing: f32,
    ) ![]Vec2 {
        var positions = try allocator.alloc(Vec2, unit_count);

        switch (formation) {
            .Line => {
                const half_width = @as(f32, @floatFromInt(unit_count)) * spacing * 0.5;
                for (positions, 0..) |*pos, i| {
                    const offset = @as(f32, @floatFromInt(i)) * spacing - half_width;
                    pos.* = Vec2{ .x = center.x + offset, .y = center.y };
                }
            },
            .Column => {
                for (positions, 0..) |*pos, i| {
                    const offset = @as(f32, @floatFromInt(i)) * spacing;
                    pos.* = Vec2{ .x = center.x, .y = center.y + offset };
                }
            },
            .Wedge => {
                positions[0] = center; // Leader at front
                var idx: usize = 1;
                var row: usize = 1;
                while (idx < unit_count) {
                    const row_size = row + 1;
                    var i: usize = 0;
                    while (i < row_size and idx < unit_count) : (i += 1) {
                        const x_offset = (@as(f32, @floatFromInt(i)) - @as(f32, @floatFromInt(row_size)) * 0.5) * spacing;
                        const y_offset = @as(f32, @floatFromInt(row)) * spacing;
                        positions[idx] = Vec2{ .x = center.x + x_offset, .y = center.y + y_offset };
                        idx += 1;
                    }
                    row += 1;
                }
            },
            .Box => {
                const side = @ceil(@sqrt(@as(f32, @floatFromInt(unit_count))));
                for (positions, 0..) |*pos, i| {
                    const row = @as(f32, @floatFromInt(@divTrunc(i, @as(usize, @intFromFloat(side)))));
                    const col = @as(f32, @floatFromInt(@mod(i, @as(usize, @intFromFloat(side)))));
                    pos.* = Vec2{
                        .x = center.x + (col - side * 0.5) * spacing,
                        .y = center.y + (row - side * 0.5) * spacing,
                    };
                }
            },
            .Circle => {
                const radius = spacing * @as(f32, @floatFromInt(unit_count)) / (2.0 * std.math.pi);
                for (positions, 0..) |*pos, i| {
                    const angle = (@as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(unit_count))) * 2.0 * std.math.pi;
                    pos.* = Vec2{
                        .x = center.x + @cos(angle) * radius,
                        .y = center.y + @sin(angle) * radius,
                    };
                }
            },
        }

        return positions;
    }
};
