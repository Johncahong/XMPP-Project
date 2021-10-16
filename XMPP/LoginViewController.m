//
//  LoginViewController.m
//  XMPP
//
//  Created by Hello Cai on 2021/8/11.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTF;
@property (weak, nonatomic) IBOutlet UITextField *pswTF;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)registerAction:(id)sender {
    //注册
    [[XmppManager defaultManager] registerWithName:self.usernameTF.text andPassword:self.pswTF.text result:^(BOOL success, NSError *error) {
        if (success) {
            //注册成功
            UIAlertController *vc = [UIAlertController alertControllerWithTitle:@"恭喜你，注册成功" message:@"您现在可以登录了" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
            [vc addAction:sureAction];
            [self presentViewController:vc animated:YES completion:nil];
        }else{
            //注册失败
            NSLog(@"error%@",error.description);
            UIAlertController *vc = [UIAlertController alertControllerWithTitle:@"抱歉，注册失败" message:error.description preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
            [vc addAction:sureAction];
            [self presentViewController:vc animated:YES completion:nil];
        }
    }];
}

- (IBAction)loginAction:(UIButton *)sender {
    //登录
    [[XmppManager defaultManager] loginWithName:self.usernameTF.text andPassword:self.pswTF.text result:^(BOOL success, NSError *error) {
        if (success) {
            //登录成功
            [self performSegueWithIdentifier:@"FriendListViewController" sender:nil];
        }else{
            //登录失败
            UIAlertController *vc = [UIAlertController alertControllerWithTitle:@"抱歉，登录失败" message:error.description preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
            [vc addAction:sureAction];
            [self presentViewController:vc animated:YES completion:nil];
        }
    }];
}
@end
