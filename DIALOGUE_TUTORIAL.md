# Dialogue System Tutorial

## Overview

This tutorial will teach you how to create new dialogues and unlock them programmatically using the existing dialogue system. The system is built around a base `DialogueSystem` class that handles all the core functionality.

## Table of Contents

1. [Creating a New NPC with Dialogues](#creating-a-new-npc-with-dialogues)
2. [Adding Dialogues to Existing NPCs](#adding-dialogues-to-existing-npcs)
3. [Unlocking Dialogues via Code](#unlocking-dialogues-via-code)
4. [Advanced Dialogue Management](#advanced-dialogue-management)
5. [Best Practices](#best-practices)

---

## Creating a New NPC with Dialogues

### Step 1: Create the NPC Script

Create a new script that extends `DialogueSystem`:

```gdscript
# systems/NPCs/MyNPC.gd
extends DialogueSystem
class_name MyNPC

func _ready():
    # Set basic NPC info
    character_name = "MyNPC"
    interaction_prompt = "Press E to talk to MyNPC"
    interaction_range = 100.0
    
    # Call parent initialization
    super._ready()
    
    print("🎭 MyNPC initialized")

func _initialize_dialogues():
    """Set up this NPC's dialogues"""
    
    # Dialogue 1: Introduction
    add_dialogue("introduction", [
        "Hello there, traveler!",
        "I'm MyNPC, and I have stories to tell.",
        "Come back when you're ready for more."
    ])
    
    # Dialogue 2: Second conversation  
    add_dialogue("second_meeting", [
        "You've returned! Excellent.",
        "I have more wisdom to share.",
        "Your journey is just beginning."
    ])
    
    # Dialogue 3: Final conversation
    add_dialogue("farewell", [
        "This is our final conversation.",
        "You've learned all I can teach.",
        "Go forth and be victorious!"
    ])
    
    print("💬 MyNPC dialogues initialized with ", dialogues.size(), " conversations")
```

### Step 2: Create the NPC Scene

1. Create a new scene: `scenes/NPCs/MyNPC.tscn`
2. Set up the scene structure:

```
MyNPC (Node2D) [with MyNPC.gd script]
├── AnimatedSprite2D
├── InteractionArea (Area2D)
│   └── CollisionShape2D
└── NameLabel (Label)
```

### Step 3: Configure the Scene

```gdscript
# In the .tscn file (or via editor):
[node name="MyNPC" type="Node2D"]
script = ExtResource("path/to/MyNPC.gd")

[node name="NameLabel" type="Label" parent="."]
text = "MyNPC"
```

---

## Adding Dialogues to Existing NPCs

### Adding to Carl

To add new dialogues to Carl, edit `systems/NPCs/Carl.gd`:

```gdscript
func _initialize_dialogues():
    # ... existing dialogues ...
    
    # Add new dialogue
    add_dialogue("special_event", [
        "Something extraordinary has happened!",
        "The stars align in your favor.",
        "This changes everything we know."
    ])
```

### Adding to Ego

To add new dialogues to Ego, edit `systems/NPCs/Ego.gd`:

```gdscript
func _initialize_dialogues():
    # ... existing dialogues ...
    
    # Add new competitive dialogue
    add_dialogue("ultimate_challenge", [
        "Now THIS is what I'm talking about!",
        "You're ready for the ultimate test.",
        "Show them what a REAL champion looks like!"
    ])
```

---

## Unlocking Dialogues via Code

### Method 1: Direct Unlocking

```gdscript
# Get reference to the NPC
var carl = get_node("Carl")  # or however you access the NPC

# Unlock next dialogue in sequence
carl._unlock_dialogue(carl.dialogue_progress["completed_dialogues"].size())

# Or unlock a specific dialogue by index
carl._unlock_dialogue(2)  # Unlock the 3rd dialogue (0-indexed)
```

### Method 2: Using Custom Trigger Methods

For NPCs with custom progression methods:

```gdscript
# For Carl
var carl = get_node("Carl")
carl.on_first_dungeon_entered()  # Unlocks next story chapter
carl.trigger_next_story_chapter()  # Manual progression

# For Ego  
var ego = get_node("Ego")
ego.on_first_victory()  # Unlocks next dialogue stage
ego.trigger_ego_boost()  # Manual progression
```

### Method 3: Event-Based Unlocking

```gdscript
# In your game controller or event system
func on_player_level_up():
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        if npc.character_name == "Carl":
            npc.trigger_next_story_chapter()
        elif npc.character_name == "Ego":
            npc.trigger_ego_boost()

func on_boss_defeated():
    # Unlock special dialogue for all NPCs
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        # Add a new dialogue dynamically
        npc.add_dialogue("boss_victory", [
            "Incredible! You defeated the boss!",
            "Your power has grown tremendously.",
            "What will you do next?"
        ])
        
        # Unlock it immediately
        var dialogue_index = npc.dialogues.size() - 1
        npc._unlock_dialogue(dialogue_index)
```

### Method 4: Conditional Unlocking

```gdscript
# Create a system that checks conditions
func check_dialogue_conditions():
    var player_level = PlayerData.get_level()
    var quests_completed = PlayerData.get_completed_quests()
    
    # Unlock Carl's special dialogue at level 10
    if player_level >= 10:
        var carl = get_node("Carl")
        if not carl.is_story_complete():
            carl.trigger_next_story_chapter()
    
    # Unlock Ego's dialogue after completing 5 quests
    if quests_completed >= 5:
        var ego = get_node("Ego")
        if not ego.is_ego_humbled():
            ego.trigger_ego_boost()
```

---

## Advanced Dialogue Management

### Creating Dynamic Dialogues

```gdscript
# Add dialogues based on game state
func create_dynamic_dialogue(npc: DialogueSystem, player_data: Dictionary):
    var dialogue_lines = []
    
    if player_data.has("high_score"):
        dialogue_lines.append("I heard about your incredible score!")
    
    if player_data.has("secret_found"):
        dialogue_lines.append("You found the secret, didn't you?")
    
    dialogue_lines.append("You're full of surprises.")
    
    # Add the dynamic dialogue
    npc.add_dialogue("dynamic_response", dialogue_lines)
    
    # Unlock it immediately
    var dialogue_index = npc.dialogues.size() - 1
    npc._unlock_dialogue(dialogue_index)
```

### Dialogue Chains and Dependencies

```gdscript
# Create dialogues that depend on others being completed
func setup_dialogue_chain(npc: DialogueSystem):
    # Check if previous dialogue was completed
    if "introduction" in npc.dialogue_progress["completed_dialogues"]:
        # Unlock the next dialogue
        npc.add_dialogue("followup", [
            "Since we've met before...",
            "I can tell you something important.",
            "Trust is earned through conversation."
        ])
        
        var dialogue_index = npc.dialogues.size() - 1
        npc._unlock_dialogue(dialogue_index)
```

### Time-Based Unlocking

```gdscript
# Unlock dialogues after certain time periods
func setup_timed_dialogues():
    # Create a timer
    var timer = Timer.new()
    timer.wait_time = 300.0  # 5 minutes
    timer.one_shot = true
    add_child(timer)
    
    # Connect to unlock dialogue
    timer.timeout.connect(_on_timed_unlock)
    timer.start()

func _on_timed_unlock():
    var carl = get_node("Carl")
    carl.add_dialogue("time_passed", [
        "Time has passed since we last spoke.",
        "The world has changed around us.",
        "Are you ready for what comes next?"
    ])
    
    var dialogue_index = carl.dialogues.size() - 1
    carl._unlock_dialogue(dialogue_index)
```

---

## Best Practices

### 1. Dialogue Organization

```gdscript
# Keep dialogue IDs descriptive and organized
add_dialogue("ch1_introduction", [...])
add_dialogue("ch1_tutorial", [...])
add_dialogue("ch2_revelation", [...])
add_dialogue("ch2_conflict", [...])
```

### 2. Error Handling

```gdscript
# Always check if NPC exists before unlocking
func unlock_dialogue_safely(npc_name: String, dialogue_index: int):
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        if npc.character_name == npc_name:
            if dialogue_index < npc.dialogues.size():
                npc._unlock_dialogue(dialogue_index)
                print("✅ Unlocked dialogue ", dialogue_index, " for ", npc_name)
            else:
                print("⚠️ Dialogue index out of range for ", npc_name)
            return
    
    print("❌ NPC not found: ", npc_name)
```

### 3. Save System Integration

```gdscript
# Save dialogue progress
func save_dialogue_progress():
    var save_data = {}
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        save_data[npc.character_name] = npc.dialogue_progress
    
    # Save to file...
    return save_data

# Load dialogue progress
func load_dialogue_progress(save_data: Dictionary):
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        if save_data.has(npc.character_name):
            npc.dialogue_progress = save_data[npc.character_name]
```

### 4. Debugging Dialogues

```gdscript
# Add debug commands for testing
func _input(event):
    if OS.is_debug_build():
        if event.is_action_pressed("debug_unlock_all_dialogues"):
            unlock_all_dialogues()

func unlock_all_dialogues():
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        for i in range(npc.dialogues.size()):
            npc._unlock_dialogue(i)
        print("🔓 Unlocked all dialogues for ", npc.character_name)
```

---

## Quick Reference

### Essential Methods

```gdscript
# DialogueSystem methods you'll use most:
npc.add_dialogue(id: String, lines: Array)      # Add new dialogue
npc._unlock_dialogue(index: int)                # Unlock dialogue by index
npc.dialogue_progress["completed_dialogues"]   # Get completed dialogues
npc.dialogue_progress["unlocked_dialogues"]    # Get available dialogues
npc.dialogues.size()                           # Get total dialogue count

# Custom NPC methods (if implemented):
carl.trigger_next_story_chapter()              # Advance Carl's story
ego.trigger_ego_boost()                        # Advance Ego's development
```

### Example: Complete Dialogue Unlock System

```gdscript
# systems/DialogueController.gd
extends Node

func _ready():
    # Connect to game events
    GameEvents.level_up.connect(_on_level_up)
    GameEvents.boss_defeated.connect(_on_boss_defeated)
    GameEvents.secret_found.connect(_on_secret_found)

func _on_level_up(new_level: int):
    if new_level == 5:
        unlock_dialogue_for_npc("Carl", "ch2_power_growth")
    elif new_level == 10:
        unlock_dialogue_for_npc("Ego", "recognition_of_strength")

func _on_boss_defeated(boss_name: String):
    unlock_dialogue_for_npc("Carl", "victory_wisdom")
    unlock_dialogue_for_npc("Ego", "triumphant_boasting")

func unlock_dialogue_for_npc(npc_name: String, dialogue_id: String):
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        if npc.character_name == npc_name:
            # Find dialogue index by ID
            var keys = npc.dialogues.keys()
            var index = keys.find(dialogue_id)
            
            if index != -1:
                npc._unlock_dialogue(index)
                print("✨ Unlocked '", dialogue_id, "' for ", npc_name)
```

This tutorial should give you everything you need to create and manage dialogues in your system! The key is understanding that dialogues are stored in arrays, unlocked by index, and can be triggered by any game event you choose to connect to the system. 