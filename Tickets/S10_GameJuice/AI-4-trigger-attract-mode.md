Attract Mode Trigger & AI vs. AI Setup
Goal: Implement the mechanism to trigger an AI vs. AI duel after a period 
of inactivity on the main menu.
Tasks:
Idle Timer (main.lua):
In love.update, when game.currentState == "MENU", add an idle timer.
game.menuIdleTimer = (game.menuIdleTimer or 0) + dt.
Reset game.menuIdleTimer = 0 whenever any key is pressed in the MENU state 
(modify Input.lua or main menu key handlers).
Attract Mode Trigger (main.lua):
In love.update (MENU state), if game.menuIdleTimer > ATTRACT_MODE_DELAY 
(e.g., 15-30 seconds):
Set game.attractModeActive = true.
Call a new function startGameAttractMode().
startGameAttractMode() function (main.lua):
Call resetGame() (ensure resetGame() doesn't try to re-initialize player 
AI if attractModeActive is true).
Disable player input (e.g., by setting a flag that Input.lua checks, or by 
temporarily clearing Input.Routes.p1 and Input.Routes.p2).
Randomly select (or predefine) two different wizards (e.g., Ashgar vs 
Selene).
Create OpponentAI instances for both game.wizards[1] and game.wizards[2].
local AshgarPersonality = require("ai.personalities.AshgarPersonality")
local SelenePersonality = require("ai.personalities.SelenePersonality")
game.player1AI = OpponentAI.new(game.wizards[1], game, AshgarPersonality)
game.player2AI = OpponentAI.new(game.wizards[2], game, SelenePersonality)
(Or, if one AI should be fixed, game.opponentAI can be used for P2, and a 
new game.player1AI for P1)
Set game.currentState = "BATTLE_ATTRACT" (or a similar new state to 
distinguish from normal battle).
Reset game.menuIdleTimer = 0.
Update AI Calls (main.lua):
In love.update (BATTLE state), if game.attractModeActive is true, call 
game.player1AI:update(dt) and game.player2AI:update(dt).
If not in attract mode, call the regular game.opponentAI:update(dt) if 
game.useAI is true.
Acceptance Criteria:
After ~15-30 seconds of inactivity on the main menu, the game 
automatically starts an AI vs. AI duel.
Both AI-controlled wizards attempt to cast spells.
Player input is disabled during attract mode.
