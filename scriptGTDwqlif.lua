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
AutoFarm.currentMacro = 1 -- 1 = первый макрос, 2 = второй макрос
AutoFarm.antiAfkActive = false -- Флаг для анти-афк

-- ========== АНТИ-AFK СИСТЕМА ==========
local function setupAntiAfk()
    -- Проверяем, не запущена ли уже анти-афк
    if AutoFarm.antiAfkActive then
        print("[АНТИ-AFK] Уже запущена")
        return
    end
    
    -- Создаем GUI для анти-афк
    local Rice = Instance.new("ScreenGui")
    Rice.Name = "Rice"
    Rice.Parent = game.CoreGui
    Rice.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Rice.Enabled = false -- По умолчанию скрываем, но анти-афк будет работать
    
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = Rice
    Main.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.321207851, 0, 0.409807354, 0)
    Main.Size = UDim2.new(0, 295, 0, 116)
    Main.Visible = false
    Main.Active = true
    Main.Draggable = true

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Main
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Title.BorderSizePixel = 0
    Title.Size = UDim2.new(0, 295, 0, 16)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "Rice Anti-Afk"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true
    Title.TextWrapped = true

    local Credits = Instance.new("TextLabel")
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
    Credits.TextWrapped = true

    local Activate = Instance.new("TextButton")
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

    local UICorner = Instance.new("UICorner")
    UICorner.Parent = Activate

    local OpenClose = Instance.new("TextButton")
    OpenClose.Name = "OpenClose"
    OpenClose.Parent = Rice
    OpenClose.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    OpenClose.Position = UDim2.new(0.353924811, 0, 0.921739101, 0)
    OpenClose.Size = UDim2.new(0, 247, 0, 35)
    OpenClose.Font = Enum.Font.GothamBold
    OpenClose.Text = "Open/Close"
    OpenClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpenClose.TextSize = 14.000

    local UICorner_2 = Instance.new("UICorner")
    UICorner_2.Parent = OpenClose

    -- Логика открытия/закрытия
    local function toggleFrame()
        Main.Visible = not Main.Visible
    end
    
    OpenClose.MouseButton1Click:Connect(toggleFrame)
    
    -- АКТИВАЦИЯ АНТИ-AFK (автоматическая при создании кнопки)
    local vu = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        print("[АНТИ-AFK] Сброс AFK таймера")
    end)
    
    -- Кнопка Activate (на случай если пользователь захочет переактивировать)
    Activate.MouseButton1Down:connect(function()
        print("[АНТИ-AFK] Повторная активация защиты")
    end)
    
    -- Сохраняем ссылки на GUI для возможного удаления
    AutoFarm.antiAfkGui = Rice
    AutoFarm.antiAfkActive = true
    
    print("[АНТИ-AFK] Система защиты от AFK активирована")
    print("[АНТИ-AFK] Кнопка Open/Close в правом нижнем углу")
end

-- ========== КОНЕЦ АНТИ-AFK ==========

-- Первый макрос - 4 юнита (старые позиции)
local macro1Data = {
    {
        CF = "109.055374, 1.24449992, -94.5933304, 0.924202919, 0, -0.381901979, -0, 1.00000012, -0, 0.381902039, 0, 0.9242028",
        PathIndex = 1,
        Time = 2,
        Unit = "unit_rafflesia"
    },
    {
        CF = "106.745476, 1.24417794, 87.8872986, -0.830875754, -0.00013255376, -0.556458056, 7.27595761e-12, 1, -0.000238209774, 0.556458116, -0.000197922724, -0.830875695",
        PathIndex = 2,
        Time = 14,
        Unit = "unit_rafflesia"
    },
    {
        CF = "-64.3955765, 1.2441957, 89.0993805, -0.556458056, 9.89613545e-05, 0.830875695, -0, 1, -0.000119104887, -0.830875695, -6.62768725e-05, -0.556458056",
        PathIndex = 3,
        Time = 22,
        Unit = "unit_rafflesia"
    },
    {
        CF = "-74.0376816, 1.24399996, -52.8071785, 0.707106829, 0, 0.707106769, -0, 1, -0, -0.707106829, 0, 0.707106769",
        PathIndex = 4,
        Time = 30,
        Unit = "unit_rafflesia"
    }
}

