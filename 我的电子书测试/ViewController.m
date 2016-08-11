//
//  ViewController.m
//  我的电子书测试
//
//  Created by apple on 16/5/30.
//  Copyright © 2016年 CHJ. All rights reserved.
//

#import "ViewController.h"

#define kTXT_allPage              @"TXT_allPage"

#define kTXT_currentPage          @"TXT_currentPage"

#define kTXT_pageCharLength       @"TXT_pageCharLength"

#define kTXT_loadCharLength       @"TXT_loadCharLength"

#define kTXT_path                 @"TXT_path"



typedef enum : NSUInteger {
    AnimalDirectionLeft,
    AnimalDirectionRight,
    AnimalDirectionUp,
    AnimalDirectionDown,

} AnimalDirection;


@interface ViewController (){
    BOOL isload;//是否是第一次加载
}

@property (nonatomic,assign)NSInteger allPage;//理想状态下的总页数
@property (nonatomic,assign)NSInteger pageCharLength;//理想状态下的每页的字数
@property (nonatomic,assign)NSInteger currentPage;//当前页
@property (nonatomic,assign)NSInteger loadCharLength;//已经记载过得总字数


@property (nonatomic,strong)NSString *content;//总内容

@property (nonatomic,strong)UITextView *textView;


@property (nonatomic,strong)NSString *fileName;//缓存每页字数的文件路径
@property (nonatomic)BOOL isLoadMore;//是否是加载更多

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    /*
     获取内容长度
     除以屏幕高度得到理想状态下的总页数
     内容长度除以总页数得到每页的理想字数
     
     加载理想字数的内容，sizetofit 得到textview的contentSize.height，和屏幕进行对比
     大于  说明字数过多，循环减一，再进行判断，直到textview的contentSize.height小于或者等于屏幕的高度，此时的字数刚刚好
     缓存每页的字数，减少cpu的资源利用
     缓存当前加载了多少字数
     
     
     加载缓存过得页面，直接从本地读取当前页面的字数，再根据本地的一共加载的字数进行判断处理
     
     上一个页面，就是一共加载的字数-当前页面的字数-上一个页面的字数=form
     
     */
    
    
  
    isload=YES;
    
    _isLoadMore=YES;
    _fileName=[[NSString alloc]init];
    
    //创建本地字数缓存文件
    [self creatPlist];
    
    
    NSString *path=[[NSBundle mainBundle]pathForResource:@"book" ofType:@"txt"];
    
    _content=[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    
    
   if([[NSUserDefaults standardUserDefaults] integerForKey:kTXT_allPage] == 0) {
        //第一次进入 保存信息
      
        CGSize size=[_content boundingRectWithSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height-20) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]} context:nil].size;
        
        CGFloat Page=size.height/(self.view.frame.size.height-20);
        
        //总页数
        _allPage=(NSInteger)Page+1;
        
        //理想状态下每页的字符个数
        _pageCharLength=_content.length/self.allPage;
        
        //当前页数
        _currentPage=1;
       
    
        [[NSUserDefaults standardUserDefaults] setInteger:_allPage forKey:kTXT_allPage];
        [[NSUserDefaults standardUserDefaults] setInteger:_pageCharLength forKey:kTXT_pageCharLength];
        [[NSUserDefaults standardUserDefaults] setInteger:_currentPage forKey:kTXT_currentPage];

       

    }
    
    
    _allPage=[[NSUserDefaults standardUserDefaults] integerForKey:kTXT_allPage];
    _pageCharLength=[[NSUserDefaults standardUserDefaults] integerForKey:kTXT_pageCharLength];
    _currentPage=[[NSUserDefaults standardUserDefaults] integerForKey:kTXT_currentPage];
    _loadCharLength=[[NSUserDefaults standardUserDefaults] integerForKey:kTXT_loadCharLength];

    _textView=[[UITextView alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height-20)];
    [self.view addSubview:_textView];
    _textView.editable=NO;
    _textView.font=[UIFont systemFontOfSize:15];
    [self loadTxt];
    
