-- Manastorm - Wizard Duel Game
-- Main game file

-- Load dependencies
local AssetCache = require("core.AssetCache")
local AssetPreloader = require("core.assetPreloader")
local Constants = require("core.Constants")
local Input = require("core.Input")
local Pool = require("core.Pool")
local Wizard = require("wizard")
local ManaPool = require("manapool")
local UI = require("ui")
local VFX = require("vfx")
local Keywords = require("keywords")
local SpellCompiler = require("spellCompiler")
local SpellsModule = require("spells") -- Now using the modular spells structure
local SustainedSpellManager = require("systems.SustainedSpellManager")
local Settings = require("core.Settings")
local OpponentAI = require("ai.OpponentAI")
local SelenePersonality = require("ai.personalities.SelenePersonality")
local AshgarPersonality = require("ai.personalities.AshgarPersonality")
local SilexPersonality = require("ai.personalities.SilexPersonality")
local BorrakPersonality = require("ai.personalities.BorrakPersonality")
local CharacterData = require("characterData")

-- Resolution settings
local baseWidth = 800    -- Base design resolution width
local baseHeight = 600   -- Base design resolution height
local scale = 1          -- Current scaling factor
local offsetX = 0        -- Horizontal offset for pillarboxing
local offsetY = 0        -- Vertical offset for letterboxing

-- Screen shake variables
local shakeTimer = 0
local shakeIntensity = 0

-- Hitstop variables
local hitstopTimer = 0

-- Game state (globally accessible)
game = {
    wizards = {},
    manaPool = nil,
    font = nil,
    characterData = CharacterData,
    rangeState = Constants.RangeState.FAR,  -- Initial range state (NEAR or FAR)
    gameOver = false,
    winner = nil,
    winScreenTimer = 0,
    winScreenDuration = 5,  -- How long to show the win screen before auto-reset
    keywords = Keywords,
    spellCompiler = SpellCompiler,
    -- State management
    currentState = "MENU", -- Start in the menu state (MENU, CHARACTER_SELECT, BATTLE, GAME_OVER, BATTLE_ATTRACT, GAME_OVER_ATTRACT, CAMPAIGN_MENU, CAMPAIGN_VICTORY, CAMPAIGN_DEFEAT)
    campaignProgress = nil, -- Holds campaign run info when active
    -- Game mode
    useAI = false,         -- Whether to use AI for the second player
    -- Attract mode properties
    attractModeActive = false,
    menuIdleTimer = 0,
    ATTRACT_MODE_DELAY = 15, -- Start attract mode after 15 seconds of inactivity
    settings = Settings,
    settingsMenu = {
        selected = 1,
        mode = nil,
        waitingForKey = nil,
        bindOrder = {
            {"p1","slot1","P1 Slot 1"},
            {"p1","slot2","P1 Slot 2"},
            {"p1","slot3","P1 Slot 3"},
            {"p1","cast","P1 Cast"},
            {"p2","slot1","P2 Slot 1"},
            {"p2","slot2","P2 Slot 2"},
            {"p2","slot3","P2 Slot 3"},
            {"p2","cast","P2 Cast"}
        },
        rebindIndex = 1
    },
    -- Resolution properties
    baseWidth = baseWidth,
    baseHeight = baseHeight,
    scale = scale,
    offsetX = offsetX,
    offsetY = offsetY
}

-- Helper function to trigger screen shake
function triggerShake(duration, intensity)
    shakeTimer = duration or 0.5
    shakeIntensity = intensity or 5
    print("Screen shake triggered: " .. duration .. "s, intensity " .. intensity)
end

-- Helper function to trigger hitstop (game pause)
function triggerHitstop(duration)
    hitstopTimer = duration or 0.1
    print("Hitstop triggered: " .. duration .. "s")
end

-- Make these functions available to other modules through the game table
game.triggerShake = triggerShake
game.triggerHitstop = triggerHitstop

-- Define token types and images (globally available for consistency)
game.tokenTypes = {
    Constants.TokenType.FIRE, 
    Constants.TokenType.WATER, 
    Constants.TokenType.SALT, 
    Constants.TokenType.SUN, 
    Constants.TokenType.MOON, 
    Constants.TokenType.STAR,
    Constants.TokenType.LIFE,
    Constants.TokenType.MIND,
    Constants.TokenType.VOID
}
game.tokenImages = {
    [Constants.TokenType.FIRE] = "assets/sprites/v2Tokens/fire-token.png",
    [Constants.TokenType.WATER] = "assets/sprites/v2Tokens/water-token.png",
    [Constants.TokenType.SALT] = "assets/sprites/v2Tokens/salt-token.png",
    [Constants.TokenType.SUN] = "assets/sprites/v2Tokens/sun-token.png",
    [Constants.TokenType.MOON] = "assets/sprites/v2Tokens/moon-token.png",
    [Constants.TokenType.STAR] = "assets/sprites/v2Tokens/star-token.png",
    [Constants.TokenType.LIFE] = "assets/sprites/v2Tokens/life-token.png",
    [Constants.TokenType.MIND] = "assets/sprites/v2Tokens/mind-token.png",
    [Constants.TokenType.VOID] = "assets/sprites/v2Tokens/void-token.png"
}

-- Character roster and unlocks
game.characterRoster = {
    "Ashgar", "Borrak", "Silex",
    "Brightwulf", "Selene", "Klaus",
    "Ohm", "Archive", "End"
}

game.unlockedCharacters = {
    Ashgar = true,
    Borrak = true,
    Silex = false,
    Selene = true,
    Brightwulf = true,
    Klaus = false,
    Ohm = false,
    Archive = false,
    End = false
}

-- Spells unlocked for customization
game.unlockedSpells = {
    conjurefire = true,
    firebolt = true,
    fireball = true,
    burnToAsh = true,
    blastwave = true,
    saltcircle = true,
    eruption = true,

    conjuremoonlight = true,
    wrapinmoonlight = true,
    moondance = true,
    infiniteprocession = true,
    eclipse = true,
    gravityTrap = true,
    fullmoonbeam = true,

    conjuresalt = true,
    glitterfang = true,
    imprison = true,
    stoneshield = true,
    shieldbreaker = true,
    saltstorm = true,

    conjurewater = true,
    watergun = true,
    riptideguard = true,
    tidalforce = true,
    brinechain = true,
    maelstrom = true,
    wavecrash = true,
}

-- Custom spellbooks configured by the player
game.customSpellbooks = {}

game.compendium = {
    page = 1,
    cursor = 1,
    scrollOffset = 0,
    assignFeedback = {
        active = false,
        slot = 0,
        timer = 0
    }
}

-- Temporary state for the campaign character selection menu
game.campaignMenu = {
    selectedCharacterIndex = 1
}

-- Get a list of all unlocked characters in the roster
local function getUnlockedCharacterList()
    local list = {}
    for _, name in ipairs(game.characterRoster) do
        if game.unlockedCharacters[name] then
            table.insert(list, name)
        end
    end
    return list
end

-- Helper to grab an AI personality for a given character name
local function getPersonalityFor(name)
    if name == "Selene" then
        return SelenePersonality
    elseif name == "Ashgar" then
        return AshgarPersonality
    elseif name == "Borrak" then
        return BorrakPersonality
    elseif name == "Silex" then
        return SilexPersonality
    else
        return nil
    end
end

game.characterSelect = {
    stage = 1, -- 1: choose player, 2: choose opponent, 3: confirm
    cursor = 1,
    selected = {nil, nil}
}

