### 项目概述
- 这是一个可以登录jabber账号，获取好友列表，并且能与好友进行聊天的项目。   
使用的是第三方库XMPPFramework框架来实现XMPP通讯。   
项目地址：[XMPP-Project](https://github.com/Johncahong/XMPP-Project)    
如果文章和项目对你有帮助，还请给个Star⭐️，你的Star⭐️是我持续输出的动力，谢谢啦😘
- 项目准备工作：搭建好Openfire服务器，安装客户端Spark，具体步骤请见：[iOS实现XMPP通讯（一）搭建Openfire](https://johncahong.github.io/2021/09/03/iOS-XMPP-communication-with-building-Openfire/)  
这样就可以登录本项目与登录Spark的另一用户进行XMPP通讯。
- 项目结构概述：
有三个视图控制器LoginViewController，ListViewController，ChatViewController。  
LoginViewController：登录和注册xmpp账号界面。  
ListViewController：获取花名册(好友列表)界面。  
ChatViewController：和好友进行单聊界面。  
为此封装了XmppManager类，方便统一管理与服务器的连接、好友列表回调、聊天消息回调等代理方法。
- 注意：**由于XMPPFramework框架还依赖其他第三方库**，如KissXML、CocoaAsyncSocket等，因此用cocoaPods添加XMPPFramework库时，`podfile必须添加use_frameworks!`，如下：
```c
platform:ios , '8.0'
target 'XMPP' do
    use_frameworks!
    pod 'XMPPFramework', '~> 4.0.0'
end
```
- 注册登录界面        
<div align=center><img width="50%" src="https://raw.githubusercontent.com/Johncahong/XMPP-Project/main/readmeImage/xmppcode02.png"/></div>

- 添加好友和获取好友列表界面    
<div align=center><img width="50%" src="https://raw.githubusercontent.com/Johncahong/XMPP-Project/main/readmeImage/xmppcode03.png"/></div>

- 与好友聊天界面    
<div align=center><img width="50%" src="https://raw.githubusercontent.com/Johncahong/XMPP-Project/main/readmeImage/xmppcode04.png"/></div>

- 更多项目的描述请看：[OS实现XMPP通讯（二）XMPP编程](https://johncahong.github.io/2021/09/05/iOS-XMPP-communication-with-XMPP-programming)
