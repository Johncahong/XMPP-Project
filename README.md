### 项目概述
- 这是一个可以登录jabber账号，获取好友列表，并且能与好友进行聊天的项目。
使用的是第三方库XMPPFramework框架来实现XMPP通讯。 
- 项目准备工作：搭建好Openfire服务器，安装客户端Spark，具体步骤请见：[iOS实现XMPP通讯（一）搭建Openfire](/2021/09/03/iOS实现XMPP通讯（一）搭建Openfire/index.html)
这样就可以登录本项目与登录Spark的另一用户进行XMPP通讯。
- 项目结构概述：
有三个视图控制器LoginViewController，ListViewController，ChatViewController
LoginViewController：登录和注册xmpp账号界面
ListViewController：获取花名册(好友列表)界面
ChatViewController：和好友进行单聊界面
为此封装了XmppManager类，方便统一管理与服务器的连接、好友列表回调、聊天消息回调等代理方法。
- 注意：由于XMPPFramework框架还依赖其他第三方库，如KissXML、CocoaAsyncSocket等，因此用cocoaPods添加XMPPFramework库时，podfile必须添加use_frameworks!，如下：
```c
platform:ios , '8.0'
target 'XMPP' do
    use_frameworks!
    pod 'XMPPFramework', '~> 4.0.0'
end
```
 


### 注册登录
- xmpp的登录流程是：先连接xmpp服务器，连接成功后再进行登录的鉴权，即校验密码的准确性。
xmpp的注册流程是：先连接xmpp服务器，连接成功后再向xmpp服务器注册账号、密码。
XmppManager类提供一个连接xmpp服务器的方法，当点击LoginViewController的"注册"和"登录"按钮时调用该方法。（备注：islogin用来区分是登录还是注册），该方法如下：
```c
//服务器地址（改成自己电脑的IP地址）
#define HOST @"192.168.2.2"
//端口号
#define KPort 5222
     
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
    if ([self.xmppStream connectWithTimeout:10.0f error:&error]) {
        NSLog(@"连接成功");
    }
    //如果连接服务器超过10s钟
    if (error) {
        NSLog(@"error = %@",error);
    }
}
```
 HOST是Openfire后台服务器的主机名，我们在Openfire后台服务器中配置了主机名为127.0.0.1，让电脑充当Openfire服务器，因此HOST的值为我电脑网络的IP地址192.168.2.2。
Openfire后台服务器配置的客户端连接端口默认是5222，因此这里KPort的值设为5222。后台配置如下：
 ![img](xmppcode01.png)

 输入账号、密码并按下注册或登录按钮后，app会向XMPP服务器进行连接请求，服务器连接成功会有相应的回调，在连接成功的回调中进行密码校验或账号注册操作。即如下所示：
```c
//除了上面可以判断是否连接上服务器外还能通过如下这种形式判断
-(void)xmppStreamDidConnect:(XMPPStream *)sender{
    NSLog(@"连接服务器成功");
    //这里要清楚，连接服务器成功并不是注册成功或登录成功【可以把“连接服务器成功”当做接收到当前服务器开启了的通知】
    if (self.isLogin) {
        //进行验证身份（或者叫进行登录）
        [self.xmppStream authenticateWithPassword:self.pswStr error:nil];
    }else{
        //进行注册
        [self.xmppStream registerWithPassword:self.pswStr error:nil];
    }
}
```
 附上LoginViewController的“注册”按钮和”登录“按钮的点击事件便于理解：
```c
- (IBAction)registerAction:(id)sender {
    //注册
    [[XmppManager defaultManager] connectHost:self.usernameTF.text andPassword:self.pswTF.text andisLogin:NO];
}
- (IBAction)loginAction:(UIButton *)sender {    
    //登录
    [[XmppManager defaultManager] connectHost:self.usernameTF.text andPassword:self.pswTF.text andisLogin:YES];
}
```
 对于注册成功或登录验证成功的回调结果，XmppManager类中有相应的回调方法：
```c
//注册成功的回调
-(void)xmppStreamDidRegister:(XMPPStream *)sender{
    NSLog(@"注册成功");
}
//登录成功(密码输入正确)的回调
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender{    
    NSLog(@"验证身份成功");
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
```
 以上loginblock是用来进行视图控制器间的跳转用的，登录界面采用storyboard搭建UI。LoginViewController点击"登录"按钮跳转到ListViewController，采用”登陆“按钮拉线至ListViewController的方式，因而可以给该条segue跳转线打上标记，如"ListViewController"，然后在LoginViewController的viewDidLoad方法中实现loginblock代码块，在代码块中借助segue的标记实现跳转，即：
```c
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置回调block
    [XmppManager defaultManager].loginblock = ^{
        [self performSegueWithIdentifier:@"ListViewController" sender:nil];       
    };
}
```
 登录界面如下：
