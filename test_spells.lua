print('Testing spells module import')
local SpellsModule = require('spells')
local count = 0
for _ in pairs(SpellsModule.spells) do count = count + 1 end
print('Spells loaded:', count)
print('Success')