-- Helper function to add a random token to the mana pool
function game.addRandomToken()
    local randomType = game.tokenTypes[math.random(#game.tokenTypes)]
    game.manaPool:addToken(randomType, game.tokenImages[randomType])
    return randomType
end

-- Calculate the appropriate scaling for the current window size
function calculateScaling()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    
    -- Calculate potential scales based on window dimensions
    local scaleX = windowWidth / baseWidth
    local scaleY = windowHeight / baseHeight
    
    -- Use the smaller scale factor to maintain aspect ratio and fit within the window
    scale = math.min(scaleX, scaleY)
    
    -- Calculate offsets needed to center the scaled content
    offsetX = (windowWidth - baseWidth * scale) / 2
    offsetY = (windowHeight - baseHeight * scale) / 2
    
    -- Update global references
    game.scale = scale
    game.offsetX = offsetX
    game.offsetY = offsetY
    
    print("Window resized: " .. windowWidth .. "x" .. windowHeight .. " -> Simple scale: " .. scale .. ", Offset: (" .. offsetX .. ", " .. offsetY .. ")")
end

-- Set a scissor rectangle taking current scale and offsets into account
local function setScaledScissor(x, y, w, h)
    love.graphics.setScissor(
        offsetX + x * scale,
        offsetY + y * scale,
        w * scale,
        h * scale
    )
end

-- Handle window resize events
function love.resize(width, height)
    calculateScaling()
end

-- Set up pixel art-friendly scaling
-- function configurePixelArtRendering()
--     -- Disable texture filtering for crisp pixel art
--     love.graphics.setDefaultFilter("nearest", "nearest", 1)
--     
--     -- Use integer scaling when possible
--     love.graphics.setLineStyle("rough")
-- end

function love.load()
    -- Set up window
    love.window.setTitle("Manastorm - Realtime Strategic Wizard Duels")
    
    -- Configure pixel art rendering -- REMOVE THIS CALL
    -- configurePixelArtRendering()

    -- Set default texture filtering for sharper (potentially pixelated) look
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Calculate initial scaling
    calculateScaling()
    
    -- Load background image
    game.backgroundImage = AssetCache.getImage("assets/sprites/background.png")
    
    -- Preload all assets to prevent in-game loading hitches
    print("Preloading game assets...")
    local preloadStats = AssetPreloader.preloadAllAssets()
    print(string.format("Asset preloading complete: %d images, %d sounds in %.2f seconds",
                        preloadStats.imageCount,
                        preloadStats.soundCount,
                        preloadStats.loadTime))

    -- Load persisted settings
    Settings.load()
    Constants.setCastSpeedSet(Settings.get("gameSpeed") or "FAST")
    
    -- Set up game object to have calculateScaling function that can be called by Input
    game.calculateScaling = calculateScaling
    
    -- Load game font
    -- For now, fall back to system font if custom font isn't available
    local fontPath = "assets/fonts/LionscriptNew-Regular.ttf"
    local fontExists = love.filesystem.getInfo(fontPath)
    
    if fontExists then
        game.font = love.graphics.newFont(fontPath, 16)
        print("Using custom game font: " .. fontPath)
    else
        game.font = love.graphics.newFont(16)  -- Default system font
        print("Custom font not found, using system font")
    end
    
    -- Set default font for normal rendering
    love.graphics.setFont(game.font)
    
    -- Create mana pool positioned above the battlefield, but below health bars
    game.manaPool = ManaPool.new(baseWidth/2, 120)  -- Positioned between health bars and wizards
    
    -- Create wizards - moved lower on screen to allow more room for aerial movement
    local d1 = CharacterData.Ashgar
    local d2 = CharacterData.Selene
    game.wizards[1] = Wizard.new("Ashgar", 200, 370, d1.color, d1.spellbook)
    game.wizards[2] = Wizard.new("Selene", 600, 370, d2.color, d2.spellbook)
    
    -- Set up references
    for _, wizard in ipairs(game.wizards) do
        wizard.manaPool = game.manaPool
        wizard.gameState = game
    end
    
    -- Initialize VFX system
    game.vfx = VFX.init()
    
    -- Make screen shake and hitstop functions directly available to VFX module
    VFX.triggerShake = triggerShake
    VFX.triggerHitstop = triggerHitstop
    
    -- Precompile all spells for better performance
    print("Precompiling all spells...")
    
    -- Create a compiledSpells table and do the compilation ourselves
    game.compiledSpells = {}
    
    -- Get all spells from the SpellsModule
    local allSpells = SpellsModule.spells
    
    -- Compile each spell
    for id, spell in pairs(allSpells) do
        game.compiledSpells[id] = game.spellCompiler.compileSpell(spell, game.keywords)
        print("Compiled spell: " .. spell.name)
    end
    
    -- Count compiled spells
    local count = 0
    for _ in pairs(game.compiledSpells) do
        count = count + 1
    end
    
    print("Precompiled " .. count .. " spells")
    
    -- Create custom shield spells just for hotkeys
    -- These are complete, independent spell definitions
    game.customSpells = {}
    
    -- Define Moon Ward with minimal dependencies
    game.customSpells.moonWard = {
        id = "customMoonWard",
        name = "Moon Ward",
        description = "A mystical ward that blocks projectiles and remotes",
        attackType = Constants.AttackType.UTILITY,
        castTime = 4.5,
        cost = {Constants.TokenType.MOON, Constants.TokenType.MOON},
        keywords = {
            block = {
                type = Constants.ShieldType.WARD,
                blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.REMOTE},
                manaLinked = true
            }
        },
        vfx = "moon_ward",
        sfx = "shield_up",
    }
    
    -- Define Mirror Shield with minimal dependencies
    game.customSpells.mirrorShield = {
        id = "customMirrorShield",
        name = "Mirror Shield",
        description = "A reflective barrier that returns damage to attackers",
        attackType = Constants.AttackType.UTILITY,
        castTime = 5.0,
        cost = {Constants.TokenType.MOON, Constants.TokenType.MOON, Constants.TokenType.STAR},
        keywords = {
            block = {
                type = Constants.ShieldType.BARRIER,
                blocks = {Constants.AttackType.PROJECTILE, Constants.AttackType.ZONE},
                manaLinked = false,
                reflect = true,
                hitPoints = 3
            }
        },
        vfx = "mirror_shield",
        sfx = "crystal_ring",
    }
    
    -- Compile custom spells too
    for id, spell in pairs(game.customSpells) do
        game.compiledSpells[id] = game.spellCompiler.compileSpell(spell, game.keywords)
        print("Compiled custom spell: " .. spell.name)
    end
    
    -- Initialize mana pool with a single random token to start
    local tokenType = game.addRandomToken()
    
    -- Log which token was added
    print("Starting the game with a single " .. tokenType .. " token")
    
    -- Initialize input system with game state reference
    Input.init(game)
    print("Input system initialized")
    
    -- Initialize SustainedSpellManager
    game.sustainedSpellManager = SustainedSpellManager
    print("SustainedSpellManager initialized")
    
    -- We'll initialize the AI opponent when starting a game with AI
    -- instead of here, so it's not always active
end

-- Display hotkey help overlay
function drawHotkeyHelp()
    local x = baseWidth - 300
    local y = 50
    local lineHeight = 20
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x - 10, y - 10, 290, 500)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("HOTKEY REFERENCE", x, y)
    y = y + lineHeight * 2
    
    -- System keys
    love.graphics.setColor(0.8, 0.8, 1, 1)
    love.graphics.print("SYSTEM:", x, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.8)
    for i, key in ipairs(Input.reservedKeys.system) do
        love.graphics.print("  " .. key, x, y)
        y = y + lineHeight
    end
    y = y + lineHeight/2
    
    -- Player 1 keys
    love.graphics.setColor(1, 0.5, 0.5, 1)
    love.graphics.print("PLAYER 1:", x, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.8)
    for i, key in ipairs(Input.reservedKeys.player1) do
        love.graphics.print("  " .. key, x, y)
        y = y + lineHeight
    end
    y = y + lineHeight/2
    
    -- Player 2 keys
    love.graphics.setColor(0.5, 0.5, 1, 1)
    love.graphics.print("PLAYER 2:", x, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.8)
    for i, key in ipairs(Input.reservedKeys.player2) do
        love.graphics.print("  " .. key, x, y)
        y = y + lineHeight
    end
    y = y + lineHeight/2
    
    -- Debug keys
    love.graphics.setColor(0.8, 1, 0.8, 1)
    love.graphics.print("DEBUG:", x, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.8)
    for i, key in ipairs(Input.reservedKeys.debug) do
        love.graphics.print("  " .. key, x, y)
        y = y + lineHeight
    end
    
    -- Testing keys
    y = y + lineHeight/2
    love.graphics.setColor(1, 0.8, 0.5, 1)
    love.graphics.print("TESTING:", x, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.8)
    for i, key in ipairs(Input.reservedKeys.testing) do
        love.graphics.print("  " .. key, x, y)
        y = y + lineHeight
    end
end

-- Reset the game
function resetGame()
    -- Reset game state
    game.gameOver = false
    game.winner = nil
    game.winScreenTimer = 0
    
    -- Reset wizards
    for _, wizard in ipairs(game.wizards) do
        wizard.health = 100
        wizard.elevation = Constants.ElevationState.GROUNDED
        wizard.elevationTimer = 0
        if wizard.statusEffects and wizard.statusEffects[Constants.StatusType.STUN] then
            wizard.statusEffects[Constants.StatusType.STUN].active = false
            wizard.statusEffects[Constants.StatusType.STUN].duration = 0
            wizard.statusEffects[Constants.StatusType.STUN].elapsed = 0
            wizard.statusEffects[Constants.StatusType.STUN].totalTime = 0
        end
        
        -- Reset spell slots
        for i = 1, 3 do
            wizard.spellSlots[i] = {
                active = false,
                progress = 0,
                spellType = nil,
                castTime = 0,
                tokens = {},
                isShield = false,
                defenseType = nil,
                shieldStrength = 0,
                blocksAttackTypes = nil,
                wasAlreadyCast = false -- Add this flag to prevent repeated spell casts
            }
        end
        
        -- Reset status effects
        wizard.statusEffects[Constants.StatusType.BURN].active = false
        wizard.statusEffects[Constants.StatusType.BURN].duration = 0
        wizard.statusEffects[Constants.StatusType.BURN].tickDamage = 0
        wizard.statusEffects[Constants.StatusType.BURN].tickInterval = 1.0
        wizard.statusEffects[Constants.StatusType.BURN].elapsed = 0
        wizard.statusEffects[Constants.StatusType.BURN].totalTime = 0
        
        -- Reset blockers
        if wizard.blockers then
            for blockType in pairs(wizard.blockers) do
                wizard.blockers[blockType] = 0
            end
        end
        
        -- Reset spell keying
        wizard.activeKeys = {[1] = false, [2] = false, [3] = false}
        wizard.currentKeyedSpell = nil
    end
    
    -- Reset range state
    game.rangeState = Constants.RangeState.FAR
    
    -- Clear sustained spells
    if game.sustainedSpellManager then
        game.sustainedSpellManager.activeSpells = {}
    end
    
    -- Clear mana pool and add a single token to start
    if game.manaPool then
        game.manaPool:clear()
        local tokenType = game.addRandomToken()
        print("Game reset! Starting with a single " .. tokenType .. " token")
    end
    
    -- Reinitialize AI opponent if AI mode is enabled and not being set up by campaign
    if game.useAI then
        if not game.isSettingUpCampaignBattle then
            local aiWizard = game.wizards[2]
            local personality = getPersonalityFor(aiWizard.name)
            if personality then
                print("Initializing " .. aiWizard.name .. " AI personality")
            else
                print("Unknown wizard type: " .. aiWizard.name .. ". Using default personality.")
            end
            game.opponentAI = OpponentAI.new(aiWizard, game, personality)
            print("AI opponent reinitialized with personality: " .. (personality and personality.name or "Default"))
        end
    else
        -- Disable AI if we're switching to PvP mode
        game.opponentAI = nil
    end
    
    -- Reset health display animation state
    if UI and UI.healthDisplay then
        for i = 1, 2 do
            local display = UI.healthDisplay["player" .. i]
            if display then
                display.currentHealth = 100
                display.targetHealth = 100
                display.pendingDamage = 0
                display.lastDamageTime = 0
            end
        end
    end
    
    -- The current state is handled by the caller
    print("Game reset complete")
end

-- Add resetGame function to game state so Input system can call it
function game.resetGame()
    resetGame()
end

