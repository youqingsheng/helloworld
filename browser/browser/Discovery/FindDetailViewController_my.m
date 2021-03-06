//
//  FindDetailViewController.m
//  KY20Version
//
//  Created by liguiyang on 14-5-21.
//  Copyright (c) 2014年 lgy. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif


#import "FindDetailViewController_my.h"
#import "CustomNavigationBar.h"
#import "AppTableViewController_my.h"
#import "ArgumentViewController.h"

#import "UIImageEx.h"
#import "CollectionViewBack.h"
#import "UIWebViewController.h"
#import "ASIDownloadCache.h"
#import "FindPicInfoViewController.h"
#import "FileUtil.h"

#define TAG_ACTIVITYWEBVIEW 1123
#define TAG_MAINSCROLLVIEW 1125
#define ACTIVITY_ID(activityID) [NSString stringWithFormat:@"findDetail_%@",activityID]

@interface FindDetailViewController_my ()<UIScrollViewDelegate,UIWebViewDelegate,ArgumentViewDelegate,UIWebViewDelegate,FindPicInfoViewDelegate>
{
    // UIWebView
    UIWebView *activityWeb;
    CGFloat activityHeight;
    
    ASIHTTPRequest *activityRequest;
    ASIHTTPRequest *argumentRequest;
    
    // App tableview
    UIImageView *separateLine;
    UIImageView *separatorImgView;
    AppTableViewController_my *appTableVC;
    
    NSMutableArray *reportArray;
    
    // argument page
    //    ArgumentViewController *argumentVC;
    CGFloat argumentHeight;
    
    // scrollView
    UIScrollView *mainScrollView;
    
    CollectionViewBack * _backView;
    CustomNavigationBar *navBar;
    NSString *uniqueIdentifier;
    CGFloat  offset_appTableView;
    CGFloat  height_tableTop; // appTableView上面横线及“相关下载”图片总高度
    
    NSString *nextUrlStr;
    NSInteger index;
    
    FindPicInfoViewController *findPicVC;
    
    BOOL hasRemoveFlag; // 解决滑动返回不释放本类的问题
    
    UIButton*returnBtn;
    UIButton*ReportArticleBtn;
    NSMutableArray*_zanArray;
    UILabel*_zanLable;
}

@property (nonatomic, strong) NSDictionary *detailDic;
@property (nonatomic, strong) NSArray *appArr;
@property (nonatomic, strong) NSString *contentUrl;
@property (nonatomic, strong) NSString *share_word;
@property (nonatomic, strong) NSMutableArray *itemArray;

@end

@implementation FindDetailViewController_my

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        //
        reportArray = [NSMutableArray array];
        _appArr=[[NSArray alloc] init];
        
        // mainView
        [self initMainScreenView];
    }
    return self;
}

#pragma mark - initialization

-(void)initMainScreenView
{
    [self initActivityWebView];
    [self initDownloadTableVC];
    [self initScrollView];
    
    [mainScrollView addSubview:activityWeb];
    [mainScrollView addSubview:separateLine];
    [mainScrollView addSubview:separatorImgView];
    [mainScrollView addSubview:appTableVC.collectionView];
    //    [mainScrollView addSubview:argumentVC.view];
    [self.view addSubview:mainScrollView];
    
    // set frame
    [self setCustomFrame];
    
    //    _zanArray=[NSMutableArray new];
    _backView = [CollectionViewBack new];
    __weak FindDetailViewController_my* mySelf = self;
    [_backView setClickActionWithBlock:^{
        [mySelf performSelector:@selector(refreshDetailView) withObject:nil afterDelay:delayTime];
    }];
    [self.view addSubview:_backView];
    [self initNavButton];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    _backView.frame = self.view.bounds;
}

-(void)initActivityWebView
{
    activityWeb = [[UIWebView alloc] init];
    activityWeb.scrollView.scrollEnabled = NO;
    activityWeb.delegate = self;
    activityWeb.tag = TAG_ACTIVITYWEBVIEW;
    activityHeight = 100;
    [activityWeb.scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:@"content"];
}

