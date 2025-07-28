# 📦 Scene Transporter Box

A physical area that triggers scene transitions when the player walks into it. Perfect for doors, portals, level exits, and area transitions.

## ✨ Features

- **Walk-in Activation**: Automatically triggers when player enters the area
- **Drag-and-Drop Setup**: Drag scene files and music directly into the inspector
- **Visual Representation**: Customizable colored box with optional label
- **One-Shot Option**: Can be configured for single-use (like story transitions)
- **Full SceneTransporter Integration**: Uses the same smooth fade system

## 🚀 Quick Setup

### Method 1: Instance the Pre-built Scene

1. **Instance** `SceneTransporterBox.tscn` in your scene
2. **Position** it where you want the transport trigger
3. **Configure** in the inspector:
   - Drag your target scene into **Target Scene**
   - Drag music file into **Transition Music** (optional)
   - Adjust **Box Size** and **Label Text**

### Method 2: Add to Existing Node

```gdscript
# Add SceneTransporterBox as a child
var transport_box = preload("res://scenes/effects/SceneTransporterBox.tscn").instantiate()
transport_box.position = Vector2(200, 300)
add_child(transport_box)

# Configure via code
transport_box.target_scene_path = "res://scenes/town/town.tscn"
transport_box.label_text = "To Town"
```

## 🎯 Inspector Properties

### 📂 Scene Transition Group
- **Target Scene** (PackedScene): Drag your .tscn file here
- **Target Scene Path** (String): Alternative - type the scene path
- **Transition Music** (AudioStream): Drag your music file here  
- **Crossfade Music** (bool): Smooth music transition vs immediate change

### ⚙️ Transition Settings Group
- **Fade Duration** (float): How long the fade takes (default: 1.5s)
- **Fade Color** (Color): Color to fade to (default: Black)
- **Transition Delay** (float): Pause before scene change (default: 0.5s)
- **One Shot** (bool): Can only be used once (grays out after use)

### 🎨 Visual Settings Group  
- **Box Color** (Color): Color of the transport area (default: semi-transparent blue)
- **Box Size** (Vector2): Width and height of the trigger area (default: 64x64)
- **Show Label** (bool): Display text label on the box
- **Label Text** (String): Text to show (default: "Portal")

## 🎮 Usage Examples

### Simple Door to Another Room

```gdscript
# Just instance SceneTransporterBox.tscn and set in inspector:
# Target Scene: res://scenes/house/bedroom.tscn
# Label Text: "Bedroom"
# Box Size: 32, 80 (door-sized)
```

### Portal with Music Change

```gdscript
# In inspector:
# Target Scene: res://scenes/dungeon/level_1.tscn  
# Transition Music: res://audio/music/Dark Ambient 1.mp3
# Crossfade Music: true
# Label Text: "Enter Dungeon"
# Box Color: Dark red with transparency
```

### One-Shot Story Transition

```gdscript
# In inspector:
# Target Scene: res://scenes/cutscenes/ending.tscn
# One Shot: true
# Label Text: "The End?"
# Box Color: Golden/yellow
```

### Code-Based Setup

```gdscript
# Create and configure via code
@onready var exit_portal = $SceneTransporterBox

func _ready():
    # Set target
    exit_portal.set_target_scene_by_path("res://scenes/overworld/forest.tscn")
    
    # Set music
    exit_portal.set_transition_music_by_path("res://audio/music/Ambient 2.mp3")
    
    # Configure visuals
    exit_portal.label_text = "Exit to Forest"
    exit_portal.box_color = Color.GREEN
    exit_portal.update_visual_settings()
    
    # Connect to signals
    exit_portal.player_entered.connect(_on_player_entered_portal)
    exit_portal.transport_triggered.connect(_on_transport_started)

func _on_player_entered_portal():
    print("Player is entering the forest portal!")

func _on_transport_started(target_scene: String):
    print("Transporting to: ", target_scene)
```

## 📡 Signals

Connect to these signals for custom behavior:

```gdscript
func _ready():
    $SceneTransporterBox.player_entered.connect(_on_player_entered)
    $SceneTransporterBox.player_exited.connect(_on_player_exited)
    $SceneTransporterBox.transport_triggered.connect(_on_transport_triggered)

func _on_player_entered():
    print("Player stepped into transport area")
    # Play sound effect, show UI prompt, etc.

func _on_player_exited():
    print("Player left transport area")
    # Hide UI prompt, stop sound effects, etc.

func _on_transport_triggered(target_scene: String):
    print("Starting transport to: ", target_scene)
    # Save game state, show loading message, etc.
```

## 🎨 Visual Customization

### Custom Appearance

