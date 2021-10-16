//
//  XmppManager.m
//  XMPP学习
//
//  Created by Hello Cai on 16/8/26.
//  Copyright © 2016年 Hello Cai. All rights reserved.
//

#import "XmppManager.h"
#import "UserModel.h"

//获取好友列表ID
static NSString *JFriendListID = @"1111";

@interface XmppManager ()<XMPPStreamDelegate>
@property(nonatomic,copy)RegisterBlock registerBlock;
@property(nonatomic,copy)LoginBlock loginBlock;

@property(nonatomic, strong)XMPPRoster *xmppRoster;//xmpp花名册

@property(nonatomic,copy)NSString *usernameStr;
@property(nonatomic,copy)NSString *pswStr;
@property(nonatomic,assign)BOOL isLogin;
@property(nonatomic,strong)NSMutableArray *friendList;
@property(nonatomic,assign)BOOL isActiveAdd;
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.friendList = [NSMutableArray array];
        
        //初始化花名册
        XMPPRosterCoreDataStorage *xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
        self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
        //激活xmppStream的花名册
        [self.xmppRoster activate:self.xmppStream];
    }
    return self;
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
    [self.xmppStream setHostName:KHOST];
    //设置端口号
    [self.xmppStream setHostPort:KPort];
    
    //设置JID账号
    XMPPJID *jid = [XMPPJID jidWithUser:self.usernameStr domain:KHOST resource:nil];
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

#pragma mark - 外部接口
//注册
-(void)registerWithName:(NSString *)name andPassword:(NSString *)password result:(RegisterBlock)block{
    self.registerBlock = [block copy];
    [self connectHost:name andPassword:password andisLogin:NO];
}

//登录
-(void)loginWithName:(NSString *)name andPassword:(NSString *)password result:(LoginBlock)block{
    self.loginBlock = [block copy];
    [self connectHost:name andPassword:password andisLogin:YES];
}

//请求获取好友
-(void)requestFriends{
    //以下包含iq节点和query子节点
    /**
     <iq from="hong@192.168.2.2/750tnmoq3l" id="1111" type="get">
       <query xmlns="jabber:iq:roster"></query>
     </iq>
     */
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    //拼接属性节点from，id，type
    //属性节点"from"的值为jid账号
    [iq addAttributeWithName:@"from" stringValue:[XmppManager defaultManager].xmppStream.myJID.description];
    //id是消息的标识号，到时需要查找消息时可以根据id去找，id可以随便取值
    [iq addAttributeWithName:@"id" stringValue:JFriendListID];
    //类似http的Get请求，发出获取好友的请求。服务器的响应数据中type为result，id对应1111
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    
    //query是单节点，xmlns为它的属性节点
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    //拼接属性节点xmlns,固定写法
    [query addAttributeWithName:@"xmlns" stringValue:@"jabber:iq:roster"];
    
    //iq添加query为它的子节点
    [iq addChild:query];
    
    //发送请求获取好友的xml包
    [self.xmppStream sendElement:iq];
}

//添加好友
-(void)addFriend:(NSString *)jidName{
    XMPPJID *jid = [XMPPJID jidWithString:jidName];
    //请求添加jid为好友
    [self.xmppRoster subscribePresenceToUser:jid];
    _isActiveAdd = YES;
}

