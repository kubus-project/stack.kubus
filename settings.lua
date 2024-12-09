local composer = require("composer")
local widget = require("widget")
local scene = composer.newScene()

-- Variables to store settings
local soundVolume = 0.5
local musicVolume = 0.5

-- Function to handle slider events
local function onSoundSlider(event)
    soundVolume = event.value / 100
    -- Update sound volume in your game
end

local function onMusicSlider(event)
    musicVolume = event.value / 100
    -- Update music volume in your game
end

-- Function to handle back button
local function onBackButton(event)
    if event.phase == "ended" then
        composer.gotoScene("menu")
    end
end

function scene:create(event)
    local sceneGroup = self.view

    -- Background
    local background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    background:setFillColor(0.5, 0.5, 1)

    -- Sound Volume Slider
    local soundSlider = widget.newSlider({
        top = display.contentCenterY - 50,
        left = display.contentCenterX - 150,
        width = 300,
        value = soundVolume * 100,
        listener = onSoundSlider
    })
    sceneGroup:insert(soundSlider)

    local soundLabel = display.newText(sceneGroup, "Sound Volume", display.contentCenterX, display.contentCenterY - 80, native.systemFont, 20)

    -- Music Volume Slider
    local musicSlider = widget.newSlider({
        top = display.contentCenterY + 50,
        left = display.contentCenterX - 150,
        width = 300,
        value = musicVolume * 100,
        listener = onMusicSlider
    })
    sceneGroup:insert(musicSlider)

    local musicLabel = display.newText(sceneGroup, "Music Volume", display.contentCenterX, display.contentCenterY + 20, native.systemFont, 20)

    -- Back Button
    local backButton = widget.newButton({
        label = "Back",
        onEvent = onBackButton,
        emboss = false,
        shape = "roundedRect",
        width = 200,
        height = 40,
        cornerRadius = 10,
        fillColor = { default={0.2, 0.2, 0.8, 1}, over={0.2, 0.2, 0.8, 0.8} },
        labelColor = { default={1, 1, 1}, over={0.8, 0.8, 1} },
        fontSize = 20
    })
    backButton.x = display.contentCenterX
    backButton.y = display.contentCenterY + 150
    sceneGroup:insert(backButton)
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase

    if phase == "will" then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
    elseif phase == "did" then
        -- Code here runs when the scene is entirely on screen
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase

    if event.phase == "will" then
        -- Code here runs when the scene is on screen (but is about to go off screen)
    elseif phase == "did" then
        -- Code here runs immediately after the scene goes entirely off screen
    end
end

function scene:destroy(event)
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene