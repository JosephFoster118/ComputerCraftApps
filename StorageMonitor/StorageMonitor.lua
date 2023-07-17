
--Globals
monitor = peripheral.wrap("monitor_0")
rs = peripheral.wrap("rsBridge_0")
battery = peripheral.wrap("basicEnergyCube_0")

--Configure monitor
monitor.setPaletteColor(colors.white, 0xFFFFFF)


--Storage table
storage_data = {
    items = {
        max = 0,
        current = 0
    },
    fluids = {
        max = 0,
        current = 0
    },
    rs_energy = {
        max = 0,
        current = 0
    },
    battery = {
        max = 0,
        current = 0
    }
}

--StorageBar class
StorageBar = {}
StorageBar.__index = StorageBar

function StorageBar:new(label ,y)
    local res = {}
    setmetatable(res,StorageBar)
    res.label = label
    res.y = y
    res.max = 0
    res.current = 0
    return res
end

function StorageBar:draw()
    m_x, m_y = monitor.getSize()
    ratio = self.current/self.max
    --label
    monitor.setCursorPos(1, self.y)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)
    monitor.write(self.label)
    --ammount
    monitor.setCursorPos(1, self.y + 1)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)
    local percent = math.floor(ratio*10000+0.5)/100
    monitor.write(string.format("%d/%d: %01.2f%%", self.current, self.max, percent))
    --bar
    if self.max > 0 and self.current >= 0 then
        if self.max >= self.current then
            draw_amount = math.floor(ratio*m_x)
            for i = 1, m_x do
                if i <= draw_amount then
                    monitor.setBackgroundColor(colors.blue)
                else
                    monitor.setBackgroundColor(colors.yellow)
                end
                monitor.setCursorPos(i, self.y + 2)
                monitor.write(" ")
            end
        else
            monitor.setBackgroundColor(colors.blue)
            for i = 1, m_x do
                
                monitor.setCursorPos(i, self.y + 2)
                monitor.write(" ")
            end
        end
    else
        monitor.setBackgroundColor(colors.yellow)
        for i = 1, m_x do
            
            monitor.setCursorPos(i, self.y + 2)
            monitor.write(" ")
        end
    end
end

--Tasks
function storageUsageTask()
    while true do
        storage_data.items.max = rs.getMaxItemDiskStorage()
        local current_cnt = 0
        local current_items = rs.listItems()
        for k,v in pairs(current_items) do
            current_cnt = current_cnt + v.amount
        end
        storage_data.items.current = current_cnt
        sleep(5) --Kinda heavy of a task, only perform every 5 seconds
    end
end

function energyUsageTask()
    while true do
        storage_data.battery.current = battery.getEnergy()
        storage_data.battery.max = battery.getMaxEnergy()
        storage_data.rs_energy.current = rs.getEnergyStorage()
        storage_data.rs_energy.max = rs.getMaxEnergyStorage()
        sleep(0.1)
    end
end

function displayTask()
    
    item_storage_bar = StorageBar:new("Items",1)
    battery_storage_bar = StorageBar:new("Battery",4)
    rs_energy_bar = StorageBar:new("RS Energy",7)
    while true do
        monitor.setTextColor(colors.white)
        monitor.setBackgroundColor(colors.black)
        monitor.clear()

        item_storage_bar.current = storage_data.items.current
        item_storage_bar.max = storage_data.items.max
        item_storage_bar:draw()

        battery_storage_bar.current = storage_data.battery.current
        battery_storage_bar.max = storage_data.battery.max
        battery_storage_bar:draw()

        rs_energy_bar.current = storage_data.rs_energy.current
        rs_energy_bar.max = storage_data.rs_energy.max
        rs_energy_bar:draw()

        --TODO: add fluid storage bar

        sleep(0.1)
    end
end

--Start all tasks
parallel.waitForAll(storageUsageTask, displayTask, energyUsageTask)
