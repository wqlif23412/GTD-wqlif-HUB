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
AutoFarm.antiAFKEnabled = true  -- Анти-АФК включен по умолчанию
AutoFarm.antiAFKThread = nil

-- Функция для анти-АФК системы
local function setupAntiAFK()
    if not AutoFarm.antiAFKEnabled then return end
    
    print("[Анти-АФК] Система активируется...")
    
    -- Отключаем стандартный анти-афк Roblox
    local Players = game:GetService("Players")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local UserInputService = game:GetService("UserInputService")
    
    -- Сохраняем стандартный анти-афк
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Создаем анти-афк действия
    local antiAFKActions = {
        -- Движение камеры
        cameraMovement = function()
            local currentCamera = workspace.CurrentCamera
            local currentCF = currentCamera.CFrame
            local newCF = currentCF * CFrame.Angles(0, math.rad(1), 0)
            currentCamera.CFrame = newCF
        end,
        
        -- Нажатие клавиш
        keyPress = function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end,
        
        -- Движение мыши
        mouseMovement = function()
            local mouse = player:GetMouse()
            local moveDistance = 10
            mousemoverel(moveDistance, 0)
            task.wait(0.1)
            mousemoverel(-moveDistance, 0)
        end
    }
    
    -- Создаем плавное вращение камеры для лучшего анти-афк
    local function smoothCameraRotation()
        local camera = workspace.CurrentCamera
        local rotationSpeed = 0.5  -- градусов в секунду
        local totalRotation = 0
        local maxRotation = 30
        
        while AutoFarm.running and AutoFarm.antiAFKEnabled do
            local deltaTime = 0.1
            local rotationAmount = rotationSpeed * deltaTime
            
            -- Плавное вращение вперед-назад
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
    
    -- Основной анти-АФК цикл
    AutoFarm.antiAFKThread = task.spawn(function()
        print("[Анти-АФК] Система запущена")
        
        -- Запускаем плавное вращение камеры
        task.spawn(smoothCameraRotation)
        
        local actionCounter = 0
        while AutoFarm.running and AutoFarm.antiAFKEnabled do
            actionCounter = actionCounter + 1
            
            -- Каждые 30 секунд делаем разные действия
            if actionCounter % 30 == 0 then
                -- Движение камеры
                antiAFKActions.cameraMovement()
                
                -- Каждую минуту нажимаем пробел
                if actionCounter % 60 == 0 then
                    antiAFKActions.keyPress()
                    print("[Анти-АФК] Пробел нажат (", os.date("%H:%M:%S"), ")")
                end
                
                -- Каждые 2 минуты движение мыши
                if actionCounter % 120 == 0 then
                    antiAFKActions.mouseMovement()
                    print("[Анти-АФК] Мышь подвинута (", os.date("%H:%M:%S"), ")")
                end
                
                print("[Анти-АФК] Активность обновлена (", os.date("%H:%M:%S"), ")")
            end
            
            task.wait(1)  -- Проверяем каждую секунду
        end
        
        print("[Анти-АФК] Система остановлена")
    end)
    
    -- Также используем стандартный метод
    local function standardAntiAFK()
        local gc = getconnections or get_signal_connections
        if gc then
            for _, v in pairs(gc(player.Idled)) do
                if v.Function then
                    v:Disable()
                elseif v.Disconnect then
                    v:Disconnect()
                end
            end
        end
    end
    
    -- Пробуем стандартный метод
    pcall(standardAntiAFK)
    
    -- Альтернативный метод: переподключение Idled события
    local function reconnectAntiAFK()
        player.Idled:Connect(function()
            -- Вместо кика делаем виртуальное действие
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.S, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.S, false, game)
        end)
    end
    
    pcall(reconnectAntiAFK)
    
    print("[Анти-АФК] ✅ Система полностью активирована")
    print("[Анти-АФК] Камера будет плавно вращаться")
    print("[Анти-АФК] Периодические нажатия клавиш")
end

-- Функция для остановки анти-АФК
local function stopAntiAFK()
    AutoFarm.antiAFKEnabled = false
    
    if AutoFarm.antiAFKThread then
        task.cancel(AutoFarm.antiAFKThread)
        AutoFarm.antiAFKThread = nil
    end
    
    print("[Анти-АФК] Система отключена")