-(void)initDownloadTableVC
{
    separateLine = [[UIImageView alloc] init];
    separateLine.backgroundColor =  [UIColor colorWithRed:168.0/255.0 green:168.0/255.0 blue:168.0/255.0 alpha:1];
    separatorImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"relatedApp.png"]];
    
    //    appTableVC = [[AppTableViewController alloc] init];
    
    UICollectionViewFlowLayout *flowLayout=[[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    appTableVC = [[AppTableViewController_my alloc]initWithCollectionViewLayout:flowLayout];
}

//　　项的宽度必须少,UICollectionView的宽度减去部分insets左和右值。
//- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
//{
//    // does the superclass do anything at this point?
//    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
//
//    // do whatever else you need before rotating toInterfaceOrientation
//
//    // tell the layout to recalculate
//    [appTableVC.collectionViewLayout invalidateLayout];
//}


-(void)initScrollView
{
    mainScrollView = [[UIScrollView alloc] init];
    mainScrollView.backgroundColor = [UIColor whiteColor];
    mainScrollView.delegate = self;
    mainScrollView.tag = TAG_MAINSCROLLVIEW;
}

#pragma mark - RequestMethods

-(void)reloadActivityDetailVC:(NSDictionary *)dic
{
    self.detailDic = dic;
    
    NSString*url=[self.detailDic objectForKey:@"content_url"];
    [self loadWebView:[NSURL URLWithString:url] withType:activity_Type];
    
    // 相关应用页
    
    _appArr=[self.detailDic objectForKey:@"apps"];
    
    if (IS_NSARRAY([self.detailDic objectForKey:@"apps"])) {
        
        if(_appArr.count>0&&_appArr!=nil){
            separateLine.hidden=NO;
            separatorImgView.hidden=NO;
            [appTableVC reloadAppTableView:_appArr withFromSource:DETAIL(_fromSource)];
        }else{
            separateLine.hidden=YES;
            separatorImgView.hidden=YES;
        }
    }else{
        separateLine.hidden=YES;
        separatorImgView.hidden=YES;
    }
}

-(void)requestActivityDetailWidhId:(NSInteger)activityId appId:(NSString *)appId
{
    // 请求
    uniqueIdentifier = [NSString stringWithFormat:@"%ld_%@",(long)activityId,appId];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
    });
    
    _backView.status = Loading;
}

