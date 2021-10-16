//
//  UserModel.h
//  XMPP
//
//  Created by Hello Cai on 2021/10/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserModel : NSObject

//用户名(比如：li@192.168.2.2)
@property (nonatomic, copy)NSString *jidUserName;
//在线状态（0表示下线，1表示上线）
@property (nonatomic, assign)int status;

@end

NS_ASSUME_NONNULL_END
