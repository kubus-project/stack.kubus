local composer = require("composer")
local scene = composer.newScene()

function scene:create(event)
    local sceneGroup = self.view

    -- display a background image
    local background = display.newImage("splash.png")
    background.anchorX = 0.5
    background.anchorY = 0.5
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    
    -- Calculate scale factors to fill the screen
    local scaleX = display.actualContentWidth / background.width
    local scaleY = display.actualContentHeight / background.height
    local scale = math.max(scaleX, scaleY) -- Use the larger scale factor to ensure the image fills the screen
    
    background:scale(scale, scale)
    sceneGroup:insert(background)
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase

    if phase == "did" then
        -- Go to the menu scene after 3 seconds
        timer.performWithDelay(3000, function()
            transition.to(sceneGroup, { time = 500, alpha = 0, onComplete = function()
                composer.gotoScene("menu")
            end })
        end)
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)

return scene