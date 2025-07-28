# Player UI System

## Overview
This document describes the comprehensive Player UI system that provides real-time feedback for health, abilities, and currency in the game.

## Components

### 1. Health Bar (Top Left)
- **Location**: Top left corner of the screen
- **Style**: White/transparent bar with smooth animations
- **Features**:
  - Animated health changes with smooth tweening
  - Color coding: White (>70%), Orange (30-70%), Red (<30%)
  - Flash effect when taking damage
  - No numbers displayed for clean aesthetic

### 2. Ability Icons (Bottom Left)
- **Location**: Bottom left corner in horizontal layout
- **Features**:
  - Uses frame 9 from Special1.png and Special2.png sprites
  - Real-time cooldown indicators with vertical progress bars
  - Grey overlay when on cooldown
  - Countdown timer display
  - Key bindings displayed (Q and R)
  - Pulse animation when abilities are used

### 3. Shadow Essence Currency (Bottom Right)
- **Location**: Bottom right corner of the screen
- **Features**:
  - Displays current shadow essence amount
  - Animated updates with scale pulse effect
  - Purple-themed icon and styling
  - Ready for integration with game economy

## Technical Implementation

### Files Structure
```
scenes/player/PlayerUI.tscn       # UI scene with all elements
systems/player/PlayerUI.gd        # UI controller script
systems/player/PlayerController.gd # Player integration
```

### Key Classes

#### PlayerUI (CanvasLayer)
- Manages all UI elements and animations
- Updates health bar, ability cooldowns, and currency
- Provides visual effects (flash, pulse, etc.)

#### PlayerController Integration
- Connects player events to UI updates
- Provides shadow essence management functions
- Triggers UI effects for damage and abilities

## Usage

### Shadow Essence System
```gdscript
# Add shadow essence
player.add_shadow_essence(10)

# Spend shadow essence (returns bool for success)
if player.spend_shadow_essence(5):
    print("Purchase successful!")

# Check current amount
var current = player.get_shadow_essence()
```

## Integration

The UI automatically connects to the player systems:
1. Health bar updates from `player.current_health`
2. Ability cooldowns track `player.q_ability_cooldown_timer` and `player.r_ability_cooldown_timer`
3. Shadow essence is managed independently in the UI system

## Styling

The UI uses a consistent dark theme with:
- Semi-transparent backgrounds (0.6 alpha)
- Rounded corners (8px radius)
- White/grey text with shadows
- Smooth animations for all interactions

## Future Enhancements

Potential additions:
- Mana/energy system
- Status effect indicators
- Inventory hotbar
- Minimap integration
- Combat feedback numbers 