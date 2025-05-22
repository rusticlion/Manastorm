Ticket #CAMP-3: Starting and Managing a Campaign Battle
Goal: Correctly set up and start a duel based on the current campaign progress, and modify resetGame to be campaign-aware.
Tasks:
Create startCampaignBattle() function in main.lua:
This function is called after character selection (from CAMP-2) and after winning a campaign battle (CAMP-4).
Preconditions: game.campaignProgress must be populated.
Retrieve playerCharacterName = game.campaignProgress.characterName.
Retrieve opponentIndex = game.campaignProgress.currentOpponentIndex.
Get opponentCharacterName from game.characterData[playerCharacterName].campaignOpponents[opponentIndex].
If opponentCharacterName is nil (i.e., opponentIndex is out of bounds), it means the campaign is complete. Call handleCampaignVictory() (new function, details in CAMP-4). Return early from startCampaignBattle.
Call setupWizards(playerCharacterName, opponentCharacterName).
Set game.useAI = true.
Initialize AI for game.wizards[2]:
local personality = getPersonalityFor(opponentCharacterName) (using existing helper in main.lua).
game.opponentAI = OpponentAI.new(game.wizards[2], game, personality).
Call resetGame().
Set game.currentState = "BATTLE".
Modify resetGame() in main.lua:
This function is called by startCampaignBattle and also when exiting GAME_OVER.
Crucially, when resetGame() is called during an active campaign (i.e., game.campaignProgress is not nil and we are setting up for the next campaign battle), it should not clear game.opponentAI if game.useAI is true (as it's set by startCampaignBattle).
The part of resetGame that initializes game.opponentAI should only run if game.campaignProgress is nil (i.e., it's a regular duel).
Alternatively, startCampaignBattle can set a temporary flag like game.isSettingUpCampaignBattle = true before calling resetGame, and resetGame can check this flag to skip AI re-initialization. Clear the flag afterwards.
Acceptance Criteria:
startCampaignBattle correctly configures game.wizards[1] (player) and game.wizards[2] (AI opponent) based on game.campaignProgress.
The AI opponent uses the personality appropriate for its character name.
resetGame correctly prepares the battle state without interfering with ongoing campaign AI setup.
The game transitions to the "BATTLE" state.
Design Notes/Pitfalls:
The interaction between startCampaignBattle and resetGame regarding AI initialization needs care to avoid double-initialization or premature clearing of the campaign AI. Using a temporary flag might be the cleanest.
Consider what happens if campaignOpponents list is empty or an opponent name is invalid.