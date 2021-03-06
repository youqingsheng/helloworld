//
//  WallpaperInfoViewController.m
//  browser
//
//  Created by 王毅 on 14-8-27.
//
//

#import "WallpaperInfoViewController.h"
#import "MyNavigationController.h"
#import "UIImageEx.h"

#define FIRST_HEIGHT MainScreen_Height - 20 - 35.0
#define SECOND_HEIGHT MainScreen_Height - 20 - 15.0
#define FINISH_HEIGHT MainScreen_Height - 20 - 30.0
#define BTN_WIDTH 60
#define BTN_HEIGHT 50
#define PRE_WIDTH 40
#define PRE_HEIGHT 46.5
#define FAIL_RETRY_CONT 2
#define HIDDEN_BTN_HEIGHT MainScreen_Height + 100
#define LAST_IMAGE_IS_NOT_FINISH @"上一张图片还未完成加载，请稍候"
#define NEXT_IMAGE_IS_NOT_FINISH @"下一张图片还未完成加载，请稍候"
#define CURRENT_IMAGE_IS_NOT_FINISH @"当前图片还未加载完毕，请稍候"
#define DATA_IS_LOADING @"新数据加载中，请稍候"

@interface WallpaperInfoViewController ()<UIAlertViewDelegate>{
    //后退按钮
    UIImageView *backSubview;
    //后退按钮触点大小
    UIView *_backBackgroundView;
    //保存按钮
    UIImageView *preserveSubview;
    //保存按钮触点大小
    UIView *_preserveBackgroundView;
    //预览的伪桌面
    UIImageView *backgroundView;
    
    UIImageView *dibumengbanImageView;
    
    NSInteger firstIndex;
    
    BOOL isClickViewAgain;
    BOOL isCanRequestAgain;
    
    NSString *lastRequestUrlStr;
    
    BOOL isLastOne;
    BOOL isShowTitleLabel;
    
}
@property (nonatomic , strong) UILabel *titleLabel;
@property (nonatomic , strong) NSString *fromStr;
@property (nonatomic , strong) NSString *caozuoType;
@end

@implementation WallpaperInfoViewController

