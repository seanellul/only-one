# Combat Particle System Documentation

## Overview

The Combat Particle System has been extracted from the `CharacterController` into a separate, modular `CombatParticleManager` class. This separation improves maintainability, testability, and allows for easier customization and redesign of particle effects.

## Architecture

### CombatParticleManager (`systems/CombatParticleManager.gd`)

The main particle management class that handles all combat-related particle effects.

**Key Features:**
- Modular design for easy testing and modification
- Configurable particle properties via exports
- Runtime reconfiguration support
- Debug mode for development
- Signal-based communication
- Independent testing capabilities

### Particle Effects

#### 1. Whirlwind Effect
- **Used for:** 3rd melee combo attack and Q ability
- **Visual:** White swirling particles in a ring pattern
- **Configuration:** Amount, lifetime, velocities, colors, emission radius

#### 2. Shockwave Effect
- **Used for:** R ability
- **Visual:** Brown particles exploding radially outward
- **Configuration:** Amount, lifetime, velocities, colors, emission radius

## Usage

### Basic Integration

```gdscript
# In your character controller or scene
@onready var particle_manager: CombatParticleManager

func _ready():
    # Create and add particle manager
    particle_manager = CombatParticleManager.new()
    particle_manager.name = "CombatParticleManager"
    add_child(particle_manager)

func trigger_whirlwind():
    if particle_manager:
        particle_manager.trigger_whirlwind_effect()

func trigger_shockwave():
    if particle_manager:
        particle_manager.trigger_shockwave_effect()
```

### Configuration

The particle manager exposes many configurable properties:

```gdscript
# Enable/disable all particles
particle_manager.particles_enabled = true

# Configure whirlwind effect
particle_manager.whirlwind_amount = 75
particle_manager.whirlwind_color = Color.BLUE
particle_manager.whirlwind_effect_duration = 0.8

# Configure shockwave effect
particle_manager.shockwave_amount = 120
particle_manager.shockwave_color = Color.RED
```

### Runtime Reconfiguration

```gdscript
# Reconfigure whirlwind at runtime
var whirlwind_config = {
    "amount": 100,
    "lifetime": 0.8,
    "color": Color.BLUE
}
particle_manager.reconfigure_whirlwind(whirlwind_config)

# Reconfigure shockwave at runtime
var shockwave_config = {
    "amount": 150,
    "lifetime": 0.6,
    "color": Color.RED
}
particle_manager.reconfigure_shockwave(shockwave_config)
```

### Signals

The particle manager emits signals for effect lifecycle:

```gdscript
# Connect to particle manager signals
particle_manager.particle_effect_started.connect(_on_particle_started)
particle_manager.particle_effect_completed.connect(_on_particle_completed)

func _on_particle_started(effect_type: String):
    print("Effect started: ", effect_type)

func _on_particle_completed(effect_type: String):
    print("Effect completed: ", effect_type)
```

## Testing

### Standalone Test Scene

Use `scenes/test/ParticleTestScene.tscn` to test particle effects independently:

1. **Load the test scene** in Godot
2. **Use the UI buttons** to trigger different effects
3. **Toggle particles on/off** to test enable/disable functionality
4. **Enable debug mode** for detailed console output
5. **Use keyboard shortcuts** for quick testing:
   - Space/Enter: Whirlwind effect
   - Escape: Shockwave effect
   - Tab: All effects

### Console Testing

From the test scene, you can call testing functions:

```gdscript
# Test runtime reconfiguration
$ParticleTestController.test_particle_reconfiguration()

# Reset to defaults
$ParticleTestController.reset_particle_configuration()

# Generate test report
$ParticleTestController.print_test_report()
```

### Direct Testing

You can also test the particle manager directly:

```gdscript
# Create a particle manager for testing
var test_manager = CombatParticleManager.new()
test_manager.debug_particles = true
add_child(test_manager)

# Test individual effects
test_manager.test_whirlwind()
test_manager.test_shockwave()
test_manager.test_all_effects()
```

## API Reference

### Core Functions

- `trigger_whirlwind_effect()` - Trigger whirlwind particle effect
- `trigger_shockwave_effect()` - Trigger shockwave particle effect
- `set_particles_enabled(enabled: bool)` - Enable/disable all particles
- `get_particle_status() -> Dictionary` - Get current particle system status

### Configuration Functions

- `reconfigure_whirlwind(config: Dictionary)` - Runtime whirlwind configuration
- `reconfigure_shockwave(config: Dictionary)` - Runtime shockwave configuration

### Debug Functions

- `enable_debug()` - Enable debug mode
- `disable_debug()` - Disable debug mode
- `test_whirlwind()` - Test whirlwind effect
- `test_shockwave()` - Test shockwave effect
- `test_all_effects()` - Test all effects in sequence

### Signals

- `particle_effect_started(effect_type: String)` - Emitted when an effect starts
- `particle_effect_completed(effect_type: String)` - Emitted when an effect completes

## Configuration Properties

### Whirlwind Effect
- `whirlwind_amount: int = 50`
- `whirlwind_lifetime: float = 0.4`
- `whirlwind_initial_velocity_min/max: float`
- `whirlwind_angular_velocity_min/max: float`
- `whirlwind_orbit_velocity_min/max: float`
- `whirlwind_scale_min/max: float`
- `whirlwind_emission_radius: float = 30.0`
- `whirlwind_emission_inner_radius: float = 10.0`
- `whirlwind_effect_duration: float = 0.5`
- `whirlwind_color: Color = Color.WHITE`

### Shockwave Effect
- `shockwave_amount: int = 80`
- `shockwave_lifetime: float = 0.4`
- `shockwave_emission_radius: float = 5.0`
- `shockwave_initial_velocity_min/max: float`
- `shockwave_scale_min/max: float`
- `shockwave_effect_duration: float = 0.8`
- `shockwave_color: Color = Color.BROWN`

### Global Settings
- `particles_enabled: bool = true`
- `particle_activation_delay: float = 0.25`
- `debug_particles: bool = false`

## Benefits of Extraction

1. **Modularity:** Particle effects are now isolated and reusable
2. **Testability:** Independent testing without full character setup
3. **Maintainability:** Easier to modify and extend particle effects
4. **Performance:** Can optimize particle systems independently
5. **Flexibility:** Runtime configuration and customization
6. **Debugging:** Dedicated debug mode and testing tools

## Migration from Old System

The old particle system in `CharacterController` has been completely replaced. The new system:

- ✅ Maintains the same visual effects
- ✅ Provides the same triggering interface
- ✅ Adds extensive configuration options
- ✅ Includes comprehensive testing tools
- ✅ Supports runtime reconfiguration
- ✅ Offers better debugging capabilities

The `CharacterController` now uses the particle manager through simple method calls, making the integration clean and maintainable.

## Future Enhancements

Potential improvements for the particle system:

1. **Additional Effects:** Add more particle types (fire, ice, lightning, etc.)
2. **Animation Integration:** Sync particles with animation frames
3. **Sound Integration:** Coordinate with audio system
4. **Performance Optimization:** Particle pooling and LOD system
5. **Visual Editor:** In-editor particle configuration tools
6. **Preset System:** Predefined effect configurations
7. **Particle Chaining:** Combine multiple effects in sequences 