# Combat System for 2D Game (Godot 4.3)

A comprehensive combat system that integrates seamlessly with the existing 8-directional movement player controller.

## 🎮 Features

### ⚔️ Melee Combat System
- **3-Hit Combo Chain**: Left-click to perform melee attacks in sequence
- **Combo Window**: 1-second window to continue the combo chain
- **Progressive Damage**: Each hit in the combo can have different properties
- **Directional Attacks**: Attacks face the direction the player is looking

### ✨ Special Abilities
- **Q Ability**: First special ability with 3-second cooldown
- **R Ability**: Second special ability with 8-second cooldown  
- **Large AOE Hitboxes**: Both abilities have wider area of effect than melee
- **Visual Feedback**: Debug UI shows cooldown timers

### 🛡️ Shield System
- **3-State Shield**: Start → Hold → End animations
- **Directional Blocking**: Only blocks attacks from the front (90° arc)
- **Hold to Shield**: Right-click and hold - shield stays up while button is pressed
- **Instant Response**: Releasing button immediately starts shield lowering
- **Smooth Transitions**: Proper animation flow between shield states

### 💥 Advanced Hitbox System
- **Direction-Aware**: Hitboxes track attack direction for blocking mechanics
- **Configurable Size/Shape**: Easy to resize for different attack types
- **Timer-Based Activation**: Hitboxes activate at specific timing during attacks
- **Collision Detection**: Handles both Area2D and CharacterBody2D targets
- **Self-Damage Protection**: Players cannot damage themselves with their own attacks

### 🏃 Movement Restrictions
- **Attack Lock**: No movement during melee attacks and special abilities
- **Shield Lock**: No movement while shielding for defensive positioning
- **Smooth Transitions**: Enhanced friction for quick stopping during combat
- **Visual Feedback**: Debug UI shows movement restriction status

### ✨ Particle Effects System
- **Whirlwind Effects**: Spinning white particles for 3rd melee attack and Q ability
- **Shockwave Effects**: Explosive brown particles for R ability  
- **Automatic Timing**: Particles triggered with configurable delay during attacks
- **Performance Optimized**: GPU-based particles with automatic cleanup
- **Toggleable**: Can be enabled/disabled via exported variable

### 💔 Health & Damage System
- **Health Management**: Configurable max health (default 100 HP)
- **Damage Animation**: Take damage state with red screen flash effect
- **Death Animation**: Death state leading to Game Over screen
- **Damage Flash**: Red screen overlay with smooth fade-out
- **State Protection**: Can't take damage while already taking damage or dead

### 💀 Death & Game Over System
- **Death Animation**: Plays death animation for configured duration
- **Game Over UI**: Full-screen overlay with restart button
- **Scene Restart**: Complete scene reload on restart
- **State Reset**: All combat states and health restored on restart

## 🎯 Controls

| Input | Action | Description |
|-------|--------|-------------|
| **Left Click** | Melee Attack | Triggers combo sequence (1/2/3) |
| **Right Click (Hold)** | Shield | Hold to block frontal attacks |
| **Q Key** | Special Ability 1 | AOE ability with 3s cooldown |
| **R Key** | Special Ability 2 | AOE ability with 8s cooldown |

## 🎬 Animation Requirements

The system expects animations following this naming convention:

### Melee Attacks
```
face_[direction]_melee_1    # First attack in combo
face_[direction]_melee_2    # Second attack in combo  
face_[direction]_melee_3    # Third attack in combo (AOE spin)
```

### Special Abilities
```
face_[direction]_ability_1  # Q ability animation
face_[direction]_ability_2  # R ability animation
```

### Shield System
```
face_[direction]_shield_start  # Shield raising animation
face_[direction]_shield_hold   # Shield held (loops)
face_[direction]_shield_end    # Shield lowering animation
```

### Health & Damage System
```
face_[direction]_take_damage   # Taking damage animation
face_[direction]_death         # Death animation
```

**Direction values**: `north`, `south`, `east`, `west`, `northeast`, `northwest`, `southeast`, `southwest`

## 🔧 Integration Guide

### 1. Input Actions Setup
The combat system requires these input actions in your `project.godot`:

```gdscript
primary_attack     # Left mouse button
secondary_attack   # Right mouse button  
ability_q         # Q key
ability_r         # R key
```

### 2. Adding to Existing Player
The combat system is already integrated into `PlayerController.gd`. Simply ensure your player scene has:

