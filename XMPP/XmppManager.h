//
//  XmppManager.h
//  XMPP学习
//
//  Created by Hello Cai on 16/8/26.
//  Copyright © 2016年 Hello Cai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPP.h>

//ViewController的回调
typedef void(^loginBlock)(void);

//ListViewController的回调
typedef void(^listBlock)(XMPPIQ *iq);

//ChatViewController的回调
typedef void(^chatBlock)(XMPPMessage *message);

@interface XmppManager : NSObject


@property(nonatomic,copy)loginBlock loginblock;
@property(nonatomic,copy)listBlock listblock;
@property(nonatomic,copy)chatBlock chatblock;

//基本上xmpp的所有功能都与xmppStream相关
@property(nonatomic,strong)XMPPStream *xmppStream;

//获取单例对象
+(instancetype)defaultManager;

//连接服务器
-(void)connectHost:(NSString *)usernameStr andPassword:(NSString *)passwordStr andisLogin:(BOOL)islogin;

@end