-(void)loadWebView:(NSURL *)url withType:(WebViewType)type
{
    if (type == activity_Type) {
        activityRequest = [ASIHTTPRequest requestWithURL:url];
        [activityRequest setTimeOutSeconds:60.0f];
        [activityRequest setDelegate:self];
        activityRequest.tag = type;
        [activityRequest setDidFailSelector:@selector(webViewRequestFailed:)];
        [activityRequest setDidFinishSelector:@selector(webViewRequestSuccess:)];
        // 缓存策略
        [activityRequest setDownloadCache:[ASIDownloadCache sharedCache]];
        [activityRequest setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
        [activityRequest setDownloadDestinationPath:[[ASIDownloadCache sharedCache] pathToStoreCachedResponseDataForRequest:activityRequest]];
        [activityRequest startAsynchronous];
    }
    else if(type == argument_Type)
    {
        argumentRequest = [ASIHTTPRequest requestWithURL:url];
        [argumentRequest setTimeOutSeconds:60.0f];
        [argumentRequest setDelegate:self];
        argumentRequest.tag = type;
        [argumentRequest setDidFailSelector:@selector(webViewRequestFailed:)];
        [argumentRequest setDidFinishSelector:@selector(webViewRequestSuccess:)];
        // 缓存策略
        [argumentRequest setDownloadCache:[ASIDownloadCache sharedCache]];
        [argumentRequest setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
        [argumentRequest setDownloadDestinationPath:[[ASIDownloadCache sharedCache] pathToStoreCachedResponseDataForRequest:argumentRequest]];
        [argumentRequest startAsynchronous];
    }
}

#pragma mark - Utility

-(void)showLoadingView
{
    _backView.status = Loading;
}

-(void)showFailedView
{
    _backView.status = Failed;
}


-(void)hideAllView
{
    _backView.status = Hidden;
}

-(void)hideAppTableViewUtility:(BOOL)flag
{
    separatorImgView.hidden = flag;
    [self setCustomFrame];
}

-(void)setCustomFrame
{
    CGRect rect = [UIScreen mainScreen].bounds;
//    CGFloat topHeight = IOS7?64:0;
    // webView
    activityWeb.frame = CGRectMake(0, 20, rect.size.width, activityHeight - 44);
    
    // download Tableview
    separateLine.frame = CGRectMake(10, activityWeb.frame.origin.y+activityWeb.frame.size.height+15, MainScreen_Width-20, 0.5);
    separatorImgView.frame = CGRectMake(separateLine.frame.origin.x, separateLine.frame.origin.y+13, 159, 16);
    appTableVC.collectionView.frame = CGRectMake(0, separatorImgView.frame.origin.y+separatorImgView.frame.size.height+3+offset_appTableView, rect.size.width, 212/2*MULTIPLE*_appArr.count+100);
    //    NSLog(@"----%f,----%f",appTableVC.collectionView.frame.size.height,212/2*MULTIPLE*_appArr.count);
    // mainScrollView
    mainScrollView.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
    mainScrollView.contentSize = CGSizeMake(rect.size.width, 64+activityWeb.frame.size.height+height_tableTop+appTableVC.collectionView.frame.size.height*MULTIPLE+50);
}

-(void)resetPraiseButtonState
{
    
}

-(void)refreshDetailView
{
    // 请求数据
    
    [self reloadActivityDetailVC:self.detailDic];
    //    NSString *appId = [_detailDic objectForKey:@"appid"];
    //    NSString *acId  = [_detailDic objectForKey:@"huodong_id"];
    //    if (acId == nil) { // 区分lunbo id
    //        acId = [_detailDic objectForKey:@"id"];
    //    }
    //
    //    if (appId && ![appId isEqualToString:@""]) {
    //        [self requestActivityDetailWidhId:[acId intValue] appId:[_detailDic objectForKey:@"appid"]];
    //    }
    //    else
    //    {
    //        [self requestActivityDetailWidhId:[acId intValue] appId:@""];
    //    }
    
}

-(void)stopLoadingAndClearCache
{
    // ASIHttpRequest
    [activityRequest clearDelegatesAndCancel];
    [argumentRequest clearDelegatesAndCancel];
    
    // 内容WebView
    [activityWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    //[activityWeb loadHTMLString:@"" baseURL:nil];
    [activityWeb stopLoading];
    [activityWeb setDelegate:nil];
    [activityWeb removeFromSuperview];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    NSHTTPCookie *cookie;
    for (cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

-(void)backFindVC
{
    [self.navigationController popViewControllerAnimated:YES];
    //    [self hideNavBottomBar:NO];
    
    [self removeObserverAndListener]; // 移除监听释放本类
    
}

-(void)removeObserverAndListener
{ // 移除observer 和 listener 为了系统调用dealloc
    if (!hasRemoveFlag) {
        hasRemoveFlag = YES;
        [activityWeb.scrollView removeObserver:self forKeyPath:@"contentSize" context:@"content"];
        [self removeObserver:self forKeyPath:@"zanArray"];
    }
}

-(void)resetWebViewFrame
{
    activityHeight = 100;
    argumentHeight = 100;
    [self setCustomFrame];
}

-(void)webViewRequestFailed:(ASIHTTPRequest *)theRequest
{
    if (theRequest.tag == activity_Type) {
        _backView.status = Failed;
    }
}

-(void)webViewRequestSuccess:(ASIHTTPRequest *)theRequest
{
    NSString *response = [NSString stringWithContentsOfFile:[theRequest downloadDestinationPath] encoding:NSUTF8StringEncoding error:nil];
    
    if (theRequest.tag == activity_Type) {
        [activityWeb loadHTMLString:response baseURL:[theRequest url]];
        
        // 加载成功去掉数据
        [self performSelector:@selector(hideAllView) withObject:nil afterDelay:1.0f];
        
        //导航按钮状态
        [navBar praiseAndShareButtonSelectEnable:YES];
        
        // 该活动已被查看
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        });
    }
    else if (theRequest.tag == argument_Type)
    {
    }
    
    
}

#pragma mark - 曝光度

-(void)reportBaoGuangAboutAppsByOffset:(CGFloat)offset
{
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat topHeight = (IOS7)?64:44;
    CGFloat visibleHeight = screenHeight-topHeight-BOTTOM_HEIGHT;
    CGFloat appOriY = appTableVC.collectionView.frame.origin.y;
    
    if (appOriY < visibleHeight+topHeight) {
        [self setVisibleAppsReportArray]; // 设置reportArray
        long sourceIndex = -1;
        [[ReportManage instance] reportAppBaoGuang:DEVELOPER_OTHER_APP([self.detailDic objectForKey:@"id"], sourceIndex) appids:reportArray digitalIds:nil];
        
    }
    else if (offset>(appOriY-visibleHeight-topHeight))
    {
        [self setVisibleAppsReportArray];
        long sourceIndex = -1;
        [[ReportManage instance] reportAppBaoGuang:DEVELOPER_OTHER_APP([self.detailDic objectForKey:@"id"], sourceIndex) appids:reportArray digitalIds:nil];
    }
}

-(void)setVisibleAppsReportArray
{
    [reportArray removeAllObjects];
    
    for (NSDictionary *dic in _appArr) {
        [reportArray addObject:[dic objectForKey:@"appid"]];
    }
}

#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( [(__bridge NSString *)context isEqualToString:@"content"] && [keyPath isEqualToString:@"contentSize"]) {
        activityHeight = activityWeb.scrollView.contentSize.height;
        [self setCustomFrame];
    }
    
    [_zanArray writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/zan.plist"] atomically:YES];
    
}

#pragma mark - UIScrollViewDelegate

static bool _deceler = false;
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (scrollView.decelerating) _deceler = true;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate && _deceler==false && _appArr.count!=0) {
        [self reportBaoGuangAboutAppsByOffset:scrollView.contentOffset.y];
    }
    
    _deceler = false;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (_appArr.count != 0) {
        [self reportBaoGuangAboutAppsByOffset:scrollView.contentOffset.y];
    }
}