![img](xmppcode02.png)



### 获取好友列表
- 好友是事先用Spark客户端添加的。要获取到好友列表可以根据xmpp的花名册格式来编写xml包，然后将编写好的xml包发送给服务器，即向服务器发起获取好友花名册的请求。以下是在ListViewController的viewDidLoad方法中的代码：
```c
- (void)viewDidLoad {
    [super viewDidLoad];
     
    [self getList]; 
}
//向服务器请求好友列表
-(void)getList {
    //以下包含iq节点和query子节点
    /**
     <iq from="hong@192.168.2.2/750tnmoq3l" id="1111" type="get">
       <query xmlns="jabber:iq:roster"></query>
     </iq>
     */
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    //拼接属性节点from，id，type
    //属性节点”from“的值为jid账号 
    [iq addAttributeWithName:@"from" stringValue:[XmppManager defaultManager].xmppStream.myJID.description];
    //id是消息的标识号，到时需要查找消息时可以根据id去找，id可以随便取值 
    [iq addAttributeWithName:@"id" stringValue:@"1111"];
    [iq addAttributeWithName:@"type" stringValue:@"get"];
         
    //query是单节点，xmlns为它的属性节点
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    //拼接属性节点xmlns,固定写法
    [query addAttributeWithName:@"xmlns" stringValue:@"jabber:iq:roster"];
     
    //iq添加query为它的子节点
    [iq addChild:query];
        
    //发送xml包
    [[XmppManager defaultManager].xmppStream sendElement:iq];
}
```
 对于花名册返回的结果，XmppManager类有相应的回调方法：
```c
//获取到服务器返回的花名册（即好友列表）
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    //NSLog(@"%@",iq);
    if (self.listblock) {
        self.listblock(iq);
    }
    return YES;
}
```
 以上listblock是用来向ListViewController回调iq结果（iq里面含有好友账号信息），即ListViewController的viewDidLoad方法最终代码如下： 
```c
- (void)viewDidLoad {
    [super viewDidLoad];
    //设置回调block
    [XmppManager defaultManager].listblock = ^(XMPPIQ *xmppiq){
    
        //服务器返回的内容，进行解析xml，取出我们需要的好友名字(账号)
        /*
        <iq xmlns="jabber:client" type="result" id="1111" to="hong@192.168.2.2/t7i1lbc63">
          <query xmlns="jabber:iq:roster" ver="-1497960644">
            <item jid="ming@192.168.2.2" name="ming" subscription="to">
              <group>Friends</group>
            </item>
            <item jid="wang@192.168.2.2" name="wang" subscription="both">
              <group>Friends</group>
            </item>
          </query>
        </iq>
         */
        //获取好友列表
        NSXMLElement *query = xmppiq.childElement;  //由于iq节点里面只有一个子节点query，所以可以直接用childElement获取其子节点query
        //query.children：获得节点query的所有孩子节点
        for (NSXMLElement *item in query.children) {
            NSString *friendJidString = [item attributeStringValueForName:@"jid"];
            //添加到数组中
            [self.friendArr addObject:friendJidString];
        }
        [self.tableView reloadData];
    };
        
    [self getList];
}
```
 获取好友列表界面如下：
![img](xmppcode03.png)



### 单聊界面
- 当我们获取到好友列表后，针对某一好友进行聊天，我们得区分自己与好友，项目采用的是Message类，里面有如下属性：
```c
@interface Message : NSObject
//内容
@property(nonatomic,copy)NSString *contentString;
//谁的信息
@property(nonatomic,assign)BOOL isOwn;
@end
```
 isOwn用来区分自己与好友对方，contentString即表示自己或好友发送消息的内容。本次ChatViewController在tableView中只用了一种cell，实际开发还是建议区分开来。在ChatViewController的主要代码如下：
```c
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{  
    //获取信息模型
    Message *model = self.messageArr[indexPath.row];
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
    [cell setCellWithModel:model];
    return cell;
}
```
 cell内部根据isOwn区分自己和好友，进而调整子控件的frame，代码如下：
