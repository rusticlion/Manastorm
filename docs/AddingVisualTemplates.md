# Adding Visual Templates

This guide walks through the **end-to-end** workflow for adding a new VFX "template" (a _base_ effect definition) and making it available everywhere (runtime, constants, resolver and tests).

---
## 1  Create/extend the template in `vfx.lua`
1.  Open `vfx.lua` and locate the `VFX.effects` table near the top.
2.  Add a new entry, e.g.
   ```lua
   myeffect_base = {
       type          = "myEffectType",  -- projectile / beam / surge / etc.
       duration      = 1.0,
       particleCount = 30,
       startScale    = 0.4,
       endScale      = 0.8,
       color         = Constants.Color.SMOKE,
       -- any extra fields that the effect's logic needs
   }
   ```
3.  If you introduce **new per-template fields** (e.g. `spread`, `height`, `defaultParticleAsset`):
   • Copy them into the effect instance in `VFX.createEffect` (`effect.spread = template.spread`).  
   • Clear them in `VFX.resetEffect` (`effect.spread = nil`).

---
## 2  Add particle initialisation
Inside `VFX.initializeParticles(effect)` insert a new `elseif effect.type == "myEffectType" then ...` branch that **creates particles** and stores them in `effect.particles`.

---
## 3  Add per-frame logic
1.  Implement `VFX.updateMyEffect(effect, dt)` to animate particles and update per-effect state.
2.  Call it from the main dispatcher in `VFX.update`:
   ```lua
   elseif effect.type == "myEffectType" then
       VFX.updateMyEffect(effect, dt)
   ```

---
## 4  Add rendering
1.  Implement `VFX.drawMyEffect(effect)`.
2.  Dispatch it from `VFX.draw` just like the update step.

---
## 5  Expose a constant for the template
Add an identifier in `core/Constants.lua` so other systems can reference it:
```lua
Constants.VFXType.MY_EFFECT_BASE = "myeffect_base"
```

---
## 6  Hook into **VisualResolver** (optional but typical)
1.  Decide how the game should pick the template (by `visualShape`, `attackType`, tags, etc.).
2.  Update `systems/VisualResolver.lua` mapping tables, e.g.:
   ```lua
   TEMPLATE_BY_SHAPE["myShape"] = Constants.VFXType.MY_EFFECT_BASE
   ```

---
## 7  Assets & sounds (if any)
• Add asset paths in `VFX.assetPaths`.  
• If the effect **must** be shown instantly (e.g. shields) preload the asset in `VFX.init()`.  
• Otherwise it will be lazily loaded on first use.

---
## 8  Testing checklist
☑  The game starts with no Lua errors.  
☑  `VisualResolver.test()` prints the expected base template for a crafted event.  
☑  In-game the effect animates, updates and fades out correctly.  
☑  Pool statistics (`VFX.showPoolStats()`) do not leak particles.

---
## 9  Troubleshooting
| Symptom | Common cause |
|---------|--------------|
| Nil-field error inside update/draw | Forgot to copy the field from template in `createEffect()` |
| Effect visible but never removed | Didn't mark `effect.progress` to `1` or forgot `isComplete` flag |
| No visual appears | Asset path typo or `initializeParticles` created **zero** particles |

---
Happy effect hacking! 🎆 