- (id)init{
    self = [super init];
    if (self) {
        
        isEnableButton = YES;
        isClickViewAgain = YES;
        isCanRequestAgain= YES;
        isLastOne = NO;
        wallManage = [DesktopViewDataManage new];
        wallManage.delegate = self;
        lastRequestUrlStr = @"";
        photosAlbumManager = [[PhotosAlbumManager alloc] initWithDelegate:self];
        

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (IOS7) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.userInteractionEnabled = YES;
    
    _layout = [[WallpaperFlowLayout alloc] init];
    _collectView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:_layout];
    //内部缩小的尺寸-上左下右
    _collectView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    _collectView.backgroundColor = [UIColor whiteColor];
    _collectView.delegate = self;
    _collectView.dataSource = self;
    _collectView.showsVerticalScrollIndicator = NO;
    _collectView.pagingEnabled = YES;
    [self.view addSubview:_collectView];
    _collectView.scrollEnabled = NO;
    
    
    dibumengbanImageView = [UIImageView new];
    SET_IMAGE(dibumengbanImageView.image, @"bizhixiamiandemengban.png");
    [self.view addSubview:dibumengbanImageView];
    //预览的伪桌面
    backgroundView = [UIImageView new];
    backgroundView.backgroundColor = [UIColor clearColor];
    NSString *devName = [[FileUtil instance] getDeviceName];
    NSString *imgName = nil;
    if (MainScreen_Height < 500) {
        imgName = @"bizhiyulan4.png";
    }else{
        if ([devName hasPrefix:@"iPhone 5"]) {
            imgName = @"bizhiyulan5.png";
        }else if ([@[@"iPhone 6", @"iPhone 6s"] containsObject:devName]){
            imgName = @"bizhiyulan6.png";
        }else if ([@[@"iPhone 6 Plus", @"iPhone 6s Plus"] containsObject:devName]){
            imgName = @"bizhiyulan6p.png";
        }
    }
    SET_IMAGE(backgroundView.image, imgName);
    
    backgroundView.alpha = 0.0;
    backgroundView.userInteractionEnabled = YES;
    [self.view addSubview:backgroundView];
    
    _yulanView = [YulanPageView new];
    _yulanView.delegate = self;
    _yulanView.hidden = YES;
    [self.view addSubview:_yulanView];
    
    _backBackgroundView = [[UIView alloc]init];
    _backBackgroundView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_backBackgroundView];
    
    //后退按钮
    backSubview = [UIImageView new];
    backSubview.userInteractionEnabled = YES;
    SET_IMAGE(backSubview.image, @"bizhiBack.png");
    [_backBackgroundView addSubview:backSubview];

    _preserveBackgroundView = [[UIView alloc]init];
    _preserveBackgroundView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_preserveBackgroundView];
    
    //保存按钮
    preserveSubview = [UIImageView new];
    SET_IMAGE(preserveSubview.image, @"Preserve.png");
    preserveSubview.userInteractionEnabled = YES;
    [_preserveBackgroundView addSubview:preserveSubview];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.backgroundColor = [UIColor colorWithRed:44.0f/255.0f green:62.0f/255.0f blue:80.0f/255.0f alpha:0.8];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont systemFontOfSize:14.0f];
    [self.view addSubview:_titleLabel];
    isShowTitleLabel = NO;
    
    UITapGestureRecognizer * tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickBackSubView)];
    [_backBackgroundView addGestureRecognizer:tap1];
    
    UITapGestureRecognizer * tap3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickPreserveSubView)];
    [_preserveBackgroundView addGestureRecognizer:tap3];
    
    UITapGestureRecognizer * tap4 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickbackgroundView)];
    [backgroundView addGestureRecognizer:tap4];
    
    UISwipeGestureRecognizer *recognizer;
    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:recognizer];
    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:recognizer];
    

    
    backgroundView.frame = CGRectMake(-2*self.view.frame.size.width, -2*self.view.frame.size.height, 5*self.view.frame.size.width, 5*self.view.frame.size.height);
    dibumengbanImageView.frame = CGRectMake(0, MainScreen_Height - 20 - 56, MainScreen_Width, 76);
    _yulanView.frame = self.view.bounds;
    
    _backBackgroundView.frame = CGRectMake(0, MainScreen_Height-50, 60, 50);
     backSubview.frame = CGRectMake(10, 13, 22, 22);
    
    _preserveBackgroundView.frame = CGRectMake(MainScreen_Width-60,  MainScreen_Height-50, 60, 50);
    preserveSubview.frame = CGRectMake(15, 9.5, 20, 26.5);
    _titleLabel.frame = CGRectMake(0, -100, self.view.frame.size.width, 40);
    
    //注册cell
    [_collectView registerClass:[WallpaperCollectionCell class] forCellWithReuseIdentifier:@"MY_CELL"];
    [_collectView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:firstIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];

}

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer{

//    NSLog(@"firstIndex == %ld",(long)firstIndex);
    NSString *urlStr = [[collectItems objectAtIndex:firstIndex] objectForKey:@"big"];
    if (![[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlStr]) {
        
        //告诉用户当前图片还没下完，不能滑动
        [self showTitleLabel:CURRENT_IMAGE_IS_NOT_FINISH];
        return;
    }
    
    if(recognizer.direction==UISwipeGestureRecognizerDirectionLeft) {
        if (firstIndex >= collectItems.count -1 ) {
            if (isLastOne == YES) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"当前已是最后一张壁纸" message:@"" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
                [alert show];
            }else{
                [self showTitleLabel:DATA_IS_LOADING];
                if (isCanRequestAgain == YES) {
                    isCanRequestAgain = NO;
                    [wallManage requestRecommend:_nextStr isUseCache:YES userData:self];

                }
            }
            
            return;
        }
        
        urlStr = [[collectItems objectAtIndex:firstIndex+1] objectForKey:@"big"];
        if (![[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlStr]) {
            [self showTitleLabel:NEXT_IMAGE_IS_NOT_FINISH];
            [self downloadImage:urlStr];
            //告诉用户下一张图片还没下完，不能滑动
            return;
        }
        firstIndex = firstIndex+1;
    }
    
    if(recognizer.direction==UISwipeGestureRecognizerDirectionRight) {
        if (firstIndex == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"当前已是第一张壁纸" message:@"" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        urlStr = [[collectItems objectAtIndex:firstIndex-1] objectForKey:@"big"];
        if (![[SDImageCache sharedImageCache] imageFromDiskCacheForKey:urlStr]) {
            [self showTitleLabel:LAST_IMAGE_IS_NOT_FINISH];
            //告诉用户上一张图片还没下完，不能滑动
            return;
        }
        firstIndex = firstIndex-1;
    }
    [_collectView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:firstIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    [self downloadLastAndNextImage:firstIndex];
    
}
- (void)downloadLastAndNextImage:(NSUInteger)index{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        if (index >=1) {
            [self downloadImage:[[collectItems objectAtIndex:index -1] objectForKey:@"big"]];
        }
        if (index +1 < collectItems.count){
            [self downloadImage:[[collectItems objectAtIndex:index +1] objectForKey:@"big"]];
        }
        if (index +2 < collectItems.count) {
            [self downloadImage:[[collectItems objectAtIndex:index +2] objectForKey:@"big"]];
        }
    });
}
//点击了壁纸详情的返回按钮
- (void)clickBackSubView{

    NSUInteger index = [collectItems indexOfObjectPassingTest:^ BOOL (id tr,NSUInteger index, BOOL *te){
        NSString *smallUrl = [(NSDictionary*)tr objectForKey:@"big"];
        if([smallUrl isEqualToString:_currentbigImageUrl])
        {
            return YES;
        }
        return NO;
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(notifitionInterfaceReloadArray:current:nextUrlAdress:lastRequest:)]) {
            [self.delegate notifitionInterfaceReloadArray:collectItems current:index nextUrlAdress:_nextStr lastRequest:lastRequestUrlStr];
        }
    });
    
    
}
//点击了壁纸详情的下载按钮
- (void)clickDownlaodSubView{
    
    if (isEnableButton == YES && [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:_currentbigImageUrl]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"保存到相簿",@"设置锁定屏幕",@"设定主屏幕",@"同时设定", nil];
        
        [actionSheet showInView:self.view];
    }
    
}