#pragma mark - UIWebViewDelegate
-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    // 禁用用户选择
    //    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    // 禁用长按弹出框
    //    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    
    //
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)hideNavBottomBar:(BOOL)flag
{
    self.navigationController.navigationBar.hidden = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:HIDETABBAR object:(flag?@"yes":nil)];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString* currentUrl = request.URL.absoluteString;
    
    if ([currentUrl hasPrefix:@"callios:getappstate"]) {
        
        NSArray *array = [currentUrl componentsSeparatedByString:@":"];
        if ([array isKindOfClass:[NSArray class]] && array.count > 2) {
            
            
            NSInteger imageIndex = [array[2] integerValue];
            
            index = 0;
            self.itemArray = [[FileUtil instance] AnalyticalImage:self.content];
            
            if (self.itemArray.count > 0) {
                
                
                
                if (imageIndex >= self.itemArray.count) {
                    imageIndex = self.itemArray.count -1;
                }
                
                findPicVC.currentIndex = imageIndex;
                
                [findPicVC setCollectItems:self.itemArray index:imageIndex];
                [self.navigationController pushViewController:findPicVC animated:NO];
                [[UIApplication sharedApplication] setStatusBarHidden:YES];
                //                [self hideNavBottomBar:YES];
            }
        }
        
    }
    
    BOOL refreshFlag = YES;
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        UIWebViewController *webVC = [[UIWebViewController alloc] init];
        [webVC navigation:request.URL.absoluteString];
        [self.navigationController pushViewController:webVC animated:YES];
        //
        refreshFlag = NO;
    }
    
    return refreshFlag;
}

#pragma mark - ArgumentViewDelegate

