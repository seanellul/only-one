# Game Design Document
## Project: Dungeon Town (Working Title)

### **Core Game Loop**
1. **Town Hub** → Explore shops, upgrade equipment, interact with NPCs
2. **Dungeon Dive** → Enter procedurally generated dungeons for loot/combat
3. **Return & Upgrade** → Use collected resources to improve stats/equipment
4. **Repeat** → Progressively harder dungeons, better rewards

---

## **Core Systems**

### **1. Player System**
#### **Movement & Controls**
- ✅ **8-directional movement** (WASD/Arrow keys)
- ✅ **Mouse-facing rotation** (player sprite always faces cursor)
- ✅ **New sprite animations** (idle, walk, attack for 8 directions)
- 🔄 **Dash ability** (short-range teleport on cooldown)

#### **Combat**
- ✅ **Mouse-direction attacks** (swing/projectile toward cursor)
- ✅ **Attack animations** (directional attack sprites)
- 🔄 **Hit detection** (area-based or raycast)
- 🔄 **Attack timing** (wind-up, active frames, recovery)
- 🔄 **Weapon variety** (swords, bows, magic - different attack patterns)

#### **Stats & Progression**
- ✅ **Health system** (current/max HP - boosted by armor)
- ✅ **Damage system** (base attack power - boosted by weapons)
- ✅ **Equipment-only progression** (NO XP/levels - pure gear upgrades)
- ✅ **Gold economy** (earn gold → buy better gear → tackle harder portals)

### **2. World Systems**

#### **Town (Static)**
- ✅ **Hand-designed layout** (detailed, artistic, functional)
- ✅ **Shop buildings** (weapon, armor, potion, magic shops)
- ✅ **NPCs & interactions** (shopkeepers, quest givers)
- ✅ **Central hub design** (fountain transforms to final portal)
- ✅ **Portal layout** (4 dungeon portals around town perimeter)
- 🔄 **Save points/beds** (rest areas for saving)

#### **Dungeons (Procedural)**
- ✅ **4 Main Portals** (each with unique difficulty scaling)
- ✅ **Room-based generation** (connected chambers)
- ✅ **Enemy spawning** (increasing difficulty per portal)
- ✅ **Loot placement** (gold, equipment, consumables)
- ✅ **Portal completion** (clear entire dungeon to mark as complete)
- 🔄 **Boss rooms** (end-of-dungeon challenges)
- 🔄 **Environmental hazards** (traps, puzzles)
- 🔄 **Theme variety** (forest, cave, ruins, etc.)

#### **World Transitions**
- ✅ **Portal system** (town ↔ dungeon entry/exit)
- ✅ **Progressive unlock** (final portal unlocks after 4 main portals)
- ✅ **Fountain transformation** (center fountain → final boss portal)
- 🔄 **Loading screens** (with tips/lore)
- 🔄 **Portal visual states** (locked, unlocked, completed)

### **3. Item & Inventory System**

#### **Equipment**
- ✅ **Weapon slots** (primary weapon - damage upgrades)
- ✅ **Armor slots** (health boost items only)
- ✅ **Stat bonuses** (weapons = damage, armor = max HP)
- ✅ **Gold-based progression** (buy better equipment with earned gold)

#### **Consumables**
- ✅ **Health potions** (instant healing)
- 🔄 **Buff potions** (temporary stat boosts)
- 🔄 **Utility items** (keys, tools, quest items)

#### **Inventory UI**
- ✅ **Grid-based slots** (visual item representation)
- ✅ **Drag & drop** (equip/unequip items)
- ✅ **Context menus** (use, drop, examine)
- ✅ **Stats panel** (current/equipped stats display)
- 🔄 **Item tooltips** (detailed descriptions)
- 🔄 **Sorting options** (type, value, alphabetical)

### **4. Combat System**

#### **Core Mechanics**
- ✅ **Real-time combat** (action-based, not turn-based)
- ✅ **Directional attacks** (player faces mouse, attacks toward cursor)
- ✅ **Hit feedback** (screen shake, particles, sound)
- 🔄 **Dodge/block mechanics** (defensive options)

#### **Visual Polish**
- ✅ **Blood/particles** (hit effects, damage feedback)
- ✅ **Floating damage numbers** (visual damage confirmation)
- ✅ **Screen effects** (flash on hit, screen shake)
- 🔄 **Attack trails** (weapon swing animations)

#### **Enemy AI**
- 🔄 **Basic pursuit** (move toward player)
- 🔄 **Attack patterns** (melee, ranged, special abilities)
- 🔄 **Difficulty scaling** (stats increase with dungeon depth)

### **5. Save/Load System**
- ✅ **JSON-based saves** (human-readable, debuggable)
- ✅ **Player state** (position, stats, inventory, equipment)
- ✅ **World state** (portal completion status, current progress)
- ✅ **Permadeath mechanics** (save deletion on player death)
- ✅ **Settings persistence** (audio, controls, display - separate from save)
- ✅ **One life per game** (no respawning, complete restart required)

### **6. Console System**
- ✅ **Debug commands** (teleport, give items, god mode)
- ✅ **Cheat codes** (for testing and fun)
- ✅ **System info** (FPS, memory, game state)
- 🔄 **Mod support** (custom commands)

---

## **UI/UX Systems**