```c
-(void)setCellWithModel:(Message *)model{
    _contentLabel.text = model.contentString;
    CGRect contentRect = [model.contentString boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width-100-90, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil];
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat contentWidth = contentRect.size.width;
    CGFloat contentHeight = contentRect.size.height;
        
    CGFloat popWidth = contentWidth + 40;
    CGFloat popHeight = contentHeight + 25;
    
    if (model.isOwn) {  //自己
        _headerImageView.image = [UIImage imageNamed:@"icon01"];
        //头像
        _headerImageView.frame = CGRectMake(screenWidth-70, 10, 60, 60);
        
        //气泡的图片
        CGFloat popX = screenWidth - popWidth - 70;
        _popoImageView.frame = CGRectMake(popX, 10, popWidth, popHeight);
        UIImage * image = [UIImage imageNamed:@"chatto_bg_normal.png"];
        image = [image stretchableImageWithLeftCapWidth:45 topCapHeight:12];
        _popoImageView.image = image;
        
        //聊天内容的label
        _contentLabel.frame = CGRectMake(15, 10, contentWidth, contentHeight);
    }else{    //好友
        _headerImageView.image = [UIImage imageNamed:@"icon02"];
        _headerImageView.frame = CGRectMake(10, 10, 60, 60);
        
        _popoImageView.frame = CGRectMake(70, 10, popWidth, popHeight);
        UIImage * image = [UIImage imageNamed:@"chatfrom_bg_normal.png"];
        image = [image stretchableImageWithLeftCapWidth:45 topCapHeight:55];
        _popoImageView.image = image;
        
        _contentLabel.frame = CGRectMake(25, 10, contentWidth, contentHeight);
    }
}
```
 那么自己说的内容是用textField发送出去的，运用的是textField的代理方法，遵循xml消息包格式，我们编写自己说的内容的xml消息包进行发送，即如下：
```c
//点击return键发送信息
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    /*
    <message from="hong@192.168.2.2/t7i1lbc63" id="2222" to="wang@192.168.2.2" type="chat">
      <body>准备吃饭了</body>
    </message>
    */
     
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    XMPPJID *jid = [XmppManager defaultManager].xmppStream.myJID;
    //拼接属性节点
    [message addAttributeWithName:@"from" stringValue:jid.description];
    [message addAttributeWithName:@"id" stringValue:@"2222"];
    [message addAttributeWithName:@"to" stringValue:self.chatName];
    [message addAttributeWithName:@"type" stringValue:@"chat"]; //什么类型xml包，chat表示单聊。    lang表示语言，拼不拼接都无所谓
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    //设置发送的信息
    [body setStringValue:textField.text];
    //添加子节点
    [message addChild:body];
        
    //发送xml包请求
    [[XmppManager defaultManager].xmppStream sendElement:message];
        
    Message *myMes = [[Message alloc] init];
    myMes.contentString = textField.text;
    myMes.isOwn = YES;
    [self.messageArr addObject:myMes];
    [self archiverWithArray:self.messageArr];
    
    [self.tableView reloadData];
    self.messageTF.text = @"";
    
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messageArr.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    return YES;
}
```
 当好友发消息给我时，xmpp在XmppManager类会触发相应的回调，如下：
```c
//收到服务器返回的消息回调
-(void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    //NSLog(@"message=%@",message);
    if (self.chatblock) {
        self.chatblock(message);
    }
}
```
 以上chatblock是用来向ChatViewController回调message结果（里面含有聊天消息内容)，ChatViewController的viewDidLoad方法如下：
```c
- (void)viewDidLoad {
    [super viewDidLoad];
     
    if ([self unarchiver]) {
        [self.messageArr addObjectsFromArray:[self unarchiver]];
        [self.tableView reloadData];
    }
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
    //设置回调
    [XmppManager defaultManager].chatblock = ^(XMPPMessage *message){
     
        NSXMLElement *body = [message elementForName:@"body"];
        //NSLog(@"body = %@",body);   //打印：body = <body>NIHAO</body>
        
        if ([body stringValue]==nil || [[body stringValue] isEqualToString:@""]) {
            return;
        }
        Message *otherMes = [[Message alloc] init];
        otherMes.contentString = [body stringValue];
        otherMes.isOwn = NO;
        //添加到数组当中
        [self.messageArr addObject:otherMes];
        [self archiverWithArray:self.messageArr];
            
        [self.tableView reloadData];
        
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messageArr.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    };
}
```
- 这里打算用归档（NSKeyedArchiver）的方式存储用户的聊天记录。
由于每条聊天记录都是一个Message模型，Message模型必须实现归档（encodeWithCoder:）和解档（initWithCoder:），这样才能使用NSKeyedArchiver把模型数组存储到沙盒中。
ChatViewController类中归档和解档代码如下：
```c
//写的时候是把已知对象写入，故必须实例方法
-(void)archiverWithArray:(NSMutableArray *)array{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [documentPath stringByAppendingFormat:@"/%@/%@", MessageHistory, self.chatName];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:filePath]) {
        [fm createFileAtPath:filePath contents:nil attributes:nil];
    }
    [NSKeyedArchiver archiveRootObject:array toFile:filePath];
}
         
//取的时候是获得沙盒中的对象，与当前对象_cacheModel无关，类方法即可
-(NSMutableArray *)unarchiver{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [documentPath stringByAppendingFormat:@"/%@/%@", MessageHistory, self.chatName];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:filePath]) {
        NSMutableArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        return array;
    }
    return nil;
}
```
 单聊界面如下：
 ![img](xmppcode04.png)
