import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header
from UM.Preferences import Preferences
from PyQt5.QtCore import QObject, pyqtSlot, pyqtProperty
from PyQt5.QtQml import qmlRegisterType
import sys
from PyQt5.QtWidgets import QApplication, QWidget, QPushButton, QMessageBox
from PyQt5.QtGui import QIcon
from PyQt5.QtCore import pyqtSlot


class App(QWidget):
    def __init__(self):
        super().__init__()
        self.title = 'PyQt5 messagebox - pythonspot.com'
        self.left = 700
        self.top = 400
        self.width = 320
        self.height = 200


    def initUI(self):
        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        buttonReply = QMessageBox.information(self, 'Notice', "Send Success"+"\n"+"Our representative will contact you as soon as possible",QMessageBox.Yes )

    def initFlae(self):
        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        buttonReply = QMessageBox.information(self, 'Notice', "Send Error"+"\n"+"You need fill email adress or phone number",QMessageBox.Yes )

    def initFlae2(self):
        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        buttonReply = QMessageBox.information(self, 'Notice', "Send Error"+"\n"+"You need to check your email adress ",QMessageBox.Yes )

class ContactUs(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.result = True
        # Initialise the value of the properties.
        self._context = ""

    def setContext(self, context):
        if context != self._context:
            self._context = context

    @pyqtSlot(result=bool)
    def getResult(self):
        return self.result

    @pyqtSlot(str,result = int)
    def send_email(self,key):
        # 第三方 SMTP 服务
        mail_host = "smtp.qiye.163.com"  # 设置服务器
        mail_user = "contactus@intamsys.com"  # 用户名
        mail_pass = "Honsmaker314"  # 口令

        sender = 'contactus@intamsys.com'
        receivers = 'support@intamsys.com'  # 接收邮件，可设置为你的QQ邮箱或者其他邮箱
        message = MIMEMultipart()
        message['From'] = sender
        message['To'] = receivers
        subject = 'from IntamSuite Customer'
        message['Subject'] = Header(subject, 'utf-8')
        a = key.split()
        all_files = a[len(a) - 1]
        all_files = all_files.split(",")
        # 邮件正文内容
        #message.attach(MIMEText(Preferences.getInstance().getValue("general/language")))
        message.attach(MIMEText(key,'plain', 'utf-8'))
        # 构造附件1，传送当前目录下的 test.txt 文件
        for file in all_files:
            if len(file) != 0:
                file = file[8:]
                b = file.split("/")
                filename = b[len(b) - 1]
                att = MIMEText(open(file, 'rb').read(), 'base64', 'utf-8')
                att["Content-Type"] = 'application/octet-stream'
                # 这里的filename可以任意写，写什么名字，邮件中显示什么名字
                att["Content-Disposition"] = 'attachment; filename= '+filename
                message.attach(att)
        if (key.find("@") != -1 or key.find("PhoneNumber:" + "\n") == -1):
            try:
                smtpObj = smtplib.SMTP()
                smtpObj.connect(mail_host, 25)  # 25 为 SMTP 端口号
                smtpObj.login(mail_user, mail_pass)
                smtpObj.sendmail(sender, receivers, message.as_string())
                print("邮件发送成功")
                # app = QApplication(sys.argv)

                ex = App().initUI()
                self.result = True
                # sys.exit(app.exec_())
            except smtplib.SMTPException:
                print("Error: 无法发送邮件")
                ex = App().initFlae()
                self.result = False
        else:
            print("Error: 无法发送邮件")
            if (key.find("Email:" + "\n") == -1):
                ex = App().initFlae2()
                self.result = False
            else:
                ex = App().initFlae()
                self.result = False