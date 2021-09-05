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
    
    
    //设置回调block
    [XmppManager defaultManager].loginblock = ^{
        [self performSegueWithIdentifier:@"ListViewController" sender:nil];
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)registerAction:(id)sender {
    
    //注册
    [[XmppManager defaultManager] connectHost:self.usernameTF.text andPassword:self.pswTF.text andisLogin:NO];
}

- (IBAction)loginAction:(UIButton *)sender {
    
    //登录
    [[XmppManager defaultManager] connectHost:self.usernameTF.text andPassword:self.pswTF.text andisLogin:YES];
}
@end
