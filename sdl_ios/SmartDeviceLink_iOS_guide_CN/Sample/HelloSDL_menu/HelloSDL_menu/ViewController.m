//
//  ViewController.m
//  HelloSDL_menu
//
//  Created by 鲁超 on 2017/12/1.
//  Copyright © 2017年 鲁超. All rights reserved.
//

#import "ViewController.h"
#import "MySDLManager.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *addCommandButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteCommandButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [_addCommandButton setEnabled:YES];
    [_deleteCommandButton setEnabled:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openUIAlert:) name:@"SDL_UIALERT" object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)AddCommand:(UIButton *)sender {
    [_addCommandButton setEnabled:NO];
    [_deleteCommandButton setEnabled:YES];
    
    [[MySDLManager shareManager] uiAddCommand];
}

- (IBAction)DeleteCommand:(UIButton *)sender {
    [_addCommandButton setEnabled:YES];
    [_deleteCommandButton setEnabled:NO];
    
    [[MySDLManager shareManager] uiDeleteCommand];
}

- (IBAction)PerformInteraction:(UIButton *)sender {
    [[MySDLManager shareManager] uiPerformInteraction];
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