-- Второй макрос - 4 юнита (новые позиции, измененные тайминги)
local macro2Data = {
    {
        CF = "108.549294, 1.24438035, -92.9884949, 0.981734097, -4.52478889e-05, -0.190258533, -3.63797881e-12, 1.00000012, -0.000237823173, 0.190258548, 0.000233479121, 0.981734037",
        PathIndex = 1,
        Time = 2,
        Unit = "unit_rafflesia"
    },
    {
        CF = "110.745071, 1.24402761, 98.0248947, -0.980287313, 2.34596082e-05, -0.197577298, -0, 1, 0.000118736352, 0.197577298, 0.000116395742, -0.980287313",
        PathIndex = 2,
        Time = 14,
        Unit = "unit_rafflesia"
    },
    {
        CF = "-93.1069794, 1.24399996, 89.5488358, -0, 0, 1, 0, 1, -0, -1, 0, -0",
        PathIndex = 3,
        Time = 20, -- ИЗМЕНЕНО: с 33 на 23 секунды
        Unit = "unit_rafflesia"
    },
    {
        CF = "-79.5390015, 1.24449992, -60.4018097, 0.922063351, 0, 0.387038946, -0, 1, -0, -0.387038946, 0, 0.922063351",
        PathIndex = 4,
        Time = 25, -- ИЗМЕНЕНО: с 45 на 29 секунд
        Unit = "unit_rafflesia"
    }
}

-- Авто-скип (включается автоматически)
task.delay(2, function()
    pcall(function()
        remotes.ToggleAutoSkip:InvokeServer(true)
        print("[Система] Авто-скип включен")
    end)
end)

