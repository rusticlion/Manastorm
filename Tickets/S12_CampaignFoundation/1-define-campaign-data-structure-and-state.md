Ticket #CAMP-1: Define Campaign Data Structure & Basic Game State
Goal: Establish where and how campaign progression and opponent lists will be stored, and add the new game state for campaign play.
Tasks:
Modify characterData.lua:
For each character entry (e.g., characterData.Ashgar), add a new key, campaignOpponents, which will be an ordered list (array table) of opponent character names (strings, e.g., {"Selene", "Silex", "Borrak"}).
Initially populate this for Ashgar and Selene with 2-3 opponents each for testing.
Modify main.lua (game table):
Add new states to game.currentState's possible values: "CAMPAIGN_MENU" (for selecting a character's campaign), "CAMPAIGN_VICTORY", "CAMPAIGN_DEFEAT". We will reuse the existing "BATTLE" state, using game.campaignProgress to differentiate campaign battles.
Add game.campaignProgress = nil. When active, this will be a table like { characterName = "Ashgar", currentOpponentIndex = 1, wins = 0 }.
Modify main.lua (drawMainMenu and input handling):
Add a new menu option, e.g., "[1] Campaign", to drawMainMenu.
Update Input.Routes.ui["1"] (or a new key if "1" is too overloaded) in Input.setupRoutes to set game.currentState = "CAMPAIGN_MENU" if chosen from the main menu.
Acceptance Criteria:
characterData.lua includes campaignOpponents lists for Ashgar and Selene.
main.lua recognizes new campaign-related game states.
The main menu has a "Campaign" option that transitions game.currentState to "CAMPAIGN_MENU".
game.campaignProgress is initialized to nil.
Design Notes/Pitfalls:
Opponent lists should contain valid character names that have corresponding AI personalities.
The CAMPAIGN_MENU state will initially be simple, focusing on character selection for the campaign.