//同意对方的加好友请求
-(void)acceptAddFriend:(NSString *)jidName{
    XMPPJID *jid = [XMPPJID jidWithString:jidName];
    /*同意对方的加好友请求，第二个参数表示是否请求添加对方为好友。
      取YES时其实就是调用subscribePresenceToUser:
     */
    [self.xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
}

//发送消息
-(void)sendMessageText:(NSString *)text jidUserName:(NSString *)jidUserName{
    /*
    <message from="hong@192.168.2.2/t7i1lbc63" id="2222" to="wang@192.168.2.2" type="chat">
      <body>准备吃饭了</body>
    </message>
    */
    if (text.length == 0) {
        return;
    }
     
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    XMPPJID *jid = self.xmppStream.myJID;
    //拼接属性节点
    [message addAttributeWithName:@"from" stringValue:jid.description];
    [message addAttributeWithName:@"id" stringValue:@"2222"];
    [message addAttributeWithName:@"to" stringValue:jidUserName];
    //什么类型xml包，chat表示单聊。lang表示语言，拼不拼接都无所谓
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    //设置发送的信息
    [body setStringValue:text];
    //添加子节点
    [message addChild:body];
    
    //发送xml包请求
    [self.xmppStream sendElement:message];
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
    if (self.registerBlock) {
        self.registerBlock(YES, nil);
    }
}
-(void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error{
    NSLog(@"注册失败：%@", error);
    NSError *cError = [NSError errorWithDomain:error.description code:-1 userInfo:nil];
    if (self.registerBlock) {
        self.registerBlock(NO, cError);
    }
}

//登录成功(密码输入正确)的回调
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    NSLog(@"登录成功");
    
    //申请上线，告诉服务器，让服务器将我的状态改为‘上线’，服务器会群发给所有好友（包括自己）
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"available"];
    //参数：DDXMLElement，XMPPPresence继承自它
    [self.xmppStream sendElement:presence];
    
    //跳转控制器
    if (self.loginBlock) {
        self.loginBlock(YES, nil);
    }
}

-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error{
    NSLog(@"登录失败：%@",error);
    NSError *cError = [NSError errorWithDomain:error.description code:-1 userInfo:nil];
    if (self.loginBlock) {
        self.loginBlock(NO, cError);
    }
}

//服务器返回的IQ信息。比如花名册数据（即好友列表）
//该方法可能多次返回相似的数据，可通过id值过滤，判断服务器是响应什么请求
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    
    NSLog(@"didReceiveIQ:%@",iq);
    /**
     第一次回调
     <iq xmlns="jabber:client" type="result" id="1111" to="hong@192.168.2.2/2uc83c92op">
       <query xmlns="jabber:iq:roster" ver="204617739">
         <item jid="ming@192.168.2.2" subscription="both"/>
         <item jid="wang@192.168.2.2" name="wang" ask="subscribe" subscription="from">
           <group>我的联系人</group>
         </item>
       </query>
     </iq>
     
     第二次回调
     <iq xmlns="jabber:client" type="get" id="515-72" to="hong@192.168.2.2/2uc83c92op" from="192.168.2.2">
       <query xmlns="jabber:iq:version"></query>
     </iq>
     */
    
    //获取好友列表
    //由于iq节点里面只有一个子节点query，所以可以直接用childElement获取其子节点query
    NSXMLElement *query = iq.childElement;
    if ([iq.elementID isEqualToString:JFriendListID]) {
        NSLog(@"好友花名册");
        NSArray *friends = [self.friendList copy];
        
        //query.children：获得节点query的所有孩子节点
        for (NSXMLElement *item in query.children) {
            NSString *friendJidString = [item attributeStringValueForName:@"jid"];
            
            BOOL shouldAdd = YES;
            for (UserModel *model in friends) {
                if ([friendJidString isEqualToString:model.jidUserName]) {
                    shouldAdd = NO;
                    break;
                }
            }
            if (shouldAdd) {
                UserModel *newmodel = [[UserModel alloc] init];
                newmodel.jidUserName = friendJidString;
                newmodel.status = 0;
                //添加到数组中
                [self.friendList addObject:newmodel];
            }
        }
        if (self.friendListBlock) {
            self.friendListBlock(self.friendList);
        }
    }
    return YES;
}

#pragma mark 接收到服务器的聊天消息
//收到服务器返回的聊天消息
-(void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    
    NSLog(@"message=%@",message);
    
    /*
     <message xmlns="jabber:client" to="hong@192.168.2.2/t7i1lbc63" id="bFTVn-127" type="chat" from="wang@192.168.2.2/HellodeMacBook-Pro.local">
       <thread>ykBwqQ</thread>
       <body>好的</body>
       <x xmlns="jabber:x:event">
         <offline/>
         <composing/>
       </x>
       <active xmlns="http://jabber.org/protocol/chatstates"></active>
     </message>
     */
    if ([message.type isEqualToString:@"chat"]) { //表示聊天
        NSXMLElement *body = [message elementForName:@"body"];
        //NSLog(@"body = %@",body);   //打印：body = <body>好的</body>
        NSString *messageText = [body stringValue];
        if (self.getMessageBlock) {
            self.getMessageBlock(messageText);
        }
    }
}

