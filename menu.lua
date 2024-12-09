-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

--------------------------------------------

function scene:create(event)
    local sceneGroup = self.view

    -- Called when the scene's view does not exist.
    --
    -- INSERT code here to initialize the scene
    -- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

    -- display a background image
    local background = display.newImage("images/bg_menu.png")
    background.anchorX = 0
    background.anchorY = 0
    background.x = 0 + display.screenOriginX
    background.y = 0 + display.screenOriginY
    
    -- Calculate scale factors to fill the screen
    local scaleX = display.actualContentWidth / background.width
    local scaleY = display.actualContentHeight / background.height
    local scale = math.max(scaleX, scaleY) -- Use the larger scale factor to ensure the image fills the screen
    
    background:scale(scale, scale)
    sceneGroup:insert(background)

    -- List of image filenames and their corresponding actions
    local images = {
        { filename = "images/name.png" },
        { filename = "images/play.png", action = function() composer.gotoScene("level1", "fade", 500) end },
        { filename = "images/endless.png", action = function() composer.gotoScene("level_endless", "fade", 500) end },
        { filename = "images/settings.png", action = function() composer.gotoScene("settings", "fade", 500) end },
        { filename = "images/exit.png", action = function() native.requestExit() end }
    }

    -- Insert images one on top of another but slightly offset to the right
    local startX = display.contentCenterX - 50
    local startY = display.contentCenterY - 215
    local offsetX = 35
    local offsetY = 130

    for i = 1, #images do
        local image = display.newImage(images[i].filename)
        image.x = startX + (i - 1) * offsetX
        image.y = startY + (i - 1) * offsetY
        image.rotation = 0 -- Ensure the image is not rotated
        image.xScale = 0.33 -- Scale to 25%
        image.yScale = 0.33 -- Scale to 25%
        sceneGroup:insert(image)

        -- Add touch listener if action is defined
        if images[i].action then
            image:addEventListener("tap", images[i].action)
        end
    end
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase

    if phase == "will" then
        -- Called when the scene is still off screen and is about to move on screen
    elseif phase == "did" then
        -- Called when the scene is now on screen
        --
        -- INSERT code here to make the scene come alive
        -- e.g. start timers, begin animation, play audio, etc.
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase

    if event.phase == "will" then
        -- Called when the scene is on screen and is about to move off screen
        --
        -- INSERT code here to pause the scene
        -- e.g. stop timers, stop animation, unload sounds, etc.)
    elseif phase == "did" then
        -- Called when the scene is now off screen
    end
end

function scene:destroy(event)
    local sceneGroup = self.view

    -- Called prior to the removal of scene's "view" (sceneGroup)
    --
    -- INSERT code here to cleanup the scene
    -- e.g. remove display objects, remove touch listeners, save state, etc.
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

-----------------------------------------------------------------------------------------

return scene