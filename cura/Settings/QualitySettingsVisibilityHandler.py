# Copyright (c) 2017 Ultimaker B.V.
# Uranium is released under the terms of the AGPLv3 or higher.

import UM.Settings.Models.SettingVisibilityHandler

class QualitySettingsVisibilityHandler(UM.Settings.Models.SettingVisibilityHandler.SettingVisibilityHandler):
    def __init__(self, parent = None, *args, **kwargs):
        super().__init__(parent = parent, *args, **kwargs)

        quality_settings = {
            "layer_height",
            "layer_height_0",
            "line_width",
            "wall_line_width",
            "wall_line_width_0",
            "wall_line_width_x",
            "skin_line_width",
            "infill_line_width",
            "skirt_brim_line_width",
            "support_line_width",
            "support_interface_line_width",
            "prime_tower_line_width",
        }
        self.setVisible(quality_settings)
