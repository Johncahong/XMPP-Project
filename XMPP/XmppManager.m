//
//  XmppManager.m
//  XMPP学习
//
//  Created by Hello Cai on 16/8/26.
//  Copyright © 2016年 Hello Cai. All rights reserved.
//

#import "XmppManager.h"

@interface XmppManager ()<XMPPStreamDelegate>
@property(nonatomic,copy)NSString *usernameStr;
@property(nonatomic,copy)NSString *pswStr;
@property(nonatomic,assign)BOOL isLogin;
@end

@implementation XmppManager

//懒加载
-(XMPPStream *)xmppStream{
    if (_xmppStream ==nil) {
        _xmppStream = [[XMPPStream alloc] init];
        //设置代理
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _xmppStream;
}

+(instancetype)defaultManager{
    
    static XmppManager *single = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        single = [[XmppManager alloc] init];
    });
    return single;
}

//连接服务器
-(void)connectHost:(NSString *)usernameStr andPassword:(NSString *)passwordStr andisLogin:(BOOL)islogin{
    
    self.usernameStr = usernameStr;
    self.pswStr = passwordStr;
    self.isLogin = islogin;
    
    //判断当前没有连接服务器，如果连接了就断开连接
    if ([self.xmppStream isConnected]) {
        [self.xmppStream disconnect];
    }
    //设置服务器地址
    [self.xmppStream setHostName:HOST];
    //设置端口号
    [self.xmppStream setHostPort:KPort];
    
    //设置JID账号
    XMPPJID *jid = [XMPPJID jidWithUser:self.usernameStr domain:HOST resource:nil];
    [self.xmppStream setMyJID:jid];
    
    //连接服务器
    NSError *error = nil;
    //该方法返回了bool值，可以作为判断是否连接成功，如果10s内顺利连接上服务器返回yes
    [self.xmppStream connectWithTimeout:10.0f error:&error];
    
    //如果连接服务器超过10s钟
    if (error) {
        NSLog(@"error = %@",error);
    }
}

#pragma mark - XMPPStreamDelegate
//除了上面可以判断是否连接上服务器外还能通过如下这种形式判断
-(void)xmppStreamDidConnect:(XMPPStream *)sender{
    
    NSLog(@"连接服务器成功");
    //这里要清楚，连接服务器成功并不是注册成功或登录成功【可以把“连接服务器成功”当做接收到当前服务器开启了的通知】
    NSError *error = nil;
    if (self.isLogin) {
        //进行验证身份（或者叫进行登录）
        [self.xmppStream authenticateWithPassword:self.pswStr error:&error];
    }else{
        //进行注册
        [self.xmppStream registerWithPassword:self.pswStr error:&error];
    }
    
    if (error) {
        NSLog(@"密码认证错误：%@", [error localizedDescription]);
    }
}
    

//注册成功的回调
-(void)xmppStreamDidRegister:(XMPPStream *)sender{
    NSLog(@"注册成功");
}
-(void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error{
    NSLog(@"注册失败：%@", error);
}

//登录成功(密码输入正确)的回调
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    NSLog(@"登录成功");
    
    //发送一个登录状态
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"available"];
    //发送一个xml包给服务器
    //参数：DDXMLElement，XMPPPresence继承自它
    [self.xmppStream sendElement:presence];
    
    //跳转控制器
    if (self.loginblock) {
        self.loginblock();        
    }
}

-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error{
    NSLog(@"登录失败：%@",error);
}

//获取到服务器返回的花名册（即好友列表）
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    
    NSLog(@"didReceiveIQ:%@",iq);
    
    if (self.listblock) {
        self.listblock(iq);
    }
    return YES;
}

//收到服务器返回的消息回调
-(void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    
    NSLog(@"message=%@",message);
    
    if (self.chatblock) {
        self.chatblock(message);
    }
}
@end
