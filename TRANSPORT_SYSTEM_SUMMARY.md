# 🚪 Complete Scene Transport System

## What's Been Created

### 1. **SceneTransporter** (Original System)
- **File**: `systems/main/SceneTransporter.gd`
- **Scene**: `scenes/effects/SceneTransporter.tscn`
- **Purpose**: Programmatic scene transitions with fade effects
- **Best For**: Code-triggered transitions, death handling, menu systems

### 2. **SceneTransporterBox** (NEW - Physical Box)
- **File**: `systems/main/SceneTransporterBox.gd`
- **Scene**: `scenes/effects/SceneTransporterBox.tscn`
- **Purpose**: Physical areas that trigger when player walks in
- **Best For**: Doors, portals, level exits, interactive transport

## 🎯 Quick Usage Guide

### For Physical Transport Areas (Most Common)

1. **Instance** `SceneTransporterBox.tscn` in your scene
2. **Position** it where you want the trigger
3. **In Inspector**:
   - **Drag** your target `.tscn` file into "Target Scene"
   - **Drag** music file into "Transition Music" (optional)
   - **Set** "Label Text" (what players see)
   - **Adjust** "Box Size" to fit your area

**That's it!** When player walks into the box, smooth transition happens.

### For Code-Triggered Transitions

```gdscript
# Create transporter
var transporter = SceneTransporter.new()
add_child(transporter)

# Use it
transporter.transition_to_town()
transporter.transition_with_music("res://scenes/level1.tscn", "res://audio/action.mp3")
```

## 📦 SceneTransporterBox Inspector Properties

### **Scene Transition** Group
- **Target Scene**: Drag your .tscn file here 📂
- **Target Scene Path**: Alternative text path
- **Transition Music**: Drag music file here 🎵  
- **Crossfade Music**: Smooth vs immediate music change

### **Visual Settings** Group
- **Box Color**: Color of the transport area
- **Box Size**: Width/height of trigger area
- **Label Text**: Text displayed on box
- **Show Label**: Show/hide the text

### **Transition Settings** Group
- **Fade Duration**: How long fade takes (1.5s default)
- **Fade Color**: Color to fade to (Black default)
- **One Shot**: Can only be used once

## 🎮 Example Setups

### Door to Another Room
```
Target Scene: res://scenes/house/bedroom.tscn
Label Text: "Bedroom"
Box Size: 32, 64 (tall and narrow)
Box Color: Brown/wood color
```

### Magic Portal
```
Target Scene: res://scenes/dungeon/level_1.tscn
Transition Music: res://audio/music/Dark Ambient 1.mp3
Label Text: "Enter Dungeon"
Box Color: Purple with transparency
Crossfade Music: true
```

### One-Time Story Exit
```
Target Scene: res://scenes/main/MainMenu.tscn
Label Text: "The End"
One Shot: true
Box Color: Golden
```

## 🔧 Advanced Features

### Conditional Transport
```gdscript
extends SceneTransporterBox

func _trigger_transport(player_body):
    if player_body.has_key("magic_key"):
        super._trigger_transport(player_body)
    else:
        print("🔒 Locked! Need magic key.")
```

### Dynamic Destinations
```gdscript
func update_portal_destination():
    if player.level >= 10:
        set_target_scene_by_path("res://scenes/advanced_area.tscn")
        label_text = "Advanced Area"
    else:
        set_target_scene_by_path("res://scenes/beginner_area.tscn")
        label_text = "Training Ground"
    update_visual_settings()
```

## 🎵 Music Integration

Both systems work with your existing **MusicManager**:

- **Crossfade**: Smooth transition between tracks
- **Immediate**: Instant music change
- **None**: Keep current music playing

## 💀 Player Death System

**Modified Behavior**:
- **Before**: Game over screen with restart button
- **After**: Smooth fade transition to town.tscn
- **Automatic**: Uses SceneTransporter internally

## 📁 File Locations

```
📁 systems/main/
  ├── SceneTransporter.gd          # Core transition system
  ├── SceneTransporterBox.gd       # Physical transport areas
  └── SceneTransporterExample.gd   # Usage examples

📁 scenes/effects/
  ├── SceneTransporter.tscn        # Ready-to-use transporter
  ├── SceneTransporterBox.tscn     # Ready-to-use transport box
  └── TransportBoxExample.tscn     # Demo scene with examples

📁 Documentation/
  ├── SCENE_TRANSPORTER_README.md     # Original system docs
  ├── SCENE_TRANSPORTER_BOX_README.md # Box system docs
  └── TRANSPORT_SYSTEM_SUMMARY.md     # This file
```

## 🚀 Getting Started

### For Most Use Cases (Doors, Portals, Exits):
1. Use `SceneTransporterBox.tscn`
2. Drag & drop in inspector
3. Done!

### For Custom Code Logic:
1. Use `SceneTransporter.gd`
2. Call methods like `transition_to_town()`
3. Full control in code

---

**🎮 Both systems work together perfectly! Use boxes for world navigation and code for special events.** 