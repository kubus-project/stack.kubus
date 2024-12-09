local composer = require("composer")
local scene = composer.newScene()

-- include Corona's "physics" library
local physics = require("physics")
local audio = require("audio")
local pauseMenu = require("pauseMenu")

--------------------------------------------

-- forward declarations and other locals
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
local countdownTimer

function scene:create(event)
    local sceneGroup = self.view
    uiGroup = display.newGroup() -- Create a new group for UI elements
    gameGroup = display.newGroup() -- Create a new group for game elements

    -- Load the crate landing sound
    crateLandingSound = audio.loadSound("sounds/crateLanding.wav")

    -- Start physics
    physics.start()
    physics.pause() 

    -- Create a washed blue rectangle as the backdrop
    background = display.newRect(display.screenOriginX, display.screenOriginY, screenW, screenH)
    background.anchorX = 0
    background.anchorY = 0
    background:setFillColor(0.5, 0.5, 1) -- Set initial background color to washed blue
    sceneGroup:insert(background)

    -- Create a platform object and add physics (with custom shape)
    local platform = display.newImageRect("images/platform.png", 320, 193)
    platform.anchorX = 0.5
    platform.anchorY = 1
    platform.x, platform.y = display.contentCenterX, display.actualContentHeight + display.screenOriginY

    -- Define the custom collision shape for the platform

        local platformShape = { 
            -160, 89,  -- Bottom-left corner (96.5 - 7.5)
            160, 89,   -- Bottom-right corner (96.5 - 7.5)
            160, -7.5,  -- Top-right corner (0 - 7.5)
            -160, -7.5  -- Top-left corner (0 - 7.5)
        }
    physics.addBody(platform, "static", { friction = 0.3, shape = platformShape })
    gameGroup:insert(platform)

    -- Create invisible walls to prevent crates from falling off the screen
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

    -- Create and display the score text
    scoreText = display.newText({
        text = "Score: " .. score,
        x = screenW - 138,
        y = display.screenOriginY + 30,
        font = native.systemFontBold,
        fontSize = 20
    })
    scoreText:setFillColor(1, 1, 1)
    uiGroup:insert(scoreText) -- Insert into UI group

    -- Create and display the stopwatch text
    stopwatchText = display.newText({
        text = "Time: 00:00",
        x = 70,
        y = display.screenOriginY + 30,
        font = native.systemFontBold,
        fontSize = 20
    })
    stopwatchText:setFillColor(1, 1, 1)
    uiGroup:insert(stopwatchText) -- Insert into UI group

    -- Function to update the stopwatch
    local function updateStopwatch()
        stopwatchMilliseconds = stopwatchMilliseconds + 10
        local totalSeconds = math.floor(stopwatchMilliseconds / 1000)
        local displaySeconds = totalSeconds % 60
        local displayMilliseconds = (stopwatchMilliseconds % 1000) / 10

        stopwatchText.text = string.format("Time: %02d:%02d", displaySeconds, displayMilliseconds)
    end

    -- Start the stopwatch timer
    stopwatchTimer = timer.performWithDelay(10, updateStopwatch, 0)

    -- Function to handle touch events on a crate...... Try to change from the physics to the linear motion of the crate to avoid this altogether
    local function onCrateTouch(event)
        local crate = event.target
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
    end

    -- Function to display "Game Over" title
    local function displayGameOver()
        -- Stop the stopwatch timer
        if stopwatchTimer then
            timer.cancel(stopwatchTimer)
        end
    
        -- Calculate the final time
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
        uiGroup:insert(gameOverText) -- Insert into UI group
    
        -- Return to menu after 5 seconds
        timer.performWithDelay(5000, function()
            composer.gotoScene("menu")
        end)
    end

    -- Function to display "You Won" title
    local function displayYouWon()
        -- Stop the stopwatch timer
        if stopwatchTimer then
            timer.cancel(stopwatchTimer)
        end

        -- Calculate the final time
        local totalSeconds = math.floor(stopwatchMilliseconds / 1000)
        local displaySeconds = totalSeconds % 60
        local displayMilliseconds = (stopwatchMilliseconds % 1000) / 10
        local finalTime = string.format("%02d:%02d", displaySeconds, displayMilliseconds)

        local youWonText = display.newText({
            text = "You Won!\nTime: " .. finalTime .. "\nCrates: " .. crateCount,
            x = screenW / 2,
            y = screenH / 2,
            font = native.systemFontBold,
            fontSize = 40,
            align = "center"
        })
        youWonText:setFillColor(0, 1, 0)
        uiGroup:insert(youWonText) -- Insert into UI group

        -- Return to menu after 5 seconds
        timer.performWithDelay(5000, function()
            composer.gotoScene("menu")
        end)
    end

    -- Function to start the countdown for "You Won" screen
    local function startCountdown()
        countdownTimer = timer.performWithDelay(1000, displayYouWon)
    end

    -- Function to check if the tower has tipped over
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

    -- Function to handle crate collision
    local function onCrateCollision(self, event)
        if event.phase == "began" then
            -- Play the crate landing sound
            audio.play(crateLandingSound)
            -- Display crate number at landing point
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
            -- Animate the text in an arc and fade out
            transition.to(crateNumberText, { time = 1000, x = crateNumberText.x + math.random(-50, 50), y = crateNumberText.y - 50, alpha = 0, transition = easing.outQuad, onComplete = function()
                display.remove(crateNumberText)
            end })
            -- Remove the collision listener to prevent multiple triggers
            self.collision = nil
            self:removeEventListener("collision", self)
            -- Move the crate to the gameGroup to make it fixed relative to the world after a short delay
            timer.performWithDelay(1, function()
                local crateX, crateY = self:localToContent(0, 0)
                gameGroup:insert(self)
                self.x, self.y = gameGroup:contentToLocal(crateX, crateY)
            end)
            -- Spawn a new crate after a short delay
            timer.performWithDelay(500, function()
                activeCrate = nil
                createCrate()
            end)
            -- Increment the score
            score = score + 1
            scoreText.text = "Score: " .. score
        end
    end

    -- Function to enable crate collision after a short delay
    local function enableCrateCollision(crate)
        crate.collision = onCrateCollision
        crate:addEventListener("collision", crate)
    end

    -- List of crate image filenames
    local crateImages = { "images/crate.png", "images/crate_bl.png", "images/crate_b.png", "images/crate_r.png", "images/crate_g.png" }
    
    -- Function to create a crate to be dragged and dropped
    function createCrate()
        if crateCount >= 15 then
            startCountdown()
            return
        end
    
        local crateWidth, crateHeight = 39, 45
        -- Randomly select a crate image
        local crateImage = crateImages[math.random(#crateImages)]
        local crate = display.newImageRect(crateImage, crateWidth, crateHeight)
        crate.x = math.random(crateWidth / 2, screenW - crateWidth / 2) -- Random x position within screen width
        crate.y = display.screenOriginY - crateHeight - 600 + gameGroup.y -- Adjust spawn position based on gameGroup's y position
        crate.name = "crate"
        crate.isActive = true
    
        -- Define the custom collision shape for the isometric crate
        local crateShape = { -19.25, -11.25, 19.25, -11.25, 19.25, 11.25, -19.25, 11.25 }
        physics.addBody(crate, { density = 0.3, friction = 0.2, bounce = 0.05, shape = crateShape, gravityScale = 0.05 }) -- Adjusted gravityScale for slower falling
        gameGroup:insert(crate) -- Insert into game group to keep it fixed relative to the game elements
        table.insert(crates, crate)
        crateCount = crateCount + 1
        activeCrate = crate

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
    
        -- Enable collision after a short delay
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
    end

    -- Create the first crate
    createCrate()

    -- Create the pause button
    local pauseButton = display.newText({
        text = "Pause",
        x = screenW - 50,
        y = display.screenOriginY + 30,
        font = native.systemFontBold,
        fontSize = 20
    })
    pauseButton:setFillColor(1, 1, 1)
    uiGroup:insert(pauseButton) -- Insert into UI group
    
    -- Add event listener to the pause button
    pauseButton:addEventListener("tap", function()
        pauseMenu.showPauseMenu(sceneGroup, stopwatchTimer, "level1")
    end)

    -- Add an enterFrame listener to check if the tower has tipped over
    Runtime:addEventListener("enterFrame", checkTower)

    -- Insert the UI group and game group into the scene group
    sceneGroup:insert(gameGroup)
    sceneGroup:insert(uiGroup)
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase

    if phase == "will" then
        -- Called when the scene is still off screen and is about to move on screen
    elseif phase == "did" then
        -- Called when the scene is now on screen
        physics.start()
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase

    if event.phase == "will" then
        -- Called when the scene is on screen and is about to move off screen
        physics.pause()
    elseif phase == "did" then
        -- Called when the scene is now off screen
    end
end

function scene:destroy(event)
    local sceneGroup = self.view
    -- Remove the enterFrame listener
    Runtime:removeEventListener("enterFrame", checkTower)
    -- Cancel any active timers
    if countdownTimer then
        timer.cancel(countdownTimer)
    end
    -- Dispose of the crate landing sound
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

-- Listener setup
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene