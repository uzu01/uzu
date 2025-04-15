getgenv().config = {}

local players = game:GetService("Players")
local http_service = game:GetService("HttpService")
local replicated_storage = game:GetService("ReplicatedStorage")

local player = players.LocalPlayer
local data_remote_event = replicated_storage.BridgeNet2.dataRemoteEvent

local ctrl_char = {"\a", "\b", "\f", "\n", "\r", "\t", "\v", "\z", "\0", "\1", "\2", "\3", "\4", "\5", "\6", "\7", "\8", "\9"}

local folder = "Uzu"
local name = ("%*- %* Arise Dungeon.lua"):format(player.UserId, game.GameId)
local path = ("%*/%*"):format(folder, name)

repeat task.wait() until player:GetAttribute("Loaded") and workspace.__Extra:FindFirstChild("__Spawns")

function save()
    if not isfolder(folder) then makefolder(folder) end
    writefile(path, http_service:JSONEncode(config))
end

function load()
    if not isfile(path) then return end
    getgenv().config = http_service:JSONDecode(readfile(path))
end

function teleport(position)
    local character = player.Character
    if not character then return end

    character:SetAttribute("InTp", true)
    character:PivotTo(position)
end

function get_distance(position)
    return player.Character and player:DistanceFromCharacter(position) or math.huge
end

function float()
    local character = player.Character
    local root_part = character and character:FindFirstChild("HumanoidRootPart")
    if not root_part then return end
    root_part.Velocity = Vector3.zero
end

function get_nearest_mob()
    local dist = math.huge
    local target = nil

    for i, v in workspace.__Main.__Enemies.Server:GetDescendants() do
        local mag = v:IsA("Part") and not v:GetAttribute("Dead") and get_distance(v:GetPivot().p)

        if mag and mag < dist then
            dist = mag
            target = v
        end
    end
    return target
end

function replay_dungeon()
    local ticket_amount = player.leaderstats.Inventory.Items.Ticket:GetAttribute("Amount")
    getgenv().old_ticket = old_ticket or ticket_amount

    if old_ticket ~= ticket_amount or not replicated_storage:GetAttribute("Dungeon") then
        for i, v in ctrl_char do
            data_remote_event:FireServer({{Type = "Gems", Event = "DungeonAction", Action = "BuyTicket"}, v})
            data_remote_event:FireServer({{Event = "DungeonAction", Action = "Create"}, v})
            data_remote_event:FireServer({{Dungeon = player.UserId, Event = "DungeonAction", Action = "Start"}, v})
        end
        task.wait(60)
    end
end

function auto_dungeon()
    while task.wait() and config.auto_dungeon do
        replay_dungeon()

        local mob = get_nearest_mob()
        if not mob then continue end

        float()
        
        if get_distance(mob:GetPivot().p) > 10 then
            teleport(mob:GetPivot() * CFrame.new(0, 2, 0.1))
            task.wait(0.5)
        end

        data_remote_event:FireServer({{Event = "PunchAttack", Enemy = mob.Name}, "\4"})
    end
end

task.wait(.1)
load()

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/uzu01/public/main/ui/uwuware"))()
local window = library:CreateWindow("Arise Crossover | Uzu")

local main_folder = window:AddFolder("Main")
local misc_folder = window:AddFolder("Misc")

main_folder:AddToggle({text = "Auto Dungeon", state = config.auto_dungeon, callback = function(v)
    config.auto_dungeon = v
    save()

    task.spawn(auto_dungeon)
end})

misc_folder:AddToggle({text = "Auto Execute", state = config.auto_execute, callback = function(v)
    config.auto_execute = v
    save()

    if not v then return end
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/uzu01/uzu/refs/heads/main/arise.lua"))()')
end})

misc_folder:AddBind({text = "Toggle GUI", key = "LeftControl", callback = function() 
    library:Close()
end})

library:Init()
