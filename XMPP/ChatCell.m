//
//  ChatCell.m
//  XMPP
//
//  Created by Hello Cai on 2021/8/13.
//

#import "ChatCell.h"

@implementation ChatCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _headerImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_headerImageView];
        
        _popoImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_popoImageView];
        
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.numberOfLines = 0;
        _contentLabel.font = [UIFont systemFontOfSize:14];
        [_popoImageView addSubview:_contentLabel];
    }
    return self;
}

+(CGRect)getContentRect:(NSString *)content{
    CGRect contentRect = [content boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width-100-90, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil];
    return contentRect;
}

-(void)setCellWithModel:(Message *)model{
    _contentLabel.text = model.contentString;
    CGRect contentRect = [[self class] getContentRect:model.contentString];
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat contentWidth = contentRect.size.width;
    CGFloat contentHeight = contentRect.size.height;
    
    CGFloat popWidth = contentWidth + 40;
    CGFloat popHeight = contentHeight + 25;
    
    if (model.isOwn) {  //自己
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
    }else{  //好友
        _headerImageView.image = [UIImage imageNamed:@"icon02"];
        _headerImageView.frame = CGRectMake(10, 10, 60, 60);
        
        _popoImageView.frame = CGRectMake(70, 10, popWidth, popHeight);
        UIImage * image = [UIImage imageNamed:@"chatfrom_bg_normal.png"];
        image = [image stretchableImageWithLeftCapWidth:45 topCapHeight:55];
        _popoImageView.image = image;
        
        _contentLabel.frame = CGRectMake(25, 10, contentWidth, contentHeight);
    }
}

//获取cell高度
+(CGFloat)cellHeight:(Message *)model{
    if (!model.cellHeight) {
        CGRect contentRect = [self getContentRect:model.contentString];
        CGFloat height = contentRect.size.height + 40;
        if (height < 80) {
            height = 80;
        }
        model.cellHeight = height;
    }
    return model.cellHeight;
}

@end