- `AnimatedSprite2D` with combat animations
- `CharacterBody2D` as the root node
- The `PlayerController.gd` script attached

### 3. Debug UI (Optional)
Add the debug UI to monitor combat status:

1. Instance `scenes/player/CombatDebugUI.tscn` 
2. Add it as a child of your player scene
3. The UI will automatically connect and show real-time combat info

## ⚙️ Customization

### Timing Adjustments
```gdscript
# Melee system timing
@export var melee_combo_window: float = 1.0      # Time window for next combo
@export var melee_attack_duration: float = 0.8   # How long each attack lasts

# Ability cooldowns
@export var q_ability_cooldown: float = 3.0      # Q ability cooldown
@export var r_ability_cooldown: float = 8.0      # R ability cooldown

# Shield timing
var shield_start_duration: float = 0.3           # Shield raise time
var shield_end_duration: float = 0.3             # Shield lower time
```

### Hitbox Configuration
```gdscript
# Hitbox timing
@export var hitbox_activation_delay: float = 0.3 # Delay before hitbox activates
@export var hitbox_active_duration: float = 0.2  # How long hitbox stays active

# Hitbox frame timing (for frame-based activation)
@export var melee_hitbox_start_frame: int = 6    # Frame to start melee hitbox
@export var melee_hitbox_end_frame: int = 10     # Frame to end melee hitbox
```

### Hitbox Shapes & Sizes
Modify in `_setup_hitboxes()`:

```gdscript
# Melee hitbox (rectangular)
melee_shape.size = Vector2(60, 40)        # Width x Height
melee_hitbox.position = Vector2(30, 0)     # Offset from player

# Ability hitbox (circular AOE)  
ability_shape.radius = 80                 # Radius for AOE
ability_hitbox.position = Vector2.ZERO    # Centered on player
```

### Movement Restrictions
Customize movement behavior during combat:

```gdscript
func _get_combat_movement_modifier() -> float:
    if is_attacking or is_using_ability or is_shielding:
        return 0.0  # No movement during any combat action
    else:
        return 1.0  # Normal movement

# Enhanced friction during combat restrictions
var enhanced_friction = friction * 2.0    # Multiplier for stopping speed
```

### Particle Effects
Customize particle effects for special attacks:

```gdscript
# Particle system toggles and timing
@export var particles_enabled: bool = true           # Enable/disable particles
@export var particle_activation_delay: float = 0.25  # Delay before particles start

# Whirlwind particle customization (3rd melee + Q ability)
whirlwind_material.initial_velocity_min = 50.0       # Minimum particle speed
whirlwind_material.initial_velocity_max = 100.0      # Maximum particle speed  
whirlwind_material.orbit_velocity_min = 2.0          # Spinning speed
whirlwind_material.color = Color.WHITE               # Particle color
whirlwind_material.emission_ring_radius = 30.0       # Ring size

# Shockwave particle customization (R ability)  
shockwave_material.initial_velocity_min = 80.0       # Explosion speed
shockwave_material.initial_velocity_max = 150.0      # Maximum burst speed
shockwave_material.color = Color.BROWN               # Particle color
shockwave_particles.amount = 75                      # Number of particles
```

### Health & Damage System
Customize health, damage, and death behavior:

```gdscript
# Health system configuration
@export var max_health: int = 100                    # Maximum player health
var damage_animation_duration: float = 0.6           # Duration of damage animation
var death_animation_duration: float = 2.0            # Duration of death animation

# Damage flash effect
@export var damage_flash_duration: float = 0.3       # How long flash lasts
@export var damage_flash_intensity: float = 0.6      # Flash opacity (0.0-1.0)

# Apply damage to player
player_controller.take_damage(25)                    # Deal 25 damage
player_controller.take_damage(50, Vector2.LEFT)      # 50 damage from left direction

# Testing functions (for development)
player_controller.test_take_damage(20)               # Test 20 damage
player_controller.test_death()                       # Test death instantly
player_controller.test_heal(50)                      # Test healing 50 HP
```

## 🎯 Damage & Blocking System

### Damage Application
Targets can implement these methods:
```gdscript
func take_damage(amount: int, attack_direction: Vector2):
    # Handle taking damage from attacks
    
func can_block_attack(attack_direction: Vector2) -> bool:
    # Return true if this attack should be blocked
```

