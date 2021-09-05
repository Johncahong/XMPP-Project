//
//  Message.m
//  XMPP学习
//
//  Created by Hello Cai on 16/8/29.
//  Copyright © 2016年 Hello Cai. All rights reserved.
//

#import "Message.h"
#import <objc/runtime.h>

@implementation Message

//setValue:的value为nil时会抛出以下异常，以下用来防止崩溃
-(void)setNilValueForKey:(NSString *)key{};

//解档
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList([self class], &count);
        for (int i=0; i<count; i++) {
            Ivar ivar = ivars[i];
            const char *name = ivar_getName(ivar);
            NSString *key = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            id value = [aDecoder decodeObjectForKey:key];
            [self setValue:value forKey:key];
        }
        free(ivars);
    }
    return self;
}

//归档
-(void)encodeWithCoder:(NSCoder *)aCoder{
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([self class], &count);
    for (int i=0; i<count; i++) {
        Ivar ivar = ivars[i];
        const char *name = ivar_getName(ivar);
        NSString *key = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        id value = [self valueForKey:key];     //用kvc读取对象的属性值
        [aCoder encodeObject:value forKey:key];//将key与value关联并归档到文件
    }
    free(ivars);
}

@end