-- Функция полной остановки и сброса (ДОБАВЛЕНО УДАЛЕНИЕ АНТИ-AFK)
function AutoFarm:StopEverything()
    print("[СИСТЕМА] Начинаем полную остановку...")
    
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
    
    -- Удаляем интерфейс автофермы
    print("[СИСТЕМА] Удаляем интерфейс...")
    local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local oldGui = playerGui:FindFirstChild("AutoFarmGUI")
        if oldGui then
            oldGui:Destroy()
        end
    end
    
    -- Удаляем анти-афк интерфейс
    print("[СИСТЕМА] Удаляем анти-афк интерфейс...")
    if self.antiAfkGui and self.antiAfkGui.Parent then
        self.antiAfkGui:Destroy()
        self.antiAfkGui = nil
        self.antiAfkActive = false
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
    
    local difficulty = "dif_apocalypse"
    local baseDelay = 5
    
    while AutoFarm.running do
        -- Определяем текущий макрос
        local currentData
        local macroNum
        local lastUnitTime
        
        if AutoFarm.currentMacro == 1 then
            currentData = macro1Data
            macroNum = 1
            lastUnitTime = 30 -- последний юнит на 30 секунде
        else
            currentData = macro2Data
            macroNum = 2
            lastUnitTime = 29 -- последний юнит на 29 секунде (исправлено)
        end
        
        -- Расчет длительности в реальных секундах
        local gameDuration
        if speed == 2 then
            gameDuration = 155 -- 2:35 реальных секунд
        else
            gameDuration = 105 -- 1:50 реальных секунд
        end
        
        -- Время последнего юнита в реальных секундах
        local lastUnitRealTime = lastUnitTime / speed
        
        -- Сколько ждать после последнего юнита
        local waitAfterLastUnit = gameDuration - lastUnitRealTime
        
        print("")
        print("==========================================")
        print("[ЦИКЛ] Начало нового цикла (x" .. speed .. ")")
        print("[ЦИКЛ] Используется: МАКРОС " .. macroNum)
        print("[ЦИКЛ] Юнитов: " .. #currentData)
        print("[ЦИКЛ] Тайминги: " .. currentData[1].Time .. "с, " .. currentData[2].Time .. "с, " .. currentData[3].Time .. "с, " .. currentData[4].Time .. "с")
        print("[ЦИКЛ] Последний юнит на: " .. lastUnitTime .. " игровой секунде (" .. string.format("%.1f", lastUnitRealTime) .. " реальных сек)")
        print("[ЦИКЛ] Ожидание после последнего юнита: " .. string.format("%.1f", waitAfterLastUnit) .. " реальных секунд")
        print("[ЦИКЛ] Общая длительность: " .. gameDuration .. " сек (" .. math.floor(gameDuration/60) .. ":" .. string.format("%02d", gameDuration%60) .. ")")
        print("==========================================")
        print("")
        
        -- Устанавливаем скорость
        remotes.ChangeTickSpeed:InvokeServer(speed)
        
        -- Голосуем за сложность
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        print("[СИСТЕМА] Выбрана сложность: Apocalypse")
        
        -- Базовая задержка перед стартом
        print("[СИСТЕМА] Базовая задержка " .. baseDelay .. " секунд...")
        for i = 1, baseDelay do
            if not AutoFarm.running then return end
            task.wait(1)
        end
        
        -- Размещаем юниты
        print("[РАЗМЕЩЕНИЕ] Начинаем размещение юнитов (Макрос " .. macroNum .. ")")
        
        for i, unitData in ipairs(currentData) do
            -- Время размещения с учетом базовой задержки
            local placeTime = unitData.Time - baseDelay
            
            if placeTime > 0 then
                scheduleTask(placeTime, function()
                    if AutoFarm.running then
                        print("[МАКРОС " .. macroNum .. "] Юнит " .. i .. " на " .. unitData.Time .. " сек")
                        placeUnit(unitData.CF, unitData.Unit, unitData.PathIndex)
                    end
                end, "macro" .. macroNum .. "_unit" .. i)
            elseif placeTime <= 0 then
                if AutoFarm.running then
                    print("[МАКРОС " .. macroNum .. "] Юнит " .. i .. " СРАЗУ (тайминг " .. unitData.Time .. " сек)")
                    placeUnit(unitData.CF, unitData.Unit, unitData.PathIndex)
                end
            end
        end
        
        -- Ждем завершения игры (реальные секунды)
        if waitAfterLastUnit > 0 then
            print("[ОЖИДАНИЕ] До конца игры: " .. string.format("%.1f", waitAfterLastUnit) .. " реальных секунд")
            local waitSeconds = math.floor(waitAfterLastUnit + 0.5)
            
            for i = 1, waitSeconds do
                if not AutoFarm.running then return end
                if i % 10 == 0 then
                    print("[ОЖИДАНИЕ] Осталось ~" .. (waitSeconds - i) .. " сек")
                end
                task.wait(1)
            end
        end
        
        if not AutoFarm.running then break end
        
        -- Рестарт игры
        print("[РЕСТАРТ] Перезапускаем игру...")
        remotes.RestartGame:InvokeServer()
        
        -- Меняем макрос для следующей игры
        if AutoFarm.currentMacro == 1 then
            AutoFarm.currentMacro = 2
        else
            AutoFarm.currentMacro = 1
        end
        
        print("[СЛЕДУЮЩАЯ ИГРА] Будет использован МАКРОС " .. AutoFarm.currentMacro)
        
        -- Пауза перед следующим раундом
        for i = 1, 3 do
            if not AutoFarm.running then return end
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
    title.Text = "🌿 АВТОФЕРМА (2 макроса)"
    title.TextColor3 = Color3.fromRGB(0, 255, 170)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = mainFrame
    
    -- Статус фермы
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 40)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ферма: Остановлено | Текущий: Макрос 1"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.Parent = mainFrame
    
    -- Информация о макросах
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 100)
    infoLabel.Position = UDim2.new(0, 0, 0, 65)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "МАКРОС 1: 2,16,22,30 сек\nМАКРОС 2: 2,16,23,29 сек\n\nx2: оба 2:35 (155 сек)\nx3: оба 1:50 (110 сек)\nМакросы чередуются каждый раунд"
    infoLabel.TextColor3 = Color3.fromRGB(170, 170, 255)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 11
    infoLabel.TextWrapped = true
    infoLabel.Parent = mainFrame
    
    -- Кнопка запуска x2
    local btnStart2x = Instance.new("TextButton")
    btnStart2x.Size = UDim2.new(0.9, 0, 0, 30)
    btnStart2x.Position = UDim2.new(0.05, 0, 0.68, 0)
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
    btnStart3x.Position = UDim2.new(0.05, 0, 0.76, 0)
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
    btnStop.Position = UDim2.new(0.05, 0, 0.86, 0)
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
    local function updateStatus(isRunning, speed)
        if isRunning then
            statusLabel.Text = "Ферма: Работает (x" .. speed .. ") | Текущий: Макрос " .. AutoFarm.currentMacro
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            btnStart2x.Visible = false
            btnStart3x.Visible = false
            btnStop.Visible = true
            if speed == 2 then
                infoLabel.Text = "МАКРОС 1: 2,16,22,30 сек\nМАКРОС 2: 2,16,23,29 сек\nДлительность: 2:35\nЧередуются каждый раунд"
            else
                infoLabel.Text = "МАКРОС 1: 2,16,22,30 сек\nМАКРОС 2: 2,16,23,29 сек\nДлительность: 1:50\nЧередуются каждый раунд"
            end
        else
            statusLabel.Text = "Ферма: Остановлено | Текущий: Макрос " .. AutoFarm.currentMacro
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            btnStart2x.Visible = true
            btnStart3x.Visible = true
            btnStop.Visible = false
            infoLabel.Text = "МАКРОС 1: 2,16,22,30 сек\nМАКРОС 2: 2,16,23,29 сек\n\nx2: оба 2:35 (155 сек)\nx3: оба 1:50 (110 сек)\nМакросы чередуются каждый раунд"
        end
    end
    
    -- Функция запуска автоигры
    local function startGame(speed)
        if AutoFarm.running then
            warn("[СИСТЕМА] Автоигра уже запущена!")
            return
        end
        
        AutoFarm.running = true
        updateStatus(true, speed)
        
        AutoFarm.thread = task.spawn(function()
            local success, error = pcall(function()
                startAutoGame(speed)
            end)
            
            if not success then
                warn("❌ Ошибка автоигры:", error)
            end
            
            AutoFarm.running = false
            updateStatus(false)
            print("[СИСТЕМА] Автоигра завершена")
        end)
    end
    
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
    
    btnStart2x.Parent = mainFrame
    btnStart3x.Parent = mainFrame
    btnStop.Parent = mainFrame
    mainFrame.Parent = screenGui
    
    return screenGui