-(void)argumentViewChangeHeight:(CGFloat)height
{
    CGFloat maxHeight = MainScreeFrame.size.height-64-BOTTOM_HEIGHT+10;
    if (height > maxHeight) {
        argumentHeight = maxHeight;
    }
    
    [self setCustomFrame];
}

#pragma mark - 数据验证

-(BOOL)checkAppArray:(NSArray *)appArray
{
    BOOL arrayFlag = NO;
    if (IS_NSARRAY(appArray)) {
        if (appArray.count == 0) {
            arrayFlag = YES;
        }
        else if (appArray.count > 0)
        {
            for (id obj in appArray) {
                if (IS_NSDICTIONARY(obj)) {// 是个字典
                    if ([obj getNSStringObjectForKey:@"appdowncount"] &&
                        [obj getNSStringObjectForKey:@"appiconurl"] &&
                        [obj getNSStringObjectForKey:@"appid"] &&
                        [obj getNSStringObjectForKey:@"appintro"] &&
                        [obj getNSStringObjectForKey:@"appname"] &&
                        [obj getNSStringObjectForKey:@"appreputation"] &&
                        [obj getNSStringObjectForKey:@"appsize"] &&
                        [obj getNSStringObjectForKey:@"appupdatetime"] &&
                        [obj getNSStringObjectForKey:@"appversion"] &&
                        [obj getNSStringObjectForKey:@"category"] &&
                        [obj getNSStringObjectForKey:@"ipadetailinfor"] &&
                        [obj getNSStringObjectForKey:@"plist"] &&
                        [obj getNSStringObjectForKey:@"share_url"]) {
                        arrayFlag = YES;
                    }
                }
                else
                {
                    arrayFlag = NO;
                    break;
                }
            }
        }
    }
    
    return arrayFlag;
}

-(BOOL)checkData:(NSDictionary *)dataDic
{
    BOOL typeFlag = NO;
    NSDictionary *tmpDic = [dataDic getNSDictionaryObjectForKey:@"data"];
    
    if (tmpDic) {
        
        if ([tmpDic getNSStringObjectForKey:@"content"] &&
            [tmpDic getNSStringObjectForKey:@"comment"] &&
            [tmpDic getNSStringObjectForKey:@"content_url_open_type"] &&
            [tmpDic getNSStringObjectForKey:@"share_word"] &&
            [self checkAppArray:[tmpDic objectForKey:@"app"]]) {
            typeFlag = YES;
        }
    }
    
    return typeFlag;
}

#pragma mark - marketSearchManageDelegate
//栏目-发现-活动详情请求成功
- (void)discoverActivityDetailRequestSucess:(NSDictionary*)dataDic testEvaluationID:(int)testEvaluationID appid:(NSString*)appid userData:(id)userData
{
    if ([userData isEqualToString:uniqueIdentifier]) {
        
        if ([self checkData:dataDic]) {
            self.appArr = [[dataDic objectForKey:@"data"] objectForKey:@"app"];
            self.share_word = [[dataDic objectForKey:@"data"]objectForKey:@"share_word"];
            self.contentUrl = [[dataDic objectForKey:@"data"] objectForKey:@"content"];
            NSString *argumentUrl = [[dataDic objectForKey:@"data"] objectForKey:@"comment"];
            
            BOOL flag = NO;
            if (_appArr.count==0 || _appArr==nil) { // 数据为空隐藏TableView上的提示图片、分割线、argumentView.frame.origin.y变小
                offset_appTableView = -48.0f;
                height_tableTop = 0;
                flag = YES;
            }
            else
            {
                offset_appTableView = 0.0f;
                height_tableTop = 48;
                flag = NO;
            }
            [self hideAppTableViewUtility:flag];
            
            // 网页请求
            if (_contentUrl) { // 内容页
                [self loadWebView:[NSURL URLWithString:_contentUrl] withType:activity_Type];
            }
            if (argumentUrl) { // 评论页
                [self loadWebView:[NSURL URLWithString:argumentUrl] withType:argument_Type];
            }
            
            // 相关应用页
            if (IS_NSARRAY([[dataDic objectForKey:@"data"] objectForKey:@"apps"])) {
                [appTableVC reloadAppTableView:_appArr withFromSource:DETAIL(_fromSource)];
            }
        }
        else
        {
            _backView.status = Failed;
        }
        
    }
}

