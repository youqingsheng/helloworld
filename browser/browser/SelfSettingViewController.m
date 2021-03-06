//
//  SelfSettingViewController.m
//  browser
//
//  Created by mahongzhi on 14-11-18.
//
//
#define  TAG_ALERTVIEW_INSTALLSELFFIX 34340

#import "SelfSettingViewController.h"
#import "CustomNavigationBar.h"
#import "PopView.h"
#import "IphoneAppDelegate.h"

@interface SelfSettingViewController (){
    
    UIColor *defaultColor;
    UILabel *topicLabel;
    UILabel *desLabel;
    UIImageView *logoImageView;
    UIImageView *backgroundImageView;
}

@end

@implementation SelfSettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        defaultColor = [UIColor colorWithRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:1.0];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = WHITE_BACKGROUND_COLOR;
    
    addNavgationBarBackButton(self, popRepairSelfViewController);
    CustomNavigationBar *navBar = [[CustomNavigationBar alloc] init];
    [navBar showNavigationTitleView:@"自我修复"];
    self.navigationItem.titleView = navBar;
    
    backgroundImageView = [UIImageView new];
    UIImage *img = [UIImage imageNamed:@"more_fixbg.png"];
    backgroundImageView.backgroundColor = [UIColor colorWithPatternImage:img];
    backgroundImageView.userInteractionEnabled = YES;

    
    
    logoImageView = [[UIImageView alloc] init];
    logoImageView.backgroundColor = [UIColor clearColor];
    SET_IMAGE(logoImageView.image, @"more_fixlogo.png");


    topicLabel = [UILabel new];
    topicLabel.textColor = [UIColor blackColor];
    topicLabel.backgroundColor = [UIColor clearColor];
    topicLabel.textAlignment = NSTextAlignmentCenter;
    topicLabel.font = [UIFont boldSystemFontOfSize:22.0f];
    topicLabel.text = @"修复应用宝贝自身闪退";
    
    desLabel = [UILabel new];
    desLabel.textColor = [UIColor grayColor];
    desLabel.textAlignment = NSTextAlignmentCenter;
    desLabel.backgroundColor = [UIColor clearColor];
    desLabel.font = [UIFont systemFontOfSize:16.0f];
    desLabel.text = @"强烈建议您马上安装";
    
    self.repairBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.repairBtn setTitle:@"安装应用宝贝闪退修复" forState:UIControlStateNormal];
    [self.repairBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.repairBtn setBackgroundImage:[UIImage imageNamed:@"more_fixbtnbg.png"] forState:UIControlStateNormal];
    self.repairBtn.backgroundColor = [UIColor clearColor];
    [self.repairBtn addTarget:self action:@selector(installFixClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.view addSubview:backgroundImageView];
    [self.view addSubview:topicLabel];
    [self.view addSubview:desLabel];
    [self.view addSubview:logoImageView];
    [self.view addSubview:self.repairBtn];
}

#pragma mark - Utility

-(void)popRepairSelfViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 安装应用宝贝闪退修复
- (void)installFixClick:(id)sender
{
    UIAlertView *alert =[ [UIAlertView alloc]initWithTitle:@"是否安装？" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"是",@"否", nil];
    alert.tag = TAG_ALERTVIEW_INSTALLSELFFIX;
    alert.delegate = self;
    [alert show];
}

#pragma mark - UIAlertView delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    switch (alertView.tag) {
        case TAG_ALERTVIEW_INSTALLSELFFIX:{ //自我修复
            if (buttonIndex ==0) {
                [browserAppDelegate installFix];
            }
        }
            break;
        default:
            break;
    }
    
}

-(void)viewWillLayoutSubviews{

    backgroundImageView.frame = self.view.bounds;
    logoImageView.frame = CGRectMake((self.view.frame.size.width - 175)/2, 54*(MainScreen_Width/320) + 44, 175, 175);
    
    topicLabel.frame = CGRectMake(0, logoImageView.frame.origin.y + logoImageView.frame.size.height + 18*(MainScreen_Width/320), self.view.frame.size.width, 20);
    desLabel.frame = CGRectMake(0, topicLabel.frame.origin.y + topicLabel.frame.size.height + 8*(MainScreen_Width/320), self.view.frame.size.width, 20);
    self.repairBtn.frame = CGRectMake((self.view.frame.size.width - 160)/2, self.view.frame.size.height - 87*(MainScreen_Width/320) - 44, 160, 43);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
