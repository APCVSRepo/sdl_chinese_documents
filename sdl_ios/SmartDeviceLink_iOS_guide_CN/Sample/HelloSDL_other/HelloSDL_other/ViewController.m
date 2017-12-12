//
//  ViewController.m
//  HelloSDL_other
//
//  Created by 鲁超 on 2017/12/7.
//  Copyright © 2017年 鲁超. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openUIAlert:) name:@"SDL_UIALERT" object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openUIAlert:(NSNotification*)notification {
    NSString* message = [notification object];
    
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"HelloSDL" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
