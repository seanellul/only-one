# Enemy AI System for "Only One"

## Overview

The Enemy AI System for "Only One" creates shadow selves of the player that scale in difficulty from timid beginners to perfect mirrors of the player's capabilities. This system implements Carl Jung's concept of the shadow archetype through gameplay mechanics.

## Core Philosophy

> "One does not become enlightened by imagining figures of light, but by making the darkness conscious." - Carl Jung

Each enemy represents a different aspect of the player's shadow self, from the hesitant beginner to the perfect mirror. The goal is to defeat all shadow selves until only the original remains.

## System Architecture

### 1. EnemyController.gd
**Location**: `systems/enemies/EnemyController.gd`  
**Purpose**: AI-driven enemies that extend PlayerController

**Key Features**:
- 5 Difficulty levels with distinct personalities
- State machine-based AI decision making
- Target acquisition and tracking
- Predictive movement and combat
- Visual difficulty identification

### 2. EnemySpawner.gd
**Location**: `systems/enemies/EnemySpawner.gd`  
**Purpose**: Wave-based enemy spawning and management

**Key Features**:
- Progressive difficulty scaling
- Wave management system
- Safe spawn positioning
- Enemy tracking and cleanup

### 3. Enemy.tscn
**Location**: `scenes/enemies/Enemy.tscn`  
**Purpose**: Enemy scene with AI debug UI

### 4. Game Integration
- **GameController**: Manages overall game state and UI
- **Main Game Scene**: Complete "Only One" experience

## Difficulty Levels

### 1. Timid Shadow (Level 1) 
**Color**: Pale Blue  
**Personality**: Hesitant and reactive  
- **Reaction Time**: 1.5s
- **Aggression**: 10%
- **Health**: 60 HP
- **Behaviors**: Basic attacks only, high defensive chance
- **AI Strategy**: Waits for player to approach, rarely initiates combat

### 2. Cautious Shadow (Level 2)
**Color**: Pale Green  
**Personality**: Defensive and methodical  
- **Reaction Time**: 1.0s
- **Aggression**: 20%
- **Health**: 80 HP
- **Behaviors**: Uses shields frequently, simple combos
- **AI Strategy**: Defensive positioning, blocks often

### 3. Aggressive Shadow (Level 3)
**Color**: Pale Orange  
**Personality**: Offensive and predictable  
- **Reaction Time**: 0.7s
- **Aggression**: 40%
- **Health**: 100 HP
- **Behaviors**: Full combo usage, ability usage
- **AI Strategy**: Direct confrontation, predictable patterns

### 4. Tactical Shadow (Level 4)
**Color**: Pale Red  
**Personality**: Strategic and adaptive  
- **Reaction Time**: 0.4s
- **Aggression**: 60%
- **Health**: 120 HP
- **Behaviors**: Advanced positioning, counters attacks
- **AI Strategy**: Reads player patterns, adaptive combat

### 5. Perfect Shadow (Level 5)
**Color**: Pale Purple  
**Personality**: Mirror of perfection  
- **Reaction Time**: 0.2s
- **Aggression**: 80%
- **Health**: 140 HP
- **Behaviors**: Frame-perfect timing, prediction
- **AI Strategy**: Perfect mirror of player capabilities

## AI State Machine

### States
1. **IDLE**: Resting state, occasionally looks around
2. **PATROL**: Random movement when no target
3. **CHASE**: Pursuing detected target
4. **ATTACK**: In combat range, executing attacks
5. **DEFEND**: Defensive posture, using shield
6. **RETREAT**: Low health escape behavior
7. **DEAD**: Defeated state

### Decision Making
- **Think Interval**: Varies by difficulty (0.1s to 0.5s)
- **Reaction Time**: Simulates human-like delays
- **Prediction**: Higher difficulties predict player movement
- **Memory**: Learns from player patterns (expandable)

## Combat Capabilities

### All Enemies Have Access To:
- **Melee Combos**: 3-hit combination attacks
- **Q Ability**: Whirlwind attack with particles
- **R Ability**: Shockwave attack with area effect
- **Shield System**: Directional blocking
- **Roll Dodging**: Evasive maneuvers
- **All Player Animations**: Complete animation set

### Difficulty-Based Restrictions:
- **Level 1-2**: No abilities, limited combos
- **Level 3+**: Full combat abilities
- **Level 4-5**: Enhanced prediction and timing

## Visual Design

### Color-Coded Difficulty
Each enemy has a distinct color tint to immediately communicate threat level:
- **Blue**: Safe (Timid)
- **Green**: Easy (Cautious)  
- **Orange**: Normal (Aggressive)
- **Red**: Hard (Tactical)
- **Purple**: Expert (Perfect)

### Debug Information
When `show_ai_debug = true`:
- Real-time AI state display
- Target information and distance
- Health with color coding
- Aggression and reaction time stats

## Wave Progression System