-(void)saveImage
{
    UIImage *tempImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:_currentbigImageUrl];
    NSString *deviceModel = [[FileUtil instance] platform];
    if ([deviceModel isEqualToString:@"iPhone6"]) {
        tempImage = [UIImage reSizeImage:tempImage toSize:CGSizeMake(750, 1334)];
    }
    
    [self saveImageToImageGroup:tempImage];
    _caozuoType = @"save";

}



//保存到相册
- (void)clickPreserveSubView{
    if (isEnableButton == YES && [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:_currentbigImageUrl]) {
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        if(ALAuthorizationStatusNotDetermined == author)
        {
            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
            [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if(group == nil){
//                    NSLog(@"nil");
                    [self saveImage];
                }
                  *stop = YES;
                
            } failureBlock:^(NSError *error) {
                //点击“不允许”回调方法
                ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
                if(ALAuthorizationStatusDenied == author){
                    UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"访问相册失败"
                                                                           message:@"请在\"设置-->隐私-->照片\"中\"应用宝贝\"对应的开关调为打开状态，再次尝试保存即可"
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"确定"
                                                                 otherButtonTitles:nil, nil];
                    [tmpAlertView show];
                    return ;
                }
            }];

            
        }
        else if(ALAuthorizationStatusDenied == author){
            //用户拒绝
            UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"访问相册失败"
                                                                   message:@"请在\"设置-->隐私-->照片\"中\"应用宝贝\"对应的开关调为打开状态，再次尝试保存即可"
                                                                  delegate:nil
                                                         cancelButtonTitle:@"确定"
                                                         otherButtonTitles:nil, nil];
            [tmpAlertView show];
        }
        else if(ALAuthorizationStatusAuthorized == author){ //用户同意
            [self saveImage];
        }
       
    }
    
    
}

//点击了伪桌面
- (void)clickbackgroundView{
    [self showyulan:NO];
}

//YES 显示伪桌面 NO 弹出底部按钮
- (void)showyulan:(BOOL)sender{
    if (isClickViewAgain == NO) {
        return;
    }
    isClickViewAgain = NO;
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(clickViewAgain:) userInfo:nil repeats:NO];
    if (sender == YES) {
        dibumengbanImageView.hidden = YES;
        [UIView animateWithDuration:0.3 animations:^(void){
            _backBackgroundView.frame = CGRectMake(0,HIDDEN_BTN_HEIGHT, 60, 50);
             _preserveBackgroundView.frame = CGRectMake(MainScreen_Width-60,HIDDEN_BTN_HEIGHT, 60, 50);
            
        } completion:^(BOOL finished){
            [self showBackGround];
        }];
        
    }else{
        dibumengbanImageView.hidden = NO;
        [self bounceOutAnimationStoped];
        [self bottomAnimate:_backBackgroundView x:0];
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(showBottomAnimate:) userInfo:@"2" repeats:NO];
        [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(showBottomAnimate:) userInfo:@"3" repeats:NO];
        
    }
    
    
}

