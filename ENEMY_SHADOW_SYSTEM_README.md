# Enemy Shadow System Documentation

## Overview
The shadow system transforms enemies into shadow-selves with multiple visual modes, making them appear distinctly different from the player while preserving all animations and functionality.

## Shadow Modes

### 🌑 **SHADOW** (Default)
- **Appearance**: Pure black silhouette
- **Best For**: Classic shadow enemies, high contrast
- **Alpha**: Preserves original transparency
```gdscript
shadow_mode = ShadowMode.SHADOW
```

### 🌫️ **DARK_SHADOW**  
- **Appearance**: Dark grey silhouette
- **Best For**: Subtle shadows, less harsh contrast
- **Configurable**: Uses `shadow_intensity` for darkness level
```gdscript
shadow_mode = ShadowMode.DARK_SHADOW
shadow_intensity = 0.8  # 0.0 = black, 1.0 = normal
```

### 🎨 **COLORED_SHADOW**
- **Appearance**: Dark version of difficulty color tint
- **Best For**: Maintaining enemy identity while shadowing
- **Smart**: Preserves color relationships between difficulty levels
```gdscript
shadow_mode = ShadowMode.COLORED_SHADOW
difficulty_color_tint = Color.RED  # Will become dark red shadow
```

### 👥 **SILHOUETTE**
- **Appearance**: High-contrast black silhouette with special material
- **Best For**: Dramatic effect, clean look
- **Enhanced**: Uses unshaded material for consistent appearance
```gdscript
shadow_mode = ShadowMode.SILHOUETTE
```

### 👤 **NORMAL**
- **Appearance**: Original color tint system (no shadow)
- **Best For**: Disabling shadow system, debugging
- **Classic**: Maintains original difficulty color behavior
```gdscript
shadow_mode = ShadowMode.NORMAL
```

## Configuration Options

### Inspector Settings
```gdscript
@export var shadow_mode: ShadowMode = ShadowMode.SHADOW
@export var shadow_intensity: float = 0.8           # Darkness level
@export var shadow_preserve_alpha: bool = true      # Keep transparency
@export var shadow_add_outline: bool = false        # Add outline effect
```

### Shadow Intensity Guide
- **0.0**: Completely black shadows
- **0.3**: Very dark shadows (dramatic)
- **0.8**: Dark shadows (balanced, default)
- **1.0**: Light shadows (subtle)

### Alpha Preservation
- **true**: Maintains sprite transparency (recommended)
- **false**: Shadows become fully opaque

## Visual Examples

### Difficulty Progression with Shadows
```gdscript
# Timid Shadow (Difficulty 1)
shadow_mode = ShadowMode.DARK_SHADOW
shadow_intensity = 0.9  # Lighter shadow

# Aggressive Shadow (Difficulty 3) 
shadow_mode = ShadowMode.SHADOW
shadow_intensity = 0.8  # Standard shadow

# Perfect Shadow (Difficulty 5)
shadow_mode = ShadowMode.SILHOUETTE
shadow_intensity = 0.6  # Darker, more dramatic
```

### Thematic Variations
```gdscript
# Fire Enemies
shadow_mode = ShadowMode.COLORED_SHADOW
difficulty_color_tint = Color.ORANGE_RED

# Ice Enemies  
shadow_mode = ShadowMode.COLORED_SHADOW
difficulty_color_tint = Color.CYAN

# Void Enemies
shadow_mode = ShadowMode.SILHOUETTE
```

## Testing & Debug

### Quick Testing Controls
In test scenes (AITest.tscn):
- **Ctrl+H**: Run comprehensive shadow mode test (cycles through all modes)
- **Ctrl+J**: Quickly cycle through shadow modes on nearest enemy
- **Enter**: Test other systems while observing shadows

### Testing Functions
```gdscript
# Test all shadow modes automatically
enemy.test_shadow_modes()

# Change shadow mode dynamically
enemy.set_shadow_mode(ShadowMode.SHADOW, 0.7)

# Toggle outline effects
enemy.toggle_shadow_outline()
```

