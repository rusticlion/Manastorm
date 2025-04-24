~Below is a lightweight retrofit that keeps the whole defence pipeline 
“pure-events” while giving every shield an optional on-block hook you can 
stuff with whatever effects you like. I broke it into four surgical 
commits so you can cherry-pick.

1 · Keyword side – let block carry an onBlock payload
Add one line to the Keywords.block.execute builder so the event that 
reaches the runner brings the callback along:

lua
Copy
Edit
-- keywords.lua  (inside Keywords.block.execute)
table.insert(events or {}, {
    type               = "CREATE_SHIELD",
    source             = "caster",
    target             = "self_slot",
    slotIndex          = results.currentSlot,
    defenseType        = params.type   or "barrier",
    blocksAttackTypes  = params.blocks or {"projectile"},
    reflect            = params.reflect or false,
    onBlock            = params.onBlock        -- ★ new
})
​

Nothing else in the keyword layer changes; if a spell doesn’t specify 
onBlock, the field is simply nil.

2 · Runner side – pass that payload straight through
EventRunner is already handing onBlock through to 
ShieldSystem.createShield; the field is copied verbatim, so no edits 
needed there.​​

3 · Shield system – actually fire the hook
Right after tokens are consumed in handleShieldBlock, drop in a small 
trampoline:

lua
Copy
Edit
-- ShieldSystem.lua  (end of handleShieldBlock)
-------------------------------------------------
-- existing VFX code here …

-- ✦ NEW: trigger on-block effects
if slot.onBlock then
    local EventRunner = require("systems.EventRunner")
    local ok, blockEvents = pcall(slot.onBlock,
                                  wizard,          -- defender (owner of 
the shield)
                                  incomingSpell and incomingSpell.caster, 
-- attacker (may be nil)
                                  slotIndex,
                                  { blockType = slot.defenseType })
    if ok and type(blockEvents) == "table" and #blockEvents > 0 then
        EventRunner.processEvents(blockEvents, wizard, incomingSpell and 
incomingSpell.caster, slotIndex)
    end
end
-------------------------------------------------
return true
​

A few notes:

Signature – I pass (defender, attacker, slotIndex, ctxTable) so custom 
hooks have everything they usually need.

Return value – an array of already-formed events keeps the handler 
decoupled from game state.

4 · Spell definition – move Elevate into the hook
Finally, rewrite Wings of Moonlight so the shield itself decides when to 
lift you:

lua
Copy
Edit
-- spells.lua
Spells.wrapinmoonlight = {
    id          = "wrapinmoonlight",
    name        = "Wings of Moonlight",
    affinity    = Constants.TokenType.MOON,
    description = "Ward that elevates the caster each time it blocks.",
    attackType  = "utility",
    castTime    = Constants.CastSpeed.FAST,
    cost        = { Constants.TokenType.MOON , "any" },
    keywords = {
        block = {
            type   = Constants.ShieldType.WARD,
            blocks = { Constants.AttackType.PROJECTILE , 
Constants.AttackType.ZONE },

            -- ★ hook: emit a SET_ELEVATION event every time the ward 
absorbs a hit
            onBlock = function(defender, attacker, slot, info)
                return {{
                    type      = "SET_ELEVATION",
                    source    = "caster",  -- defender is the caster for 
shields
                    target    = "self",
                    elevation = Constants.ElevationState.AERIAL,
                    duration  = 4.0,
                    vfx       = "mist_veil"
                }}
            end
        }
        -- (the original top-level `elevate` keyword is removed)
    },
    vfx         = "mist_veil",
    sfx         = "mist_shimmer",
    blockableBy = {}
}
Now the first cast only parks the ward; every successful block re-fires 
the identical SET_ELEVATION event, giving Selene that floaty, reactive 
style you wanted.

Why this wiring is “clean”
Single source of truth – Shields own their lifecycle; the combat loop 
never pings spell data again.

Pure events – The hook produces normal events, so all downstream logic 
(VFX, status expiry, echoes, etc.) continues to live in EventRunner.

Zero impact on non-shield spells – The extra parameter is ignored unless a 
designer explicitly uses it.

Flip side: if you foresee very complicated block effects, consider 
formalising an BLOCK_TRIGGER event and letting EventRunner do the heavy 
lifting instead of a callback. For now this tiny hook keeps things 
readable and ships your demo.

Happy blocking!~