//    UIButton *btn_pervious=[[UIButton alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-44, 60, 44)];
//    [self.view addSubview:btn_pervious];
//    [btn_pervious setTitle:@"上一页" forState:UIControlStateNormal];
//    btn_pervious.titleLabel.textAlignment=NSTextAlignmentLeft;
//    [btn_pervious addTarget:self action:@selector(perviousAction) forControlEvents:UIControlEventTouchUpInside];
//    [btn_pervious setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//    
//    
//    UIButton *btn_next=[[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width-60, self.view.frame.size.height-44, 60, 44)];
//    [self.view addSubview:btn_next];
//    [btn_next setTitle:@"下一页" forState:UIControlStateNormal];
//    btn_next.titleLabel.textAlignment=NSTextAlignmentRight;
//    [btn_next addTarget:self action:@selector(nextAction) forControlEvents:UIControlEventTouchUpInside];
//    [btn_next setTitleColor:[UIColor redColor] forState:UIControlStateNormal];

    
    UISwipeGestureRecognizer *swipeGestureleft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeGestureLeft:)];
    [_textView addGestureRecognizer:swipeGestureleft];
    swipeGestureleft.direction=UISwipeGestureRecognizerDirectionLeft;
    
    UISwipeGestureRecognizer *swipeGestureright=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeGestureRight:)];
    [_textView addGestureRecognizer:swipeGestureright];
    swipeGestureright.direction=UISwipeGestureRecognizerDirectionRight;

}


- (void)loadTxt {
    
    NSLog(@"_loadCharLength   %ld",_loadCharLength);
   __block NSInteger length=_pageCharLength;

    //加载更多--》下一个页面
    if (_isLoadMore) {
        //加载txt
        
        
        //是否加载过
      __block  NSDictionary* dic2 = [NSDictionary dictionaryWithContentsOfFile:_fileName];

        
        //加载已经加载过得页面
        if ([[dic2 allKeys] containsObject:[NSString stringWithFormat:@"%ld",_currentPage]]) {
            
            
            
            NSNumber *number1=[dic2 objectForKey:[NSString stringWithFormat:@"%ld",_currentPage]];
            
            NSString *loadContent;
            
            
            //刚刚进入程序，加载最后一页的txt。总字数不变，什么都不变也不存储
            
            if (isload) {
                loadContent=[_content substringWithRange:NSMakeRange(_loadCharLength-number1.integerValue,number1.integerValue)];

            }else{
                
                //加载已经加载过的页面，由于返回上一个页面的时候总字数已经减少，所有重新加载下一页的数据需要改变总字数
                
                loadContent=[_content substringWithRange:NSMakeRange(_loadCharLength,number1.integerValue)];

                _loadCharLength=_loadCharLength+number1.integerValue;
                
                [[NSUserDefaults standardUserDefaults] setInteger:_loadCharLength forKey:kTXT_loadCharLength];

            }
            _textView.text=loadContent;

            
        }else{
            //加载没有加载过的页面
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                /*
                加载理想字数的内容，sizetofit 得到textview的contentSize.height，和屏幕进行对比
                大于  说明字数过多，循环减一，再进行判断，直到textview的contentSize.height小于或者等于屏幕的高度，此时的字数刚刚好
                 
                 缓存总字数
                 
                */
                
                do {
                    
                    NSString *loadContent=[_content substringWithRange:NSMakeRange(_loadCharLength, length--)];
                    _textView.text=loadContent;
                    
                    [_textView sizeToFit];
                    
                    
                } while (_textView.contentSize.height >= self.view.frame.size.height-20);
                
                
                
                _loadCharLength=_loadCharLength+length;

                
                
                [[NSUserDefaults standardUserDefaults] setInteger:_loadCharLength forKey:kTXT_loadCharLength];
                
                
                
                
                [dic2 setValue:[NSNumber numberWithInteger:length] forKey:[NSString stringWithFormat:@"%ld",_currentPage]];
                
                
                [dic2 writeToFile:_fileName atomically:YES];
                
                
            });

        }
        
        
        
      
    }else{
        //上一页txt  加载已经加载过得数据
        NSDictionary* dic2 = [NSDictionary dictionaryWithContentsOfFile:_fileName];
        
        
        //直接读取当前页和上一个页面的字数
        
        NSNumber *number=[dic2 objectForKey:[NSString stringWithFormat:@"%ld",_currentPage]];
        NSNumber *number1=[dic2 objectForKey:[NSString stringWithFormat:@"%ld",_currentPage+1]];

        
        //通过加载的总字数和上面两个字数  进行判断
        
        
        NSString *loadContent=[_content substringWithRange:NSMakeRange(_loadCharLength-number.integerValue-number1.integerValue,number.integerValue)];
        _textView.text=loadContent;
                
        
        
        //总的字数减少  保存
        _loadCharLength =_loadCharLength-number1.integerValue;
        
        
        [[NSUserDefaults standardUserDefaults] setInteger:_loadCharLength forKey:kTXT_loadCharLength];

    }
    
    
    [[NSUserDefaults standardUserDefaults] setInteger:_currentPage forKey:kTXT_currentPage];

    
    isload=NO;
}