```gdscript
# Make it look like a magic portal
transport_box.box_color = Color(0.8, 0.2, 1.0, 0.5)  # Purple with transparency
transport_box.label_text = "✨ Magic Portal ✨"
transport_box.box_size = Vector2(80, 80)

# Make it look like a door
transport_box.box_color = Color(0.6, 0.3, 0.1, 0.3)  # Brown/wood color
transport_box.label_text = "Door"
transport_box.box_size = Vector2(32, 64)

# Make it invisible (for secret passages)
transport_box.box_color = Color.TRANSPARENT
transport_box.show_label = false
```

### Dynamic Visual Updates

```gdscript
# Update visuals at runtime
func make_portal_active():
    transport_box.box_color = Color.CYAN
    transport_box.label_text = "Active Portal"
    transport_box.update_visual_settings()

func make_portal_inactive():
    transport_box.box_color = Color.GRAY
    transport_box.label_text = "Inactive"
    transport_box.update_visual_settings()
```

## 🔧 Advanced Features

### Conditional Transport

```gdscript
extends SceneTransporterBox

# Override the trigger method for custom conditions
func _trigger_transport(player_body):
    # Check if player has key
    if not player_body.has_key("dungeon_key"):
        print("🔒 Door is locked! Need dungeon key.")
        return
    
    # Check player level
    if player_body.level < 5:
        print("⚠️ You need to be level 5 to enter!")
        return
    
    # All conditions met - proceed with transport
    super._trigger_transport(player_body)
```

### Progressive Unlocking

```gdscript
# Unlock different scenes based on game progress
func update_destination_based_on_progress():
    var progress = GameManager.get_story_progress()
    
    match progress:
        0, 1, 2:
            set_target_scene_by_path("res://scenes/tutorial/safe_area.tscn")
            label_text = "Training Grounds"
        3, 4, 5:
            set_target_scene_by_path("res://scenes/dungeon/level_1.tscn")
            label_text = "Dungeon Entrance"
        _:
            set_target_scene_by_path("res://scenes/endgame/final_area.tscn")
            label_text = "Final Challenge"
    
    update_visual_settings()
```

### Multiple Destinations

```gdscript
# Cycle through different destinations
var destinations = [
    "res://scenes/town/town.tscn",
    "res://scenes/forest/forest.tscn", 
    "res://scenes/mountain/mountain.tscn"
]
var current_destination = 0

func _on_special_key_pressed():
    current_destination = (current_destination + 1) % destinations.size()
    set_target_scene_by_path(destinations[current_destination])
    label_text = "Portal: %d/3" % (current_destination + 1)
    update_visual_settings()
```

## 🛠️ Integration with Existing Systems

### With Save System

```gdscript
# Save which transporters have been used
func _trigger_transport(player_body):
    super._trigger_transport(player_body)
    
    # Mark this transporter as used in save data
    SaveManager.mark_transporter_used(get_path())

func _ready():
    super._ready()
    
    # Check if this transporter was already used
    if SaveManager.is_transporter_used(get_path()) and one_shot:
        is_used = true
        _disable_visual_feedback()
```

### With Dialogue System

```gdscript
# Show dialogue before transport
func _trigger_transport(player_body):
    if not has_shown_dialogue:
        DialogueManager.start_dialogue("portal_warning")
        DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
        has_shown_dialogue = true
    else:
        super._trigger_transport(player_body)

func _on_dialogue_finished():
    # Now proceed with transport
    super._trigger_transport(get_tree().get_first_node_in_group("players"))
```

## 🎯 Best Practices

1. **Clear Visual Feedback**: Make transport areas visually distinct so players know they're interactive
2. **Appropriate Sizing**: Match box size to the visual element (door, portal, etc.)
3. **Consistent Labeling**: Use clear, descriptive labels for where the transport leads
4. **Sound Integration**: Connect to signals to play sound effects on entry/exit
5. **Performance**: Use one-shot for story moments to prevent backtracking issues

## 🚨 Important Notes

### Player Group Required
- Transport boxes only trigger for bodies in the "players" group
- Make sure your player CharacterBody2D is added to the "players" group

### Scene Path Validation
- The system validates scene paths before transport
- Invalid paths will log errors and prevent transport
- Use the `_validate_setup()` method for debugging

### Music Integration
- Requires the MusicManager singleton (already in your project)
- Music files must be properly imported as AudioStream resources
- Crossfading works best with looping background music

## 🆘 Troubleshooting

### Transport doesn't trigger
- Check player is in "players" group
- Verify collision detection is working (player has collision body)
- Check console for "Player entered transport box" messages

### "No target scene set" error
- Make sure either Target Scene or Target Scene Path is set in inspector
- Verify scene file exists at the specified path

### Music doesn't change
- Check that Transition Music is set to an AudioStream resource
- Verify MusicManager singleton is loaded
- Try setting Crossfade Music to false for immediate changes

### Visual box doesn't appear
- Check that Box Color has some alpha (transparency) value
- Verify Box Size is not zero
- Make sure the transport box isn't behind other visual elements

---

**🎮 Perfect for creating seamless world navigation! Just drop, configure, and go!** 