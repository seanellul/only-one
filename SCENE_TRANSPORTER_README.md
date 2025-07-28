# 🚪 Scene Transporter System

A reusable scene transition system with fade effects and music integration for smooth navigation between game scenes.

## ✨ Features

- **Smooth Fade Transitions**: Customizable fade in/out effects with color and duration control
- **Music Integration**: Seamless integration with the MusicManager for crossfading and music changes
- **Easy-to-Use API**: Simple methods for common transitions
- **Signal-Based**: Connect to transition events for custom behavior
- **Flexible**: Can be instantiated as a scene or created dynamically in code

## 🚀 Quick Start

### Method 1: Use the Pre-built Scene

1. Instance `SceneTransporter.tscn` in your scene
2. Get a reference to it in your script:

```gdscript
@onready var transporter: SceneTransporter = $SceneTransporter

func _ready():
    # Use convenience methods
    transporter.transition_to_town()
```

### Method 2: Create Dynamically

```gdscript
var transporter: SceneTransporter

func _ready():
    transporter = SceneTransporter.new()
    add_child(transporter)
    
    # Configure if needed
    transporter.set_fade_duration(2.0)
    transporter.set_fade_color(Color.BLUE)
```

## 🎯 Common Usage Examples

### Basic Transitions

```gdscript
# Quick transition (no music change)
transporter.quick_transition("res://scenes/town/town.tscn")

# Transition with music
transporter.transition_with_music(
    "res://scenes/levels/Level_1.tscn",
    "res://audio/music/Action 1.mp3",
    true # crossfade music
)

# Full custom transition
transporter.transition_to_scene(
    "res://scenes/main/Campsite.tscn",
    "res://audio/music/Ambient 1.mp3",
    false # don't crossfade
)
```

### Convenience Methods

```gdscript
# Pre-configured transitions to common scenes
transporter.transition_to_town()         # Goes to town with ambient music
transporter.transition_to_campsite()     # Goes to campsite with light ambience
transporter.transition_to_main_menu()    # Goes to main menu, stops music
```

### Player Death Integration

The PlayerController automatically uses the SceneTransporter on death:

```gdscript
# In PlayerController.gd - this is already implemented!
func _complete_death_animation():
    _transport_to_town_on_death()  # Uses SceneTransporter.transition_to_town()
```

## 🎵 Music Integration

The SceneTransporter automatically communicates with the **MusicManager** singleton:

```gdscript
# Crossfade to new music
transporter.transition_with_music(
    "res://scenes/combat/arena.tscn",
    "res://audio/music/Action 3.mp3",
    true  # This will crossfade smoothly
)

# Change music without crossfade
transporter.transition_with_music(
    "res://scenes/peaceful/garden.tscn",
    "res://audio/music/Ambient 2.mp3",
    false  # Abrupt music change
)

# Keep current music playing
transporter.quick_transition("res://scenes/same_area/room2.tscn")
```

## 🔧 Configuration

### Fade Settings

```gdscript
# Adjust fade duration (default: 1.5 seconds)
transporter.set_fade_duration(3.0)

# Change fade color (default: black)
transporter.set_fade_color(Color.WHITE)  # Fade to white
transporter.set_fade_color(Color.BLUE)   # Fade to blue

# Set transition delay (time between fade out and scene change)
transporter.transition_delay = 0.8  # Default is 0.5
```

### Export Variables (Scene Inspector)

When using `SceneTransporter.tscn`, you can configure these in the inspector:

- **fade_duration**: How long the fade takes (1.5s default)
- **fade_color**: Color to fade to (Black default)
- **transition_delay**: Delay before scene change (0.5s default)

## 📡 Signals and Events

Connect to these signals for custom behavior:

```gdscript
func _ready():
    transporter.transition_started.connect(_on_transition_started)
    transporter.fade_out_complete.connect(_on_fade_out_complete)
    transporter.fade_in_complete.connect(_on_fade_in_complete)
    transporter.transition_complete.connect(_on_transition_complete)

func _on_transition_started(target_scene: String):
    print("Going to: ", target_scene)
    # Disable UI, save game state, etc.

func _on_fade_out_complete():
    print("Screen is black - perfect time for cleanup")
    # Save data, cleanup resources, etc.

func _on_fade_in_complete():
    print("Fade in finished - new scene fully visible")

func _on_transition_complete():
    print("Transition completely finished")
    # Re-enable controls, show UI, etc.
```

