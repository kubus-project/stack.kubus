local composer = require("composer")
local scene = composer.newScene()

local physics = require("physics")
local audio = require("audio")
local pauseMenu = require("pauseMenu")

local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX
local activeCrate
local crateCount = 0
local gameOver = false
local crates = {}
local crateLandingSound
local score = 0
local scoreText
local stopwatchMilliseconds = 0
local stopwatchText
local stopwatchTimer
local uiGroup
local gameGroup
local background
local overlay

local crateShape = { -19.25, -11.25, 19.25, -11.25, 19.25, 11.25, -19.25, 11.25 }
local largeCrateShape = { -39, -22.5, 39, -22.5, 39, 22.5, -39, 22.5 }

function scene:create(event)
    local sceneGroup = self.view
    uiGroup = display.newGroup()
    gameGroup = display.newGroup()

    crateLandingSound = audio.loadSound("crateLanding.wav")

    physics.start()
    physics.pause()

    background = display.newRect(display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    background:setFillColor(0.5, 0.5, 1)
    sceneGroup:insert(background)

    overlay = display.newImage("images/bg_splash.png")
    overlay.anchorX = 0.5
    overlay.anchorY = 0.5
    overlay.x = display.contentCenterX
    overlay.y = display.contentCenterY
    
    local scaleX = display.actualContentWidth / overlay.width
    local scaleY = display.actualContentHeight / overlay.height
    local scale = math.max(scaleX, scaleY)
    
    overlay:scale(scale, scale)
    sceneGroup:insert(overlay)

    local platform = display.newImageRect("images/platform.png", 320, 193)
    platform.anchorX = 0.5
    platform.anchorY = 1
    platform.x, platform.y = display.contentCenterX, display.actualContentHeight + display.screenOriginY

    local platformShape = { 
        -160, 89,
        160, 89,
        160, -7.5,
        -160, -7.5
    }
    physics.addBody(platform, "static", { friction = 0.3, shape = platformShape })
    gameGroup:insert(platform)

    local leftWall = display.newRect(display.screenOriginX - 10, display.contentCenterY, 20, screenH)
    leftWall.anchorX = 1
    leftWall.anchorY = 0.5
    physics.addBody(leftWall, "static", { bounce = 0.0 })
    gameGroup:insert(leftWall)
    
    local rightWall = display.newRect(display.actualContentWidth + display.screenOriginX + 10, display.contentCenterY, 20, screenH)
    rightWall.anchorX = 0
    rightWall.anchorY = 0.5
    physics.addBody(rightWall, "static", { bounce = 0.0 })
    gameGroup:insert(rightWall)

    scoreText = display.newText({
        text = "Score: " .. score,
        x = screenW - 138,
        y = display.screenOriginY + 30,
        font = native.systemFontBold,
        fontSize = 20
    })
    scoreText:setFillColor(1, 1, 1)
    uiGroup:insert(scoreText)

    stopwatchText = display.newText({
        text = "Time: 00:00",
        x = 70,
        y = display.screenOriginY + 30,
        font = native.systemFontBold,
        fontSize = 20
    })
    stopwatchText:setFillColor(1, 1, 1)
    uiGroup:insert(stopwatchText)

    local function updateStopwatch()
        stopwatchMilliseconds = stopwatchMilliseconds + 10
        local totalSeconds = math.floor(stopwatchMilliseconds / 1000)
        local displaySeconds = totalSeconds % 60
        local displayMilliseconds = (stopwatchMilliseconds % 1000) / 10

        stopwatchText.text = string.format("Time: %02d:%02d", displaySeconds, displayMilliseconds)
    end

    stopwatchTimer = timer.performWithDelay(10, updateStopwatch, 0)

    local function onCrateTouch(event)
        local crate = event.target
        if event.phase == "began" then
            display.getCurrentStage():setFocus(crate)
            crate.touchOffsetX = event.x - crate.x
            crate.touchOffsetY = event.y - crate.y
            crate.bodyType = "dynamic" -- Change to dynamic when the user starts dragging
            crate.isFixedRotation = false -- Allow rotation for more natural physics
            crate:setLinearVelocity(0, 0)
            crate.angularVelocity = 0
            physics.removeBody(crate)
            physics.addBody(crate, { density = 0.3, friction = 0.2, bounce = 0.05, shape = crateShape, gravityScale = 0.005 })
        elseif event.phase == "moved" then
            if crate.touchOffsetX and crate.touchOffsetY then
                crate.x = event.x - crate.touchOffsetX
                crate.y = event.y - crate.touchOffsetY
                crate:setLinearVelocity(0, 0)
            end
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
            crate.bodyType = "dynamic" -- Change to dynamic when the user starts dragging
            crate.isFixedRotation = false -- Allow rotation for more natural physics
            physics.removeBody(crate)
            physics.addBody(crate, { density = 0.3, friction = 0.2, bounce = 0.05, shape = crateShape, gravityScale = 0.005 })
        end
        return true
    end

    local function displayGameOver()
        if stopwatchTimer then
            timer.cancel(stopwatchTimer)
        end
    
        local totalSeconds = math.floor(stopwatchMilliseconds / 1000)
        local displaySeconds = totalSeconds % 60
        local displayMilliseconds = (stopwatchMilliseconds % 1000) / 10
        local finalTime = string.format("%02d:%02d", displaySeconds, displayMilliseconds)
    
        local gameOverText = display.newText({
            text = "Game Over\nTime: " .. finalTime .. "\nCrates: " .. crateCount,
            x = screenW / 2,
            y = screenH / 2,
            font = native.systemFontBold,
            fontSize = 40,
            align = "center"
        })
        gameOverText:setFillColor(1, 0, 0)
        uiGroup:insert(gameOverText)
    
        timer.performWithDelay(5000, function()
            composer.gotoScene("menu")
        end)
    end

    local function checkTower()
        for i = 1, #crates do
            local crate = crates[i]
            if crate and crate.rotation then
                if crate.rotation > 45 or crate.rotation < -45 then
                    if not gameOver then
                        gameOver = true
                        displayGameOver()
                    end
                    return
                end
            end
        end
    end

    local function onCrateCollision(self, event)
        if event.phase == "began" then
            audio.play(crateLandingSound)
            local crateNumberText = display.newText({
                text = crateCount,
                x = self.x,
                y = self.y,
                font = native.systemFontBold,
                fontSize = 20
            })
            crateNumberText:setFillColor(1, 1, 1)
            if scene.view then
                scene.view:insert(crateNumberText)
            end
            transition.to(crateNumberText, { time = 1000, x = crateNumberText.x + math.random(-50, 50), y = crateNumberText.y - 50, alpha = 0, transition = easing.outQuad, onComplete = function()
                display.remove(crateNumberText)
            end })
            self.collision = nil
            self:removeEventListener("collision", self)
            timer.performWithDelay(1, function()
                local crateX, crateY = self:localToContent(0, 0)
                gameGroup:insert(self)
                self.x, self.y = gameGroup:contentToLocal(crateX, crateY)
            end)
            if crateCount >= 8 then
                transition.to(gameGroup, { y = gameGroup.y - -35, time = 500, transition = easing.inOutQuad })
                local newColor = math.max(0, 0.5 - (crateCount - 10) * 0.01)
                transition.to(background.fill, { r = newColor, g = newColor, b = newColor, time = 500, transition = easing.inOutQuad })
            end
            timer.performWithDelay(500, function()
                activeCrate = nil
                createCrate()
            end)
            score = score + 1
            scoreText.text = "Score: " .. score
        end
    end

    local function enableCrateCollision(crate)
        crate.collision = onCrateCollision
        crate:addEventListener("collision", crate)
    end
    
    local crateImages = { "images/crate.png", "images/crate_bl.png", "images/crate_b.png", "images/crate_r.png", "images/crate_g.png" }
    
    function createCrate()
        local crateWidth, crateHeight = 39, 45
        local crateImage = crateImages[math.random(#crateImages)]
        local crate = display.newImageRect(crateImage, crateWidth, crateHeight)
        -- Narrow the spawning range
        local spawnMargin = 50
        crate.x = math.random(spawnMargin, screenW - spawnMargin)
        crate.y = display.screenOriginY - crateHeight - 600 + gameGroup.y
        crate.name = "crate"
        crate.isActive = true
    
        crate.bodyType = "kinematic" -- Make the crate kinematic initially
        crate.isSensor = false -- Ensure collision detection
        crate:setLinearVelocity(0, 250) -- Set a constant linear downward velocity
    
        -- Add touch listener to the crate
        crate:addEventListener("touch", function(event)
            if event.phase == "began" then
                display.getCurrentStage():setFocus(crate)
                crate.touchOffsetX = event.x - crate.x
                crate.touchOffsetY = event.y - crate.y
                crate.bodyType = "dynamic" -- Change to dynamic when the user starts dragging
                crate.isFixedRotation = false -- Allow rotation for more natural physics
                crate:setLinearVelocity(0, 0) -- Stop any existing motion
                crate.angularVelocity = 0 -- Stop any existing rotation
            elseif event.phase == "moved" then
                if crate.touchOffsetX and crate.touchOffsetY then
                    crate.x = event.x - crate.touchOffsetX
                    crate.y = event.y - crate.touchOffsetY
                    crate:setLinearVelocity(0, 0) -- Manually update the crate's position
                end
            elseif event.phase == "ended" or event.phase == "cancelled" then
                display.getCurrentStage():setFocus(nil)
                crate.bodyType = "dynamic" -- Make the crate dynamic to allow tipping
                crate.isFixedRotation = false -- Allow rotation for more natural physics
            end
            return true
        end)
    
        timer.performWithDelay(100, function()
            enableCrateCollision(crate)
        end)
        crate:addEventListener("collision", function(self, event)
            if event and event.phase == "began" and event.other == platform then
                self.bodyType = "dynamic"
                self.isFixedRotation = false
                self.isSensor = false -- Ensure collision detection
                self:setLinearVelocity(0, 0) -- Stop any existing motion
                self.angularVelocity = 0 -- Stop any existing rotation
            end
        end)
        physics.addBody(crate, { density = 0.3, friction = 0.2, bounce = 0.05, shape = largeCrateShape, gravityScale = 0.05 }) -- Adjusted gravityScale for slower falling
    end
    createCrate()

    local pauseButton = display.newText({
        text = "Pause",
        x = screenW - 50,
        y = display.screenOriginY + 30,
        font = native.systemFontBold,
        fontSize = 20
    })
    pauseButton:setFillColor(1, 1, 1)
    uiGroup:insert(pauseButton)
    
    pauseButton:addEventListener("tap", function()
        pauseMenu.showPauseMenu(sceneGroup, stopwatchTimer, "level_endless")
    end)

    Runtime:addEventListener("enterFrame", checkTower)

    sceneGroup:insert(gameGroup)
    sceneGroup:insert(uiGroup)
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase

    if phase == "will" then
    elseif phase == "did" then
        physics.start()
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase

    if event.phase == "will" then
        physics.pause()
    elseif phase == "did" then
    end
end

function scene:destroy(event)
    local sceneGroup = self.view
    Runtime:removeEventListener("enterFrame", checkTower)
    if countdownTimer then
        timer.cancel(countdownTimer)
    end
    audio.dispose(crateLandingSound)
    crateLandingSound = nil
    -- Remove all crates and their physics bodies
    for i = #crates, 1, -1 do
        local crate = crates[i]
        if crate then
            crate:removeEventListener("collision", crate)
            display.remove(crate)
            crates[i] = nil
        end
    end
    package.loaded[physics] = nil
    physics = nil
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene