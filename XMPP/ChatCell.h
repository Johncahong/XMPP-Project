//
//  ChatCell.h
//  XMPP
//
//  Created by Hello Cai on 2021/8/13.
//

#import <UIKit/UIKit.h>
#import "Message.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatCell : UITableViewCell

@property (strong, nonatomic)UIImageView * headerImageView;
@property (strong, nonatomic)UIImageView * popoImageView;
@property (strong, nonatomic)UILabel * contentLabel;

-(void)setCellWithModel:(Message *)model;
+(CGFloat)cellHeight:(Message *)model;
@end

NS_ASSUME_NONNULL_END