#pragma mark 获取订阅信息
/*
 available -- 发送available：申请上线(默认)； 接收到available：某好友上线了
 unavailable -- 发送unavailable：申请下线； 接收到unavailable： 某好友下线了
 subscribe -- 发送subscribe：请求加对方为好友； 接收到subscribe：别人加我好友
 subscribed -- 发送subscribed：同意对方的加好友请求； 接收到subscribed：对方已经同意我的加好友请求
 unsubscribe -- 发送unsubscribe：删除好友； 接收到unsubscribe：对方已将我删除
 unsubscribed -- 发送unsubscribed：拒绝对方的加好友请求； 接收到unsubscribed：对方拒绝我的加好友请求
 error -- 当前状态packet有错误
 */
-(void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence{
    NSLog(@"获取订阅信息presence: %@", presence);
    /*
     第一次回调
     <presence xmlns="jabber:client" from="hong@192.168.2.2/852t6h63tn" to="hong@192.168.2.2/852t6h63tn"></presence>
     
     第二次回调
     <presence xmlns="jabber:client" id="FHcB3-42" from="ming@192.168.2.2/HellodeMacBook-Pro.local" to="hong@192.168.2.2/2uc83c92op">
       <status>在线</status>
       <priority>1</priority>
       <c xmlns="http://jabber.org/protocol/caps" hash="sha-1" node="http://www.igniterealtime.org/projects/smack" ver="9LJego/jm+LdNGOFm5gPTMPapl0="></c>
     </presence>
     */
    
    //获取哪位好友给我发的信息
    //from：ming@192.168.2.2/HellodeMacBook-Pro.local
    NSString *from = [presence attributeStringValueForName:@"from"];
    XMPPJID *fromJid = [XMPPJID jidWithString:from];
    if ([fromJid isEqualToJID:self.xmppStream.myJID]) {
        return;
    }
    //jidUserName：ming@192.168.2.2
    NSString *jidUserName = [NSString stringWithFormat:@"%@@%@", fromJid.user, fromJid.domain];
//    NSLog(@"friend--: %@", jidUserName);
    
    if ([presence.type isEqualToString:@"unavailable"]) {//下线
        [self updateJidName:jidUserName status:0];
    }else if ([presence.type isEqualToString:@"subscribe"] ) {
        NSLog(@"对方想添加我为好友");
        if (_isActiveAdd == NO) {
            if (self.beAddedFriendBlock) {
                self.beAddedFriendBlock(jidUserName);
            }
        }
        _isActiveAdd = NO;
    }else if ([presence.type isEqualToString:@"subscribed"]) {
        NSLog(@"对方已经同意我的加好友请求");
    }else if ([presence.type isEqualToString:@"unsubscribe"] ||
              [presence.type isEqualToString:@"unsubscribed"]) {
        
        if ([presence.type isEqualToString:@"unsubscribe"]) {
            NSLog(@"对方已将我删除");
        }else if ([presence.type isEqualToString:@"unsubscribed"]){
            NSLog(@"对方拒绝我的加好友请求");
        }
        //如果存在该好友，则移除
        NSArray *arr = [self.friendList copy];
        for (UserModel *model in arr) {
            if ([jidUserName isEqualToString:model.jidUserName]) {
                [self.friendList removeObject:model];
                //返回更新后的好友数组
                if (self.friendListBlock) {
                    self.friendListBlock(self.friendList);
                }
                break;
            }
        }
    }else{
        //默认为上线
        [self updateJidName:jidUserName status:1];
    }
}

-(void)updateJidName:(NSString *)jidUserName status:(int)status{
    //如果存在该好友，则更新好友的在线状态
    for (UserModel *model in self.friendList) {
        if ([jidUserName isEqualToString:model.jidUserName]) {
            model.status = status;
            //返回更新后的好友数组
            if (self.friendListBlock) {
                self.friendListBlock(self.friendList);
            }
            return;
        }
    }
    
    //如果不存在该好友，则先添加到好友列表中
    UserModel *model = [[UserModel alloc] init];
    model.jidUserName = jidUserName;
    model.status = status;
    [self.friendList addObject:model];

    if (self.friendListBlock) {
        self.friendListBlock(self.friendList);
    }
}
@end