end

-- Авто-скип (включается автоматически)
task.delay(2, function()
    pcall(function()
        remotes.ToggleAutoSkip:InvokeServer(true)
        print("[Система] Авто-скип включен")
    end)
    
    -- Запускаем анти-АФК через 3 секунды после старта
    task.wait(1)
    setupAntiAFK()
end)

-- Функция полной остановки и сброса
function AutoFarm:StopEverything()
    print("[СИСТЕМА] Начинаем полную остановку...")
    
    -- Останавливаем анти-АФК
    stopAntiAFK()
    
    -- Останавливаем основной поток
    self.running = false
    
    if self.thread then
        print("[СИСТЕМА] Останавливаем основной поток...")
        local thread = self.thread
        self.thread = nil
        
        -- Пытаемся корректно остановить поток
        task.spawn(function()
            task.wait(0.1)
            if coroutine.status(thread) ~= "dead" then
                print("[СИСТЕМА] Принудительная остановка потока...")
            end
        end)
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
    
    -- Завершаем скрипт
    return true
end

-- Функция для отмены задачи
local function cancelTask(taskId)
    if AutoFarm.scheduledTasks[taskId] then
        AutoFarm.scheduledTasks[taskId] = nil
        return true
    end
    return false
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
    
    local success, result = pcall(function()
        return remotes.PlaceUnit:InvokeServer(unitName, placementData)
    end)
    
    if success then
        print("✅ Юнит размещен:", unitName, "PathIndex:", pathIndex)
        return true
    else
        warn("❌ Ошибка:", result)
        return false
    end
end

