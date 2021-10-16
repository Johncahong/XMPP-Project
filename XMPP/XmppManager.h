//
//  XmppManager.h
//  XMPP学习
//
//  Created by Hello Cai on 16/8/26.
//  Copyright © 2016年 Hello Cai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework.h>

//注册的Block
typedef void(^RegisterBlock)(BOOL success, NSError *error);

//登录的Block
typedef void(^LoginBlock)(BOOL success, NSError *error);

//获取好友列表的Block
typedef void(^FriendListBlock)(NSArray *friends);

//被别人添加好友Block
typedef void(^BeAddedFriendBlock)(NSString *jidString);

//收到好友消息的Block
typedef void(^GetMessageBlock)(NSString *message);

@interface XmppManager : NSObject

@property(nonatomic,copy)FriendListBlock friendListBlock;
@property(nonatomic,copy)BeAddedFriendBlock beAddedFriendBlock;
@property(nonatomic,copy)GetMessageBlock getMessageBlock;

//基本上xmpp的所有功能都与xmppStream相关
@property(nonatomic,strong)XMPPStream *xmppStream;

//获取单例对象
+(instancetype)defaultManager;

//注册
-(void)registerWithName:(NSString *)name andPassword:(NSString *)password result:(RegisterBlock)block;

//登录
-(void)loginWithName:(NSString *)name andPassword:(NSString *)password result:(LoginBlock)block;

//获取好友列表
-(void)requestFriends;

//主动添加好友
-(void)addFriend:(NSString *)jidName;

//同意对方的加好友请求
-(void)acceptAddFriend:(NSString *)jidName;

//发送消息
-(void)sendMessageText:(NSString *)text jidUserName:(NSString *)jidUserName;

@end
