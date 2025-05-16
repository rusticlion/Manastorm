Attract Mode Gameplay Loop & Exit Condition
Goal: Ensure the AI vs. AI duel in attract mode plays out to completion 
and can be exited by the player.
Tasks:
Game Over Handling (main.lua):
Ensure the existing game over logic (if wizard.health <= 0) correctly 
identifies a winner in AI vs. AI mode.
When game.gameOver becomes true during BATTLE_ATTRACT state:
Transition to GAME_OVER_ATTRACT state.
Display the win screen as normal.
After winScreenDuration, or on player input, transition back to MENU 
state.
Exiting Attract Mode (Input.lua / main.lua):
Modify Input.handleKey (or relevant key handlers in main.lua if attract 
mode bypasses Input.lua):
If game.attractModeActive is true, any key press should:
Set game.attractModeActive = false.
Clean up AI instances: game.player1AI = nil, game.player2AI = nil.
Re-enable player input routes if they were disabled.
Call resetGame() to prepare for a potential player-initiated game.
Set game.currentState = "MENU".
Reset game.menuIdleTimer = 0.
UI for Attract Mode (Optional, ui.lua):
Consider adding a small "Attract Mode - Press Any Key" text overlay during 
BATTLE_ATTRACT or GAME_OVER_ATTRACT.
Acceptance Criteria:
AI vs. AI duels play until one wizard wins.
The win screen is displayed.
Pressing any key during the attract mode (battle or game over screen) 
immediately returns to the main menu.
The game state is correctly reset, and player controls are restored after 
exiting attract mode.
