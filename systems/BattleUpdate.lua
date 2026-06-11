local Log = require("core.Log")
local Tips = require("core.Tips")
local UI = require("ui")

local BattleUpdate = {}

local function getWinnerColor(winnerIndex)
    if winnerIndex == 1 then
        return {1.0, 0.5, 0.2, 0.9}
    end
    return {0.3, 0.3, 1.0, 0.9}
end

local function createVictoryVfx(game, winnerIndex)
    if not game.vfx or not game.vfx.createEffect then
        return
    end

    local winner = game.wizards[winnerIndex]
    if not winner then
        return
    end

    local color = getWinnerColor(winnerIndex)
    for j = 1, 15 do
        local angle = math.random() * math.pi * 2
        local distance = math.random(40, 100)
        local x = winner.x + math.cos(angle) * distance
        local y = winner.y + math.sin(angle) * distance

        game.vfx.createEffect("impact", x, y, nil, nil, {
            duration = 0.8 + math.random() * 0.5,
            color = color,
            particleCount = 5,
            radius = 15,
            delay = j * 0.1
        })
    end
end

local function enterGameOver(game, nextState)
    game.currentState = nextState
    game.winScreenTimer = 0
    game.currentTip = Tips.getRandomTip()
end

local function checkWinConditions(game, nextState, logPrefix)
    if game.gameOver then
        enterGameOver(game, nextState)
        return true
    end

    for i, wizard in ipairs(game.wizards) do
        if wizard.health <= 0 then
            game.gameOver = true
            game.winner = 3 - i
            game.winScreenTimer = 0

            createVictoryVfx(game, game.winner)

            local winner = game.wizards[game.winner]
            if winner then
                Log.debug((logPrefix or "") .. winner.name .. " wins!")
            end

            enterGameOver(game, nextState)
            return true
        end
    end

    return false
end

local function updateBattleSystems(game, dt)
    if game.eventRunner and game.eventRunner.updateTimedEffects then
        game.eventRunner.updateTimedEffects(game, dt)
    end

    for _, wizard in ipairs(game.wizards) do
        wizard:update(dt)
    end

    game.manaPool:update(dt)
    game.vfx.update(dt)
    game.sustainedSpellManager.update(dt)
    UI.updateHealthDisplays(dt, game.wizards)
end

local function updateAttractAIs(game, dt)
    if game.player1AI then
        game.player1AI:update(dt)
    end
    if game.player2AI then
        game.player2AI:update(dt)
    end
end

function BattleUpdate.updateBattle(game, dt)
    if checkWinConditions(game, "GAME_OVER", "") then
        return
    end

    updateBattleSystems(game, dt)

    if game.useAI and game.opponentAI then
        game.opponentAI:update(dt)
    end

    if game.attractModeActive then
        updateAttractAIs(game, dt)
    end
end

function BattleUpdate.updateAttractBattle(game, dt)
    if checkWinConditions(game, "GAME_OVER_ATTRACT", "[Attract Mode] ") then
        return
    end

    updateBattleSystems(game, dt)
    updateAttractAIs(game, dt)
end

return BattleUpdate
