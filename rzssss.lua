-- The key of engine lock
local Eng_K = "sa"

-- Get voltage
local tx_O = "tx-voltage"
local Rx_Bt = "RxBt"

-- Model battery parameters
local RxBatt_Cells = 4
local RxV_Offset = 3.5
local RxV_Max = 4.16
local RxV_Alarm = 3.7

-- Get RSSI
local rssi, alarm_low, alarm_crit

-- Get RxBt value
local RxV_id
local Rx_V

-- Get SA value
local Eng_id
local Eng_L

-- Get Tx-voltage value
local tx_id
local tx_V

local RunClock = 0
local BackgroundClock = 0

-- RxBt icon
local function drawBattery(x, y, w, h, a, b)
    local SignalBars = math.floor((24 * a / b)+0.1) 
    lcd.drawFilledRectangle( x, y, w - 2, h ) 
    lcd.drawFilledRectangle(x + w - 1 , y + 6, 1, 6) 
    while SignalBars > 0 do
        lcd.drawFilledRectangle( x+1+(SignalBars -1)*3, y + 1, 2, 16)
        SignalBars = SignalBars - 1
    end 
end

-- Tx-voltage icon
local function drawRxV(x, y, w)
    tx_id = getFieldInfo(tx_O).id 
    tx_V = getValue(tx_id)
    local percent = math.min(math.max(math.ceil((tx_V - 7) * 100 / (8.2 - 7)), 0), 100)
    local filling = math.ceil(percent / 100 * (w - 1) + 0.2)

    -- Battery outline
    lcd.drawRectangle(x-1, y, w + 2, 10)

    -- Fill the battery
    lcd.drawFilledRectangle(x, y + 1, filling, 8)
    lcd.drawFilledRectangle(x+26, y + 3, 1, 4)
end

local function init()
    RxV_Alarm = (RxV_Alarm-RxV_Offset)*RxBatt_Cells*100
    RxV_Max = RxV_Max*RxBatt_Cells*100
    RxV_Offset = RxV_Offset*RxBatt_Cells*100
    RxV_Range = RxV_Max-RxV_Offset
    RxV_id = getFieldInfo(Rx_Bt).id 
    Rx_V = getValue(RxV_id)
    Eng_id = getFieldInfo(Eng_K).id 
    Eng_L = getValue(Eng_id)
    rssi, alarm_low, alarm_crit = getRSSI()
end

local function background()
    if (BackgroundClock % 8 == 0) then
        Rx_V = getValue(RxV_id)
        rssi, alarm_low, alarm_crit = getRSSI()
        Eng_L = getValue(Eng_id)
        BackgroundClock = 0
    end
    BackgroundClock = BackgroundClock + 1
end


local function run(event)
    if (RunClock % 2 == 0) then
        local SignalBars = -1
        local RxV_Scaled
        if (Rx_V*100 < RxV_Offset ) then
            RxV_Scaled = 0
        elseif (Rx_V*100 > RxV_Max) then
            RxV_Scaled = RxV_Range
        else
            RxV_Scaled = Rx_V*100 - RxV_Offset
        end

        -- Display code
        lcd.clear()

        if (Eng_L > 0) then
            lcd.drawText( 32, 47, "LOCK", DBLSIZE)
        end

        -- Draw model name
        lcd.drawText( 1, 0, model.getInfo()['name'], MIDSIZE)
        lcd.drawFilledRectangle(0, 12, 75, 20)
        lcd.drawText( 3, 47, "4S", DBLSIZE)

        -- Draw Tx-voltage icon
        drawRxV(101, 1, 25)

        -- Draw RxBt icon
        drawBattery( 1, 13, 75, 18, RxV_Scaled, RxV_Range)


        -- Draw RxBt value
        if (RxV_Scaled > RxV_Alarm) then
            lcd.drawText( 1, 33, "RxBt", MIDSIZE)
            lcd.drawText( 73, 33, "V", MIDSIZE + RIGHT)
            lcd.drawNumber( lcd.getLastLeftPos()-1, 33, Rx_V*10, MIDSIZE + PREC1 + RIGHT)
        else
            lcd.drawText( 1, 33, "RxBt", MIDSIZE + BLINK)
            lcd.drawText( 73, 33, "V", MIDSIZE + RIGHT + BLINK)
            lcd.drawNumber( lcd.getLastLeftPos()-1, 33, Rx_V*10, MIDSIZE + PREC1 + RIGHT + BLINK)
        end

        -- Draw timer1
        lcd.drawTimer( 85, 47, model.getTimer(0).value, DBLSIZE)

        -- Draw time
        lcd.drawText( 64, 0, string.format("%02d", getDateTime()['hour']), MIDSIZE)
        lcd.drawText( lcd.getLastPos(), 0, ":", MIDSIZE + BLINK)
        lcd.drawText( lcd.getLastPos(), 0, string.format("%02d", getDateTime()['min']), MIDSIZE)

        -- Draw RSSI
        if rssi > alarm_crit then
            lcd.drawText( 76, 33, "RSSI", MIDSIZE)
            lcd.drawText(lcd.getLastPos(), 33, ":", MIDSIZE)
            lcd.drawNumber(lcd.getLastPos(), 33, rssi, MIDSIZE)
        else
            lcd.drawText( 76, 33, "RSSI", MIDSIZE + BLINK)
            lcd.drawText(lcd.getLastPos(), 33, ":", MIDSIZE + BLINK)
            lcd.drawNumber(lcd.getLastPos(), 33, rssi, MIDSIZE + BLINK)
        end
        if rssi > 90 then
            SignalBars = 10
        elseif rssi > 85 then
            SignalBars = 9
        elseif rssi > 80 then
            SignalBars = 8
        elseif rssi > 75 then
            SignalBars = 7
        elseif rssi > 70 then
            SignalBars = 6
        elseif rssi > 65 then
            SignalBars = 5
        elseif rssi > 60 then
            SignalBars = 4
        elseif rssi > 55 then
            SignalBars = 3
        elseif rssi > 50 then
            SignalBars = 2
        elseif rssi > 45 then
            SignalBars = 1
        elseif rssi > alarm_low then
            SignalBars = 0
        end
        while SignalBars > -1 do
            lcd.drawFilledRectangle( 79+(SignalBars)*4, 12+(10-SignalBars)*2, 3, 20-(10-SignalBars)*2)
            SignalBars = SignalBars - 1
        end
        RunClock = 0
    end
    RunClock = RunClock + 1
end
return { run = run, background = background, init = init }