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
AutoFarm.connections = {}
AutoFarm.scheduledTasks = {}
AutoFarm.currentMacro = 1
AutoFarm.antiAFKEnabled = true
AutoFarm.antiAFKThread = nil

-- Сервисы
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local humanoid = nil
local character = nil
local moveThread = nil

-- Rice Anti-Afk GUI
local Rice = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local Credits = Instance.new("TextLabel")
local Activate = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local OpenClose = Instance.new("TextButton")
local UICorner_2 = Instance.new("UICorner")

Rice.Name = "Rice"
Rice.Parent = game.CoreGui
Rice.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Main.Name = "Main"
Main.Parent = Rice
Main.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.321207851, 0, 0.409807354, 0)
Main.Size = UDim2.new(0, 295, 0, 116)
Main.Visible = false
Main.Active = true
Main.Draggable =  true

Title.Name = "Title"
Title.Parent = Main
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(0, 295, 0, 16)
Title.Font = Enum.Font.GothamBold
Title.Text = "Rice Anti-Afk"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextSize = 12.000
Title.TextWrapped = true

Credits.Name = "Credits"
Credits.Parent = Main
Credits.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Credits.BorderSizePixel = 0
Credits.Position = UDim2.new(0, 0, 0.861901641, 0)
Credits.Size = UDim2.new(0, 295, 0, 16)
Credits.Font = Enum.Font.GothamBold
Credits.Text = "Made by jamess#0007"
Credits.TextColor3 = Color3.fromRGB(255, 255, 255)
Credits.TextScaled = true
Credits.TextSize = 12.000
Credits.TextWrapped = true

Activate.Name = "Activate"
Activate.Parent = Main
Activate.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Activate.BorderColor3 = Color3.fromRGB(27, 42, 53)
Activate.BorderSizePixel = 0
Activate.Position = UDim2.new(0.0330629945, 0, 0.243326917, 0)
Activate.Size = UDim2.new(0, 274, 0, 59)
Activate.Font = Enum.Font.GothamBold
Activate.Text = "Activate"
Activate.TextColor3 = Color3.fromRGB(0, 255, 127)
Activate.TextSize = 43.000
Activate.TextStrokeColor3 = Color3.fromRGB(102, 255, 115)