-- Функция автоигры
local function startAutoGame(speed)
    print("[СИСТЕМА] Запуск автоигры x" .. speed .. " скорость...")
    print("[СИСТЕМА] Статус работы: " .. tostring(AutoFarm.running))
    
    -- Устанавливаем скорость
    remotes.ChangeTickSpeed:InvokeServer(speed)
    
    -- Выбираем сложность
    local difficulty = "dif_apocalypse"
    
    -- БАЗОВЫЕ РАЗМЕЩЕНИЯ (для x2 скорости)
    local basePlacements = {
        {targetTime = 2,   actualTime = -3, unit = "unit_rafflesia", cf = "108.478439, 1.24432266, -92.6322784, 0.981734037, -2.26239445e-05, -0.190258533, -0, 1, -0.000118911586, 0.190258533, 0.000116739553, 0.981734037", pathIndex = 1},
        {targetTime = 11,  actualTime = 6,  unit = "unit_rafflesia", cf = "110.600975, 1.24414515, 97.3004379, -0.981734037, 2.26239445e-05, -0.190258533, -0, 1, 0.000118911586, 0.190258533, 0.000116739553, -0.981734037", pathIndex = 2},
        {targetTime = 19,  actualTime = 14, unit = "unit_rafflesia", cf = "-97.5022354, 1.24399996, 89.5488358, -0, 0, 1, 0, 1, -0, -1, 0, -0", pathIndex = 3},
        {targetTime = 28,  actualTime = 23, unit = "unit_rafflesia", cf = "-73.7794266, 1.24399996, -117.989304, 0.707106829, 0, 0.707106769, -0, 1, -0, -0.707106829, 0, 0.707106769", pathIndex = 4}
    }
    
    -- ПАРАМЕТРЫ ДЛЯ РАЗНЫХ СКОРОСТЕЙ
    local speedSettings = {
        [2] = {placements = basePlacements, gameDuration = 164, waitAfterLastUnit = 136},  -- 2:44
        
        [3] = { -- МОДИФИЦИРОВАННЫЕ НАСТРОЙКИ ДЛЯ x3
            placements = {
                basePlacements[1],  -- 1-й юнит без изменений
                basePlacements[2],  -- 2-й юнит без изменений
                basePlacements[3],  -- 3-й юнит без изменений
                -- ИЗМЕНЕН 4-й юнит:
                {targetTime = 21,  actualTime = 18, unit = "unit_rafflesia", cf = "-73.7794266, 1.24399996, -117.989304, 0.707106829, 0, 0.707106769, -0, 1, -0, -0.707106829, 0, 0.707106769", pathIndex = 4}
            },
            -- ИЗМЕНЕНО: увеличение длительности на 21 секунду
            -- Было: 94 секунды (1:34), стало: 115 секунд (1:55)
            gameDuration = 115,  -- 1:55 (115 реальных секунд)
            waitAfterLastUnit = 94  -- 115 - 21 = 94 секунды
        }
    }
    
    -- Выбираем настройки по скорости
    local settings = speedSettings[speed] or speedSettings[2]
    local placements = settings.placements
    local gameDuration = settings.gameDuration
    local waitAfterLastUnit = settings.waitAfterLastUnit
    
    print("[НАСТРОЙКИ] Длительность игры: " .. gameDuration .. " сек (" .. math.floor(gameDuration/60) .. ":" .. string.format("%02d", gameDuration%60) .. ")")
    print("[РАЗМЕЩЕНИЯ] 4-й юнит: на " .. placements[4].targetTime .. " секунде игры (через " .. placements[4].actualTime .. " сек)")
    print("[РАСЧЕТ] Ожидание после 4-го юнита: " .. waitAfterLastUnit .. " секунд")
    
    while AutoFarm.running do
        print("[ЦИКЛ] Начало нового цикла (x" .. speed .. ")...")
        
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        print("[ЦИКЛ] Выбрана сложность: Apocalypse")
        
        -- Ожидание 6 секунд для компенсации задержки
        print("[ЦИКЛ] Ожидание 6 секунд (компенсация)...")
        for i = 1, 6 do
            if not AutoFarm.running then 
                print("[ЦИКЛ] Прерывание во время ожидания")
                return 
            end
            task.wait(1)
        end
        
        -- Немедленно ставим первый юнит
        if AutoFarm.running then
            print("[РАЗМЕЩЕНИЕ] Ставим юнит 1 (targetTime: " .. placements[1].targetTime .. ")")
            placeUnit(placements[1].cf, placements[1].unit, placements[1].pathIndex)
        end
        
        -- Планируем остальные юниты (2, 3, 4)
        for i = 2, 4 do
            local p = placements[i]
            if p.actualTime > 0 then
                scheduleTask(p.actualTime, function()
                    if AutoFarm.running then
                        print("[РАЗМЕЩЕНИЕ] Ставим юнит " .. i .. " (targetTime: " .. p.targetTime .. ")")
                        placeUnit(p.cf, p.unit, p.pathIndex)
                    end
                end, "unit_" .. i)
            end
        end
        
        -- Ждем завершения игры (реальные секунды)
        if waitAfterLastUnit > 0 then
            print("[ЦИКЛ] Ожидание конца игры: " .. waitAfterLastUnit .. " реальных секунд")
            for i = 1, waitAfterLastUnit do
                if not AutoFarm.running then 
                    print("[ЦИКЛ] Прерывание во время ожидания конца игры")
                    return 
                end
                task.wait(1)
            end
        end
        
        -- Проверяем перед рестартом
        if not AutoFarm.running then
            print("[ЦИКЛ] Игра остановлена перед рестартом")
            break
        end
        
        -- Рестарт игры
        remotes.RestartGame:InvokeServer()
        print("[ЦИКЛ] Игра перезапущена, ожидание 3 секунды...")
        
        -- Ждем перед началом новой игры
        for i = 1, 3 do
            if not AutoFarm.running then
                print("[ЦИКЛ] Прерывание во время ожидания рестарта")
                return
            end
            task.wait(1)
        end
    end
    
    print("[ЦИКЛ] Игровой цикл завершен")
end

