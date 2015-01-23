local wibox         = require("wibox")
local awful         = require("awful")
local beautiful     = require("beautiful")
local naughty       = require("naughty")

local indicator = {}
local function worker(args)
    local args = args or {}
    local widget = wibox.widget.imagebox()

    local interfaces    = args.interfaces or {"enp2s0"}
    local ICON_DIR      = awful.util.getdir("config").."/net_widgets/icons/"
    local timeout       = args.timeout or 5
    
    
    local connected = false
    local function text_grabber()
        local msg = ""
        if connected then
            for _, i in pairs(interfaces) do            
                f = io.popen("ifconfig "..i)
            
                line    = f:read()      -- wlp1s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500 
                line    = f:read()      -- inet 192.168.1.15  netmask 255.255.255.0  broadcast 192.168.1.255
                inet    = string.match(line, "inet (%d+%.%d+%.%d+%.%d+)") or "N/A"
                line    = f:read()      -- ether 50:b7:c3:08:37:b7  txqueuelen 1000  (Ethernet)
                mac     = string.match(line, "(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x)") or "N/A"

                f:close()
                msg =   "┌["..i.."]\n"..
                        "├IP:\t"..inet.."\n"..
                        "└MAC:\t"..mac
            end
        else
            msg = "Wired network is disconnected"
        end
    
        return msg
    end
    
    
    widget:set_image(ICON_DIR.."wired_na.png")
    local function net_update()
        connected = false
        for _, i in pairs(interfaces) do
            state = awful.util.pread("ip link show "..i.." | awk 'NR==1 {printf \"%s\", $9}'")    
            if (state == "UP") then
                connected = true
            end
            if connected then
                widget:set_image(ICON_DIR.."wired.png")
            else
                widget:set_image(ICON_DIR.."wired_na.png")
            end
        end
    end
    
    net_update()
    
    local net_timer = timer({ timeout = timeout })
    net_timer:connect_signal("timeout", net_update)
    net_timer:start()
    
    local notification = nil
    function widget:hide() 
        if notification ~= nil then
            naughty.destroy(notification)
            notification = nil
        end
    end

    function widget:show(t_out)
        widget:hide()
    
        notification = naughty.notify({
            preset = fs_notification_preset,
            text = text_grabber(),
            timeout = t_out,
        })
    end

    widget:connect_signal('mouse::enter', function () widget:show(0) end)
    widget:connect_signal('mouse::leave', function () widget:hide() end)
    return widget
end
return setmetatable(indicator, {__call = function(_,...) return worker(...) end})