//栏目-发现-活动详情请求失败
- (void)discoverActivityDetailRequestFail:(int)testEvaluationID appid:(NSString*)appid userData:(id)userData;
{
    //导航按钮状态
    [navBar praiseAndShareButtonSelectEnable:NO];
    //动画处理
    [self showFailedView];
}

-(void)discoverTestEvaluationDetailRequestSucess:(NSDictionary *)dataDic testEvaluationID:(int)testEvaluationID appid:(NSString *)appid userData:(id)userData
{
}

#pragma mark - AppTableViewDelegate
-(void)appTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // 汇报点击
    
    //    [[ReportManage instance] reportAppDetailClick:DETAIL(_fromSource) contentDic:_appArr[indexPath.row]];
    
}

#pragma mark - Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    if (IOS7) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    
    findPicVC = [[FindPicInfoViewController alloc] init];
    findPicVC.delegate = self;
    
    // 设置网页默认高度
    [self resetWebViewFrame];
    
    hasRemoveFlag = NO;
    //    [self initNavButton];
}
-(void)initNavButton{
    UIView*view =[[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-49, MainScreen_Width, 49)];
    view.backgroundColor=[UIColor colorWithRed:236.f/255 green:236.f/255 blue:236.f/255 alpha:1];
    [self.view addSubview:view];
    UIImageView*backimage=[[UIImageView alloc] initWithFrame:CGRectMake(0,0, MainScreen_Width, 0.5)];
    backimage.backgroundColor=hllColor(188, 188, 188, 1);
    
    UIImageView*navimage=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, MainScreen_Width, 44)];
    navimage.image=[UIImage imageNamed:@"nav_find"];
    
    UIButton*backBtn=[[UIButton alloc] initWithFrame:CGRectMake(15*MULTIPLE,0, 50,self.view.frame.size.height)];
    backBtn.backgroundColor=[UIColor clearColor];
    backBtn.tag=71;
    [backBtn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    returnBtn=[[UIButton alloc] initWithFrame:CGRectMake(15*MULTIPLE, 10, 26/2*MULTIPLE,52/2*MULTIPLE )];
    returnBtn.backgroundColor=[UIColor clearColor];
    returnBtn.tag=71;
    [returnBtn setImage:[UIImage imageNamed:@"back-gray"] forState:UIControlStateNormal];
    [returnBtn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton*backArticleBtn=[[UIButton alloc] initWithFrame:CGRectMake(MainScreen_Width-50*MULTIPLE,0, 50,view.frame.size.height)];
    backArticleBtn.backgroundColor=[UIColor clearColor];
    backArticleBtn.tag=72;
    [backArticleBtn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    ReportArticleBtn=[[UIButton alloc] initWithFrame:CGRectMake(MainScreen_Width-50*MULTIPLE, 10, 23*MULTIPLE, 26*MULTIPLE)];
    ReportArticleBtn.backgroundColor=[UIColor clearColor];
    ReportArticleBtn.adjustsImageWhenHighlighted = NO;
    ReportArticleBtn.enabled=YES;
    ReportArticleBtn.tag=72;
    
    UIImage*image = [self.zanArray containsObject:[_detailDic objectForKey:@"id"]] ? [UIImage imageNamed:@"praise_selected"]:[UIImage imageNamed:@"praise"] ;
    
    [ReportArticleBtn setImage:image forState:UIControlStateNormal];
    [ReportArticleBtn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:returnBtn];
    [view addSubview:ReportArticleBtn];
    
    _zanLable=[[UILabel alloc] initWithFrame:CGRectMake(ReportArticleBtn.frame.origin.x+20*MULTIPLE-2, 6*MULTIPLE, 20*MULTIPLE, 15*MULTIPLE)];
    _zanLable.textColor =[UIColor whiteColor];
    _zanLable.font = [UIFont systemFontOfSize:12.0f*MULTIPLE];
    _zanLable.backgroundColor = hllColor(188,188,188,1);
    _zanLable.textAlignment=NSTextAlignmentCenter;
    _zanLable.text=@"+1";
    _zanLable.layer.cornerRadius = 5;
    _zanLable.layer.masksToBounds = YES;
    _zanLable.hidden=YES;
    [view addSubview:_zanLable];
    [view addSubview:backimage];
    [view addSubview:backBtn];
    [view addSubview:backArticleBtn];
    [self.view addSubview:navimage];
    
}
- (NSMutableArray *)zanArray{
    
    NSMutableArray*ary=[NSMutableArray arrayWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/zan.plist"]];
    if (ary==nil) {
        [ary writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/zan.plist"] atomically:YES];
        
    }
    
    
    
    if (_zanArray) return _zanArray;
    
    _zanArray = [NSMutableArray arrayWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/zan.plist"]];
    
    if (!_zanArray) _zanArray = [NSMutableArray new];
    
    [self addObserver:self forKeyPath:@"zanArray" options:NSKeyValueObservingOptionNew context:nil];
    
    return _zanArray;
}

- (void)buttonClick:(UIButton *)btn{
    
    if (btn.tag==71) {
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    if (btn.tag==72) {
        [self clickzan];
        
    }
    
}

- (void)clickzan{
    
    if (!_detailDic) return;
    if (![self.zanArray containsObject:[_detailDic objectForKey:@"id"]]) {
        [[self mutableArrayValueForKey:@"zanArray"] addObject:[_detailDic objectForKey:@"id"]];
        NSString *source =@"kyclient_developer_Zan_";
        _zanLable.hidden=NO;
        //赞 点击曝光
        [[ReportManage instance] reportDiscoveryDetailRecommend:source appid:[_detailDic objectForKey:@"id"]];
        
        UIImage*image = [self.zanArray containsObject:[_detailDic objectForKey:@"id"]] ? [UIImage imageNamed:@"praise_selected"]:[UIImage imageNamed:@"praise"] ;
        
        [ReportArticleBtn setImage:image forState:UIControlStateNormal];
    }
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIImage*image = [self.zanArray containsObject:[_detailDic objectForKey:@"id"]] ? [UIImage imageNamed:@"praise_selected"]:[UIImage imageNamed:@"praise"] ;
    if ([self.zanArray containsObject:[_detailDic objectForKey:@"id"]]) {
        _zanLable.hidden=NO;
    }
    [ReportArticleBtn setImage:image forState:UIControlStateNormal];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //    [[NSNotificationCenter defaultCenter] postNotificationName:HIDETABBAR object:(@"yes")];
    //
    [self resetPraiseButtonState];
    if (IOS7) {
        //开启iOS7的滑动返回效果
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self removeObserverAndListener]; // 移除监听释放本类（解决反动返回不释放本类的问题）
    //    [self hideNavBottomBar:NO];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // 本页面网页停止加载并置空
    [activityWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    [activityWeb stopLoading];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    // UI
    [self resetWebViewFrame];
    _backView.status = Failed;
    //    NSLog(@"详情界面 内存警告 停止加载并置空");
}

-(void)dealloc
{
    //
    navBar = nil;
    // 文章
    [self stopLoadingAndClearCache];
    
    activityRequest = nil;
    argumentRequest = nil;
    
    activityWeb.delegate = nil;
    activityWeb = nil;
    // 评论
    //    argumentVC = nil;
    
    // 应用页及详情
    separateLine = nil;
    separatorImgView = nil;
    appTableVC = nil;
    //    appDetailVC = nil;
    
    mainScrollView = nil;
    _backView = nil;
    // 数据源
    self.appArr = nil;
    self.detailDic = nil;
    self.fromSource = nil;
    reportArray = nil;
}

- (void)clickFindWebYulanBackButton{
    [self.navigationController popViewControllerAnimated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    if(IOS7){
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    //    [self hideNavBottomBar:NO];
}

@end
