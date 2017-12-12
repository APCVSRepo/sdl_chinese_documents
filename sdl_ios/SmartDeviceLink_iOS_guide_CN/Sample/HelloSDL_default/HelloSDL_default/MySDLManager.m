//
//  MySDLProxyManager.m
//  HelloSDL_default
//
//  Created by 鲁超 on 2017/12/1.
//  Copyright © 2017年 鲁超. All rights reserved.
//

#import "MySDLManager.h"
#import "SmartDeviceLink.h"

@interface MySDLManager()<SDLManagerDelegate>

@property (strong, nonatomic) SDLManager* sdlManager;

@end

@implementation MySDLManager

+ (instancetype)shareManager {
    static MySDLManager* sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[MySDLManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    SDLLifecycleConfiguration* lifecycleConfiguration = [SDLLifecycleConfiguration defaultConfigurationWithAppName:@"HelloSDL" appId:@"8675309"];
    
    lifecycleConfiguration.appType = SDLAppHMITypeDefault;
    
    UIImage* appImage = [UIImage imageNamed:@"icon.png"];
    SDLArtwork* icon = [SDLArtwork persistentArtworkWithImage:appImage name:@"icon.png" asImageFormat:SDLArtworkImageFormatPNG];
    lifecycleConfiguration.appIcon = icon;
    
    SDLConfiguration* configuration = [[SDLConfiguration alloc] initWithLifecycle:lifecycleConfiguration lockScreen:[SDLLockScreenConfiguration disabledConfiguration] logging:[SDLLogConfiguration defaultConfiguration]];
    
    self.sdlManager = [[SDLManager alloc] initWithConfiguration:configuration delegate:self];
    
    return self;
}

- (void)connect {
    [self.sdlManager startWithReadyHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            // Your app has successfully connected with the SDL Core
        }
        else {
            NSLog(@"SDLManager connect failed, %@", error.debugDescription);
        }
    }];
}

#pragma mark - SDLManagerDelegate
- (void)hmiLevel:(nonnull SDLHMILevel)oldLevel didChangeToLevel:(nonnull SDLHMILevel)newLevel {
    if (([oldLevel isEqualToEnum:SDLHMILevelNone] || [oldLevel isEqualToEnum:SDLHMILevelBackground])
        && [newLevel isEqualToEnum:SDLHMILevelFull]) {
        // From HMI NONE/BACKGROUND to FULL
        }
    else if (([oldLevel isEqualToEnum:SDLHMILevelFull] || [oldLevel isEqualToEnum:SDLHMILevelLimited])
         && [newLevel isEqualToEnum:SDLHMILevelNone]) {
        // From HMI FULL/LIMITED to NONE
    }
}

- (void)managerDidDisconnect {
    // Clear flags when SDLManager reports disconnection
}

@end
