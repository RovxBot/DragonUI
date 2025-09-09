local addon = _G.DragonUI_Addon

function addon._buildCastbarsTarget()
    return { type='group', name='Target Castbar', order=2, args={
        enabled = { type='toggle', order=1, name='Enable Target Castbar', desc='Enable or disable the target castbar',
            get=function()
                if not addon.db.profile.castbar.target then return true end
                local v = addon.db.profile.castbar.target.enabled
                return v == nil and true or v == true
            end,
            set=function(_,val) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.enabled=val; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        x_position = { type='range', order=2, name='X Position', desc='Horizontal position relative to anchor point', min=-500, max=500, step=1,
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.x_position) or -20 end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.x_position=v; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        y_position = { type='range', order=3, name='Y Position', desc='Vertical position relative to anchor point', min=-500, max=500, step=1,
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.y_position) or -20 end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.y_position=v; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        sizeX = { type='range', order=4, name='Width', desc='Width of the target castbar', min=50, max=400, step=1,
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.sizeX) or 150 end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.sizeX=v; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        sizeY = { type='range', order=5, name='Height', desc='Height of the target castbar', min=5, max=50, step=1,
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.sizeY) or 10 end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.sizeY=v; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        scale = { type='range', order=6, name='Scale', desc='Scale of the target castbar', min=0.5, max=2.0, step=0.1,
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.scale) or 1 end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.scale=v; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        showIcon = { type='toggle', order=7, name='Show Spell Icon', desc='Show the spell icon next to the target castbar',
            get=function()
                if not addon.db.profile.castbar.target then return true end
                local v = addon.db.profile.castbar.target.showIcon
                return v == nil and true or v == true
            end,
            set=function(_,val) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.showIcon=val; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        sizeIcon = { type='range', order=8, name='Icon Size', desc='Size of the spell icon', min=10, max=50, step=1,
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.sizeIcon) or 20 end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.sizeIcon=v; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end,
            disabled=function() return not (addon.db.profile.castbar.target and addon.db.profile.castbar.target.showIcon) end },
        text_mode = { type='select', order=9, name='Text Mode', desc='Choose how to display spell text', values={ simple='Simple (Centered Name Only)', detailed='Detailed (Name + Time)' },
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.text_mode) or 'simple' end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.text_mode=v; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        precision_time = { type='range', order=10, name='Time Precision', desc='Decimal places for remaining time', min=0, max=3, step=1,
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.precision_time) or 1 end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.precision_time=v end,
            disabled=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.text_mode)=='simple' end },
        precision_max = { type='range', order=11, name='Max Time Precision', desc='Decimal places for total time', min=0, max=3, step=1,
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.precision_max) or 1 end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.precision_max=v end,
            disabled=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.text_mode)=='simple' end },
        autoAdjust = { type='toggle', order=12, name='Auto Adjust for Auras', desc='Automatically adjust position based on target auras',
            get=function()
                if not addon.db.profile.castbar.target then return true end
                local v = addon.db.profile.castbar.target.autoAdjust
                return v == nil and true or v == true
            end,
            set=function(_,val) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.autoAdjust=val; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        holdTime = { type='range', order=13, name='Hold Time (Success)', desc='How long to show the castbar after successful completion', min=0, max=3, step=0.1,
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.holdTime) or 0.3 end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.holdTime=v; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        holdTimeInterrupt = { type='range', order=14, name='Hold Time (Interrupt)', desc='How long to show the castbar after interruption/failure', min=0, max=3, step=0.1,
            get=function() return (addon.db.profile.castbar.target and addon.db.profile.castbar.target.holdTimeInterrupt) or 0.8 end,
            set=function(_,v) addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.holdTimeInterrupt=v; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
        reset_position = { type='execute', order=15, name='Reset Position', desc='Reset target castbar position to default',
            func=function() addon.db.profile.castbar.target = addon.db.profile.castbar.target or {}; addon.db.profile.castbar.target.x_position=-20; addon.db.profile.castbar.target.y_position=-20; if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end end },
    }}
end