- (void)clickViewAgain:(NSTimer*)timer{
    isClickViewAgain = YES;
}

//底部按钮的timer
- (void)showBottomAnimate:(NSTimer*)timer{
    NSString *imageStr = timer.userInfo;
    if ([imageStr isEqualToString:@"3"]) {
        [self bottomAnimate:_preserveBackgroundView x: MainScreen_Width-25-30];
    }
}

//弹出底部按钮
- (void)bottomAnimate:(UIView*)imageview x:(CGFloat)x{
    
    [UIView animateWithDuration:0.3 animations:^(void){
        imageview.frame = CGRectMake(x, FIRST_HEIGHT, BTN_WIDTH, BTN_HEIGHT);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.1 animations:^(void){
            imageview.frame = CGRectMake(x, SECOND_HEIGHT, BTN_WIDTH, BTN_HEIGHT);
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.1 animations:^(void){
                imageview.frame = CGRectMake(x, FINISH_HEIGHT, BTN_WIDTH, BTN_HEIGHT);
            } completion:^(BOOL finished){
                
            }];
            
        }];
        
    }];
}



//弹出伪桌面
- (void)showBackGround{
    
    [UIView animateWithDuration:0.3 animations:^(void){
        backgroundView.frame = self.view.bounds;
        backgroundView.alpha = 1.0;
    }
                     completion:^(BOOL finished){
                     }];
    
    
}
- (void)bounceOutAnimationStoped
{
    [UIView animateWithDuration:0.3 animations:
     ^(void){
         backgroundView.frame = CGRectMake(-2*self.view.frame.size.width, -2*self.view.frame.size.height, 5*self.view.frame.size.width, 5*self.view.frame.size.height);
         backgroundView.alpha =0.0;
     }
                     completion:^(BOOL finished){
                     }];
}

- (void)isEnableBottomButton:(BOOL)isEnable{
    isEnableButton = isEnable;
    if (isEnable) {
        backSubview.alpha = 1.0;
        preserveSubview.alpha = 1.0;
    }else{
        backSubview.alpha = 0.5;
        preserveSubview.alpha = 0.5;
    }
}

- (void)showTitleLabel:(NSString *)title{
    
    if (isShowTitleLabel == YES) {
        return;
    }
    isShowTitleLabel = YES;
    _titleLabel.text = title;
    [[UIApplication sharedApplication]setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [UIView animateWithDuration:0.3 animations:^(void){
        _titleLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 40);
    } completion:^(BOOL finished){
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(titleLabelWillHidden:) userInfo:nil repeats:NO];
    }];

}
- (void)titleLabelWillHidden:(NSTimer*)time{
    [UIView animateWithDuration:0.3 animations:^(void){
        _titleLabel.frame = CGRectMake(0, -100, self.view.frame.size.width, 40);
    } completion:^(BOOL finished){
        isShowTitleLabel = NO;
        [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }];
}


#pragma mark - view life
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //移除导航的右滑返回手势
     MyNavigationController *nav = (MyNavigationController *)(self.navigationController);
    [nav cancelSlidingGesture];
    
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //重新添加导航的右滑返回手势
    MyNavigationController *nav = (MyNavigationController *)(self.navigationController);
    [nav addSlidingGesture];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}