end

-- Основная функция (ДОБАВЛЕН ЗАПУСК АНТИ-AFK)
local function main()
    if _G.AutoFarmLoaded then
        warn("⚠️ Скрипт уже запущен! Используйте StopAutoFarm() для остановки")
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
    AutoFarm.antiAfkActive = false
    
    function AutoFarm:StopEverything()
        print("[СИСТЕМА] Начинаем полную остановку...")
        
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
        
        -- Удаляем анти-афк GUI
        if self.antiAfkGui and self.antiAfkGui.Parent then
            self.antiAfkGui:Destroy()
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
    
    -- АВТОМАТИЧЕСКИЙ ЗАПУСК АНТИ-AFK
    task.spawn(function()
        setupAntiAfk()
    end)
    
    _G.AutoFarmLoaded = true
    
    print("✅ Автоферма загружена!")
    print("==========================================")
    print("🌿 GARDEN TOWER DEFENSE - АВТОФЕРМА 2 МАКРОСА + АНТИ-AFK")
    print("==========================================")
    print("🎮 МАКРОС 1 (старые позиции):")
    print("• 2 секунды - Юнит 1")
    print("• 16 секунд - Юнит 2")
    print("• 22 секунды - Юнит 3")
    print("• 30 секунд - Юнит 4")
    print("")
    print("🎮 МАКРОС 2 (новые позиции):")
    print("• 2 секунды - Юнит 1")
    print("• 16 секунд - Юнит 2")
    print("• 23 секунды - Юнит 3 (ИЗМЕНЕНО)")
    print("• 29 секунд - Юнит 4 (ИЗМЕНЕНО)")
    print("")
    print("⚡ ОБЩИЕ НАСТРОЙКИ:")
    print("• x2 скорость: 2:35 (155 реальных секунд)")
    print("• x3 скорость: 1:50 (110 реальных секунд)")
    print("• Макросы чередуются каждый раунд")
    print("• Начинается с Макроса 1")
    print("")
    print("🛡️ АНТИ-AFK:")
    print("• Запускается автоматически")
    print("• Кнопка Open/Close в правом нижнем углу")
    print("• Защищает от выкидывания за бездействие")
    print("")
    print("🔄 Управление:")
    print("• 🚀 ЗАПУСТИТЬ x2 - автоигра на x2 скорости")
    print("• ⚡ ЗАПУСТИТЬ x3 - автоигра на x3 скорости")
    print("• 🛑 ПОЛНАЯ ОСТАНОВКА - полный сброс скрипта")
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
