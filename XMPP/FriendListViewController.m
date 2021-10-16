//
//  FriendListViewController.m
//  XMPP学习
//
//  Created by Hello Cai on 16/8/29.
//  Copyright © 2016年 Hello Cai. All rights reserved.
//

#import "FriendListViewController.h"
#import "XmppManager.h"
#import "ChatViewController.h"
#import "UserModel.h"

@interface FriendListViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *friendTF;


//好友列表
@property(nonatomic,strong)NSMutableArray *friendArr;
@end

@implementation FriendListViewController

-(NSMutableArray *)friendArr{
    
    if (_friendArr==nil) {
        _friendArr = [[NSMutableArray alloc] init];
    }
    return _friendArr;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //设置回调block
    [XmppManager defaultManager].friendListBlock = ^(NSArray *friends) {
        NSLog(@"friendcount:%d", (int)friends.count);
        [self.friendArr removeAllObjects];
        [self.friendArr addObjectsFromArray:friends];
        [self.tableView reloadData];
    };
    
    //向服务器请求好友列表
    [[XmppManager defaultManager] requestFriends];
    
    //对方添加我为好友
    [XmppManager defaultManager].beAddedFriendBlock = ^(NSString *jidString) {
        NSString *message = [NSString stringWithFormat:@"是否允许添加%@为好友？", jidString];
        UIAlertController *vc = [UIAlertController alertControllerWithTitle:message message:@"" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //同意对方的加好友请求
            [[XmppManager defaultManager] acceptAddFriend:jidString];
        }];
        [vc addAction:sureAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"不允许" style:UIAlertActionStyleCancel handler:nil];
        [vc addAction:cancelAction];
        
        [self presentViewController:vc animated:YES completion:nil];
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.friendArr.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    UserModel *model = self.friendArr[indexPath.row];
    cell.textLabel.text = model.jidUserName;
    if (model.status == 1) {
        //在线
        cell.textLabel.textColor = [UIColor blackColor];
    }else{
        //不在线
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.destinationViewController isKindOfClass:[ChatViewController class]]) {
        ChatViewController *chatCtl = segue.destinationViewController;
        //获取cell的indexPath
        //因为连线的时候是用cell连到ChatViewController的，所以sender就表示tableViewCell
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        UserModel *model = self.friendArr[indexPath.row];
        //传递聊天名称
        chatCtl.chatName = model.jidUserName;
    }
}

- (IBAction)addFriendClick:(UIButton *)sender {
    [self.friendTF resignFirstResponder];
    
    NSString *domain = [XmppManager defaultManager].xmppStream.myJID.domain;
    NSLog(@"domain:%@", domain);
    NSString *jidName = [NSString stringWithFormat:@"%@@%@", self.friendTF.text, domain];
    [[XmppManager defaultManager] addFriend:jidName];
    
    UIAlertController *vc = [UIAlertController alertControllerWithTitle:@"已发送添加好友申请" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:vc animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [vc dismissViewControllerAnimated:YES completion:nil];
    });
}
@end
