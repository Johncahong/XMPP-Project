//
//  ListViewController.m
//  XMPP学习
//
//  Created by Hello Cai on 16/8/29.
//  Copyright © 2016年 Hello Cai. All rights reserved.
//

#import "ListViewController.h"
#import "XmppManager.h"
#import "ChatViewController.h"
@interface ListViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//好友列表
@property(nonatomic,strong)NSMutableArray *friendArr;
@end

@implementation ListViewController

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
    [XmppManager defaultManager].listblock = ^(XMPPIQ *xmppiq){
        
        //服务器返回的内容，进行解析xml，取出我们需要的好友名字(账号)
        /*
        <iq xmlns="jabber:client" type="result" id="1111" to="hong@192.168.2.2/t7i1lbc63">
          <query xmlns="jabber:iq:roster" ver="-1497960644">
            <item jid="ming@192.168.2.2" name="ming" subscription="to">
              <group>Friends</group>
            </item>
            <item jid="wang@192.168.2.2" name="wang" subscription="both">
              <group>Friends</group>
            </item>
          </query>
        </iq>
         */
        //获取好友列表
        NSXMLElement *query = xmppiq.childElement;  //由于iq节点里面只有一个子节点query，所以可以直接用childElement获取其子节点query
        //query.children：获得节点query的所有孩子节点
        for (NSXMLElement *item in query.children) {
            NSString *friendJidString = [item attributeStringValueForName:@"jid"];
            //添加到数组中
            [self.friendArr addObject:friendJidString];
        }
        [self.tableView reloadData];
    };
    
    //向服务器请求好友列表
    [self getList];
}

-(void)getList{
    //以下包含iq节点和query子节点
    /**
     <iq from="hong@192.168.2.2/750tnmoq3l" id="1111" type="get">
       <query xmlns="jabber:iq:roster"></query>
     </iq>
     */
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    //拼接属性节点from，id，type
    //属性节点"from"的值为jid账号
    [iq addAttributeWithName:@"from" stringValue:[XmppManager defaultManager].xmppStream.myJID.description];
    //id是消息的标识号，到时需要查找消息时可以根据id去找，id可以随便取值
    [iq addAttributeWithName:@"id" stringValue:@"1111"];
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    
    //query是单节点，xmlns为它的属性节点
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    //拼接属性节点xmlns,固定写法
    [query addAttributeWithName:@"xmlns" stringValue:@"jabber:iq:roster"];
    
    //iq添加query为它的子节点
    [iq addChild:query];
    
    //发送xml包
    [[XmppManager defaultManager].xmppStream sendElement:iq];
    
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
    
    cell.textLabel.text = self.friendArr[indexPath.row];
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.destinationViewController isKindOfClass:[ChatViewController class]]) {
        ChatViewController *chatCtl = segue.destinationViewController;
        //获取cell的indexPath
        //因为连线的时候是用cell连到ChatViewController的，所以sender就表示tableViewCell
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        //传递聊天名称
        chatCtl.chatName = self.friendArr[indexPath.row];
    }
}

@end