-- Автоматическое включение анти-афк
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(function()
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

UICorner.Parent = Activate

OpenClose.Name = "Open/Close"
OpenClose.Parent = Rice
OpenClose.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
OpenClose.Position = UDim2.new(0.353924811, 0, 0.921739101, 0)
OpenClose.Size = UDim2.new(0, 247, 0, 35)
OpenClose.Font = Enum.Font.GothamBold
OpenClose.Text = "Open/Close"
OpenClose.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenClose.TextSize = 14.000

UICorner_2.Parent = OpenClose

-- Функция для открытия/закрытия GUI
OpenClose.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

-- Базовая позиция каждого юнита (X, Z координаты) - НОВЫЙ МАКРОС
local basePositions = {
    [1] = {x = -21.6971283, z = 35.2651024},  -- Юнит 1 (Electric Jabber) на 5 сек
    [2] = {x = -16.0617104, z = 34.657795},   -- Юнит 2 (Electric Jabber) на 24 сек
    [3] = {x = -23.7096596, z = 24.1806145},  -- Юнит 3 (Electric Jabber) на 30 сек
    [4] = {x = -13.574295, z = 18.9693451},   -- Юнит 4 (Beehive) на 52 сек
    [5] = {x = -20.7439041, z = 16.8078041},  -- Юнит 5 (Beehive) на 72 сек
    [6] = {x = -16.6652946, z = 11.3560066}   -- Юнит 6 (Beehive) на 75 сек
}

-- Функция для получения персонажа
local function getCharacter()
    character = player.Character
    if character then
        humanoid = character:FindFirstChild("Humanoid")
    end
    return character, humanoid
end

-- Функция для реалистичного бега к точке
local function runToPosition(targetX, targetY, targetZ)
    local char, hum = getCharacter()
    if not char or not hum then
        print("[БЕГ] ❌ Персонаж не найден")
        return false
    end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        print("[БЕГ] ❌ RootPart не найден")
        return false
    end
    
    -- Останавливаем предыдущий бег
    if moveThread then
        task.cancel(moveThread)
        moveThread = nil
        hum.WalkToPoint = rootPart.Position -- останавливаем
    end
    
    local targetPos = Vector3.new(targetX, targetY, targetZ)
    local distance = (targetPos - rootPart.Position).Magnitude
    
    print(string.format("[БЕГ] 🏃‍♂️ Бежим к юниту (расстояние: %.1f)", distance))
    
    -- Используем встроенную механику бега Roblox
    hum.WalkToPoint = targetPos
    
    -- Запускаем поток для отслеживания прибытия
    moveThread = task.spawn(function()
        local startTime = tick()
        local timeout = distance / 10 + 5 -- максимум времени на бег + запас
        
        while AutoFarm.running do
            task.wait(0.5)
            
            if not hum or not hum.Parent then
                break
            end
            
            local currentPos = rootPart.Position
            local currentDistance = (targetPos - currentPos).Magnitude
            
            -- Если дошли до цели
            if currentDistance < 5 then
                hum.WalkToPoint = currentPos -- останавливаем
                print("[БЕГ] ✅ Прибыли к юниту")
                break
            end
            
            -- Таймаут на случай если застряли
            if tick() - startTime > timeout then
                print("[БЕГ] ⚠️ Таймаут движения")
                hum.WalkToPoint = currentPos
                break
            end
        end
        moveThread = nil
    end)
    
    return true
end

-- Функция для генерации случайного смещения в пределах ±0.5
local function getRandomOffset()
    return (math.random() * 1.0) - 0.5  -- от -0.5 до +0.5
end

-- Функция для создания CF строки со случайным смещением
local function generateRandomizedCF(baseCF, unitId)
    local parts = {}
    for num in baseCF:gmatch("[%-%d%.eE+]+") do
        table.insert(parts, tonumber(num))
    end
    
    local baseX = basePositions[unitId].x
    local baseZ = basePositions[unitId].z
    local y = parts[2]
    
    local offsetX = getRandomOffset()
    local offsetZ = getRandomOffset()
    
    local newX = baseX + offsetX
    local newZ = baseZ + offsetZ
    
    local newCF = string.format("%f, %f, %f, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", 
        newX, y, newZ)
    
    return newCF, newX, newZ
end

-- Данные для размещения юнитов (НОВЫЙ МАКРОС - 6 юнитов)
local macroData = {
    -- Юнит 1 (Electric Jabber) на 5 секунде
    {Type = "PlaceUnit", CF = "-21.6971283, -85.1852188, 35.2651024, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 1, Time = 5, Unit = "unit_electric_jabber", ID = 1},
    -- Юнит 2 (Electric Jabber) на 24 секунде
    {Type = "PlaceUnit", CF = "-16.0617104, -85.1852188, 34.657795, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 2, Time = 24, Unit = "unit_electric_jabber", ID = 2},
    -- Юнит 3 (Electric Jabber) на 30 секунде
    {Type = "PlaceUnit", CF = "-23.7096596, -85.1852188, 24.1806145, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 3, Time = 30, Unit = "unit_electric_jabber", ID = 3},
    -- Юнит 4 (Beehive) на 52 секунде
    {Type = "PlaceUnit", CF = "-13.574295, -85.1852188, 18.9693451, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 4, Time = 52, Unit = "unit_beehive", ID = 4},
    -- Юнит 5 (Beehive) на 72 секунде
    {Type = "PlaceUnit", CF = "-20.7439041, -85.1852188, 16.8078041, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 5, Time = 72, Unit = "unit_beehive", ID = 5},
    -- Юнит 6 (Beehive) на 75 секунде
    {Type = "PlaceUnit", CF = "-16.6652946, -85.1852188, 11.3560066, -1, 0, -8.74227766e-08, 0, 1, 0, 8.74227766e-08, 0, -1", PathIndex = 4, Time = 75, Unit = "unit_beehive", ID = 6}
}

-- Функция для бесконечного авто-рестарта (каждые 3 секунды)
local function startInfiniteRestartLoop()
    local function restartLoop()
        if not AutoFarm.running then return end
        
        print("[АВТО-РЕСТАРТ] 🔄 Перезапуск игры...")
        pcall(function() remotes.RestartGame:InvokeServer() end)
        
        task.delay(3, restartLoop)
    end
    task.delay(3, restartLoop)
end

-- Функция полной остановки и сброса
function AutoFarm:StopEverything()
    print("[СИСТЕМА] Начинаем полную остановку...")
    
    self.running = false
    
    -- Останавливаем бег
    if moveThread then
        task.cancel(moveThread)
        moveThread = nil
    end
    
    local char, hum = getCharacter()
    if hum then
        hum.WalkToPoint = hum.Parent.HumanoidRootPart.Position
    end
    
    if self.thread then
        print("[СИСТЕМА] Останавливаем основной поток...")
        local thread = self.thread
        self.thread = nil
    end
    
    -- Отменяем все запланированные задачи
    print("[СИСТЕМА] Отменяем запланированные задачи...")
    for i, taskInfo in pairs(self.scheduledTasks) do
        if taskInfo and taskInfo.cancel then
            pcall(taskInfo.cancel)
        end
    end
    self.scheduledTasks = {}
    
    -- Отключаем все соединения
    print("[СИСТЕМА] Отключаем соединения...")
    for _, connection in pairs(self.connections) do
        if connection and connection.Disconnect then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    self.connections = {}
    
    -- Удаляем интерфейс
    print("[СИСТЕМА] Удаляем интерфейс...")
    local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local oldGui = playerGui:FindFirstChild("AutoFarmGUI")
        if oldGui then
            oldGui:Destroy()
        end
    end
    
    -- Сбрасываем все флаги
    print("[СИСТЕМА] Сбрасываем все флаги...")
    _G.AutoPlacementLoaded = false
    _G.AutoFarmLoaded = false
    
    print("[СИСТЕМА] ✅ Полная остановка завершена!")
    print("[СИСТЕМА] Скрипт полностью остановлен и сброшен")
    print("[СИСТЕМА] Перезапустите скрипт для нового запуска")
    
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
    
    if success then
        return true
    else
        return false
    end
end

-- Функция размещения юнита со случайным смещением и бегом к нему
local function placeUnitWithRandomOffset(baseCF, unitName, pathIndex, unitId)
    local randomizedCF, newX, newZ = generateRandomizedCF(baseCF, unitId)
    local cf = decodeCFrame(randomizedCF)
    
    local offsetX = cf.X - basePositions[unitId].x
    local offsetZ = cf.Z - basePositions[unitId].z
    print(string.format("[СМЕЩЕНИЕ] Юнит %d: X%+.4f, Z%+.4f", unitId, offsetX, offsetZ))
    
    local success = placeUnit(randomizedCF, unitName, pathIndex)
    
    if success then
        print("[УСПЕХ] ✅ Юнит " .. unitId .. " размещен")
        
        -- Бежим к юниту
        task.wait(0.5)
        runToPosition(newX, cf.Y, newZ)
    end
    
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

-- Функция автоигры (только x3 скорость)
local function startAutoGame()
    local baseDelay = 5
    local speed = 3
    local lastUnitTime = 75 -- последний юнит на 75 секунде
    
    -- Запускаем периодические функции
    startDifficultyLoop()
    startAutoSkipLoop()
    startInfiniteRestartLoop()
    
    while AutoFarm.running do
        -- Устанавливаем скорость x3
        remotes.ChangeTickSpeed:InvokeServer(speed)
        
        -- Базовая задержка перед стартом
        for i = 1, baseDelay do
            if not AutoFarm.running then return end
            task.wait(1)
        end
        
        print("")
        print("==========================================")
        print("🚀 НАЧАЛО НОВОГО РАУНДА (x3)")
        print("==========================================")
        
        -- Размещаем юниты по расписанию со случайными смещениями
        for i, action in ipairs(macroData) do
            if action.Type == "PlaceUnit" then
                local placeTime = action.Time - baseDelay
                
                if placeTime > 0 then
                    scheduleTask(placeTime, function()
                        if not AutoFarm.running then return end
                        
                        print("[РАЗМЕЩЕНИЕ] Юнит " .. action.ID .. " на " .. action.Time .. " сек")
                        placeUnitWithRandomOffset(action.CF, action.Unit, action.PathIndex, action.ID)
                    end, "place_" .. action.ID)
                elseif placeTime <= 0 and AutoFarm.running then
                    print("[РАЗМЕЩЕНИЕ] Юнит " .. action.ID .. " СРАЗУ")
                    placeUnitWithRandomOffset(action.CF, action.Unit, action.PathIndex, action.ID)
                end
            end
        end
        
        -- Ждем пока пройдет время последнего юнита
        local waitTime = (lastUnitTime / speed) - baseDelay
        if waitTime > 0 then
            for i = 1, math.floor(waitTime) do
                if not AutoFarm.running then return end
                task.wait(1)
            end
        end
        
        -- Небольшая пауза перед рестартом
        for i = 1, 3 do
            if not AutoFarm.running then return end
            task.wait(1)
        end
    end
end

-- Функция для создания интерфейса (только x3)
local function createSimpleUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFarmGUI"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🌿 АВТОФЕРМА"
    title.TextColor3 = Color3.fromRGB(0, 255, 170)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = mainFrame
    
    -- Статус фермы
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 40)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ферма: Остановлено"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.Parent = mainFrame
    
    -- Информация
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 120)
    infoLabel.Position = UDim2.new(0, 0, 0, 65)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "6 юнитов\nТолько x3 скорость\nЮниты 1-3: Electric Jabber (5,24,30 сек)\nЮниты 4-6: Beehive (52,72,75 сек)\nРандомные координаты ±0.5\nПерсонаж БЕЖИТ к каждому юниту\nАвто-рестарт каждые 3 сек\nRice Anti-Afk автоматически включен"
    infoLabel.TextColor3 = Color3.fromRGB(170, 170, 255)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 11
    infoLabel.TextWrapped = true
    infoLabel.Parent = mainFrame
    
    -- Кнопка запуска x3
    local btnStart3x = Instance.new("TextButton")
    btnStart3x.Size = UDim2.new(0.9, 0, 0, 30)
    btnStart3x.Position = UDim2.new(0.05, 0, 0.80, 0)
    btnStart3x.Text = "⚡ ЗАПУСТИТЬ x3"
    btnStart3x.Font = Enum.Font.GothamBold
    btnStart3x.TextSize = 13
    btnStart3x.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnStart3x.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    btnStart3x.AutoButtonColor = true
    
    local btn3xCorner = Instance.new("UICorner")
    btn3xCorner.CornerRadius = UDim.new(0, 6)
    btn3xCorner.Parent = btnStart3x
    
    -- Кнопка остановки
    local btnStop = Instance.new("TextButton")
    btnStop.Size = UDim2.new(0.9, 0, 0, 30)
    btnStop.Position = UDim2.new(0.05, 0, 0.90, 0)
    btnStop.Text = "🛑 ПОЛНАЯ ОСТАНОВКА"
    btnStop.Font = Enum.Font.GothamBold
    btnStop.TextSize = 12
    btnStop.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnStop.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnStop.AutoButtonColor = true
    btnStop.Visible = false
    
    local stopCorner = Instance.new("UICorner")
    stopCorner.CornerRadius = UDim.new(0, 5)
    stopCorner.Parent = btnStop
    
    -- Функция обновления статуса
    local function updateStatus(isRunning)
        if isRunning then
            statusLabel.Text = "Ферма: Работает x3"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            btnStart3x.Visible = false
            btnStop.Visible = true
        else
            statusLabel.Text = "Ферма: Остановлено"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            btnStart3x.Visible = true
            btnStop.Visible = false
        end
    end
    
    -- Функция запуска автоигры
    local function startGame()
        if AutoFarm.running then
            return
        end
        
        AutoFarm.running = true
        updateStatus(true)
        
        AutoFarm.thread = task.spawn(function()
            local success, error = pcall(function()
                startAutoGame()
            end)
            
            if not success then
                warn("❌ Ошибка автоигры:", error)
            end
            
            AutoFarm.running = false
            updateStatus(false)
        end)
    end
    
    btnStart3x.MouseButton1Click:Connect(function()
        if not AutoFarm.running then
            btnStart3x.Text = "🔄 ЗАПУСК..."
            btnStart3x.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            
            task.delay(0.5, function()
                startGame()
                btnStart3x.Text = "⚡ ЗАПУСТИТЬ x3"
                btnStart3x.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            end)
        end
    end)
    
    btnStop.MouseButton1Click:Connect(function()
        if AutoFarm.running then
            btnStop.Text = "⏳ ОСТАНАВЛИВАЕМ..."
            btnStop.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
            
            task.spawn(function()
                local success, result = pcall(function()
                    return AutoFarm:StopEverything()
                end)
                
                if success then
                    print("[СИСТЕМА] ✅ Скрипт полностью остановлен!")
                    if screenGui and screenGui.Parent then
                        screenGui:Destroy()
                    end
                    _G.AutoFarmLoaded = false
                    _G.AutoPlacementLoaded = false
                else
                    print("[СИСТЕМА] ⚠️ Ошибка при остановке:", result)
                    btnStop.Text = "🛑 ПОЛНАЯ ОСТАНОВКА"
                    btnStop.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                end
            end)
        end
    end)
    
    btnStart3x.Parent = mainFrame
    btnStop.Parent = mainFrame
    mainFrame.Parent = screenGui
    
    return screenGui
end

-- Основная функция
local function main()
    if _G.AutoFarmLoaded then
        return
    end
    
    if _G.AutoFarm and type(_G.AutoFarm.StopEverything) == "function" then
        pcall(function()
            _G.AutoFarm:StopEverything()
        end)
    end
    
    _G.AutoFarm = {}
    AutoFarm = _G.AutoFarm
    AutoFarm.running = false
    AutoFarm.thread = nil
    AutoFarm.connections = {}
    AutoFarm.scheduledTasks = {}
    AutoFarm.currentMacro = 1
    AutoFarm.antiAFKEnabled = true
    AutoFarm.antiAFKThread = nil
    
    function AutoFarm:StopEverything()
        print("[СИСТЕМА] Начинаем полную остановку...")
        
        self.running = false
        
        -- Останавливаем бег
        if moveThread then
            task.cancel(moveThread)
            moveThread = nil
        end
        
        local char, hum = getCharacter()
        if hum then
            hum.WalkToPoint = hum.Parent.HumanoidRootPart.Position
        end
        
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
        
        for _, connection in pairs(self.connections) do
            if connection and connection.Disconnect then
                pcall(function()
                    connection:Disconnect()
                end)
            end
        end
        self.connections = {}
        
        local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local oldGui = playerGui:FindFirstChild("AutoFarmGUI")
            if oldGui then
                oldGui:Destroy()
            end
        end
        
        _G.AutoPlacementLoaded = false
        _G.AutoFarmLoaded = false
        
        print("[СИСТЕМА] ✅ Полная остановка завершена!")
        print("[СИСТЕМА] Перезапустите скрипт для нового запуска")
        
        return true
    end
    
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("AutoFarmGUI") then
        playerGui:FindFirstChild("AutoFarmGUI"):Destroy()
    end
    
    createSimpleUI()
    
    _G.AutoFarmLoaded = true
    
    print("✅ Автоферма загружена!")
    print("==========================================")
    print("🌿 GARDEN TOWER DEFENSE - АВТОФЕРМА")
    print("==========================================")
    print("🎮 6 юнитов:")
    print("• 5 сек - Юнит 1 (Electric Jabber)")
    print("• 24 сек - Юнит 2 (Electric Jabber)")
    print("• 30 сек - Юнит 3 (Electric Jabber)")
    print("• 52 сек - Юнит 4 (Beehive)")
    print("• 72 сек - Юнит 5 (Beehive)")
    print("• 75 сек - Юнит 6 (Beehive)")
    print("")
    print("⚡ НАСТРОЙКИ:")
    print("• Только x3 скорость")
    print("• Рандомные координаты ±0.5")
    print("• Персонаж БЕЖИТ к каждому юниту")
    print("• Авто-рестарт: каждые 3 секунды")
    print("• Rice Anti-Afk автоматически включен")
    print("")
    print("🔄 Управление:")
    print("• ⚡ ЗАПУСТИТЬ x3 - автоигра")
    print("• 🛑 ПОЛНАЯ ОСТАНОВКА - сброс скрипта")
    print("")
    print("==========================================")
    print("Для остановки из консоли: StopAutoFarm()")
    print("==========================================")
end

-- Функция для ручной остановки из консоли
function StopAutoFarm()
    print("[КОНСОЛЬ] Запущена полная остановка скрипта...")
    
    if _G.AutoFarm and type(_G.AutoFarm.StopEverything) == "function" then
        local success, result = pcall(function()
            return _G.AutoFarm:StopEverything()
        end)
        
        if success then
            print("[КОНСОЛЬ] ✅ Скрипт полностью остановлен!")
            print("[КОНСОЛЬ] Запустите скрипт заново для нового запуска")
            _G.AutoFarmLoaded = false
            _G.AutoPlacementLoaded = false
            return true
        else
            warn("[КОНСОЛЬ] ❌ Ошибка при остановке:", result)
            return false
        end
    else
        warn("[КОНСОЛЬ] ❌ Скрипт не запущен или не инициализирован")
        return false
    end
end

-- Запуск основной функции
if not _G.AutoFarmLoaded then
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    task.wait(2)
    
    local success, error = pcall(main)
    
    if not success then
        warn("❌ Ошибка при запуске скрипта:", error)
        print("Попробуйте выполнить: StopAutoFarm() для сброса")
    end
else
    warn("⚠️ Скрипт уже запущен!")
    print("Используйте StopAutoFarm() для полной остановки")
    print("Затем запустите скрипт заново")
end