## 🛠️ Advanced Usage

### Manual Fade Control

```gdscript
# Just fade out (without changing scenes)
await transporter.fade_out()

# Do custom work here while screen is black
perform_heavy_loading()

# Just fade in
await transporter.fade_in()
```

### Auto Fade In

For scenes that need to fade in when they start:

```gdscript
# In your new scene's _ready() function
func _ready():
    var transporter = SceneTransporter.new()
    add_child(transporter)
    transporter.auto_fade_in_on_scene_start()
```

### Preventing Multiple Transitions

```gdscript
if not transporter.is_currently_transitioning():
    transporter.transition_to_town()
else:
    print("Already transitioning!")
```

## 🎮 Integration Examples

### Door/Portal System

```gdscript
# DoorController.gd
extends Area2D

@export var target_scene: String = "res://scenes/town/house_interior.tscn"
@export var door_music: String = ""

@onready var transporter: SceneTransporter = $SceneTransporter

func _on_body_entered(body):
    if body.is_in_group("players"):
        if door_music != "":
            transporter.transition_with_music(target_scene, door_music, true)
        else:
            transporter.quick_transition(target_scene)
```

### Level Completion

```gdscript
# LevelController.gd
func _complete_level():
    level_complete = true
    
    # Transition to next level or campsite
    if level_number < max_levels:
        var next_level = "res://scenes/levels/Level_%d.tscn" % (level_number + 1)
        transporter.transition_with_music(next_level, "res://audio/music/Action 2.mp3")
    else:
        transporter.transition_to_campsite()  # Return to campsite
```

### Menu System

```gdscript
# MainMenu.gd
func _on_start_button_pressed():
    transporter.transition_with_music(
        "res://scenes/main/IntroSequence.tscn",
        "res://audio/music/Ambient 1.mp3",
        true
    )

func _on_quit_button_pressed():
    # Fade out before quitting
    await transporter.fade_out()
    get_tree().quit()
```

## 🚨 Important Notes

### Player Death Behavior

- **Before**: Player death showed a game over screen with restart button
- **After**: Player death automatically transports to town with fade transition
- The old `_show_game_over()` method now redirects to town transport
- Town transition includes appropriate ambient music

### MusicManager Integration

- Requires the **MusicManager** singleton (already exists in your project)
- Crossfading works automatically when MusicManager is available
- Graceful fallback if MusicManager is not found

### Performance

- Fade overlays use high z-index layers to appear on top
- Transitions are prevented from running simultaneously
- Automatic cleanup of tween resources

## 🔄 Migration Guide

If you have existing transition code, here's how to migrate:

### Old Manual Transition Code

```gdscript
# OLD WAY
var tween = create_tween()
tween.tween_property(fade_overlay, "color:a", 1.0, 2.0)
await tween.finished
get_tree().change_scene_to_file("res://scenes/town/town.tscn")
```

### New SceneTransporter Way

```gdscript
# NEW WAY
transporter.transition_to_town()  # That's it!
```

## 🎯 Best Practices

1. **One Transporter Per Scene**: Usually one SceneTransporter per scene is sufficient
2. **Connect Signals Early**: Connect to signals in `_ready()` for reliable event handling
3. **Use Convenience Methods**: Prefer `transition_to_town()` over manual scene paths
4. **Test Transition Times**: Adjust `fade_duration` based on your game's pacing
5. **Handle Edge Cases**: Always check `is_currently_transitioning()` for user-triggered transitions

## 🆘 Troubleshooting

### "No scene transporter available"
- Make sure you've called `_setup_scene_transporter()` in your script
- Check that SceneTransporter.gd is in the correct path

### Music doesn't change
- Verify MusicManager is loaded as a singleton
- Check that your music file paths are correct
- Use crossfade=false if you want immediate music changes

### Fade doesn't appear
- Ensure no other high z-index elements are blocking the fade
- Check that fade_color has proper alpha values
- Verify the CanvasLayer is set up correctly

### Transitions feel too slow/fast
- Adjust `fade_duration` and `transition_delay` values
- Consider different durations for different types of transitions

---

**🎮 Happy transitioning! Your players will love the smooth scene changes!** 