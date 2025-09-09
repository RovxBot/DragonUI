local addon = _G.DragonUI_Addon

function addon._buildCastbarsPlayer()
    return { type='group', name='Player Castbar', order=1, args={
        enabled = { type='toggle', order=1, name='Enable Cast Bar',
            get=function() return addon.db.profile.castbar.enabled end,
            set=function(_,v) addon.db.profile.castbar.enabled=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end },
        x_position = { type='range', order=2, name='X Position', min=-500, max=500, step=1,
            get=function() return addon.db.profile.castbar.x_position end,
            set=function(_,v) addon.db.profile.castbar.x_position=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end },
        y_position = { type='range', order=3, name='Y Position', min=0, max=600, step=1,
            get=function() return addon.db.profile.castbar.y_position end,
            set=function(_,v) addon.db.profile.castbar.y_position=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end },
        sizeX = { type='range', order=4, name='Width', min=80, max=512, step=1,
            get=function() return addon.db.profile.castbar.sizeX end,
            set=function(_,v) addon.db.profile.castbar.sizeX=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end },
        sizeY = { type='range', order=5, name='Height', min=10, max=64, step=1,
            get=function() return addon.db.profile.castbar.sizeY end,
            set=function(_,v) addon.db.profile.castbar.sizeY=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end },
        scale = { type='range', order=6, name='Scale', min=0.5, max=2.0, step=0.1,
            get=function() return addon.db.profile.castbar.scale end,
            set=function(_,v) addon.db.profile.castbar.scale=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end },
        showIcon = { type='toggle', order=7, name='Show Icon',
            get=function() return addon.db.profile.castbar.showIcon end,
            set=function(_,v) addon.db.profile.castbar.showIcon=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end },
        sizeIcon = { type='range', order=8, name='Icon Size', min=1, max=64, step=1,
            get=function() return addon.db.profile.castbar.sizeIcon end,
            set=function(_,v) addon.db.profile.castbar.sizeIcon=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end,
            disabled=function() return not addon.db.profile.castbar.showIcon end },
        text_mode = { type='select', order=9, name='Text Mode', values={ simple='Simple (Centered Name Only)', detailed='Detailed (Name + Time)' },
            get=function() return addon.db.profile.castbar.text_mode or 'simple' end,
            set=function(_,v) addon.db.profile.castbar.text_mode=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end },
        precision_time = { type='range', order=10, name='Time Precision', min=0, max=3, step=1,
            get=function() return addon.db.profile.castbar.precision_time end,
            set=function(_,v) addon.db.profile.castbar.precision_time=v end,
            disabled=function() return addon.db.profile.castbar.text_mode=='simple' end },
        precision_max = { type='range', order=11, name='Max Time Precision', min=0, max=3, step=1,
            get=function() return addon.db.profile.castbar.precision_max end,
            set=function(_,v) addon.db.profile.castbar.precision_max=v end,
            disabled=function() return addon.db.profile.castbar.text_mode=='simple' end },
        holdTime = { type='range', order=12, name='Hold Time (Success)', min=0, max=2, step=0.1,
            get=function() return addon.db.profile.castbar.holdTime end,
            set=function(_,v) addon.db.profile.castbar.holdTime=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end },
        holdTimeInterrupt = { type='range', order=13, name='Hold Time (Interrupt)', min=0, max=2, step=0.1,
            get=function() return addon.db.profile.castbar.holdTimeInterrupt end,
            set=function(_,v) addon.db.profile.castbar.holdTimeInterrupt=v; if addon.RefreshCastbar then addon.RefreshCastbar() end end },
        reset_position = { type='execute', order=14, name='Reset Position', func=function()
            addon.db.profile.castbar.x_position = addon.defaults.profile.castbar.x_position
            addon.db.profile.castbar.y_position = addon.defaults.profile.castbar.y_position
            if addon.RefreshCastbar then addon.RefreshCastbar() end
        end },
    }}
end

