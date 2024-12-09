local composer = require("composer")
local physics = require("physics")

local M = {}

function M.showPauseMenu(sceneGroup, stopwatchTimer, currentScene)
    -- Pause the physics engine
    physics.pause()

    -- Pause the stopwatch timer
    if stopwatchTimer then
        timer.pause(stopwatchTimer)
    end

    -- Create a semi-transparent overlay
    local overlay = display.newRect(display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    overlay:setFillColor(0, 0, 0, 0.5)

    -- Create the pause menu group
    local pauseGroup = display.newGroup()
    pauseGroup:insert(overlay)

    -- Create the pause title
    local pauseTitle = display.newText({
        text = "Paused",
        x = display.contentCenterX,
        y = display.contentCenterY - 50,
        font = native.systemFontBold,
        fontSize = 40
    })
    pauseTitle:setFillColor(1, 1, 1)
    pauseGroup:insert(pauseTitle)

    -- Create the resume button
    local resumeButton = display.newText({
        text = "Resume",
        x = display.contentCenterX,
        y = display.contentCenterY,
        font = native.systemFontBold,
        fontSize = 30
    })
    resumeButton:setFillColor(0, 1, 0)
    pauseGroup:insert(resumeButton)

    -- Create the restart button
    local restartButton = display.newText({
        text = "Restart",
        x = display.contentCenterX,
        y = display.contentCenterY + 50,
        font = native.systemFontBold,
        fontSize = 30
    })
    restartButton:setFillColor(1, 0, 0)
    pauseGroup:insert(restartButton)

    -- Create the exit button
    local exitButton = display.newText({
        text = "Exit",
        x = display.contentCenterX,
        y = display.contentCenterY + 100,
        font = native.systemFontBold,
        fontSize = 30
    })
    exitButton:setFillColor(1, 1, 0)
    pauseGroup:insert(exitButton)

    -- Function to resume the game
    local function resumeGame()
        -- Remove the pause menu
        display.remove(pauseGroup)
        -- Resume the physics engine
        physics.start()
        -- Resume the stopwatch timer
        if stopwatchTimer then
            timer.resume(stopwatchTimer)
        end
    end

    -- Function to restart the game
    local function restartGame()
        -- Remove the pause menu
        display.remove(pauseGroup)
        -- Restart the scene
        composer.removeScene(currentScene)
        composer.gotoScene(currentScene, { effect = "fade", time = 500 })
    end

    -- Function to exit to the main menu
    local function exitToMenu()
        -- Remove the pause menu
        display.remove(pauseGroup)
        -- Remove the current scene
        composer.removeScene(currentScene)
        -- Go to the main menu scene
        composer.gotoScene("menu", { effect = "fade", time = 500 })
    end

    -- Add event listeners to the buttons
    resumeButton:addEventListener("tap", resumeGame)
    restartButton:addEventListener("tap", restartGame)
    exitButton:addEventListener("tap", exitToMenu)
end

return M