### Wave Scaling
- **Waves 1-2**: Timid and Cautious shadows only
- **Waves 3-5**: Introduce Aggressive shadows
- **Waves 6-8**: Add Tactical shadows
- **Waves 9+**: Include Perfect shadows

### Dynamic Spawning
- Enemies spawn at safe distances from player
- Prevents spawn camping
- Scales spawn count with wave number
- Maximum concurrent enemies limit

## Usage Instructions

### Basic Setup
```gdscript
# In your scene, instance an Enemy
var enemy = enemy_scene.instantiate()
enemy.ai_difficulty = 3  # Set difficulty 1-5
enemy.show_ai_debug = true  # Enable debug UI
add_child(enemy)
```

### Using the Spawner
```gdscript
# Add EnemySpawner to your scene
var spawner = EnemySpawner.new()
spawner.enemy_scene = preload("res://scenes/enemies/Enemy.tscn")
spawner.max_enemies = 5
spawner.difficulty_scaling = true
add_child(spawner)
```

### Testing Specific Difficulties
```gdscript
# Spawn specific difficulty for testing
spawner.spawn_specific_difficulty(5, Vector2(100, 100))

# Test enemy behavior
enemy.set_ai_difficulty(4)
enemy.set_ai_target(player)
```

## Game Integration

### Required Player Setup
```gdscript
# Player must be in "players" group
add_to_group("players")

# Player should emit death signal
signal player_died
```

### Scene Structure
```
OnlyOneGame
├── Player (PlayerController)
├── EnemySpawner (EnemySpawner)
├── GameController (OnlyOneGameController)
└── UI Elements
```

## Customization Options

### AI Behavior Tuning
Modify these values in `EnemyController.gd`:
```gdscript
@export var ai_difficulty: int = 1
@export var show_ai_debug: bool = false
reaction_time = 1.0
aggression_level = 0.3
defensive_chance = 0.2
ability_usage_chance = 0.1
```

### Spawner Configuration
```gdscript
@export var spawn_radius: float = 300.0
@export var min_spawn_distance: float = 150.0
@export var max_enemies: int = 5
@export var wave_delay: float = 5.0
```

## Future Enhancements

### Planned Features
1. **Machine Learning**: Enemies learn from player behavior
2. **Personality Profiles**: More distinct AI personalities
3. **Formation Combat**: Coordinated group attacks
4. **Dynamic Difficulty**: Adaptive challenge based on player skill
5. **Shadow Abilities**: Unique abilities for each difficulty tier

### Extension Points
- **Custom AI States**: Add new behavioral states
- **Ability System**: Create unique shadow abilities
- **Environmental AI**: Enemies that use terrain
- **Emotional States**: AI that reacts to player aggression

## Performance Considerations

### Optimizations
- **Think Intervals**: Prevents excessive AI calculations
- **Distance Culling**: Inactive AI for distant enemies
- **State Caching**: Reduces redundant calculations
- **Group Management**: Efficient enemy tracking

### Scalability
- Tested with up to 10 concurrent enemies
- Configurable think rates for performance tuning
- Pooling system ready for implementation

## Debugging and Testing

### Debug Commands
```gdscript
# In GameController
force_next_wave()  # Skip to next wave
spawn_test_enemy(difficulty)  # Spawn specific difficulty
clear_all_enemies()  # Remove all enemies

# Enemy status
enemy.get_ai_status()  # Get AI state information
```

### Debug UI
Enable `show_ai_debug = true` for real-time AI state visualization:
- Current AI state with color coding
- Target information and distance
- Health status with visual indicators
- Combat parameters display

## Integration with Jung's Shadow Work

### Psychological Metaphors
- **Difficulty Progression**: Stages of shadow integration
- **Color Symbolism**: Visual representation of shadow aspects
- **Combat Mechanics**: Confronting rather than avoiding shadows
- **Victory Condition**: Integration (only one remains)

### Narrative Integration
- Each enemy represents suppressed aspects of self
- Defeating shadows integrates them rather than destroying
- Progressive difficulty mirrors psychological growth
- Victory represents psychological wholeness

## Troubleshooting

### Common Issues
1. **Enemies Not Spawning**: Check player group membership
2. **No AI Debug UI**: Verify `show_ai_debug = true` and scene structure
3. **Poor Performance**: Reduce `max_enemies` or increase `ai_think_interval`
4. **Enemies Stuck**: Check pathfinding and collision setup

### Performance Tips
- Limit concurrent enemies to 5-8 for smooth gameplay
- Use appropriate think intervals (0.1s minimum recommended)
- Enable debug mode only for development

## Conclusion

The Enemy AI System for "Only One" creates a meaningful connection between gameplay mechanics and psychological concepts. Each shadow self provides a unique challenge while contributing to the overarching narrative of shadow integration and personal wholeness.

The system is designed to be both technically sophisticated and thematically meaningful, creating enemies that feel like genuine reflections of the player at different skill levels while maintaining the game's psychological metaphor.

---

*"The meeting with oneself is, at first, the meeting with one's own shadow."* - Carl Jung 