//
//  Message.h
//  XMPP学习
//
//  Created by Hello Cai on 16/8/29.
//  Copyright © 2016年 Hello Cai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject<NSCoding>
//内容
@property(nonatomic,copy)NSString *contentString;
//谁的信息
@property(nonatomic,assign)BOOL isOwn;

//辅助属性
@property(nonatomic, assign)CGFloat cellHeight;
@end