### **Menus**
- ✅ **Main Menu** (New Game, Continue, Settings, Quit)
- ✅ **Pause Menu** (Resume, Settings, Save & Quit)
- ✅ **Settings Menu** (Audio, Controls, Display)
- 🔄 **Game Over Screen** (Retry, Main Menu)

### **HUD Elements**
- ✅ **Health Bar** (visual HP indicator)
- ✅ **Inventory Hotbar** (quick-use consumables)
- 🔄 **Minimap** (dungeon navigation aid)
- 🔄 **Objective/Quest tracker** (current goals)

### **Dialogue & Cutscenes**
- ✅ **Shop interfaces** (buy/sell with pricing)
- ✅ **NPC dialogue** (conversation trees)
- ✅ **Cutscene system** (intro, story moments)
- 🔄 **Better styling** (fonts, animations, backgrounds)

---

## **Technical Architecture**

### **Scene Organization**
```
scenes/
├── player/          # Player movement, combat, stats
├── world/           # Town design, dungeon generation
├── ui/              # All menus and HUD elements
├── enemies/         # Enemy types and AI
├── items/           # Weapons, armor, consumables
└── systems/         # Core autoloads only
```

### **Autoload Structure** (Maximum 4)
1. **GameManager** - Scene transitions, game state
2. **SaveSystem** - Save/load functionality
3. **AudioManager** - Music and sound effects
4. **InventorySystem** - Item management

### **Key Principles**
- ✅ **Core-first development** (gameplay before polish)
- ✅ **One system at a time** (fully test before adding more)
- ✅ **Simple architecture** (avoid over-engineering)
- ✅ **Player-focused design** (fun first, features second)

---

## **Core Game Progression**

### **Portal System & Win Condition**
1. **Town Layout**: 4 dungeon portals positioned around town perimeter
2. **Fountain Center**: Initial decorative fountain in town center
3. **Portal Progression**: Player must complete all 4 main portals
4. **Fountain Transformation**: Once all 4 portals completed → fountain transforms into final portal
5. **Final Boss**: Enter final portal → face final boss → victory!
6. **Permadeath**: Die anywhere → save deleted → restart entire game

### **Difficulty Scaling**
- **Portal 1**: Easiest enemies, basic loot, low gold rewards
- **Portal 2**: Moderate difficulty, better equipment available in shops
- **Portal 3**: Hard enemies, require good equipment to survive
- **Portal 4**: Very hard, need best available gear
- **Final Portal**: Ultimate challenge, requires completion of all 4 + best equipment

### **Economy Flow**
1. **Start**: Basic equipment, minimal gold
2. **Portal 1**: Earn gold → buy better weapon/armor
3. **Portal 2**: More gold → upgrade equipment further
4. **Portal 3**: Significant gold → buy high-tier gear
5. **Portal 4**: Maximum preparation for final boss
6. **Final Portal**: No return - win or restart!

### **Permadeath Design Implications**
- **High Stakes**: Every decision matters - no second chances
- **Careful Progression**: Players must balance risk vs reward
- **Equipment Investment**: Gold spending becomes strategic
- **Tension**: Combat is genuinely dangerous throughout
- **Replay Value**: Each run feels unique and meaningful
- **Save Separation**: Game settings persist, but character progress doesn't

---

## **Missing Elements** (Consider Adding)

### **Audio System**
- 🔄 **Dynamic music** (town vs dungeon vs combat tracks)
- 🔄 **Sound effects** (attacks, footsteps, item pickup)
- 🔄 **Ambient audio** (atmosphere for different areas)

### **Game Flow**
- ✅ **Win condition** (final boss after completing 4 portals)
- ✅ **Difficulty progression** (each portal harder than previous)
- ✅ **Death system** (permadeath - save deletion, restart game)
- 🔄 **Portal progression** (unlock final boss portal in center)

### **Polish Features**
- 🔄 **Camera system** (smooth following, screen boundaries)
- 🔄 **Lighting effects** (torches, magic, atmosphere)
- 🔄 **Particle systems** (magic effects, environmental)

### **Quality of Life**
- 🔄 **Key bindings** (customizable controls)
- 🔄 **Accessibility** (colorblind support, text scaling)
- 🔄 **Performance optimization** (object pooling, LOD)

---

## **Development Phases**

### **Phase 1: Core Gameplay** (First Priority)
1. Player movement + mouse-facing + 8-directional sprites
2. Basic combat + directional attacks toward mouse
3. Simple dungeon generation + portal system
4. Basic inventory + equipment slots

### **Phase 2: Systems Integration** (Second Priority)
1. Shop system + NPC interactions + gold economy
2. Save/load implementation + permadeath mechanics
3. Enemy AI + combat balance
4. Portal progression + final boss unlock

### **Phase 3: Content & Polish** (Third Priority)
1. Hand-designed town layout + visual polish
2. Audio implementation + dynamic music
3. Combat feedback + particles + screen shake
4. UI polish + animations

### **Phase 4: Final Features** (Fourth Priority)
1. Cutscene improvements + better styling
2. Console commands + debug features
3. Final boss implementation + win conditions
4. Performance optimization + bug fixing

---

**Legend:**
- ✅ Confirmed requirements (from your summary)
- 🔄 Suggested additions
- 📋 Implementation notes 