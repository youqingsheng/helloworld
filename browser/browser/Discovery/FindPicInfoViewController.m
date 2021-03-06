//
//  FindPicInfoViewController.m
//  browser
//
//  Created by mahongzhi on 14-10-23.
//
//

#import "FindPicInfoViewController.h"

#define FAIL_RETRY_CONT       2

@interface FindPicInfoViewController (){

    
    //后退按钮
    UIImageView *backSubview;
    //设置按钮
    UIImageView *downloadSubview;
    
    
}

@end


@implementation FindPicInfoViewController

- (id)init{
    self = [super init];
    if (self) {
        photosAlbumManager = [[PhotosAlbumManager alloc] initWithDelegate:self];
    }
    return self;
}

#pragma mark - view life
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //移除导航的右滑返回手势
    
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    //重新添加导航的右滑返回手势
}

- (void)viewDidLoad {
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
    _collectView.showsHorizontalScrollIndicator = NO;
    _collectView.pagingEnabled = YES;
    [self.view addSubview:_collectView];
    _collectView.scrollEnabled = YES;
    
    _yulanView = [YulanPageView new];
    _yulanView.delegate = self;
    _yulanView.hidden = YES;
    [self.view addSubview:_yulanView];
    
    
    //后退按钮
    backSubview = [UIImageView new];
    backSubview.backgroundColor = [UIColor clearColor];
    backSubview.userInteractionEnabled = YES;
    SET_IMAGE(backSubview.image, @"bizhiBack.png");
    [self.view addSubview:backSubview];
    
    
    //设置按钮
    downloadSubview = [UIImageView new];
    downloadSubview.backgroundColor = [UIColor clearColor];
    downloadSubview.userInteractionEnabled = YES;
    SET_IMAGE(downloadSubview.image, @"setBizhi.png");
    [self.view addSubview:downloadSubview];
    
    
    UITapGestureRecognizer * tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickBackSubView)];
    [backSubview addGestureRecognizer:tap1];
    
    UITapGestureRecognizer * tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickDownlaodSubView)];
    [downloadSubview addGestureRecognizer:tap2];
    
    
    
    backSubview.frame = CGRectMake((self.view.frame.size.width/2 - 60)/2, MainScreen_Height - 20 - 72.0, 60, 60);
    downloadSubview.frame = CGRectMake((self.view.frame.size.width/2 - 60)/2 + self.view.frame.size.width/2, MainScreen_Height - 20 - 72.0, 60, 60);
    _yulanView.frame = self.view.bounds;
    
    
    //注册cell
    [_collectView registerClass:[FindPicInfoCollectionViewCell class] forCellWithReuseIdentifier:@"MY_CELL"];
    
    [_collectView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    
    
    
}

//点击了壁纸详情的返回按钮
- (void)clickBackSubView{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(clickFindWebYulanBackButton)]) {
            [self.delegate clickFindWebYulanBackButton];
        }
    });
    
}
//点击了壁纸详情的下载按钮
- (void)clickDownlaodSubView{
    
    if ([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:_currentbigImageUrl]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"设置" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"保存到相簿", nil];
        
        [actionSheet showInView:self.view];
    }
    
}
#pragma mark -
#pragma mark actionsheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if(ALAuthorizationStatusDenied == author){ //用户拒绝
        
        UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"访问相册失败"
                                                               message:@"请在\"设置-->隐私-->照片\"中\"应用宝贝\"对应的开关调为打开状态，再次尝试保存即可"
                                                              delegate:nil
                                                     cancelButtonTitle:@"确定"
                                                     otherButtonTitles:nil, nil];
        [tmpAlertView show];
        return ;
        
    }else if(ALAuthorizationStatusAuthorized == author){ //用户同意
        
        [self actionSheet_:actionSheet clickedButtonAtIndex:buttonIndex];
        
    }else if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) { //提示用户选择
        
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if(group == nil){
//                NSLog(@"nil");
                [self actionSheet_:actionSheet clickedButtonAtIndex:buttonIndex];
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
    
}
- (void)actionSheet_:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    UIImage *tempImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:_currentbigImageUrl];
    
    
    switch (buttonIndex) {
            //相册
        case 0:
            [self saveImageToImageGroup:tempImage];
            break;
        default:
            break;
    }

}

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
#pragma  mark yulanDelegate
- (void)clickFirstYulanPage:(NSInteger)index{
    _yulanView.hidden = YES;
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [collectItems count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FindPicInfoCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MY_CELL"  forIndexPath:indexPath];
    NSString * downLoadUrl = [collectItems objectAtIndex:indexPath.row];
    _currentbigImageUrl = downLoadUrl;
    UIImage * image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:downLoadUrl];
    if (image == nil) {
        [self downloadImage:cell downUrl:downLoadUrl];
    }else{
        
        [cell setCurrentBoundsToImage:image];
        [cell isProgressHidden:YES];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    return CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0.0;
}

#pragma mark -

- (void)setCollectItems:(NSMutableArray *)items index:(NSInteger)index {
    collectItems = items;
    
    [_collectView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    
    for (NSInteger objIndex = 0; objIndex < collectItems.count; objIndex++) {
        [self downloadImage:[collectItems objectAtIndex:objIndex]];
    }
}

- (void)downloadImage:(FindPicInfoCollectionViewCell*)cell downUrl:(NSString *)downUrl {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (![[SDImageCache sharedImageCache] imageFromDiskCacheForKey:downUrl]) {
            [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:downUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                if (expectedSize == 0 || receivedSize == 0) {
                    [cell setProgress:0.0];
                }else{
                    double prog = (double)receivedSize/(double)expectedSize;
                    prog = fabs(prog);
                    [cell setProgress:prog];
                }
            } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                [[SDImageCache sharedImageCache] storeImage:image forKey:downUrl];
                [cell isProgressHidden:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_collectView reloadData];
                });
            }];
        }
    });
}

- (void)downloadImage:(NSString *)downUrl{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (![[SDImageCache sharedImageCache] imageFromDiskCacheForKey:downUrl]) {
            [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:downUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                
            } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                [[SDImageCache sharedImageCache] storeImage:image forKey:downUrl];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_collectView reloadData];
                });
            }];
        }
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
