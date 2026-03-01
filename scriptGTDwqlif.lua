-- Auto Placement Script for Garden Tower Defense
-- Запускайте в Xeno на ПК

-- Получаем RemoteFunctions
local rs = game:GetService("ReplicatedStorage")
local remotes = rs:WaitForChild("RemoteFunctions")

-- Глобальные переменные для управления
_G.AutoFarm = _G.AutoFarm or {}
local AutoFarm = _G.AutoFarm

-- Инициализация переменных
AutoFarm.running = false
AutoFarm.thread = nil
AutoFarm.scheduledTasks = {}
AutoFarm.antiAFKEnabled = true
AutoFarm.antiAFKThread = nil

-- Данные макроса из предоставленного JSON
local macroData = {
    -- Юнит 1 (Lumberjack) на 19 секунде
    {Type = "PlaceUnit", CF = "-23.0003052, -85.1852188, 33.6442642, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 1, Time = 19, Unit = "unit_lumberjack", ID = 1},
    -- Юнит 2 (Lumberjack) на 45 секунде
    {Type = "PlaceUnit", CF = "-19.7339401, -85.1852188, 34.0921783, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 2, Time = 45, Unit = "unit_lumberjack", ID = 2},
    -- Юнит 3 (Beehive) на 67 секунде
    {Type = "PlaceUnit", CF = "-16.7054443, -85.1852188, 22.8883896, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 3, Time = 67, Unit = "unit_beehive", ID = 3},
    -- Юнит 4 (Beehive) на 230 секунде
    {Type = "PlaceUnit", CF = "-21.192627, -85.1852188, 21.8793602, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 4, Time = 230, Unit = "unit_beehive", ID = 4},
    -- Юнит 5 (Beehive) на 244 секунде
    {Type = "PlaceUnit", CF = "-16.9072189, -85.1852188, 16.9091415, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 4, Time = 244, Unit = "unit_beehive", ID = 5}
}

-- Цены для бесконечных апгрейдов
local upgradePrices = {
    [3] = {2000, 4500, 12500, 28000},  -- начальные цены для юнита 3
    [4] = {2000, 4500, 12500, 28000},  -- начальные цены для юнита 4
    [5] = {2000, 4500, 12500, 28000}   -- начальные цены для юнита 5
}

-- Функция анти-АФК системы
local function setupAntiAFK()
    if not AutoFarm.antiAFKEnabled then return end
    
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local player = game.Players.LocalPlayer
    
    local function smoothCameraRotation()
        local camera = workspace.CurrentCamera
        local rotationSpeed = 0.5
        local totalRotation = 0
        local maxRotation = 30
        
        while AutoFarm.running and AutoFarm.antiAFKEnabled do
            local deltaTime = 0.1
            local rotationAmount = rotationSpeed * deltaTime
            
            if totalRotation >= maxRotation then
                rotationSpeed = -rotationSpeed
            elseif totalRotation <= -maxRotation then
                rotationSpeed = -rotationSpeed
            end
            
            local currentCF = camera.CFrame
            local newCF = currentCF * CFrame.Angles(0, math.rad(rotationAmount), 0)
            camera.CFrame = newCF
            totalRotation = totalRotation + rotationAmount
            task.wait(deltaTime)
        end
    end
    
    AutoFarm.antiAFKThread = task.spawn(function()
        task.spawn(smoothCameraRotation)
        
        local actionCounter = 0
        while AutoFarm.running and AutoFarm.antiAFKEnabled do
            actionCounter = actionCounter + 1
            
            if actionCounter % 30 == 0 then
                if actionCounter % 60 == 0 then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end
            end
            task.wait(1)
        end
    end)
    
    local function standardAntiAFK()
        local gc = getconnections or get_signal_connections
        if gc then
            for _, v in pairs(gc(player.Idled)) do
                if v.Function then v:Disable()
                elseif v.Disconnect then v:Disconnect() end
            end
        end
    end
    pcall(standardAntiAFK)
end

local function stopAntiAFK()
    AutoFarm.antiAFKEnabled = false
    if AutoFarm.antiAFKThread then
        task.cancel(AutoFarm.antiAFKThread)
        AutoFarm.antiAFKThread = nil
    end
end

-- Функция для проверки и выполнения апгрейда
local function tryUpgradeUnit(unitId, price)
    local success = pcall(function()
        return remotes.UpgradeUnit:InvokeServer(unitId, price)
    end)
    return success
end

-- Функция для бесконечных апгрейдов (каждые 3 секунды)
local function startInfiniteUpgradeLoop(unitId)
    local currentPriceIndex = 1
    local prices = upgradePrices[unitId]
    
    local function upgradeLoop()
        if not AutoFarm.running then return end
        
        local price = prices[currentPriceIndex]
        
        -- Пробуем сделать апгрейд
        local success = tryUpgradeUnit(unitId, price)
        
        if success then
            print("[АПГРЕЙД] ✅ Юнит " .. unitId .. " улучшен за " .. price)
            -- Переходим к следующей цене
            currentPriceIndex = currentPriceIndex + 1
            -- Если дошли до конца списка, начинаем сначала
            if currentPriceIndex > #prices then
                currentPriceIndex = 1
                print("[АПГРЕЙД] 🔄 Юнит " .. unitId .. " начал новый цикл апгрейдов")
            end
        else
            print("[АПГРЕЙД] ⏳ Юнит " .. unitId .. ": не хватило денег на " .. price)
        end
        
        -- Запускаем следующую проверку через 3 секунды
        task.delay(3, upgradeLoop)
    end
    
    -- Запускаем первый апгрейд через 3 секунды после размещения
    task.delay(3, upgradeLoop)
end

-- Функция для бесконечного авто-рестарта (каждые 3 секунды)
local function startInfiniteRestartLoop()
    local function restartLoop()
        if not AutoFarm.running then 
            -- Если скрипт остановлен, прекращаем цикл
            return 
        end
        
        print("[АВТО-РЕСТАРТ] 🔄 Перезапуск игры...")
        local success = pcall(function() remotes.RestartGame:InvokeServer() end)
        
        if success then
            print("[АВТО-РЕСТАРТ] ✅ Игра перезапущена")
        else
            print("[АВТО-РЕСТАРТ] ❌ Ошибка рестарта")
        end
        
        -- Запускаем следующий рестарт через 3 секунды
        task.delay(3, restartLoop)
    end
    
    -- Запускаем первый рестарт через 3 секунды
    task.delay(3, restartLoop)
end

-- Функция полной остановки и сброса
function AutoFarm:StopEverything()
    stopAntiAFK()
    self.running = false
    
    if self.thread then
        local thread = self.thread
        self.thread = nil
    end
    
    for i, taskInfo in pairs(self.scheduledTasks) do
        if taskInfo and taskInfo.cancel then
            pcall(taskInfo.cancel)
        end
    end
    self.scheduledTasks = {}
    
    local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local oldGui = playerGui:FindFirstChild("AutoFarmGUI")
        if oldGui then oldGui:Destroy() end
    end
    
    _G.AutoFarmLoaded = false
    
    return true
end

-- Функция для планирования отменяемой задачи
local function scheduleTask(delay, func, taskId)
    if not AutoFarm.running then return nil end
    
    local taskInfo = {
        cancel = function()
            if AutoFarm.scheduledTasks[taskId] then
                AutoFarm.scheduledTasks[taskId] = nil
            end
        end
    }
    
    AutoFarm.scheduledTasks[taskId] = taskInfo
    
    task.delay(delay, function()
        if AutoFarm.running and AutoFarm.scheduledTasks[taskId] then
            func()
            AutoFarm.scheduledTasks[taskId] = nil
        end
    end)
    
    return taskInfo
end

-- Функция декодирования CFrame
local function decodeCFrame(cfString)
    local parts = {}
    for num in cfString:gmatch("[%-%d%.eE+]+") do
        table.insert(parts, tonumber(num))
    end
    
    return CFrame.new(
        parts[1], parts[2], parts[3],
        parts[4], parts[5], parts[6],
        parts[7], parts[8], parts[9],
        parts[10], parts[11], parts[12]
    )
end

-- Функция размещения юнита
local function placeUnit(cfString, unitName, pathIndex)
    local cf = decodeCFrame(cfString)
    
    local placementData = {
        Valid = true,
        PathIndex = pathIndex,
        Position = cf.Position,
        CF = cf,
        Rotation = 180
    }
    
    local success = pcall(function()
        return remotes.PlaceUnit:InvokeServer(unitName, placementData)
    end)
    
    return success
end

-- Функция для периодического выбора сложности
local function startDifficultyLoop()
    local function voteDifficulty()
        if not AutoFarm.running then return end
        pcall(function() remotes.PlaceDifficultyVote:InvokeServer("dif_apocalypse") end)
        task.delay(3, voteDifficulty)
    end
    task.delay(3, voteDifficulty)
end

-- Функция для периодического авто-скипа
local function startAutoSkipLoop()
    local function toggleSkip()
        if not AutoFarm.running then return end
        pcall(function() remotes.ToggleAutoSkip:InvokeServer(true) end)
        task.delay(3, toggleSkip)
    end
    task.delay(3, toggleSkip)
end

-- Функция автоигры
local function startAutoGame(speed)
    local baseDelay = 5
    
    -- Запускаем периодические функции
    startDifficultyLoop()
    startAutoSkipLoop()
    startInfiniteRestartLoop() -- Бесконечный авто-рестарт каждые 3 секунды
    
    while AutoFarm.running do
        -- Устанавливаем скорость
        remotes.ChangeTickSpeed:InvokeServer(speed)
        
        -- Базовая задержка перед стартом
        for i = 1, baseDelay do
            if not AutoFarm.running then return end
            task.wait(1)
        end
        
        print("")
        print("==========================================")
        print("🚀 НАЧАЛО НОВОГО РАУНДА (x" .. speed .. ")")
        print("==========================================")
        
        -- Размещаем юниты по расписанию
        for i, action in ipairs(macroData) do
            if action.Type == "PlaceUnit" then
                local placeTime = action.Time - baseDelay
                
                if placeTime > 0 then
                    scheduleTask(placeTime, function()
                        if not AutoFarm.running then return end
                        
                        print("[РАЗМЕЩЕНИЕ] Юнит " .. action.ID .. " на " .. action.Time .. " сек")
                        local success = placeUnit(action.CF, action.Unit, action.PathIndex)
                        if success then
                            print("[УСПЕХ] ✅ Юнит " .. action.ID .. " размещен")
                            
                            -- Для юнитов 3,4,5 запускаем бесконечные апгрейды
                            if action.ID >= 3 and action.ID <= 5 then
                                print("[АПГРЕЙД] 🔄 Запускаем бесконечные апгрейды для юнита " .. action.ID)
                                startInfiniteUpgradeLoop(action.ID)
                            end
                        else
                            print("[ОШИБКА] ❌ Не удалось разместить юнит " .. action.ID)
                        end
                    end, "place_" .. action.ID)
                elseif placeTime <= 0 and AutoFarm.running then
                    print("[РАЗМЕЩЕНИЕ] Юнит " .. action.ID .. " СРАЗУ")
                    local success = placeUnit(action.CF, action.Unit, action.PathIndex)
                    if success then
                        print("[УСПЕХ] ✅ Юнит " .. action.ID .. " размещен")
                        
                        -- Для юнитов 3,4,5 запускаем бесконечные апгрейды
                        if action.ID >= 3 and action.ID <= 5 then
                            print("[АПГРЕЙД] 🔄 Запускаем бесконечные апгрейды для юнита " .. action.ID)
                            startInfiniteUpgradeLoop(action.ID)
                        end
                    else
                        print("[ОШИБКА] ❌ Не удалось разместить юнит " .. action.ID)
                    end
                end
            end
        end
        
        -- Ждем немного перед следующей итерацией (но рестарт все равно будет каждые 3 сек)
        for i = 1, 10 do
            if not AutoFarm.running then return end
            task.wait(1)
        end
    end
end

-- Функция для создания интерфейса
local function createSimpleUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFarmGUI"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 180)
    mainFrame.Position = UDim2.new(0.5, -125, 0.5, -90)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "🌿 АВТОФЕРМА"
    title.TextColor3 = Color3.fromRGB(0, 255, 170)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = mainFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 0, 30)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "● Остановлено"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    statusLabel.Parent = mainFrame
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 60)
    infoLabel.Position = UDim2.new(0, 0, 0, 50)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "5 юнитов\nЮниты 3-5: бесконечные апгрейды (каждые 3 сек)\nАвто-рестарт: каждые 3 сек"
    infoLabel.TextColor3 = Color3.fromRGB(170, 170, 255)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 11
    infoLabel.TextWrapped = true
    infoLabel.Parent = mainFrame
    
    local btn2x = Instance.new("TextButton")
    btn2x.Size = UDim2.new(0.4, 0, 0, 30)
    btn2x.Position = UDim2.new(0.05, 0, 0.75, 0)
    btn2x.Text = "🚀 x2"
    btn2x.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    btn2x.Font = Enum.Font.GothamBold
    btn2x.TextSize = 14
    btn2x.Parent = mainFrame
    
    local btn3x = Instance.new("TextButton")
    btn3x.Size = UDim2.new(0.4, 0, 0, 30)
    btn3x.Position = UDim2.new(0.55, 0, 0.75, 0)
    btn3x.Text = "⚡ x3"
    btn3x.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    btn3x.Font = Enum.Font.GothamBold
    btn3x.TextSize = 14
    btn3x.Parent = mainFrame
    
    local function setButtonsVisible(visible)
        btn2x.Visible = visible
        btn3x.Visible = visible
    end
    
    local function updateStatus(isRunning, speed)
        if isRunning then
            statusLabel.Text = "● Работает x" .. speed
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            statusLabel.Text = "● Остановлено"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
    
    local function startGame(speed)
        if AutoFarm.running then return end
        AutoFarm.running = true
        setButtonsVisible(false)
        updateStatus(true, speed)
        
        AutoFarm.thread = task.spawn(function()
            startAutoGame(speed)
            AutoFarm.running = false
            setButtonsVisible(true)
            updateStatus(false)
        end)
    end
    
    btn2x.MouseButton1Click:Connect(function() startGame(2) end)
    btn3x.MouseButton1Click:Connect(function() startGame(3) end)
    
    -- Кнопка остановки
    local btnStop = Instance.new("TextButton")
    btnStop.Size = UDim2.new(0.9, 0, 0, 30)
    btnStop.Position = UDim2.new(0.05, 0, 0.85, 0)
    btnStop.Text = "🛑 СТОП"
    btnStop.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnStop.Font = Enum.Font.GothamBold
    btnStop.TextSize = 14
    btnStop.Visible = false
    btnStop.Parent = mainFrame
    
    btnStop.MouseButton1Click:Connect(function()
        AutoFarm:StopEverything()
    end)
    
    -- Обновляем видимость кнопок
    local function updateButtons()
        btn2x.Visible = not AutoFarm.running
        btn3x.Visible = not AutoFarm.running
        btnStop.Visible = AutoFarm.running
    end
    
    -- Подписываемся на изменения
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        updateButtons()
        if not AutoFarm.running and conn then
            conn:Disconnect()
        end
    end)
    
    mainFrame.Parent = screenGui
    return screenGui
end

-- Основная функция
local function main()
    if _G.AutoFarmLoaded then return end
    
    if _G.AutoFarm and type(_G.AutoFarm.StopEverything) == "function" then
        pcall(function() _G.AutoFarm:StopEverything() end)
    end
    
    _G.AutoFarm = {}
    AutoFarm = _G.AutoFarm
    AutoFarm.running = false
    AutoFarm.thread = nil
    AutoFarm.scheduledTasks = {}
    AutoFarm.antiAFKEnabled = true
    AutoFarm.antiAFKThread = nil
    
    function AutoFarm:StopEverything()
        stopAntiAFK()
        self.running = false
        if self.thread then self.thread = nil end
        self.scheduledTasks = {}
        local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui and playerGui:FindFirstChild("AutoFarmGUI") then playerGui.AutoFarmGUI:Destroy() end
        _G.AutoFarmLoaded = false
        return true
    end
    
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("AutoFarmGUI") then playerGui.AutoFarmGUI:Destroy() end
    
    createSimpleUI()
    _G.AutoFarmLoaded = true
    
    print("✅ Автоферма загружена")
    print("📌 5 юнитов")
    print("📌 Юниты 3-5: бесконечные апгрейды (каждые 3 сек)")
    print("📌 Авто-рестарт: каждые 3 секунды")
end

-- Функция для ручной остановки из консоли
function StopAutoFarm()
    if _G.AutoFarm and _G.AutoFarm.StopEverything then
        return _G.AutoFarm:StopEverything()
    end
    return false
end

-- Запуск основной функции
if not _G.AutoFarmLoaded then
    if not game:IsLoaded() then game.Loaded:Wait() end
    game.Players.LocalPlayer:WaitForChild("PlayerGui")
    task.wait(2)
    pcall(main)
end
