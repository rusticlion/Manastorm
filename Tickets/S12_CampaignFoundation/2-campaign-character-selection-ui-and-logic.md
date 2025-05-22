Ticket #CAMP-2: Campaign Character Selection UI & Logic
Goal: Allow the player to select a character whose campaign they wish to play.
Tasks:
Create drawCampaignMenu() function in main.lua:
This function will be called when game.currentState == "CAMPAIGN_MENU".
Display a list of unlocked player characters (from game.unlockedCharacters and game.characterRoster).
Implement simple cursor logic (can adapt parts of drawCharacterSelect() or drawSettingsMenu() for cursor movement and display). Store the selected character index/name in a temporary variable, e.g., game.campaignMenu = { selectedCharacterIndex = 1 }.
Update Input.setupRoutes() for CAMPAIGN_MENU state:
Handle up, down for cursor movement in drawCampaignMenu.
Handle return (Enter) or f (or another confirm key) to confirm character selection.
On confirmation:
Get selectedCharacterName using game.campaignMenu.selectedCharacterIndex.
Set game.campaignProgress = { characterName = selectedCharacterName, currentOpponentIndex = 1, wins = 0 }.
Call a new function startCampaignBattle() (to be created in CAMP-3).
(The startCampaignBattle function will set the state to BATTLE).
Handle escape to return to game.currentState = "MENU" and clear game.campaignMenu.
Acceptance Criteria:
Player can view and select an unlocked character for their campaign from the CAMPAIGN_MENU.
Upon selection, game.campaignProgress is correctly initialized with the chosen character and currentOpponentIndex = 1.
The game logic proceeds to start the first campaign battle.
Design Notes/Pitfalls:
The UI can be very basic text for now. Reusing drawCharacterSelect components might be too complex; a simpler list is fine.
Ensure error handling if no unlocked characters are available (though for now, Ashgar and Selene are default unlocked).