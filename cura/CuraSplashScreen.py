# Copyright (c) 2015 Ultimaker B.V.
# Uranium is released under the terms of the AGPLv3 or higher.

from PyQt5.QtCore import Qt, QCoreApplication
from PyQt5.QtGui import QPixmap, QColor, QFont, QFontMetrics
from PyQt5.QtWidgets import QSplashScreen

from UM.Resources import Resources
from UM.Application import Application

class CuraSplashScreen(QSplashScreen):
    def __init__(self):
        super().__init__()
        self._scale = round(QFontMetrics(QCoreApplication.instance().font()).ascent() / 12)

        splash_image = QPixmap(Resources.getPath(Resources.Images, "intam.png"))
        self.setPixmap(splash_image.scaled(splash_image.size() * self._scale))


