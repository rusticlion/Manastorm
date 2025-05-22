Ticket #CAMP-6: Data Population, Testing & Polish
Goal: Populate campaign data for more characters, test the full flow, and refine transitions.
Tasks:
Populate campaignOpponents in characterData.lua:
Add gauntlets for Silex and Borrak (or any other characters with implemented AI personalities). Use a mix of opponents for variety. Ensure these opponents have AI personalities defined.
Refine Transitions:
Ensure smooth and logical transitions between: Main Menu -> Campaign Menu -> Battle -> Game Over -> Next Battle / Campaign Victory / Campaign Defeat -> Main Menu.
Confirm game.campaignProgress is correctly initialized and cleared at the appropriate times.
Test Thoroughly:
Play through each implemented character's campaign.
Test winning streaks and losing at various points in a campaign.
Test exiting a campaign mid-battle (e.g., pressing ESC during a campaign BATTLE state should probably reset game.campaignProgress and return to Main Menu for now).
Acceptance Criteria:
At least 4 characters have defined, playable (short) campaigns against existing AI personalities.
The campaign mode is robust and handles various win/loss/exit scenarios gracefully.
No crashes or major logical errors in campaign flow.
Design Notes/Pitfalls:
This ticket is crucial for catching edge cases and ensuring the feature feels complete enough for its basic scope.
If an opponent in a campaign list doesn't have an AI personality, getPersonalityFor will return nil, and OpponentAI.new will use the PersonalityBase. This is acceptable for now but should be noted.