- (void)creatPlist {
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *path=[paths lastObject];
    
    
    _fileName=[path stringByAppendingPathComponent:@"test.plist"];
    
    NSFileManager *fm=[NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:_fileName]) {
        BOOL isSuccess=[fm createFileAtPath:_fileName contents:nil attributes:nil];
        
        if (isSuccess) {
            NSLog(@"创建成功");
        }else
            NSLog(@"创建失败");
        
        NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"0",nil];
        
        [dic writeToFile:_fileName atomically:YES];
        
        [[NSUserDefaults standardUserDefaults] setValue:_fileName forKey:kTXT_path];

    }
    

 
}







//上一页
- (void)perviousAction {
    if (_currentPage == 1) {
        return;
    }
    
    _isLoadMore=NO;

    _currentPage--;
    
    //想右平滑返回
    [self reloadTXTSource:AnimalDirectionLeft];
    
    
    
    
    //[self reloadTXTSourceAnimal:AnimalDirectionLeft];
}

//下一页
- (void)nextAction {
    if (_loadCharLength == _content.length) {
        return;
    }
    _isLoadMore=YES;

    _currentPage++;
    
    //想左平滑加载
    [self reloadTXTSource:AnimalDirectionRight];

    
    
    //[self reloadTXTSourceAnimal:AnimalDirectionRight];

}


//手势触发 向左轻扫 下一页
- (void)swipeGestureLeft:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"UISwipeGestureRecognizerDirectionLeft");
   
    [self nextAction];

}
//手势触发 向右轻扫 上一页
- (void)swipeGestureRight:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"UISwipeGestureRecognizerDirectionRight");
    
    [self perviousAction];

}





/**
 *  动画效果-->左右平滑
 *
 *  @return 动画方向
 */

//刷新textview数据   左右平滑返回或加载
- (void)reloadTXTSource:(AnimalDirection)direction {
    
    
    CATransition *animal=[CATransition animation];
    animal.duration=0.5f;
    animal.type=kCATransitionReveal;
    

    switch (direction) {
        case AnimalDirectionLeft:
            animal.subtype=kCATransitionFromLeft;

            break;
        case AnimalDirectionRight:
            animal.subtype=kCATransitionFromRight;
            
            break;
        case AnimalDirectionUp:
            animal.subtype=kCATransitionFromTop;
            
            break;
        case AnimalDirectionDown:
            animal.subtype=kCATransitionFromBottom;
            
            break;
            
        default:
            break;
    }
    
    /*
    _textView.text=[_content substringWithRange:NSMakeRange((_currentPage-1)*_pageCharLength, _pageCharLength)];
    
    
    [_textView sizeToFit];
    
    NSLog(@"_textView  %@",_textView);
     */
     
     
    [self loadTxt];
    
    [_textView.layer addAnimation:animal forKey:nil];

}

- (void)reloadTXTSourceAnimal:(AnimalDirection)direction {
    
    [UIView beginAnimations:@"animal" context:nil];
    
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];

    switch (direction) {
        case AnimalDirectionLeft:
            [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:_textView cache:YES];
            
            break;
        case AnimalDirectionRight:
            [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:_textView cache:YES];
            
            break;
            
        default:
            break;
    }
    
    _textView.text=[_content substringWithRange:NSMakeRange((_currentPage-1)*_pageCharLength, _pageCharLength)];

    [UIView commitAnimations];
    

}









- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