### Debug Output
The system provides detailed console output:
```
🌑 Aggressive Shadow using pure black shadow
🎭 Tactical Shadow shadow mode changed to: Dark Shadow
🔲 Perfect Shadow shadow outline: ON
```

## Integration with Existing Systems

### Death Fade Compatibility
- Shadows work seamlessly with the death fade system
- Faded shadows become even more subtle and atmospheric
- Maintains shadow appearance throughout fade

### AI Debug Compatibility
- Debug UI automatically matches shadow colors
- Labels and indicators adjust to shadow mode
- Health displays remain readable

### Difficulty System Integration
- Shadow modes can vary by difficulty level
- Higher difficulties can use more dramatic shadows
- Maintains original difficulty color relationships

## Performance Notes

### Optimized Rendering
- Uses Godot's built-in modulation (very fast)
- CanvasItemMaterial only created when needed
- No shaders required for basic shadow modes

### Memory Usage
- Minimal memory overhead
- Materials are lightweight
- Original materials preserved for restoration

## Advanced Customization

### Dynamic Shadow Changes
```gdscript
# Change shadows based on player distance
func _update_shadow_based_on_distance():
    var distance = global_position.distance_to(player.global_position)
    if distance < 100:
        set_shadow_mode(ShadowMode.SILHOUETTE)  # More dramatic up close
    else:
        set_shadow_mode(ShadowMode.SHADOW)      # Standard at distance

# Change shadows based on health
func _update_shadow_based_on_health():
    var health_pct = float(current_health) / float(max_health)
    shadow_intensity = health_pct * 0.8  # Darker as health decreases
    _apply_shadow_effect()
```

### Custom Shadow Colors
```gdscript
# Override for custom shadow effects
func _apply_custom_shadow():
    var custom_color = Color.PURPLE.darkened(0.7)
    animated_sprite.modulate = custom_color
```

### Environmental Lighting
```gdscript
# Adjust shadows based on environment
func _adjust_for_environment(environment_type: String):
    match environment_type:
        "dark_cave":
            shadow_intensity = 0.9  # Lighter in dark areas
        "bright_outdoor":
            shadow_intensity = 0.6  # Darker in bright areas
        "torch_lit":
            shadow_mode = ShadowMode.COLORED_SHADOW
            difficulty_color_tint = Color.ORANGE.darkened(0.3)
```

## Common Use Cases

### Recommended Configurations

#### **Classic Shadow Game**
```gdscript
shadow_mode = ShadowMode.SHADOW
shadow_intensity = 0.8
shadow_preserve_alpha = true
```

#### **Color-Coded Enemies**
```gdscript
shadow_mode = ShadowMode.COLORED_SHADOW
shadow_intensity = 0.7
# Use different difficulty_color_tint for each enemy type
```

#### **High-Contrast Stylized**
```gdscript
shadow_mode = ShadowMode.SILHOUETTE
shadow_add_outline = true
```

#### **Subtle Atmospheric**
```gdscript
shadow_mode = ShadowMode.DARK_SHADOW
shadow_intensity = 0.9
```

## Troubleshooting

### "Shadows not appearing"
1. Check `shadow_mode` is not set to `NORMAL`
2. Verify `animated_sprite` exists and is properly set up
3. Ensure `shadow_intensity` is not set to 1.0
4. Check console for shadow application messages

### "Shadows too dark/light"
1. Adjust `shadow_intensity` (0.0-1.0)
2. Try different `shadow_mode` options
3. Check `shadow_preserve_alpha` setting

### "Performance issues"
1. Shadows use optimized modulation - no performance impact expected
2. Disable `shadow_add_outline` if using many enemies
3. Consider simpler shadow modes for mobile platforms

### "Shadows disappear during animations"
1. Shadows persist through all animations automatically
2. Check that material isn't being overridden elsewhere
3. Verify `_apply_shadow_effect()` is called after animation changes

## Future Enhancements

### Planned Features
- Shader-based shadow effects for advanced visuals
- Dynamic shadow casting based on light sources
- Animated shadow transitions
- Shadow particle effects

### Community Suggestions
- Gradient shadows
- Textured shadows
- Shadow color cycling
- Environmental shadow adaptation 