### Self-Damage Protection
The hitbox system automatically prevents players from damaging themselves:
```gdscript
func _handle_combat_hit(target: Node, attack_type: String):
    # Prevent self-damage - player cannot hit themselves
    if target == self:
        return
    
    # Check if target is part of player entity (child nodes)
    if is_ancestor_of(target):
        return
    
    # Apply damage to valid targets only
    target.take_damage(damage, attack_direction)
```

### Blocking Mechanics
The shield blocks attacks from a 90° frontal arc:
```gdscript
func can_block_attack(attack_dir: Vector2) -> bool:
    if not is_shield_active:
        return false
    
    var angle_degrees = abs(rad_to_deg(attack_dir.angle_to(current_facing_direction)))
    return angle_degrees <= 90  # 90° frontal blocking arc
```

## 🐛 Debug Features

### Debug UI
- **Real-time Status**: Shows current combat state, combo progress, cooldowns
- **Color Coding**: Different colors for different combat states
- **Control Reference**: On-screen control reminders

### Console Logging
The system provides detailed console output:
- Attack initiation and completion
- Combo progression and resets
- Cooldown status
- Shield state changes
- Hitbox activation/deactivation
- Safety system warnings

### Safety Systems
Built-in safety checks prevent getting stuck in combat states:
- Auto-completion of stuck attack animations
- Combo reset on timeout
- Shield state recovery
- Combat state consistency checks

## 📋 TODO / Future Enhancements

- [x] ~~Particle effects for attacks and impacts~~ ✅ **COMPLETED**
- [ ] Frame-based hitbox activation (currently timer-based)
- [ ] Sound effect integration
- [ ] Camera shake on impacts
- [ ] Damage numbers display
- [ ] Status effects (stun, knockback)
- [ ] Weapon switching system
- [ ] Combo multiplier system
- [ ] Enhanced particle effects (trails, screen distortion, custom textures)
- [ ] Particle effect variations based on combo count
- [ ] Environmental particle interactions (dust, debris)

## 🔍 Troubleshooting

### Common Issues

**Animations not playing:**
- Check animation naming convention matches exactly
- Verify animations exist in AnimatedSprite2D's SpriteFrames resource
- Enable debug console to see "Animation not found" warnings

**Hitboxes not detecting:**
- Ensure target objects have collision layers/masks set correctly
- Check that targets are in detection range
- Verify `monitoring` is enabled on Area2D hitboxes

**Input not working:**
- Confirm input actions are set up in Project Settings → Input Map
- Check that the PlayerController script is attached and `_ready()` was called
- Verify no other systems are consuming the input events first

**Shield not blocking:**
- Check that `is_shield_active` is true during shield hold state
- Verify attack direction calculation
- Ensure blocking logic is implemented in target objects

**Particle effects not showing:**
- Verify `particles_enabled` is set to true in PlayerController
- Check console for "Particle effects initialized" message
- Ensure particle nodes are properly created (look for warnings in console)
- Try adjusting `particle_activation_delay` for better timing
- Check that GPU particles are supported on your target platform

**Damage/Death system not working:**
- Check console for "Damage and death UI initialized" message
- Verify animations exist: `face_[direction]_take_damage` and `face_[direction]_death`
- Test with development functions: `test_take_damage()`, `test_death()`, `test_heal()`
- Ensure UI layers are set correctly (damage flash layer 100, game over layer 200)
- Check that current_health is properly initialized to max_health

**Game Over screen not appearing:**
- Verify death animation duration is reasonable (not too long)
- Check console for "Game Over screen displayed" message  
- Ensure game_over_ui is properly created and added to scene
- Test with `test_death()` function for immediate death

**Red damage flash not visible:**
- Check `damage_flash_intensity` is between 0.0-1.0
- Verify `damage_flash_duration` is reasonable (0.1-0.5 seconds)
- Ensure damage flash ColorRect covers full screen
- Test damage flash with `test_take_damage()` function

**Player not taking damage from enemies:**
- Verify enemy hitboxes have correct collision layers/masks
- Check that enemy attacks call `player.take_damage(amount, direction)`
- Ensure player is not in invincible state (already taking damage or dead)
- Test with `test_take_damage()` to verify damage system works

**Player hitting themselves:**
- Self-damage protection is automatic - players cannot hit themselves
- Check console for "Prevented self-damage" messages if issues occur
- Protection covers both the player node and all child nodes
- If you need to disable this, modify `_handle_combat_hit()` function

---

*Combat system integrates seamlessly with existing 8-directional movement and animation systems.* 