-- Функция для создания интерфейса
local function createSimpleUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFarmGUI"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 230)  -- Увеличил высоту для анти-АФК статуса
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -115)
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
    title.Text = "🌿 АВТОФЕРМА + АНТИ-АФК"
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
    statusLabel.TextSize = 12
    statusLabel.Parent = mainFrame
    
    -- Статус анти-АФК
    local afkStatusLabel = Instance.new("TextLabel")
    afkStatusLabel.Size = UDim2.new(1, 0, 0, 25)
    afkStatusLabel.Position = UDim2.new(0, 0, 0, 65)
    afkStatusLabel.BackgroundTransparency = 1
    afkStatusLabel.Text = "Анти-АФК: ✅ Активен"
    afkStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    afkStatusLabel.Font = Enum.Font.Gotham
    afkStatusLabel.TextSize = 12
    afkStatusLabel.Parent = mainFrame
    
    -- Информация
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 60)
    infoLabel.Position = UDim2.new(0, 0, 0, 90)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "x2: юниты 2,11,19,28 сек (2:44)\nx3: юниты 2,11,19,21 сек (1:55)\nАнти-АФК: плавное вращение камеры"
    infoLabel.TextColor3 = Color3.fromRGB(170, 170, 255)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 11
    infoLabel.TextWrapped = true
    infoLabel.Parent = mainFrame
    
    -- Кнопка запуска x2
    local btnStart2x = Instance.new("TextButton")
    btnStart2x.Size = UDim2.new(0.9, 0, 0, 30)
    btnStart2x.Position = UDim2.new(0.05, 0, 0.60, 0)
    btnStart2x.Text = "🚀 ЗАПУСТИТЬ x2"
    btnStart2x.Font = Enum.Font.GothamBold
    btnStart2x.TextSize = 13
    btnStart2x.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnStart2x.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    btnStart2x.AutoButtonColor = true
    
    local btn2xCorner = Instance.new("UICorner")
    btn2xCorner.CornerRadius = UDim.new(0, 6)
    btn2xCorner.Parent = btnStart2x
    
    -- Кнопка запуска x3
    local btnStart3x = Instance.new("TextButton")
    btnStart3x.Size = UDim2.new(0.9, 0, 0, 30)
    btnStart3x.Position = UDim2.new(0.05, 0, 0.72, 0)
    btnStart3x.Text = "⚡ ЗАПУСТИТЬ x3"
    btnStart3x.Font = Enum.Font.GothamBold
    btnStart3x.TextSize = 13
    btnStart3x.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnStart3x.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    btnStart3x.AutoButtonColor = true
    
    local btn3xCorner = Instance.new("UICorner")
    btn3xCorner.CornerRadius = UDim.new(0, 6)
    btn3xCorner.Parent = btnStart3x
    
    -- Кнопка переключения анти-АФК
    local btnToggleAFK = Instance.new("TextButton")
    btnToggleAFK.Size = UDim2.new(0.9, 0, 0, 25)
    btnToggleAFK.Position = UDim2.new(0.05, 0, 0.84, 0)
    btnToggleAFK.Text = "🔄 ВЫКЛ АНТИ-АФК"
    btnToggleAFK.Font = Enum.Font.GothamBold
    btnToggleAFK.TextSize = 11
    btnToggleAFK.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnToggleAFK.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    btnToggleAFK.AutoButtonColor = true
    
    local afkCorner = Instance.new("UICorner")
    afkCorner.CornerRadius = UDim.new(0, 5)
    afkCorner.Parent = btnToggleAFK
    
    -- Кнопка остановки
    local btnStop = Instance.new("TextButton")
    btnStop.Size = UDim2.new(0.9, 0, 0, 25)
    btnStop.Position = UDim2.new(0.05, 0, 0.92, 0)
    btnStop.Text = "🛑 ПОЛНАЯ ОСТАНОВКА"
    btnStop.Font = Enum.Font.GothamBold
    btnStop.TextSize = 11
    btnStop.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnStop.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnStop.AutoButtonColor = true
    btnStop.Visible = false
    
    local stopCorner = Instance.new("UICorner")
    stopCorner.CornerRadius = UDim.new(0, 5)
    stopCorner.Parent = btnStop
    
    -- Функция обновления статуса
    local function updateStatus(isRunning, speed)
        if isRunning then
            statusLabel.Text = "Ферма: Работает (x" .. speed .. ")"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            btnStart2x.Visible = false
            btnStart3x.Visible = false
            btnToggleAFK.Visible = false
            btnStop.Visible = true
            if speed == 2 then
                infoLabel.Text = "Юниты: 2,11,19,28 сек\nДлительность: 2:44\nАнти-АФК активен"
            else
                infoLabel.Text = "Юниты: 2,11,19,21 сек\nДлительность: 1:55\nАнти-АФК активен"
            end
        else
            statusLabel.Text = "Ферма: Остановлено"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            btnStart2x.Visible = true
            btnStart3x.Visible = true
            btnToggleAFK.Visible = true
            btnStop.Visible = false
            infoLabel.Text = "x2: юниты 2,11,19,28 сек (2:44)\nx3: юниты 2,11,19,21 сек (1:55)\nАнти-АФК: плавное вращение камеры"
        end
        
        -- Обновляем статус анти-АФК
        if AutoFarm.antiAFKEnabled then
            afkStatusLabel.Text = "Анти-АФК: ✅ Активен"
            afkStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            btnToggleAFK.Text = "🔄 ВЫКЛ АНТИ-АФК"
            btnToggleAFK.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
        else
            afkStatusLabel.Text = "Анти-АФК: ❌ Выключен"
            afkStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            btnToggleAFK.Text = "🔄 ВКЛ АНТИ-АФК"
            btnToggleAFK.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
        end
    end
    
    -- Функция переключения анти-АФК
    local function toggleAntiAFK()
        AutoFarm.antiAFKEnabled = not AutoFarm.antiAFKEnabled
        
        if AutoFarm.antiAFKEnabled then
            setupAntiAFK()
            print("[Анти-АФК] Включен")
        else
            stopAntiAFK()
            print("[Анти-АФК] Выключен")
        end
        
        updateStatus(AutoFarm.running, AutoFarm.running and 2 or nil)
    end
    
    -- Функция запуска автоигры
    local function startGame(speed)
        if AutoFarm.running then
            warn("[СИСТЕМА] Автоигра уже запущена!")
            return
        end
        
        AutoFarm.running = true
        updateStatus(true, speed)
        
        -- Запускаем автоигру в отдельном потоке
        AutoFarm.thread = task.spawn(function()
            local success, error = pcall(function()
                startAutoGame(speed)
            end)
            
            if not success then
                warn("❌ Ошибка автоигры:", error)
            end
            
            -- После завершения автоигры
            AutoFarm.running = false
            updateStatus(false)
            print("[СИСТЕМА] Автоигра завершена")
        end)
    end
    
    -- Обработчики событий
    btnStart2x.MouseButton1Click:Connect(function()
        if not AutoFarm.running then
            btnStart2x.Text = "🔄 ЗАПУСК..."
            btnStart2x.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            
            task.delay(0.5, function()
                startGame(2)
                btnStart2x.Text = "🚀 ЗАПУСТИТЬ x2"
                btnStart2x.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            end)
        end
    end)
    
    btnStart3x.MouseButton1Click:Connect(function()
        if not AutoFarm.running then
            btnStart3x.Text = "🔄 ЗАПУСК..."
            btnStart3x.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            
            task.delay(0.5, function()
                startGame(3)
                btnStart3x.Text = "⚡ ЗАПУСТИТЬ x3"
                btnStart3x.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            end)
        end
    end)
    
    btnToggleAFK.MouseButton1Click:Connect(toggleAntiAFK)
    
    -- ИСПРАВЛЕННАЯ ФУНКЦИЯ ОСТАНОВКИ
    btnStop.MouseButton1Click:Connect(function()
        if AutoFarm.running then
            btnStop.Text = "⏳ ОСТАНАВЛИВАЕМ..."
            btnStop.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
            
            task.spawn(function()
                -- Используем pcall для безопасного вызова StopEverything
                local success, result = pcall(function()
                    return AutoFarm:StopEverything()
                end)
                
                if success then
                    print("[СИСТЕМА] ✅ Скрипт полностью остановлен и сброшен!")
                    print("[СИСТЕМА] Запустите скрипт заново для нового запуска")
                    
                    -- Удаляем текущий GUI
                    if screenGui and screenGui.Parent then
                        screenGui:Destroy()
                    end
                    
                    -- Сбрасываем глобальные флаги
                    _G.AutoFarmLoaded = false
                    _G.AutoPlacementLoaded = false
                    
                    -- Показываем сообщение
                    if game:GetService("StarterGui"):GetCore("SendNotification") then
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "Автоферма",
                            Text = "Скрипт полностью остановлен!\nЗапустите заново.",
                            Duration = 5
                        })
                    end
                else
                    print("[СИСТЕМА] ⚠️ Ошибка при остановке:", result)
                    btnStop.Text = "🛑 ПОЛНАЯ ОСТАНОВКА"
                    btnStop.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                end
            end)
        end
    end)
    
    btnStart2x.Parent = mainFrame
    btnStart3x.Parent = mainFrame
    btnToggleAFK.Parent = mainFrame
    btnStop.Parent = mainFrame
    mainFrame.Parent = screenGui
    
    return screenGui