-- Function to start an AI vs AI attract mode game
function startGameAttractMode()
    print("Starting attract mode...")

    -- Mark attract mode as active
    game.attractModeActive = true

    -- Reset the game to clear any existing state
    resetGame()

    -- Choose two random unlocked characters
    local unlocked = getUnlockedCharacterList()
    if #unlocked < 2 then
        print("Not enough unlocked characters for attract mode")
        return
    end

    local name1 = unlocked[math.random(#unlocked)]
    local name2 = unlocked[math.random(#unlocked)]
    while name2 == name1 do
        name2 = unlocked[math.random(#unlocked)]
    end

    setupWizards(name1, name2)

    -- Temporarily store input routes so we can restore them later
    game.savedInputRoutes = {
        p1 = Input.Routes.p1,
        p2 = Input.Routes.p2
    }

    -- Disable player input during attract mode
    Input.Routes.p1 = {}
    Input.Routes.p2 = {}

    -- Make sure AI mode is enabled but not tracked by the normal flag
    -- This way we can have two AI players without affecting the normal mode
    game.useAI = false

    -- Create AIs for both players
    game.player1AI = OpponentAI.new(game.wizards[1], game, getPersonalityFor(name1))
    game.player2AI = OpponentAI.new(game.wizards[2], game, getPersonalityFor(name2))

    -- Reset idle timer
    game.menuIdleTimer = 0

    -- Transition to the attract mode battle state
    game.currentState = "BATTLE_ATTRACT"

    print("Attract mode started: " .. game.wizards[1].name .. " vs " .. game.wizards[2].name)
end

-- Function to exit attract mode and return to the menu
function exitAttractMode()
    print("Exiting attract mode...")

    -- Disable attract mode
    game.attractModeActive = false

    -- Clean up AI instances
    game.player1AI = nil
    game.player2AI = nil

    -- Reset the game
    resetGame()

    -- Restore input routes if we saved them
    if game.savedInputRoutes then
        Input.Routes.p1 = game.savedInputRoutes.p1
        Input.Routes.p2 = game.savedInputRoutes.p2
        game.savedInputRoutes = nil
    end

    -- Reset idle timer
    game.menuIdleTimer = 0

    -- Return to menu
    game.currentState = "MENU"

    print("Attract mode ended, returned to menu")
end

-- Handle successful completion of a campaign
function handleCampaignVictory()
    if not game.campaignProgress then return end
    print(game.campaignProgress.characterName .. " campaign complete! Wins: " .. game.campaignProgress.wins)
    game.currentState = "CAMPAIGN_VICTORY"
end

-- Handle failure of a campaign run
function handleCampaignDefeat()
    if not game.campaignProgress then return end
    print(game.campaignProgress.characterName .. " campaign failed at opponent " .. game.campaignProgress.currentOpponentIndex)
    resetGame()
    game.currentState = "CAMPAIGN_DEFEAT"
end

-- Restart the entire campaign from the first opponent
function restartCampaign()
    if not game.campaignProgress then return end
    game.campaignProgress.currentOpponentIndex = 1
    game.campaignProgress.wins = 0
    startCampaignBattle()
end

-- Retry the current campaign battle
function retryCampaignBattle()
    if not game.campaignProgress then return end
    startCampaignBattle()
end

-- Expose campaign helpers
game.restartCampaign = restartCampaign
game.retryCampaignBattle = retryCampaignBattle

-- Placeholder implementation for starting a campaign battle
function startCampaignBattle()
    if not game.campaignProgress then
        print("ERROR: startCampaignBattle called without campaignProgress")
        return
    end

    local playerCharacterName = game.campaignProgress.characterName
    local opponentIndex = game.campaignProgress.currentOpponentIndex or 1
    local playerData = game.characterData[playerCharacterName] or {}
    local opponentName
    if playerData.campaignOpponents then
        opponentName = playerData.campaignOpponents[opponentIndex]
    end

    if not opponentName then
        if handleCampaignVictory then
            handleCampaignVictory()
        else
            print("Campaign complete for " .. tostring(playerCharacterName))
        end
        return
    end

    setupWizards(playerCharacterName, opponentName)

    game.useAI = true

    local personality = getPersonalityFor(opponentName)
    game.opponentAI = OpponentAI.new(game.wizards[2], game, personality)

    game.isSettingUpCampaignBattle = true
    resetGame()
    game.isSettingUpCampaignBattle = nil

    game.currentState = "BATTLE"
end

-- Initialize wizards for battle based on selected names
function setupWizards(name1, name2)
    local data1 = game.characterData[name1] or {}
    local data2 = game.characterData[name2] or {}
    local book1 = game.customSpellbooks[name1] or data1.spellbook
    local book2 = game.customSpellbooks[name2] or data2.spellbook
    game.wizards[1] = Wizard.new(name1, 200, 370, data1.color or {255,255,255}, book1)
    game.wizards[2] = Wizard.new(name2, 600, 370, data2.color or {255,255,255}, book2)
    for _, wizard in ipairs(game.wizards) do
        wizard.manaPool = game.manaPool
        wizard.gameState = game
    end
end

-- Start character selection
function game.startCharacterSelect()
    game.characterSelect.stage = 1
    game.characterSelect.cursor = 1
    game.characterSelect.selected = {nil,nil}
    game.currentState = "CHARACTER_SELECT"
end

-- Move selection cursor
function game.characterSelectMove(dir)
    local count = #game.characterRoster
    local idx = game.characterSelect.cursor
    repeat
        idx = ((idx -1 + dir -1) % count) + 1
    until game.unlockedCharacters[game.characterRoster[idx]]
    game.characterSelect.cursor = idx
end

-- Confirm selection or start fight
function game.characterSelectConfirm()
    local idx = game.characterSelect.cursor
    local name = game.characterRoster[idx]
    if not game.unlockedCharacters[name] then return end

    if game.characterSelect.stage == 1 then
        game.characterSelect.selected[1] = name
        game.characterSelect.stage = 2
    elseif game.characterSelect.stage == 2 then
        game.characterSelect.selected[2] = name
        game.characterSelect.stage = 3
    else
        setupWizards(game.characterSelect.selected[1], game.characterSelect.selected[2])
        game.useAI = true
        resetGame()
        game.currentState = "BATTLE"
    end
end

-- Back out of selection
function game.characterSelectBack(toMenu)
    if toMenu then
        game.currentState = "MENU"
        return
    end
    if game.characterSelect.stage == 2 then
        game.characterSelect.stage = 1
        game.characterSelect.selected[1] = nil
    elseif game.characterSelect.stage == 3 then
        game.characterSelect.stage = 2
        game.characterSelect.selected[2] = nil
    else
        game.currentState = "MENU"
    end
end

-- Start settings menu
function game.startSettings()
    game.settingsMenu.selected = 1
    game.settingsMenu.mode = nil
    game.settingsMenu.waitingForKey = nil
    game.settingsMenu.rebindIndex = 1
    game.currentState = "SETTINGS"
end

function game.settingsMove(dir)
    if game.settingsMenu.mode then return end
    local count = 3
    local idx = game.settingsMenu.selected + dir
    if idx < 1 then idx = count end
    if idx > count then idx = 1 end
    game.settingsMenu.selected = idx
end

function game.settingsAdjust(dir)
    if game.settingsMenu.mode then return end
    if game.settingsMenu.selected == 1 then
        if dir ~= 0 then
            local val = Settings.get("dummyFlag")
            Settings.set("dummyFlag", not val)
        end
    elseif game.settingsMenu.selected == 2 then
        if dir ~= 0 then
            local current = Settings.get("gameSpeed") or "FAST"
            if current == "FAST" then
                current = "SLOW"
            else
                current = "FAST"
            end
            Settings.set("gameSpeed", current)
            Constants.setCastSpeedSet(current)
        end
    end
end

function game.settingsSelect()
    if game.settingsMenu.selected == 3 then
        game.settingsMenu.mode = "rebind"
        game.settingsMenu.rebindIndex = 1
        local a = game.settingsMenu.bindOrder[1]
        game.settingsMenu.waitingForKey = {player=a[1], key=a[2], label=a[3]}
    else
        game.settingsAdjust(1)
    end
end

function game.startCompendium()
    game.compendium.page = 1
    game.compendium.cursor = 1
    game.compendium.scrollOffset = 0
    game.compendium.assignFeedback = {
        active = false,
        slot = 0,
        timer = 0
    }
    game.assignmentError = nil
    game.currentState = "COMPENDIUM"
end

function game.compendiumMove(dir)
    local name = game.characterRoster[game.compendium.page]
    local spells = game.characterData[name].spells or {}
    local count = #spells
    if count == 0 then return end
    
    -- Simple approach: add dir (+1 for down, -1 for up) and handle wrapping
    local newIdx = game.compendium.cursor + dir
    
    -- Handle wrapping around the list
    if newIdx < 1 then 
        newIdx = count
    elseif newIdx > count then
        newIdx = 1
    end
    
    game.compendium.cursor = newIdx
    
    -- Scrolling logic: Calculate visible items based on pane height
    if game.compendiumPanes then
        local pane = game.compendiumPanes.bottomLeft
        local spellLineHeight = 20 -- Height of each spell entry in the list
        local maxVisibleSpells = math.floor((pane.h - 50) / spellLineHeight) -- 50px for padding/header
        
        -- Adjust scroll offset if cursor moves outside visible range
        if game.compendium.cursor <= game.compendium.scrollOffset then
            -- Cursor moved above visible top
            game.compendium.scrollOffset = math.max(0, game.compendium.cursor - 1)
        elseif game.compendium.cursor > game.compendium.scrollOffset + maxVisibleSpells then
            -- Cursor moved below visible bottom
            game.compendium.scrollOffset = game.compendium.cursor - maxVisibleSpells
        end
    end
end

function game.compendiumChangePage(dir)
    local count = #game.characterRoster
    
    -- Use same approach as compendiumMove for consistency
    local newPage = game.compendium.page + dir
    
    -- Handle wrapping
    if newPage < 1 then
        newPage = count
    elseif newPage > count then
        newPage = 1
    end
    
    game.compendium.page = newPage
    game.compendium.cursor = 1 -- Reset cursor when changing pages
    game.compendium.scrollOffset = 0 -- Reset scroll offset when changing pages
    
    -- Reset feedback states
    game.compendium.assignFeedback = {
        active = false,
        slot = 0,
        timer = 0
    }
    game.assignmentError = nil
end

local slotKeys = {"1","2","3","12","13","23","123"}
function game.compendiumAssign(slot)
    local name = game.characterRoster[game.compendium.page]
    local spells = game.characterData[name].spells or {}
    local spell = spells[game.compendium.cursor]
    
    -- Check if spell is valid and unlocked
    if not spell then
        -- No spell selected
        return
    end
    
    if not game.unlockedSpells[spell.id] then
        -- Spell is locked, provide feedback
        game.assignmentError = {
            message = "Spell is locked and cannot be assigned",
            timer = 2.0 -- Show message for 2 seconds
        }
        return
    end
    
    -- Create custom spellbook if it doesn't exist yet
    if not game.customSpellbooks[name] then
        -- Copy default spellbook
        local copy = {}
        for k,v in pairs(game.characterData[name].spellbook) do copy[k]=v end
        game.customSpellbooks[name] = copy
    end
    
    -- Assign the spell to the selected slot
    game.customSpellbooks[name][slotKeys[slot]] = spell
    
    -- Trigger visual feedback
    game.compendium.assignFeedback = {
        active = true,
        slot = slot,
        timer = 0.5 -- Show highlight for 0.5 seconds
    }
    
    -- Play a sound effect for feedback (if available)
    if love.audio and game.sounds and game.sounds.click then
        game.sounds.click:stop()
        game.sounds.click:play()
    end
end

-- Initialize the campaign character selection menu
function game.startCampaignMenu()
    game.campaignMenu = { selectedCharacterIndex = 1 }
    game.currentState = "CAMPAIGN_MENU"
end

-- Move selection cursor in the campaign menu
function game.campaignMenuMove(dir)
    local unlocked = getUnlockedCharacterList()
    local count = #unlocked
    if count == 0 then return end

    local idx = game.campaignMenu.selectedCharacterIndex + dir
    if idx < 1 then idx = count end
    if idx > count then idx = 1 end
    game.campaignMenu.selectedCharacterIndex = idx
end

-- Confirm character choice and start the campaign
function game.campaignMenuConfirm()
    local unlocked = getUnlockedCharacterList()
    local name = unlocked[game.campaignMenu.selectedCharacterIndex]
    if not name then return end

    game.campaignProgress = {
        characterName = name,
        currentOpponentIndex = 1,
        wins = 0
    }

    if startCampaignBattle then
        startCampaignBattle()
    end
end
function love.update(dt)
    -- Update shake timer
    if shakeTimer > 0 then
        shakeTimer = shakeTimer - dt
        if shakeTimer < 0 then
            shakeTimer = 0
            shakeIntensity = 0
        end
    end
    
    -- Update Compendium assignment feedback timers
    if game.currentState == "COMPENDIUM" then
        if game.compendium.assignFeedback.active then
            game.compendium.assignFeedback.timer = game.compendium.assignFeedback.timer - dt
            if game.compendium.assignFeedback.timer <= 0 then
                game.compendium.assignFeedback.active = false
            end
        end
        
        -- Update assignment error message timer
        if game.assignmentError and game.assignmentError.timer > 0 then
            game.assignmentError.timer = game.assignmentError.timer - dt
        end
    end
    
    -- Check for hitstop - if active, decrement timer and skip all other updates
    if hitstopTimer > 0 then
        hitstopTimer = hitstopTimer - dt
        if hitstopTimer < 0 then
            hitstopTimer = 0
        end
        return -- Skip the rest of the update
    end
    
    -- Only update the game when not in hitstop
    -- Different update logic based on current game state
    if game.currentState == "MENU" then
        -- Menu state updates (minimal, just for animations)
        -- VFX system is still updated for menu animations
        if game.vfx then
            game.vfx.update(dt)
        end

        -- Update attract mode timer when in menu
        if not game.attractModeActive then
            game.menuIdleTimer = game.menuIdleTimer + dt

            -- Start attract mode if idle timer exceeds threshold
            if game.menuIdleTimer > game.ATTRACT_MODE_DELAY then
                startGameAttractMode()
            end
        end

        -- No other updates needed in menu state
        return
    elseif game.currentState == "SETTINGS" then
        if game.vfx then
            game.vfx.update(dt)
        end
        return
    elseif game.currentState == "COMPENDIUM" then
        if game.vfx then
            game.vfx.update(dt)
        end
        return
    elseif game.currentState == "CAMPAIGN_MENU" then
        if game.vfx then
            game.vfx.update(dt)
        end
        return
    elseif game.currentState == "CAMPAIGN_DEFEAT" then
        if game.vfx then
            game.vfx.update(dt)
        end
        return
    elseif game.currentState == "CHARACTER_SELECT" then
        -- Simple animations for character select
        if game.vfx then
            game.vfx.update(dt)
        end
        return
    elseif game.currentState == "BATTLE" then
        -- Check for win condition before updates
        if game.gameOver then
            -- Transition to game over state
            game.currentState = "GAME_OVER"
            game.winScreenTimer = 0
            return
        end
        
        -- Check if any wizard's health has reached zero
        for i, wizard in ipairs(game.wizards) do
            if wizard.health <= 0 then
                game.gameOver = true
                game.winner = 3 - i  -- Winner is the other wizard (3-1=2, 3-2=1)
                game.winScreenTimer = 0
                
                -- Create victory VFX around the winner
                local winner = game.wizards[game.winner]
                for j = 1, 15 do
                    local angle = math.random() * math.pi * 2
                    local distance = math.random(40, 100)
                    local x = winner.x + math.cos(angle) * distance
                    local y = winner.y + math.sin(angle) * distance
                    
                    -- Determine winner's color for effects
                    local color
                    if game.winner == 1 then -- Ashgar
                        color = {1.0, 0.5, 0.2, 0.9} -- Fire-like
                    else -- Selene
                        color = {0.3, 0.3, 1.0, 0.9} -- Moon-like
                    end
                    
                    -- Create sparkle effect with delay
                    game.vfx.createEffect("impact", x, y, nil, nil, {
                        duration = 0.8 + math.random() * 0.5,
                        color = color,
                        particleCount = 5,
                        radius = 15,
                        delay = j * 0.1
                    })
                end
                
                print(winner.name .. " wins!")
                
                -- Transition to game over state
                game.currentState = "GAME_OVER"
                return
            end
        end
        
        -- Update wizards
        for _, wizard in ipairs(game.wizards) do
            wizard:update(dt)
        end
        
        -- Update mana pool
        game.manaPool:update(dt)
        
        -- Update VFX system
        game.vfx.update(dt)
        
        -- Update SustainedSpellManager for trap and shield management
        game.sustainedSpellManager.update(dt)
        
        -- Update animated health displays
        UI.updateHealthDisplays(dt, game.wizards)
        
        -- Update AI opponent if it exists and AI mode is enabled
        if game.useAI and game.opponentAI then
            game.opponentAI:update(dt)
        end

        -- Update both AI players in attract mode
        if game.attractModeActive then
            if game.player1AI then
                game.player1AI:update(dt)
            end
            if game.player2AI then
                game.player2AI:update(dt)
            end
        end
    elseif game.currentState == "GAME_OVER" then
        -- Update win screen timer
        game.winScreenTimer = game.winScreenTimer + dt

        -- When timer expires, handle post-battle flow
        if game.winScreenTimer >= game.winScreenDuration then
            if game.campaignProgress then
                if game.winner == 1 then
                    game.campaignProgress.wins = game.campaignProgress.wins + 1
                    game.campaignProgress.currentOpponentIndex = game.campaignProgress.currentOpponentIndex + 1
                    startCampaignBattle()
                else
                    handleCampaignDefeat()
                end
            else
                resetGame()
                game.currentState = "MENU"
            end
        end

        -- Still update VFX system for visual effects
        game.vfx.update(dt)
    elseif game.currentState == "BATTLE_ATTRACT" then
        -- Check for win condition before updates
        if game.gameOver then
            -- Transition to attract mode game over state
            game.currentState = "GAME_OVER_ATTRACT"
            game.winScreenTimer = 0
            return
        end

        -- Check if any wizard's health has reached zero
        for i, wizard in ipairs(game.wizards) do
            if wizard.health <= 0 then
                game.gameOver = true
                game.winner = 3 - i  -- Winner is the other wizard (3-1=2, 3-2=1)
                game.winScreenTimer = 0

                -- Create victory VFX around the winner
                local winner = game.wizards[game.winner]
                for j = 1, 15 do
                    local angle = math.random() * math.pi * 2
                    local distance = math.random(40, 100)
                    local x = winner.x + math.cos(angle) * distance
                    local y = winner.y + math.sin(angle) * distance

                    -- Determine winner's color for effects
                    local color
                    if game.winner == 1 then -- Ashgar
                        color = {1.0, 0.5, 0.2, 0.9} -- Fire-like
                    else -- Selene
                        color = {0.3, 0.3, 1.0, 0.9} -- Moon-like
                    end

                    -- Create sparkle effect with delay
                    game.vfx.createEffect("impact", x, y, nil, nil, {
                        duration = 0.8 + math.random() * 0.5,
                        color = color,
                        particleCount = 5,
                        radius = 15,
                        delay = j * 0.1
                    })
                end

                print("[Attract Mode] " .. winner.name .. " wins!")

                -- Transition to game over state
                game.currentState = "GAME_OVER_ATTRACT"
                return
            end
        end

        -- Update wizards
        for _, wizard in ipairs(game.wizards) do
            wizard:update(dt)
        end

        -- Update mana pool
        game.manaPool:update(dt)

        -- Update VFX system
        game.vfx.update(dt)

        -- Update SustainedSpellManager for trap and shield management
        game.sustainedSpellManager.update(dt)

        -- Update animated health displays
        UI.updateHealthDisplays(dt, game.wizards)

        -- Update both AI players in attract mode
        if game.player1AI then
            game.player1AI:update(dt)
        end
        if game.player2AI then
            game.player2AI:update(dt)
        end
    elseif game.currentState == "GAME_OVER_ATTRACT" then
        -- Update win screen timer
        game.winScreenTimer = game.winScreenTimer + dt

        -- Auto-reset after duration - start a new attract mode battle
        if game.winScreenTimer >= game.winScreenDuration then
            -- Reset game and start another attract mode battle
            resetGame()

            local unlocked = getUnlockedCharacterList()
            if #unlocked >= 2 then
                local name1 = unlocked[math.random(#unlocked)]
                local name2 = unlocked[math.random(#unlocked)]
                while name2 == name1 do
                    name2 = unlocked[math.random(#unlocked)]
                end
                setupWizards(name1, name2)
                game.player1AI = OpponentAI.new(game.wizards[1], game, getPersonalityFor(name1))
                game.player2AI = OpponentAI.new(game.wizards[2], game, getPersonalityFor(name2))
            end

            -- Keep attract mode active
            game.attractModeActive = true

            -- Go back to attract mode battle
            game.currentState = "BATTLE_ATTRACT"
        end

        -- Still update VFX system for visual effects
        game.vfx.update(dt)
    end
end

function love.draw()
    -- Clear entire screen to black first (for letterboxing/pillarboxing)
    love.graphics.clear(0, 0, 0, 1)
    
    -- Calculate shake offset if active
    local shakeOffsetX, shakeOffsetY = 0, 0
    if shakeTimer > 0 then
        -- Random shake that gradually reduces as timer decreases
        local shakeFactor = shakeTimer / (shakeTimer + 0.1) -- Smooth falloff
        shakeOffsetX = math.random(-shakeIntensity, shakeIntensity) * shakeFactor
        shakeOffsetY = math.random(-shakeIntensity, shakeIntensity) * shakeFactor
    end
    
    -- Setup scaling transform with shake offset
    love.graphics.push()
    love.graphics.translate(offsetX + shakeOffsetX, offsetY + shakeOffsetY)
    love.graphics.scale(scale, scale)
    
    -- Draw based on current game state
    if game.currentState == "MENU" then
        -- Draw the main menu
        drawMainMenu()
    elseif game.currentState == "SETTINGS" then
        drawSettingsMenu()
    elseif game.currentState == "COMPENDIUM" then
        drawCompendium()
    elseif game.currentState == "CAMPAIGN_MENU" then
        drawCampaignMenu()
    elseif game.currentState == "CAMPAIGN_DEFEAT" then
        drawCampaignDefeat()
    elseif game.currentState == "CHARACTER_SELECT" then
        drawCharacterSelect()
    elseif game.currentState == "BATTLE" or game.currentState == "BATTLE_ATTRACT" then
        -- Draw background image
        love.graphics.setColor(1, 1, 1, 1)
        if game.backgroundImage then
            love.graphics.draw(game.backgroundImage, 0, 0)
        else
            -- Fallback to solid color if background image isn't loaded
            love.graphics.setColor(20/255, 20/255, 40/255, 1)
            love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
            love.graphics.setColor(1, 1, 1, 1) -- Reset color
        end

        -- Draw range state indicator (NEAR/FAR)
        if love.keyboard.isDown("`") then
            drawRangeIndicator()
        end

        -- Draw mana pool
        game.manaPool:draw()

        -- Draw wizards
        for _, wizard in ipairs(game.wizards) do
            wizard:draw()
        end

        -- Draw visual effects layer (between wizards and UI)
        game.vfx.draw()

        -- Draw UI elements in proper z-order
        love.graphics.setColor(1, 1, 1)

        -- First draw health bars and basic UI components
        UI.drawSpellInfo(game.wizards)

        -- Then draw spellbook buttons (the input feedback bar)
        UI.drawSpellbookButtons()

        -- Finally draw spellbook modals on top of everything else
        UI.drawSpellbookModals(game.wizards)

        -- If in attract mode, draw the attract mode overlay
        if game.currentState == "BATTLE_ATTRACT" then
            drawAttractModeOverlay()
        end
    elseif game.currentState == "GAME_OVER" or game.currentState == "GAME_OVER_ATTRACT" then
        -- Draw background image
        love.graphics.setColor(1, 1, 1, 1)
        if game.backgroundImage then
            love.graphics.draw(game.backgroundImage, 0, 0)
        else
            -- Fallback to solid color if background image isn't loaded
            love.graphics.setColor(20/255, 20/255, 40/255, 1)
            love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
            love.graphics.setColor(1, 1, 1, 1) -- Reset color
        end

        -- Draw game elements in the background (frozen in time)
        -- Draw range state indicator
        drawRangeIndicator()

        -- Draw mana pool
        game.manaPool:draw()

        -- Draw wizards
        for _, wizard in ipairs(game.wizards) do
            wizard:draw()
        end

        -- Draw visual effects layer
        game.vfx.draw()

        -- Draw win screen on top
        drawWinScreen()

        -- If in attract mode, draw the attract mode overlay
        if game.currentState == "GAME_OVER_ATTRACT" then
            drawAttractModeOverlay()
        end
    end
    
    -- Debug info only when debug key is pressed (available in all states)
    if love.keyboard.isDown("`") then
        UI.drawHelpText(game.font)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        
        -- Show current game state in debug mode
        love.graphics.print("State: " .. game.currentState, 10, 30)
        
        -- Show scaling info in debug mode
        love.graphics.print("Scale: " .. scale .. "x (" .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight() .. ")", 10, 50)
        
        -- Show asset cache stats in debug mode
        local stats = AssetCache.dumpStats()
        love.graphics.print(string.format("Assets: %d images, %d sounds loaded", 
                            stats.images.loaded, stats.sounds.loaded), 10, 70)

        -- Show Pool stats in debug mode
        if love.keyboard.isDown("p") then
            -- Draw pool statistics overlay
            Pool.drawDebugOverlay()
            -- Also show VFX-specific stats
            if game.vfx and game.vfx.showPoolStats then
                game.vfx.showPoolStats()
            end
        else
            love.graphics.print("Press P while in debug mode to see object pool stats", 10, 90)
        end
        
        -- Show hotkey summary when debug overlay is active
        if love.keyboard.isDown("tab") then
            drawHotkeyHelp()
        else
            love.graphics.print("Press TAB while in debug mode to see hotkeys", 10, 110)
        end
    else
        -- Always show a small hint about the debug key
        love.graphics.setColor(0.6, 0.6, 0.6, 0.4)
        love.graphics.print("Press ` for debug controls", 10, baseHeight - 20)
    end
    
    -- End scaling transform
    love.graphics.pop()
    
    -- Draw letterbox/pillarbox borders if needed
    if offsetX > 0 or offsetY > 0 then
        love.graphics.setColor(0, 0, 0)
        -- Top letterbox
        if offsetY > 0 then
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), offsetY)
            love.graphics.rectangle("fill", 0, love.graphics.getHeight() - offsetY, love.graphics.getWidth(), offsetY)
        end
        -- Left/right pillarbox
        if offsetX > 0 then
            love.graphics.rectangle("fill", 0, 0, offsetX, love.graphics.getHeight())
            love.graphics.rectangle("fill", love.graphics.getWidth() - offsetX, 0, offsetX, love.graphics.getHeight())
        end
    end
end

-- Helper function to convert real screen coordinates to virtual (scaled) coordinates
function screenToGameCoords(x, y)
    if not x or not y then return nil, nil end
    
    -- Adjust for offset and scale
    local virtualX = (x - offsetX) / scale
    local virtualY = (y - offsetY) / scale
    
    -- Check if the point is outside the game area
    if virtualX < 0 or virtualX > baseWidth or virtualY < 0 or virtualY > baseHeight then
        return nil, nil  -- Out of bounds
    end
    
    return virtualX, virtualY
end

-- Override love.mouse.getPosition for seamless integration
local original_getPosition = love.mouse.getPosition
love.mouse.getPosition = function()
    local rx, ry = original_getPosition()
    local vx, vy = screenToGameCoords(rx, ry)
    return vx or 0, vy or 0
end

-- Draw the win screen
function drawWinScreen()
    local screenWidth = baseWidth
    local screenHeight = baseHeight
    local winner = game.wizards[game.winner]
    
    -- Fade in effect
    local fadeProgress = math.min(game.winScreenTimer / 0.5, 1.0)
    
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7 * fadeProgress)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Determine winner's color scheme
    local winnerColor
    if game.winner == 1 then -- Ashgar
        winnerColor = {1.0, 0.4, 0.2} -- Fire-like
    else -- Selene
        winnerColor = {0.4, 0.4, 1.0} -- Moon-like
    end
    
    -- Calculate animation progress for text
    local textProgress = math.min(math.max(game.winScreenTimer - 0.5, 0) / 0.5, 1.0)
    local textScale = 1 + (1 - textProgress) * 3 -- Text starts larger and shrinks to normal size
    local textY = screenHeight / 2 - 100
    
    -- Draw winner text with animated scale
    love.graphics.setColor(winnerColor[1], winnerColor[2], winnerColor[3], textProgress)
    
    -- Main victory text
    local victoryText = winner.name .. " WINS!"
    local victoryTextWidth = game.font:getWidth(victoryText) * textScale * 3
    love.graphics.print(
        victoryText, 
        screenWidth / 2 - victoryTextWidth / 2, 
        textY,
        0, -- rotation
        textScale * 3, -- scale X
        textScale * 3  -- scale Y
    )
    
    -- Only show restart instructions after initial animation
    if game.winScreenTimer > 1.0 then
        -- Calculate pulse effect
        local pulse = 0.7 + 0.3 * math.sin(game.winScreenTimer * 4)
        
        -- Draw restart instruction with pulse effect
        local restartText = "Press [SPACE] to play again"
        local restartTextWidth = game.font:getWidth(restartText) * 1.5
        
        love.graphics.setColor(1, 1, 1, pulse)
        love.graphics.print(
            restartText,
            screenWidth / 2 - restartTextWidth / 2,
            textY + 150,
            0, -- rotation
            1.5, -- scale X
            1.5  -- scale Y
        )
        
        -- Show auto-restart countdown
        local remainingTime = math.ceil(game.winScreenDuration - game.winScreenTimer)
        local countdownText = "Auto-restart in " .. remainingTime .. "..."
        local countdownTextWidth = game.font:getWidth(countdownText)
        
        love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
        love.graphics.print(
            countdownText,
            screenWidth / 2 - countdownTextWidth / 2,
            textY + 200
        )
    end
    
    -- Draw some victory effect particles
    for i = 1, 3 do
        if math.random() < 0.3 then
            local x = math.random(screenWidth)
            local y = math.random(screenHeight)
            local size = math.random(10, 30)
            
            love.graphics.setColor(
                winnerColor[1], 
                winnerColor[2], 
                winnerColor[3], 
                math.random() * 0.3
            )
            love.graphics.circle("fill", x, y, size)
        end
    end
end

-- Function to draw the range indicator for NEAR/FAR states
function drawRangeIndicator()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local centerX = screenWidth / 2
    
    -- Only draw a subtle central line, without the text indicators
    -- The wizard positions themselves will communicate NEAR/FAR state
    
    -- Different visual style based on range state
    if game.rangeState == Constants.RangeState.NEAR then
        -- For NEAR state, draw a more vibrant, energetic line
        love.graphics.setColor(0.5, 0.5, 0.9, 0.4)
        
        -- Draw main line
        love.graphics.setLineWidth(1.5)
        love.graphics.line(centerX, 200, centerX, screenHeight - 100)
        
        -- Add a subtle energetic glow/pulse
        for i = 1, 5 do
            local pulseWidth = 3 + math.sin(love.timer.getTime() * 2.5) * 2
            local alpha = 0.12 - (i * 0.02)
            love.graphics.setColor(0.5, 0.5, 0.9, alpha)
            love.graphics.setLineWidth(pulseWidth * i)
            love.graphics.line(centerX, 200, centerX, screenHeight - 100)
        end
        love.graphics.setLineWidth(1)
    else
        -- For FAR state, draw a more distant, faded line
        love.graphics.setColor(0.3, 0.3, 0.7, 0.3)
        
        -- Draw main line with slight wave effect
        local segments = 12
        local segmentHeight = (screenHeight - 300) / segments
        local points = {}
        
        for i = 0, segments do
            local y = 200 + i * segmentHeight
            local wobble = math.sin(love.timer.getTime() + i * 0.3) * 1.5
            table.insert(points, centerX + wobble)
            table.insert(points, y)
        end
        
        love.graphics.setLineWidth(1)
        love.graphics.line(points)
        
        -- Add very subtle horizontal distortion lines
        for i = 1, 5 do
            local y = 200 + (i * (screenHeight - 300) / 6)
            local width = 15 + math.sin(love.timer.getTime() * 0.7 + i) * 5
            local alpha = 0.05
            love.graphics.setColor(0.3, 0.3, 0.7, alpha)
            love.graphics.setLineWidth(0.5)
            love.graphics.line(centerX - width, y, centerX + width, y)
        end
    end
    
    -- Reset line width
    love.graphics.setLineWidth(1)
end

-- Draw the main menu
function drawMainMenu()
    local screenWidth = baseWidth
    local screenHeight = baseHeight
    
    -- Draw a magical background effect
    love.graphics.setColor(20/255, 20/255, 40/255, 1) -- Dark blue background
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw animated arcane runes in the background
    for i = 1, 9 do
        local time = love.timer.getTime()
        local x = screenWidth * (0.1 + (i % 3) * 0.3)
        local y = screenHeight * (0.1 + math.floor(i / 3) * 0.3)
        local scale = 0.4 + 0.1 * math.sin(time + i)
        local alpha = 0.1 + 0.05 * math.sin(time * 0.5 + i * 0.7)
        local rotation = time * 0.1 * (i % 2 == 0 and 1 or -1)
        local runeTexture = AssetCache.getImage("assets/sprites/runes/rune" .. i .. ".png")
        
        if runeTexture then
            love.graphics.setColor(0.4, 0.4, 0.8, alpha)
            love.graphics.draw(
                runeTexture, 
                x, y, 
                rotation,
                scale, scale,
                runeTexture:getWidth()/2, runeTexture:getHeight()/2
            )
        end
    end
    
    -- Initialize token position history on first run
    if not game.menuTokenTrails then
        game.menuTokenTrails = {}
        for i = 1, 9 do
            game.menuTokenTrails[i] = {}
        end
    end
    
    -- Draw floating mana tokens in a circular arrangement around the content
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    local orbitRadius = 200  -- Larger orbit radius for the tokens to circle around content
    local numTokens = 9      -- Exactly 9 tokens to show all token types
    local trailLength = 75   -- Length of the trail (5x longer than original 15)
    
    -- Track token positions for triangle drawing
    local tokenPositions = {}
    
    -- First, draw the triangles BEFORE the tokens to ensure they appear behind
    -- We'll collect positions first with a dry run through the token calculations
    for i = 1, numTokens do
        local time = love.timer.getTime()
        -- Calculate position on a circle with some oscillation
        local angle = (i / numTokens) * math.pi * 2 + time * 0.2  -- Rotate around slowly over time
        local radiusVariation = 20 * math.sin(time * 0.5 + i)     -- Make orbit radius pulse
        
        -- Calculate x,y position on the orbit
        local x = centerX + math.cos(angle) * (orbitRadius + radiusVariation)
        local y = centerY + math.sin(angle) * (orbitRadius + radiusVariation)
        
        -- Add some vertical bounce
        y = y + 15 * math.sin(time * 0.7 + i * 0.5)
        
        -- Store token position for triangle drawing
        tokenPositions[i] = {x = x, y = y}
    end
    
    -- Store triangle data for drawing later
    local triangleData = {}
    
    if #tokenPositions == numTokens then
        local time = love.timer.getTime()
        
        -- Set up triangle groups
        local triangleGroups = {
            {1, 4, 7}, -- First triangle group
            {2, 5, 8}, -- Second triangle group
            {3, 6, 9}  -- Third triangle group
        }
        
        -- Prepare triangle data
        for tIndex, group in ipairs(triangleGroups) do
            -- Get color based on the first token in the group
            local tokenType = game.tokenTypes[group[1]]
            local colorTable = Constants.getColorForTokenType(tokenType)
            
            -- Create a more pronounced pulsing effect for the lines
            local pulseRate = 0.5 + tIndex * 0.2 -- Different pulse rate for each triangle
            -- More dramatic pulsing effect
            local pulseAmount = 0.12 + 0.1 * math.sin(time * pulseRate) 
            
            -- Store color and alpha information with slightly increased base values
            local triangleInfo = {
                color = colorTable,
                alpha = 0.22 + pulseAmount, -- Higher base alpha for more visibility
                points = {}
            }
            
            -- Calculate triangle points with wobble
            for _, tokenIdx in ipairs(group) do
                if tokenPositions[tokenIdx] then
                    -- Add a small wobble to the connection points
                    local wobbleX = 2 * math.sin(time * 1.2 + tokenIdx * 0.7)
                    local wobbleY = 2 * math.cos(time * 1.1 + tokenIdx * 0.9)
                    
                    table.insert(triangleInfo.points, tokenPositions[tokenIdx].x + wobbleX)
                    table.insert(triangleInfo.points, tokenPositions[tokenIdx].y + wobbleY)
                end
            end
            
            -- Add to triangleData collection if we have enough points
            if #triangleInfo.points >= 6 then
                table.insert(triangleData, triangleInfo)
            end
        end
    end
    
    -- First draw the triangles (BEHIND the tokens and trails)
    -- Draw the triangles using the data we collected earlier
    for _, triangle in ipairs(triangleData) do
        -- Draw a glow effect behind the lines first (thicker, more transparent)
        for i = 1, 3 do -- Three layers of glow
            local glowAlpha = triangle.alpha * 0.7 * (1 - (i-1) * 0.25) -- Fade out in layers
            local glowWidth = 3.5 + (i-1) * 2.5 -- Get wider with each layer
            
            love.graphics.setColor(triangle.color[1], triangle.color[2], triangle.color[3], glowAlpha)
            love.graphics.setLineWidth(glowWidth)
            
            -- Draw the triangle outline with glow
            love.graphics.line(triangle.points[1], triangle.points[2], triangle.points[3], triangle.points[4])
            love.graphics.line(triangle.points[3], triangle.points[4], triangle.points[5], triangle.points[6])
            love.graphics.line(triangle.points[5], triangle.points[6], triangle.points[1], triangle.points[2])
        end
        
        -- Draw the main triangle lines (thicker than before)
        love.graphics.setColor(triangle.color[1], triangle.color[2], triangle.color[3], triangle.alpha * 1.2)
        love.graphics.setLineWidth(2.5) -- Thicker main line
        
        -- Draw the triangle outline
        love.graphics.line(triangle.points[1], triangle.points[2], triangle.points[3], triangle.points[4])
        love.graphics.line(triangle.points[3], triangle.points[4], triangle.points[5], triangle.points[6])
        love.graphics.line(triangle.points[5], triangle.points[6], triangle.points[1], triangle.points[2])
    end
    
    -- Now draw the tokens and their trails (on top of the triangles)
    for i = 1, numTokens do
        local time = love.timer.getTime()
        -- Ensure we display each token type exactly once
        local tokenType = game.tokenTypes[i]
        local tokenImage = AssetCache.getImage(game.tokenImages[tokenType])
        
        if tokenImage then
            -- Calculate position on a circle with some oscillation
            local angle = (i / numTokens) * math.pi * 2 + time * 0.2  -- Rotate around slowly over time
            local radiusVariation = 20 * math.sin(time * 0.5 + i)     -- Make orbit radius pulse
            
            -- Calculate x,y position on the orbit
            local x = centerX + math.cos(angle) * (orbitRadius + radiusVariation)
            local y = centerY + math.sin(angle) * (orbitRadius + radiusVariation)
            
            -- Add some vertical bounce
            y = y + 15 * math.sin(time * 0.7 + i * 0.5)
            
            -- Store token position for triangle drawing
            tokenPositions[i] = {x = x, y = y}
            
            -- Keep token size large but vary slightly for animation
            local tokenScale = 1.8 + 0.3 * math.sin(time + i * 0.3)
            local rotation = time * 0.2 * (i % 2 == 0 and 1 or -1)
            
            -- Get color for this token type
            local colorTable = Constants.getColorForTokenType(tokenType)
            
            -- Update position history for trail effect
            if not game.menuTokenTrails[i] then
                game.menuTokenTrails[i] = {}
            end
            
            -- Store new position at the beginning of history array
            table.insert(game.menuTokenTrails[i], 1, {x = x, y = y, time = time})
            
            -- Limit trail length
            if #game.menuTokenTrails[i] > trailLength then
                table.remove(game.menuTokenTrails[i])
            end
            
            -- Draw the trailing effect first (behind the token)
            -- For efficiency with longer trails, only draw every other point for trails > 30
            local stepSize = (#game.menuTokenTrails[i] > 30) and 2 or 1
            
            for j = #game.menuTokenTrails[i], 2, -stepSize do
                local pos = game.menuTokenTrails[i][j]
                local timeDiff = time - pos.time
                
                -- Calculate fade based on position in trail (older = more transparent)
                -- Use a slower fade rate for longer trails
                local trailAlpha = 0.25 * (1 - (j / trailLength)^1.5)
                
                -- Gradually reduce size for trail particles
                -- Adjusted scale formula for longer trails - slower decrease
                local trailScale = 18 * (1 - (j / trailLength) * 0.6)
                
                -- Draw trail particle
                love.graphics.setColor(colorTable[1], colorTable[2], colorTable[3], trailAlpha)
                love.graphics.circle("fill", pos.x, pos.y, trailScale)
            end
            
            -- Draw smaller glow behind token (reduced aura size)
            love.graphics.setColor(colorTable[1], colorTable[2], colorTable[3], 0.3)
            -- Reduce the aura size multiplier from 50 to 35
            love.graphics.circle("fill", x, y, 35 * tokenScale)
            
            -- Draw token with same large scale as before
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.draw(
                tokenImage, 
                x, y, 
                rotation,
                tokenScale, tokenScale,
                tokenImage:getWidth()/2, tokenImage:getHeight()/2
            )
        end
    end
    
    -- Now draw all menu text ON TOP of everything else
    
    -- Draw title with a magical glow effect
    local titleY = screenHeight * 0.25
    local titleScale = 4
    local titleText = "MANASTORM"
    local titleWidth = game.font:getWidth(titleText) * titleScale
    
    -- Draw glow behind title
    local glowColor = {0.3, 0.3, 0.9, 0.3}
    local glowSize = 15 + 5 * math.sin(love.timer.getTime() * 2)
    love.graphics.setColor(glowColor)
    for i = 1, 3 do
        love.graphics.print(
            titleText,
            screenWidth/2 - titleWidth/2 + math.random(-2, 2), 
            titleY + math.random(-2, 2),
            0,
            titleScale, titleScale
        )
    end
    
    -- Draw main title
    love.graphics.setColor(0.9, 0.9, 1, 1)
    love.graphics.print(
        titleText,
        screenWidth/2 - titleWidth/2, 
        titleY,
        0,
        titleScale, titleScale
    )
    
    -- Draw subtitle
    local subtitleText = "Chosen of the Ninefold Circle"
    local subtitleScale = 2
    local subtitleWidth = game.font:getWidth(subtitleText) * subtitleScale
    
    love.graphics.setColor(0.7, 0.7, 1, 0.9)
    love.graphics.print(
        subtitleText,
        screenWidth/2 - subtitleWidth/2,
        titleY + 60,
        0,
        subtitleScale, subtitleScale
    )
    
    -- Draw menu options
    local menuY = screenHeight * 0.55
    local menuSpacing = 40
    local menuScale = 1.4

    local options = {
        {"[1] Campaign", {0.9, 0.9, 0.9, 0.9}},
        {"[2] Character Duel", {0.9, 0.7, 0.1, 0.9}},
        {"[3] Research Duel", {0.7, 0.9, 0.2, 0.9}},
        {"[4] Compendium", {0.7, 0.8, 1.0, 0.9}},
        {"[5] Settings", {0.8, 0.8, 0.8, 0.9}},
        {"[6] Exit", {0.7, 0.7, 0.7, 0.9}}
    }

    for i, option in ipairs(options) do
        local text, color = option[1], option[2]
        local width = game.font:getWidth(text) * menuScale
        love.graphics.setColor(color)
        love.graphics.print(text, screenWidth/2 - width/2, menuY + (i-1)*menuSpacing, 0, menuScale, menuScale)
    end
    
    -- Draw version and credit
    local versionText = "v0.1 - Demo"
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.print(versionText, 10, screenHeight - 30)
end

-- Draw the campaign character selection menu
function drawCampaignMenu()
    local screenWidth = baseWidth
    local screenHeight = baseHeight

    love.graphics.setColor(20/255, 20/255, 40/255, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    local unlocked = getUnlockedCharacterList()
    local spacing = 30
    local startY = screenHeight * 0.4

    for i, name in ipairs(unlocked) do
        local y = startY + (i - 1) * spacing
        if i == game.campaignMenu.selectedCharacterIndex then
            love.graphics.setColor(1, 0.8, 0.3, 1)
        else
            love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
        end
        local w = game.font:getWidth(name)
        love.graphics.print(name, screenWidth/2 - w/2, y)
    end

    love.graphics.setColor(0.7, 0.7, 1, 0.8)
    local hint = "Choose your wizard"
    local hw = game.font:getWidth(hint)
    love.graphics.print(hint, screenWidth/2 - hw/2, startY - spacing)
end

-- Draw the campaign defeat screen
function drawCampaignDefeat()
    local screenWidth = baseWidth
    local screenHeight = baseHeight

    love.graphics.setColor(20/255, 20/255, 40/255, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    local title = "Campaign Failed"
    local titleScale = 2.5
    local tw = game.font:getWidth(title) * titleScale
    love.graphics.setColor(1, 0.6, 0.6, 1)
    love.graphics.print(title, screenWidth/2 - tw/2, screenHeight*0.4, 0, titleScale, titleScale)

    local options = {
        "[R] Restart Campaign",
        "[SPACE] Retry Battle",
        "[ESC] Main Menu"
    }
    local startY = screenHeight * 0.6
    for i, text in ipairs(options) do
        local w = game.font:getWidth(text)
        love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
        love.graphics.print(text, screenWidth/2 - w/2, startY + (i-1)*30)
    end
end

-- Draw the character selection screen
function drawCharacterSelect()
    local screenWidth = baseWidth
    local screenHeight = baseHeight
    love.graphics.setColor(20/255,20/255,40/255,1)
    love.graphics.rectangle("fill",0,0,screenWidth,screenHeight)

    local paneWidth = screenWidth/3
    local cellSize = 60
    local padding = 10
    local gridWidth = cellSize*3 + padding*2
    local gridHeight = cellSize*3 + padding*2
    local gridX = paneWidth + (paneWidth - gridWidth)/2
    local gridY = screenHeight/2 - gridHeight/2

    -- Helper to draw a character sprite
    local function drawSprite(name,x,y,scale)
        local sprite = AssetCache.getImage("assets/sprites/"..string.lower(name)..".png")
        if sprite then
            love.graphics.draw(sprite,x,y,0,scale,scale,sprite:getWidth()/2,sprite:getHeight()/2)
        else
            love.graphics.print(name,x-20,y-5)
        end
    end

    -- Draw selected characters in side panes
    if game.characterSelect.selected[1] then
        love.graphics.setColor(1,1,1)
        drawSprite(game.characterSelect.selected[1],paneWidth/2,screenHeight/2,2)
    end
    if game.characterSelect.selected[2] then
        love.graphics.setColor(1,1,1)
        drawSprite(game.characterSelect.selected[2],screenWidth-paneWidth/2,screenHeight/2,2)
    end

    -- Draw grid of characters
    for i,name in ipairs(game.characterRoster) do
        local col=(i-1)%3
        local row=math.floor((i-1)/3)
        local x=gridX+col*(cellSize+padding)
        local y=gridY+row*(cellSize+padding)

        local unlocked = game.unlockedCharacters[name]
        love.graphics.setColor(0.4,0.4,0.4)
        love.graphics.rectangle("fill",x,y,cellSize,cellSize)

        local scale = cellSize/64
        if unlocked then
            love.graphics.setColor(1,1,1)
            drawSprite(name,x+cellSize/2,y+cellSize/2,scale)
        else
            love.graphics.setColor(0,0,0)
            drawSprite(name,x+cellSize/2,y+cellSize/2,scale)
        end

        if game.characterSelect.cursor==i then
            love.graphics.setColor(1,1,0)
            love.graphics.rectangle("line",x-2,y-2,cellSize+4,cellSize+4)
        end
    end

    -- Instruction text
    love.graphics.setColor(1,1,1,0.8)
    local msg
    if game.characterSelect.stage==1 then
        msg = "Select Your Wizard"
    elseif game.characterSelect.stage==2 then
        msg = "Select Opponent"
    else
        msg = "Press F to Fight!"
    end
    local w = game.font:getWidth(msg)
    love.graphics.print(msg,screenWidth/2 - w/2,gridY+gridHeight+20)
end

-- Draw the settings menu
function drawSettingsMenu()
    local screenWidth = baseWidth
    local screenHeight = baseHeight
    love.graphics.setColor(20/255, 20/255, 40/255, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    local options = {
        "Dummy Flag: " .. tostring(Settings.get("dummyFlag")),
        "Game Speed: " .. (Settings.get("gameSpeed") or "FAST"),
        "Rebind Controls"
    }

    for i, text in ipairs(options) do
        local scale = 1.4
        local y = screenHeight * 0.4 + (i-1) * 40
        local w = game.font:getWidth(text) * scale
        if i == game.settingsMenu.selected and not game.settingsMenu.mode then
            love.graphics.setColor(1, 0.8, 0.3, 1)
        else
            love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
        end
        love.graphics.print(text, screenWidth/2 - w/2, y, 0, scale, scale)
    end

    if game.settingsMenu.waitingForKey then
        local msg = "Press new key for " .. game.settingsMenu.waitingForKey.label
        local scale = 1.2
        local w = game.font:getWidth(msg) * scale
        love.graphics.setColor(1, 0.6, 0.6, 1)
        love.graphics.print(msg, screenWidth/2 - w/2, screenHeight - 60, 0, scale, scale)
    end
end

function drawCompendium()
    local screenWidth = baseWidth
    local screenHeight = baseHeight
    
    -- Background with gradient effect
    local bgColorTop = {15/255, 15/255, 35/255, 1}
    local bgColorBottom = {30/255, 30/255, 50/255, 1}
    
    -- Draw gradient background
    love.graphics.setColor(bgColorTop)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight/2)
    love.graphics.setColor(bgColorBottom)
    love.graphics.rectangle("fill", 0, screenHeight/2, screenWidth, screenHeight/2)
    
    -- Calculate pane dimensions with padding
    local panePadding = 12
    local headerHeight = 50 -- Reduced height for the title area
    local footerHeight = 45 -- Height for the footer controls
    local paneWidth = (screenWidth - panePadding * 3) / 2
    local paneHeight = (screenHeight - panePadding * 3 - headerHeight - footerHeight) / 2
    
    -- Define pane coordinates
    local panes = {
        topLeft = {
            x = panePadding,
            y = panePadding + headerHeight,
            w = paneWidth,
            h = paneHeight,
            title = "Spell Details"
        },
        topRight = {
            x = panePadding * 2 + paneWidth,
            y = panePadding + headerHeight,
            w = paneWidth,
            h = paneHeight,
            title = "Character Info"
        },
        bottomLeft = {
            x = panePadding,
            y = panePadding * 2 + paneHeight + headerHeight,
            w = paneWidth,
            h = paneHeight,
            title = "Available Spells"
        },
        bottomRight = {
            x = panePadding * 2 + paneWidth,
            y = panePadding * 2 + paneHeight + headerHeight,
            w = paneWidth,
            h = paneHeight,
            title = "Equipped Spells"
        }
    }
    
    -- Get character data
    local name = game.characterRoster[game.compendium.page]
    local data = game.characterData[name]
    
    -- Check if character is unlocked
    local isUnlocked = game.unlockedCharacters[name] or false
    
    -- Draw decorative header line
    love.graphics.setColor(0.4, 0.4, 0.7, 0.5)
    love.graphics.rectangle("fill", 20, headerHeight - 5, screenWidth - 40, 2)
    
    -- Draw main title with shadow effect
    local title
    if isUnlocked then
        title = "Compendium - " .. name
    else
        title = "Compendium - ???"
    end
    
    -- Shadow
    love.graphics.setColor(0.2, 0.2, 0.4, 0.6)
    love.graphics.print(title, screenWidth/2 - game.font:getWidth(title)/2 + 2, 22, 0, 1.5, 1.5)
    
    -- Title text
    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.print(title, screenWidth/2 - game.font:getWidth(title)/2, 20, 0, 1.5, 1.5)
    
    -- Draw the four panes with distinct colors and titles
    for paneName, pane in pairs(panes) do
        -- Draw pane background with slight transparency and gradient
        local bgColor1, bgColor2
        
        -- Different subtle coloring for each pane
        if paneName == "topLeft" then
            bgColor1 = {0.12, 0.12, 0.22, 0.9}
            bgColor2 = {0.15, 0.15, 0.25, 0.9}
        elseif paneName == "topRight" then
            bgColor1 = {0.14, 0.12, 0.22, 0.9}
            bgColor2 = {0.17, 0.15, 0.25, 0.9}
        elseif paneName == "bottomLeft" then
            bgColor1 = {0.12, 0.14, 0.22, 0.9}
            bgColor2 = {0.15, 0.17, 0.25, 0.9}
        else -- bottomRight
            bgColor1 = {0.13, 0.13, 0.23, 0.9}
            bgColor2 = {0.16, 0.16, 0.26, 0.9}
        end
        
        -- Draw gradient background
        love.graphics.setColor(bgColor1)
        love.graphics.rectangle("fill", pane.x, pane.y, pane.w, pane.h/2)
        love.graphics.setColor(bgColor2)
        love.graphics.rectangle("fill", pane.x, pane.y + pane.h/2, pane.w, pane.h/2)
        
        -- Draw pane border with rounded corners
        love.graphics.setColor(0.4, 0.4, 0.6, 0.8)
        love.graphics.rectangle("line", pane.x, pane.y, pane.w, pane.h, 3, 3)
        
        -- Draw title background
        love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
        love.graphics.rectangle("fill", pane.x, pane.y, pane.w, 30, 3, 3)
        
        -- Draw separator line under title
        love.graphics.setColor(0.4, 0.4, 0.6, 0.5)
        love.graphics.rectangle("fill", pane.x + 5, pane.y + 30, pane.w - 10, 1)
        
        -- Draw pane title with slight shadow
        love.graphics.setColor(0.3, 0.3, 0.4, 0.8)
        love.graphics.print(pane.title, pane.x + 11, pane.y + 8)
        love.graphics.setColor(0.9, 0.9, 1)
        love.graphics.print(pane.title, pane.x + 10, pane.y + 7)
    end
    
    -- Draw detailed content for each pane
    
    -- Top Left: Selected Spell Details
    local selectedSpell = nil
    local spells = data.spells or {}
    if #spells > 0 and game.compendium.cursor <= #spells then
        selectedSpell = spells[game.compendium.cursor]
    end
    
    local pane = panes.topLeft
    if selectedSpell then
        -- Set scissor to clip content to pane
        setScaledScissor(pane.x, pane.y + 35, pane.w, pane.h - 40)
        
        -- Spell name with larger font
        love.graphics.setColor(1, 1, 0.8)
        local nameY = pane.y + 40
        
        if isUnlocked then
            love.graphics.print(selectedSpell.name, pane.x + 15, nameY, 0, 1.3, 1.3)
        else
            -- For locked characters, replace name with question marks
            local lockedName = string.rep("?", #selectedSpell.name)
            love.graphics.print(lockedName, pane.x + 15, nameY, 0, 1.3, 1.3)
        end
        
        -- Spell properties
        love.graphics.setColor(0.9, 0.9, 0.9)
        local propY = nameY + 30
        
        if isUnlocked then
            -- Affinity
            love.graphics.print("Affinity: " .. (selectedSpell.affinity or "None"), pane.x + 15, propY)
            
            -- Attack Type
            love.graphics.print("Type: " .. (selectedSpell.attackType or "None"), pane.x + 15, propY + 20)
            
            -- Cast Time
            local castTimeText = "Cast Time: " .. (selectedSpell.castTime or 0) .. "s"
            love.graphics.print(castTimeText, pane.x + 15, propY + 40)
            
            -- Mana Cost with token icons
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print("Cost:", pane.x + 15, propY + 60)
        else
            -- For locked characters, show mysterious text
            love.graphics.print("Affinity: ???", pane.x + 15, propY)
            love.graphics.print("Type: ???", pane.x + 15, propY + 20)
            love.graphics.print("Cast Time: ??.?s", pane.x + 15, propY + 40)
            love.graphics.print("Cost: ???", pane.x + 15, propY + 60)
        end
        
        if isUnlocked and selectedSpell.cost and #selectedSpell.cost > 0 then
            local iconSize = 16
            local spacing = 5
            local startX = pane.x + 60
            
            for i, tokenType in ipairs(selectedSpell.cost) do
                -- Position for this token icon
                local x = startX + (i-1) * (iconSize + spacing)
                
                -- Get token image if available
                if game.tokenImages and game.tokenImages[tokenType] then
                    local tokenImg = AssetCache.getImage(game.tokenImages[tokenType])
                    if tokenImg then
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.draw(tokenImg, x, propY + 57, 0, iconSize/tokenImg:getWidth(), iconSize/tokenImg:getHeight())
                    else
                        -- Fallback if image not loaded
                        love.graphics.setColor(0.8, 0.7, 0.9)
                        love.graphics.print(tokenType, x, propY + 60)
                    end
                else
                    -- Fallback if no image defined
                    love.graphics.setColor(0.8, 0.7, 0.9)
                    love.graphics.print(tokenType, x, propY + 60)
                end
            end
        elseif not isUnlocked then
            -- Do not show any token images for locked characters
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("None", pane.x + 60, propY + 60)
        end
        
        -- Description (with word wrapping)
        if selectedSpell.description then
            love.graphics.setColor(0.8, 0.8, 0.8)
            local descY = propY + 90
            love.graphics.printf("Description:", pane.x + 15, descY, pane.w - 30)
            
            if isUnlocked then
                love.graphics.setColor(0.7, 0.7, 0.8)
                love.graphics.printf(selectedSpell.description, pane.x + 15, descY + 25, pane.w - 30)
            else
                -- Show redacted description for locked characters
                love.graphics.setColor(0.7, 0.7, 0.8)
                love.graphics.printf(string.rep("?", 100), pane.x + 15, descY + 25, pane.w - 30)
            end
        end
        
        -- Draw keywords if present
        if selectedSpell.keywords and next(selectedSpell.keywords) then
            local keywordY = propY + 170
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print("Keywords:", pane.x + 15, keywordY)
            
            love.graphics.setColor(0.6, 0.8, 0.6)
            local y = keywordY + 25
            for keyword, params in pairs(selectedSpell.keywords) do
                local keywordText = "- " .. keyword
                if type(params) == "table" and next(params) then
                    keywordText = keywordText .. " (" 
                    local paramTexts = {}
                    for k, v in pairs(params) do
                        table.insert(paramTexts, k .. ": " .. tostring(v))
                    end
                    keywordText = keywordText .. table.concat(paramTexts, ", ") .. ")"
                end
                love.graphics.print(keywordText, pane.x + 20, y)
                y = y + 20
            end
        end
        
        -- Reset scissor
        love.graphics.setScissor()
    elseif selectedSpell and not isUnlocked then
        -- Character is locked, show mystery message
        setScaledScissor(pane.x, pane.y + 35, pane.w, pane.h - 40)
        
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.print("???", pane.x + 15, pane.y + 60, 0, 1.3, 1.3)
        
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.print("Unlock this character to view spell details", 
                           pane.x + 15, pane.y + 100)
        
        love.graphics.setScissor()
    else
        -- No spell selected
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("Select a spell to see details", pane.x + 15, pane.y + 60)
    end
    
    -- Bottom Left: Available spells with scrolling
    local pane = panes.bottomLeft
    local spells = data.spells or {}
    local spellCount = #spells
    local spellLineHeight = 20 -- Height of each spell entry
    local maxVisibleSpells = math.floor((pane.h - 50) / spellLineHeight) -- 50px for padding/header
    
    -- Set a scissor to clip content to the pane
    setScaledScissor(pane.x, pane.y + 35, pane.w, pane.h - 40)
    
    if isUnlocked then
        -- Draw visible spells for unlocked characters
        for i = 1, maxVisibleSpells do
            local spellIdx = i + game.compendium.scrollOffset
            if spellIdx <= spellCount then
                local spell = spells[spellIdx]
                local y = pane.y + 40 + (i-1)*spellLineHeight
                
                -- Highlight selected spell
                if spellIdx == game.compendium.cursor then
                    love.graphics.setColor(0.3, 0.3, 0.5, 0.7)
                    love.graphics.rectangle("fill", pane.x + 5, y - 2, pane.w - 10, spellLineHeight)
                    love.graphics.setColor(1, 1, 0)
                else
                    love.graphics.setColor(0.9, 0.9, 0.9)
                end
                
                -- Show spell name, grayed out if locked
                local text = spell.name
                if not game.unlockedSpells[spell.id] then
                    text = "[LOCKED] " .. text
                    love.graphics.setColor(0.6, 0.6, 0.6)
                end
                love.graphics.print(text, pane.x + 20, y)
            end
        end
    else
        -- For locked characters, show mystery entries
        for i = 1, 5 do
            local y = pane.y + 40 + (i-1)*spellLineHeight
            
            if i == game.compendium.cursor then
                love.graphics.setColor(0.3, 0.3, 0.5, 0.7)
                love.graphics.rectangle("fill", pane.x + 5, y - 2, pane.w - 10, spellLineHeight)
                love.graphics.setColor(0.7, 0.7, 0.7)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
            end
            
            -- Mystery text
            love.graphics.print("???", pane.x + 20, y)
        end
        
        -- Message about unlocking
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.print("Unlock this character to see spells", 
                           pane.x + 20, pane.y + 40 + 6*spellLineHeight)
    end
    
    -- Draw scrollbar if needed
    if spellCount > maxVisibleSpells then
        love.graphics.setColor(0.4, 0.4, 0.6, 0.8)
        local scrollBarHeight = pane.h - 45
        local scrollThumbHeight = math.max(20, scrollBarHeight * (maxVisibleSpells / spellCount))
        local scrollThumbPos = (game.compendium.scrollOffset / (spellCount - maxVisibleSpells)) * 
                               (scrollBarHeight - scrollThumbHeight)
        
        -- Draw track
        love.graphics.setColor(0.2, 0.2, 0.3, 0.5)
        love.graphics.rectangle("fill", pane.x + pane.w - 15, pane.y + 40, 10, scrollBarHeight)
        
        -- Draw thumb
        love.graphics.setColor(0.4, 0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", 
                                pane.x + pane.w - 15, 
                                pane.y + 40 + scrollThumbPos, 
                                10, 
                                scrollThumbHeight)
    end
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Top Right: Character View
    local pane = panes.topRight
    setScaledScissor(pane.x, pane.y + 35, pane.w, pane.h - 40)
    
    -- Character name with larger font
    love.graphics.setColor(1, 1, 0.8)
    if isUnlocked then
        love.graphics.print(name, pane.x + pane.w/2 - game.font:getWidth(name)/2, pane.y + 45, 0, 1.3, 1.3)
    else
        local hiddenName = "???"
        love.graphics.print(hiddenName, pane.x + pane.w/2 - game.font:getWidth(hiddenName)/2, pane.y + 45, 0, 1.3, 1.3)
    end
    
    -- Character sprite
    local spriteY = pane.y + 80
    local spriteFileName = "assets/sprites/" .. string.lower(name) .. ".png"
    local sprite = AssetCache.getImage(spriteFileName)
    
    if sprite then
        -- For unlocked characters, show normal sprite. For locked, show silhouette
        if isUnlocked then
            love.graphics.setColor(1, 1, 1)
        else
            -- Silhouette color - complete black for a more compelling tease
            love.graphics.setColor(0, 0, 0, 1)
        end
        
        -- Calculate scaled dimensions to fit in the pane while maintaining aspect ratio
        local baseScale = 3 -- Increased base scale by 3x as requested
        local maxWidth = pane.w - 40
        local maxHeight = pane.h - 150
        
        local spriteWidth = sprite:getWidth()
        local spriteHeight = sprite:getHeight()
        
        -- Start with the 3x scale, but reduce if needed to fit
        local scale = baseScale
        if (spriteWidth * scale) > maxWidth or (spriteHeight * scale) > maxHeight then
            local scaleX = maxWidth / spriteWidth
            local scaleY = maxHeight / spriteHeight
            scale = math.min(scaleX, scaleY)
        end
        
        local scaledWidth = spriteWidth * scale
        local scaledHeight = spriteHeight * scale
        local x = pane.x + (pane.w - scaledWidth) / 2
        
        love.graphics.draw(sprite, x, spriteY, 0, scale, scale)
        
        -- Character color display as a color box (only for unlocked characters)
        if data.color and isUnlocked then
            local colorY = spriteY + scaledHeight + 20
            love.graphics.setColor(data.color[1]/255, data.color[2]/255, data.color[3]/255)
            love.graphics.rectangle("fill", pane.x + pane.w/2 - 40, colorY, 80, 20)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", pane.x + pane.w/2 - 40, colorY, 80, 20)
            
            -- Label for the color
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print("Character Color", 
                                pane.x + pane.w/2 - game.font:getWidth("Character Color")/2, 
                                colorY + 30)
        elseif data.color and not isUnlocked then
            -- For locked characters, show a mystery color box
            local colorY = spriteY + scaledHeight + 20
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", pane.x + pane.w/2 - 40, colorY, 80, 20)
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.rectangle("line", pane.x + pane.w/2 - 40, colorY, 80, 20)
            
            -- Mystery label
            love.graphics.setColor(0.6, 0.6, 0.6)
            local hiddenLabel = "???"
            love.graphics.print(hiddenLabel, 
                                pane.x + pane.w/2 - game.font:getWidth(hiddenLabel)/2, 
                                colorY + 30)
        end
    else
        -- Fallback if sprite not found
        if isUnlocked then
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("Character sprite not available", 
                                pane.x + 20, 
                                pane.y + 100)
        else
            -- Black rectangle silhouette as fallback for locked characters
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", pane.x + pane.w/2 - 40, pane.y + 100, 80, 120)
        end
    end
    
    love.graphics.setScissor()
    
    -- Bottom Right: Configured Spellbook View
    local pane = panes.bottomRight
    setScaledScissor(pane.x, pane.y + 35, pane.w, pane.h - 40)
    
    -- Slot key input mappings
    local keyMapping = {
        ["1"] = "1",
        ["2"] = "2",
        ["3"] = "3",
        ["12"] = "1+2",
        ["13"] = "1+3",
        ["23"] = "2+3",
        ["123"] = "1+2+3"
    }
    
    -- Get active spellbook (custom or default)
    local active = game.customSpellbooks[name] or data.spellbook
    
    -- Instructions
    love.graphics.setColor(0.8, 0.8, 0.8)
    if isUnlocked then
        love.graphics.print("Select a spell and press 1-7 to assign", pane.x + 15, pane.y + 40)
    else
        love.graphics.print("Unlock this character to modify spells", pane.x + 15, pane.y + 40)
    end
    
    -- Draw each slot
    for i, key in ipairs(slotKeys) do
        local spell = active[key]
        local y = pane.y + 70 + (i-1)*28
        
        -- Check if a number key is being held to highlight slot
        local isSlotSelected = false
        if isUnlocked and game.currentState == "COMPENDIUM" and game.menuInput and game.menuInput[tostring(i)] then
            isSlotSelected = true
        end
        
        -- Check if this slot has the assignment feedback active
        local isAssignFeedback = isUnlocked and game.compendium.assignFeedback.active and 
                                game.compendium.assignFeedback.slot == i
        
        -- Slot background
        if isAssignFeedback then
            -- Bright successful assignment highlight
            love.graphics.setColor(0.3, 0.8, 0.3, 0.7)
        elseif isSlotSelected then
            -- Selection highlight when hovering
            love.graphics.setColor(0.4, 0.5, 0.4, 0.7)
        else
            -- Normal background
            love.graphics.setColor(0.25, 0.25, 0.35, 0.7)
        end
        love.graphics.rectangle("fill", pane.x + 10, y - 3, pane.w - 20, 24)
        
        -- Slot border
        love.graphics.setColor(0.4, 0.4, 0.6)
        love.graphics.rectangle("line", pane.x + 10, y - 3, pane.w - 20, 24)
        
        -- Slot input hint
        love.graphics.setColor(1, 1, 0.6)
        local inputHint = "[" .. keyMapping[key] .. "]"
        love.graphics.print(inputHint, pane.x + 15, y)
        
        -- Slot assigned spell
        local displayText
        if isUnlocked then
            if spell then
                love.graphics.setColor(1, 1, 1)
                displayText = spell.name
            else
                love.graphics.setColor(0.6, 0.6, 0.6)
                displayText = "--- Empty ---"
            end
        else
            -- For locked characters, show redacted text
            love.graphics.setColor(0.6, 0.6, 0.6)
            displayText = "??? ?????"
        end
        
        -- Calculate position for the spell name so it's properly spaced from the input hint
        local hintWidth = game.font:getWidth(inputHint)
        love.graphics.print(displayText, pane.x + 25 + hintWidth, y)
    end
    
    -- Draw explanatory text about the slot system
    love.graphics.setColor(0.7, 0.7, 0.8, 0.8)
    local explanationY = pane.y + 70 + 7 * 28 + 15
    
    if isUnlocked then
        love.graphics.printf(
            "Combine keys to cast different spells. For example, pressing 1+2 together will cast the spell assigned to slot 4.",
            pane.x + 15, 
            explanationY,
            pane.w - 30
        )
    else
        love.graphics.printf(
            "???????? ???? ?? ???? ????????? ?????? ???????? ??? ???????? ???? ???? ?? ???? ? ??????",
            pane.x + 15, 
            explanationY,
            pane.w - 30
        )
    end
    
    love.graphics.setScissor()
    
    -- Display assignment error message if present
    if game.assignmentError and game.assignmentError.timer > 0 then
        love.graphics.setColor(1, 0.3, 0.3, math.min(1, game.assignmentError.timer))
        love.graphics.printf(
            game.assignmentError.message,
            screenWidth/2 - 200,
            screenHeight - 60,
            400,
            "center"
        )
    end
    
    -- Reduce the height of the header to make room for the footer
    headerHeight = 40 -- Reduced from 50
    
    -- Calculate footer position (now above the bottom panes to avoid overlap)
    local footerTop = screenHeight - footerHeight
    
    -- Draw footer background
    love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
    love.graphics.rectangle("fill", 0, footerTop, screenWidth, footerHeight)
    
    -- Draw footer separator line
    love.graphics.setColor(0.4, 0.4, 0.7, 0.5)
    love.graphics.rectangle("fill", 20, footerTop, screenWidth - 40, 1)
    
    -- Instructions at the bottom with key highlighting
    local instructions = {
        {text = "Left/Right", color = {1, 0.8, 0.4}},
        {text = " to change wizard, ", color = {0.8, 0.8, 0.9}},
        {text = "Up/Down", color = {1, 0.8, 0.4}},
        {text = " to select spell, ", color = {0.8, 0.8, 0.9}},
        {text = "1-7", color = {1, 0.8, 0.4}},
        {text = " to assign spell to slot", color = {0.8, 0.8, 0.9}}
    }
    
    local x = 20
    local y = footerTop + 15 -- Center text in footer
    
    for _, part in ipairs(instructions) do
        love.graphics.setColor(part.color)
        love.graphics.print(part.text, x, y, 0, 0.9, 0.9)
        x = x + game.font:getWidth(part.text) * 0.9
    end
    
    -- Store pane layout in the game state for future reference
    game.compendiumPanes = panes
end

-- Draw attract mode overlay
function drawAttractModeOverlay()
    local screenWidth = baseWidth
    local screenHeight = baseHeight

    -- Draw a semi-transparent banner at the top
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, 40)

    -- Draw "Attract Mode" text
    love.graphics.setColor(1, 1, 1, 0.9)
    local attractText = "ATTRACT MODE - PRESS ANY KEY TO RETURN TO MENU"
    local textWidth = game.font:getWidth(attractText) * 1.5

    -- Make text pulse slightly to draw attention
    local pulse = 0.8 + 0.2 * math.sin(love.timer.getTime() * 3)
    love.graphics.setColor(1, 1, 1, pulse)
    love.graphics.print(
        attractText,
        screenWidth / 2 - textWidth / 2,
        10,
        0, -- rotation
        1.5, -- scale X
        1.5  -- scale Y
    )

    -- Draw AI info text at bottom
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, screenHeight - 40, screenWidth, 40)

    -- Show which AI personalities are fighting
    local aiInfoText = "AI DUEL: " .. game.wizards[1].name .. " vs " .. game.wizards[2].name
    local aiTextWidth = game.font:getWidth(aiInfoText)

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(
        aiInfoText,
        screenWidth / 2 - aiTextWidth / 2,
        screenHeight - 30
    )
end

-- Unified key handler using the Input module
function love.keypressed(key, scancode, isrepeat)
    -- First check if we're in attract mode - any key exits attract mode
    if game.attractModeActive then
        exitAttractMode()
        return true -- Key handled
    end

    -- Forward all key presses to the Input module for normal gameplay
    return Input.handleKey(key, scancode, isrepeat)
end

-- Unified key release handler
function love.keyreleased(key, scancode)
    -- Skip key release handling if in attract mode (already handled in keypressed)
    if game.attractModeActive then
        return true -- Key handled
    end

    -- Forward all key releases to the Input module
    return Input.handleKeyReleased(key, scancode)
end