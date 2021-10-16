//
//  ChatViewController.m
//  XMPP学习
//
//  Created by Hello Cai on 16/8/29.
//  Copyright © 2016年 Hello Cai. All rights reserved.
//

#import "ChatViewController.h"
#import "Message.h"
#import "ChatCell.h"

NSString *const MessageHistory = @"MessageHistory";

@interface ChatViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *messageTF;

@property(nonatomic,strong)NSMutableArray *messageArr;
@end

@implementation ChatViewController

-(NSMutableArray *)messageArr{
    if (_messageArr ==nil) {
        _messageArr = [[NSMutableArray alloc] init];
    }
    return _messageArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    
    self.title = _chatName;
    self.messageTF.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[ChatCell class] forCellReuseIdentifier:@"ChatCell"];
    
    if ([self unarchiver]) {
        [self.messageArr addObjectsFromArray:[self unarchiver]];
        [self.tableView reloadData];
    }
    
    //设置回调
    [XmppManager defaultManager].getMessageBlock = ^(NSString *messageText){
        
        if (messageText==nil || [messageText isEqualToString:@""]) {
            return;
        }
        Message *otherMes = [[Message alloc] init];
        otherMes.contentString = messageText;
        otherMes.isOwn = NO;
        //添加到数组当中
        [self.messageArr addObject:otherMes];
        [self archiverWithArray:self.messageArr];
        
        [self.tableView reloadData];
        
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messageArr.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    };
}

-(void)showKeyboard:(NSNotification *)notification{
    NSValue *keyBoardBeginBounds = [[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect beginRect = [keyBoardBeginBounds CGRectValue];
    
    NSValue *keyBoardEndBounds = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect endRect = [keyBoardEndBounds CGRectValue];
    
    NSLog(@"deltaRect:%.1f", endRect.origin.y - beginRect.origin.y);
    
    UIView *view = [[UIView alloc] initWithFrame:self.tableView.bounds];
    [self.tableView addSubview:view];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHide:)];
    [view addGestureRecognizer:tap];
    
    double t = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:t animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = frame.origin.y + endRect.origin.y - beginRect.origin.y;
        self.view.frame = frame;
    }];
}

-(void)hideKeyboard:(NSNotification *)notification{
    double t = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:t animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = 0;
        self.view.frame = frame;
    }];
}

-(void)tapHide:(UITapGestureRecognizer *)tap{
    UIView *view = tap.view;
    [view removeFromSuperview];
    
    [self.messageTF resignFirstResponder];
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messageArr.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //获取信息模型
    Message *model = self.messageArr[indexPath.row];
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
    [cell setCellWithModel:model];
    return cell;
}

#pragma mark - UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    Message *model = self.messageArr[indexPath.row];
    return [ChatCell cellHeight:model];
}

//点击return键发送信息
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField.text.length == 0) {
        return YES;
    }
    [[XmppManager defaultManager] sendMessageText:textField.text jidUserName:self.chatName];
    
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

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:UIKeyboardWillShowNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:UIKeyboardWillHideNotification];
}
@end