end

-- Основная функция
local function main()
    -- Проверяем, не запущен ли уже скрипт
    if _G.AutoFarmLoaded then
        warn("⚠️ Скрипт уже запущен! Используйте StopAutoFarm() для остановки")
        return
    end
    
    -- Очищаем предыдущее состояние
    if _G.AutoFarm and type(_G.AutoFarm.StopEverything) == "function" then
        pcall(function()
            _G.AutoFarm:StopEverything()
        end)
    end
    
    -- Инициализируем заново
    _G.AutoFarm = {}
    AutoFarm = _G.AutoFarm
    AutoFarm.running = false
    AutoFarm.thread = nil
    AutoFarm.connections = {}
    AutoFarm.scheduledTasks = {}
    AutoFarm.antiAFKEnabled = true
    AutoFarm.antiAFKThread = nil
    
    -- Метод StopEverything с правильным self
    function AutoFarm:StopEverything()
        print("[СИСТЕМА] Начинаем полную остановку...")
        
        -- Останавливаем анти-АФК
        stopAntiAFK()
        
        -- Останавливаем основной поток
        self.running = false
        
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
    
    -- Проверяем GUI
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("AutoFarmGUI") then
        playerGui:FindFirstChild("AutoFarmGUI"):Destroy()
    end
    
    -- Создаем новый интерфейс
    createSimpleUI()
    
    -- Устанавливаем флаг загрузки
    _G.AutoFarmLoaded = true
    
    print("✅ Автоферма загружена!")
    print("==========================================")
    print("🌿 GARDEN TOWER DEFENSE - АВТОФЕРМА + АНТИ-АФК")
    print("==========================================")
    print("⚡ АНТИ-АФК СИСТЕМА:")
    print("• Плавное вращение камеры (автоматически)")
    print("• Периодические нажатия клавиш")
    print("• Движение мыши")
    print("• Отключение стандартного кика")
    print("• Активируется автоматически при запуске")
    print("")
    print("🎮 x2 Скорость:")
    print("• 2 секунды - Юнит 1")
    print("• 11 секунд - Юнит 2")
    print("• 19 секунд - Юнит 3")
    print("• 28 секунд - Юнит 4")
    print("• Длительность игры: 2:44 (164 реальных секунды)")
    print("• Ожидание после 4-го юнита: 136 секунд")
    print("")
    print("⚡ x3 Скорость:")
    print("• 2 секунды - Юнит 1")
    print("• 11 секунд - Юнит 2")
    print("• 19 секунд - Юнит 3")
    print("• 21 секунда - Юнит 4")
    print("• Длительность игры: 1:55 (115 реальных секунд)")
    print("• Ожидание после 4-го юнита: 94 секунды")
    print("")
    print("🔄 Управление:")
    print("• 🚀 ЗАПУСТИТЬ x2 - автоигра на x2 скорости")
    print("• ⚡ ЗАПУСТИТЬ x3 - автоигра на x3 скорости")
    print("• 🔄 ВКЛ/ВЫКЛ АНТИ-АФК - переключение защиты")
    print("• 🛑 ПОЛНАЯ ОСТАНОВКА - полный сброс скрипта")
    print("")
    print("⚠️ Анти-АФК автоматически включен!")
    print("📅 Логи активности в консоли каждую минуту")
    print("")
    print("После остановки нужно перезапустить скрипт!")
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
            
            -- Сбрасываем флаги
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