#pragma mark -
#pragma mark collectionviewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    return collectItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    WallpaperCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MY_CELL" forIndexPath:indexPath];
    NSDictionary *cellDic = [collectItems objectAtIndex:indexPath.row];
    cell.smallImageUrlStr = [cellDic objectForKey:@"small"];
    cell.bigImageUrlStr = [cellDic objectForKey:@"big"];
    cell.reportAddress = [cellDic objectForKey:@"down_stat"];
    _currentbigImageUrl = cell.bigImageUrlStr;
    _currentReportUrl = cell.reportAddress;
    _currentSmaillImageUrl = cell.smallImageUrlStr;
    
    if ([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:cell.bigImageUrlStr]) {
        cell.wallpaperImageView.image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:cell.bigImageUrlStr];
        [cell isProgressHidden:YES];
        [self isEnableBottomButton:YES];
    }else{
        if ([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:cell.smallImageUrlStr]) {
            cell.wallpaperImageView.image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:cell.smallImageUrlStr];
        }else{
            cell.wallpaperImageView.image = nil;
        }
        [self cellWillDownloadBigImage:cell cellIndex:indexPath.row];
        [cell isProgressHidden:NO];
        [cell setProgress:0.0];
        [self isEnableBottomButton:NO];
    }

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0.0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[[collectItems objectAtIndex:indexPath.row] objectForKey:@"big"]]) {
        [self showyulan:YES];
    }
}

#pragma mark -
#pragma mark scrollviewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

}

- (void)cellWillDownloadBigImage:(WallpaperCollectionCell*)cell cellIndex:(NSUInteger)index{

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self downloadBigImage:cell index:index];
        
            if (isCanRequestAgain == YES) {
                NSUInteger currentIndex = collectItems.count - index;
                
                if (currentIndex <= 5) {
                    isCanRequestAgain = NO;
                    [wallManage requestRecommend:_nextStr isUseCache:YES userData:self];
                }
                
            }

        
    });
}

- (void)downloadBigImage:(WallpaperCollectionCell*)cell index:(NSUInteger)index{
    if (![[SDImageCache sharedImageCache] imageFromDiskCacheForKey:cell.bigImageUrlStr]) {
        
        if (![[FileUtil instance] GetCurrntNet]) {
            
            _yulanView.hidden = NO;
            [_yulanView isShowWhatImageVIew:1 isSave:NO];
            return;
        }


        @synchronized(self) {
            
            WallpaperCollectionCell *_cell = cell;
            NSString *urlString = cell.bigImageUrlStr;
            NSUInteger _inde = index;
            
            [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:urlString] options:SDWebImageDownloaderLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                
                if (expectedSize == 0 || receivedSize == 0) {
                    [_cell setProgress:0.0];
                }else{
                    
                    double prog = (double)receivedSize/(double)expectedSize;
                    prog = fabs(prog);
                    [_cell setProgress:prog];
                }
                
            } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                
                // 错误处理
                if (!image) {
                    _yulanView.hidden = NO;
                    [_yulanView isShowWhatImageVIew:1 isSave:NO];
                    return ;
                }
                
                [[SDImageCache sharedImageCache] storeImage:image forKey:urlString];
                WallpaperCollectionCell *cell = (WallpaperCollectionCell *)[_collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_inde inSection:0]];
                cell.wallpaperImageView.image = image;
                [cell isProgressHidden:YES];
                [self isEnableBottomButton:YES];
                id obj = [[NSUserDefaults standardUserDefaults] objectForKey:@"YulanTubiao"];
                if (!obj){
                    _yulanView.hidden = NO;
                    [_yulanView isShowWhatImageVIew:0 isSave:NO];
                }
            }];
        }
        
        

      
  
    }else{
        [self isEnableBottomButton:YES];
    }
}

- (void)downloadImage:(NSString *)downUrl{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (![[SDImageCache sharedImageCache] imageFromDiskCacheForKey:downUrl]) {
                [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:downUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                    
                } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                    [[SDImageCache sharedImageCache] storeImage:image forKey:downUrl];
                    
                }];
            }
    });
}


#pragma mark -
#pragma mark actionsheetDelegate

- (void)saveImageToImageGroup:(UIImage*)image{
    
    ALBUMVISITSTATE state = [photosAlbumManager ifCanVisitTheAlbum];
    if (state==VISIABLESTATE) {
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
        _yulanView.hidden = NO;
        [_yulanView isShowWhatImageVIew:2 isSave:YES];
    }else if (state==CHOOCESTATE){
        UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"访问相册失败" message:@"请在点击允许应用宝贝访问您的相册，以便我们将图片保存到您的相册中" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [tmpAlertView show];
    }else{
        UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"访问相册失败" message:@"请在“设置-->隐私-->照片”中“应用宝贝”对应的开关调为打开状态，再次尝试保存即可" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [tmpAlertView show];
    }
    
    
    
}


