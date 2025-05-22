Ticket #CAMP-4: Campaign Progression & Victory/Loss Logic
Goal: Implement logic to advance to the next opponent upon winning, or end the campaign attempt on loss/completion.
Tasks:
Create handleCampaignVictory() function in main.lua:
Called by startCampaignBattle if no more opponents.
print(game.campaignProgress.characterName .. " campaign complete! Wins: " .. game.campaignProgress.wins).
Set game.currentState = "CAMPAIGN_VICTORY".
(Optionally: game.campaignProgress = nil here, or defer to when leaving CAMPAIGN_VICTORY state).
Create handleCampaignDefeat() function in main.lua:
Called if player loses a campaign battle.
print(game.campaignProgress.characterName .. " campaign failed at opponent " .. game.campaignProgress.currentOpponentIndex).
Set game.currentState = "CAMPAIGN_DEFEAT".
(Optionally: game.campaignProgress = nil here).
Modify love.update() in main.lua for GAME_OVER state:
When game.winScreenTimer >= game.winScreenDuration (or player input like Space to continue from win screen):
Check if game.campaignProgress is not nil (i.e., we were in a campaign battle).
If player won (game.winner == 1 assuming player is game.wizards[1]):
Increment game.campaignProgress.wins.
Increment game.campaignProgress.currentOpponentIndex.
Call startGameCampaignBattle() (which will check if it's the end of the campaign or set up the next fight).
Else (player lost, game.winner == 2):
Call handleCampaignDefeat().
Else (not in campaign, game.campaignProgress is nil):
Existing logic: resetGame() and game.currentState = "MENU". This remains the default for non-campaign duels.
Acceptance Criteria:
Winning a campaign battle triggers startCampaignBattle() to load the next opponent.
Losing a campaign battle triggers handleCampaignDefeat() and sets state to CAMPAIGN_DEFEAT.
Successfully defeating all opponents in a campaign triggers handleCampaignVictory() and sets state to CAMPAIGN_VICTORY.
Design Notes/Pitfalls:
The player is always game.wizards[1] in campaign mode.
The order of operations in GAME_OVER is important: check campaign status before defaulting to resetGame() and returning to menu.