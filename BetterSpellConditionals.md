~You don’t need to litter every spell definition with bespoke anonymous 
functions and keep hand-rolling per-keyword glue.
Instead, give your keyword layer a small “expression resolver” that 
automatically evaluates any field that happens to be a function. Then wire 
helper utilities (e.g. mana:count("sun")) into that resolver so authors 
can write one-liners in the DSL and forget about the plumbing.
With that in place, Infinite Procession becomes a three-line spell, and 
every other keyword instantly gains the same flexibility.

1 What feels brittle right now
tokenShift doesn’t evaluate callable params.
In its execute it blindly inserts params.type into the event, so a 
function crashes or gets stringified ​
.

damage does evaluate callables, but it does so inline.
You already wrote the pattern once ​
, yet every new keyword would have to clone it.

Spells like Infinite Procession are therefore stuck half-implemented with 
an empty anonymous function ​
.

2 Introduce a generic resolver
Add a tiny helper in keywords.lua (top-level, before keyword tables):

lua
Copy
Edit
-- Utility: resolve a param that may be a callable
local function resolve(value, caster, target, slot, default)
    if type(value) == "function" then
        local ok, result = pcall(value, caster, target, slot)
        return ok and result or default
    end
    return value ~= nil and value or default
end
Export it if you like:

lua
Copy
Edit
Keywords.util = { resolve = resolve }
3 Patch keywords with one line each
Example for tokenShift:

lua
Copy
Edit
execute = function(params, caster, target, results, events)
    local tokenType = resolve(params.type, caster, target, 
results.currentSlot, "fire")
    local amount    = resolve(params.amount, caster, target, 
results.currentSlot, 1)

    table.insert(events or {}, {
        type       = "SHIFT_TOKEN",
        source     = "caster",
        target     = "pool",
        tokenType  = tokenType,
        amount     = amount,
        shiftTarget= params.target or "self"
    })
    return results
end
Done: every future spell can pass a literal, a table, or a closure—no 
extra work in the keyword.

Apply the same single-line resolve call to any other keyword fields 
(duration, slot, etc.).
Because the helper is tiny, the diff across the whole file is mechanical 
and low-risk.

4 Write helper expressions, not anonymous functions
Inside keywords.util (or a new expr module) publish a few ready-made 
closures:

lua
Copy
Edit
local mana         = require("systems.ManaHelpers") -- hypothetical
local expr = {}

-- Choose whichever token is *more* abundant in the shared pool
function expr.more(a, b)
    return function(caster)
        return mana.count(a) > mana.count(b) and a or b
    end
end

-- Choose the scarcer token
function expr.less(a, b)
    return function(caster)
        return mana.count(a) < mana.count(b) and a or b
    end
end

return expr
Now Infinite Procession in spells.lua is trivial:

lua
Copy
Edit
keywords = {
    tokenShift = {
        -- If there’s more SUN than MOON, make MOON (and vice-versa)
        type   = expr.more(Constants.TokenType.SUN, 
Constants.TokenType.MOON),
        amount = 1
    }
}
No further edits to keywords.lua or EventRunner are required.

5 Optional niceties
Context struct – if three positional args feel clumsy, pass a single table 
(ctx.caster, ctx.pool, etc.) to every expression.

Compile-time pre-resolution – if a param is a pure constant function 
(doesn’t look at runtime data), resolve it once in SpellCompiler to save 
per-cast cost.

Declarative mini-DSL – if you’d rather not expose Lua, accept tables such 
as
{countMore = {"sun","moon"}} and let resolve detect & execute them.

6 Why this is better
Zero duplication – the evaluation logic lives in one helper, not 
copy-pasted per keyword.

Zero friction for designers – they can drop in literal values 90 % of the 
time, or use a one-liner helper when the effect must branch.

Extensible – new keywords automatically inherit the feature; new helpers 
cost nothing.

Safe – all callables are wrapped in pcall, so a bad expression fails 
gracefully instead of breaking event generation.

Next steps
Add the resolve helper and patch the handful of keywords that refer to 
param fields directly (search for params.).

Move the half-finished Infinite Procession to the clean expression style 
shown above and test.

As you touch keywords, remove any ad-hoc condition-handling code that the 
new resolver supersedes.

Once that groundwork is in, runtime conditionals will feel first-class 
rather than bolted on.~