#pragma mark -
//外界给壁纸详情传递数据--当前的全部壁纸数组、当前点击跳到详情的索引数、前一页的地址、后一页的地址
- (void)setCollectItems:(NSMutableArray *)items currentItme:(NSInteger)index prevAddress:(NSString*)prevStr nextAddress:(NSString*)nextStr from:(NSString*)from{
    collectItems = items;
    firstIndex = index;
    _currentbigImageUrl = [[collectItems objectAtIndex:index] objectForKey:@"big"];
    _currentSmaillImageUrl = [[collectItems objectAtIndex:index] objectForKey:@"small"];
    _currentReportUrl = [[collectItems objectAtIndex:index] objectForKey:@"down_stat"];
    _prevStr = prevStr;
    _nextStr = nextStr;
    isLastOne = NO;
    if ([nextStr isEqualToString:@""]) {
        isLastOne = YES;
    }
    
    if (from) {
        _fromStr = from;
    }else{
        _fromStr = @"";
    }
    [self downloadLastAndNextImage:firstIndex];
}

#pragma mark -
#pragma mark desktopManageDelegate
//请求数据成功
-(void)requestRecommendSucess:(NSDictionary*)saveDic requestStr:(NSString*)requestStr isUseCache:(BOOL)isUseCache userData:(id)userData{
    _prevStr = [[saveDic objectForKey:@"link"] objectForKey:@"prev"];
    _nextStr = [[saveDic objectForKey:@"link"] objectForKey:@"next"];
    
    if ([_nextStr isEqualToString:@""]) {
        isLastOne = YES;
    }
    
    lastRequestUrlStr = requestStr;
    NSArray *tmepArray = [saveDic objectForKey:@"data"];
    
    [collectItems addObjectsFromArray:tmepArray];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectView reloadData];
    });
    isCanRequestAgain = YES;
}
//请求数据失败
-(void)requestRecommendFail:(NSString*)requestStr isUseCache:(BOOL)isUseCache userData:(id)userData{
    static int count = 0;
    
    if (count >= FAIL_RETRY_CONT) {
        count = 0;
        isCanRequestAgain = YES;
        return;
    }
    
    [wallManage requestRecommend:_nextStr isUseCache:YES userData:self];
    
    count ++;
}

#pragma mark -
#pragma  mark yulanDelegate
- (void)clickFirstYulanPage:(NSInteger)index{
    _yulanView.hidden = YES;
    if (index > 0) [self showyulan:YES];

}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}


#pragma mark -
#pragma  mark 上报日志

/*
 
 保存壁纸和设置壁纸时记录
 1.保存还是设置操作
 2.保存和设置日期时间
 3.设备类型：4s 4 ，5 ，5s，5c
 4.ios系统
 5.客户端版本
 6.设置壁纸来源于推荐还是分类
 */


- (void) reportBizhi:(NSString*)from caozuoType:(NSString *)type imageUrl:(NSString *)url{
    
    NSString *_from = from;
    NSString *_caozuoType_ = type;
    NSString *_imageUrl = url;
    
    NSString *_caozuoTime = [[FileUtil instance] getSystemTime];
    NSString *_shebeiType = [[FileUtil instance] platform];
    NSString *_iOSVersion = [[UIDevice currentDevice] systemVersion];
    NSString *_clientVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    
    NSString *idfaStr = OBJ_NOT_NIL( [[FileUtil instance] getDeviceIDFA] );
    NSString *macStr = OBJ_NOT_NIL( [[FileUtil instance] macaddress] );
    
    NSString *bizhiReportStr = [NSString stringWithFormat:@"programme=mobile_nav&report=%@&imagefrom=%@&imageurl=%@&operationtime=%@&devicetype=%@&iosversion=%@&clientversion=%@&idfa=%@&devmac=%@",_caozuoType_,_from,_imageUrl,_caozuoTime,_shebeiType,_iOSVersion,_clientVersion,idfaStr,macStr];
    bizhiReportStr = [[FileUtil instance] encodeToPercentEscapeString:bizhiReportStr];
    NSString * urlString = [NSString stringWithFormat:@"http://pcdj.bppstore.com/report.php?%@",bizhiReportStr];
    
    NSURL * _url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 10;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    }];

    
    
}


- (void)dealloc{
    _collectView.delegate = nil;
    _collectView.dataSource = nil;
    _yulanView.delegate = nil;
}

@end
