//
//  MySDLManager.m
//  HelloSDL_media
//
//  Created by 鲁超 on 2017/12/6.
//  Copyright © 2017年 鲁超. All rights reserved.
//

#import "MySDLManager.h"
#import "SmartDeviceLink.h"

@interface MySDLManager()<SDLManagerDelegate>

@property (strong, nonatomic) SDLManager* sdlManager;
@property BOOL isFirstTimeHMIFull;
@property BOOL areGraphicsSupported;

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
    
    SDLLifecycleConfiguration* lifecycleConfig = [SDLLifecycleConfiguration defaultConfigurationWithAppName:@"HelloSDL" appId:@"8675309"];
    
    UIImage* appImage = [UIImage imageNamed:@"sdl_logo.png"];
    if (appImage) {
        SDLArtwork* icon = [SDLArtwork persistentArtworkWithImage:appImage name:@"sdl_logo.png" asImageFormat:SDLArtworkImageFormatPNG];
        lifecycleConfig.appIcon = icon;
    }
    
    lifecycleConfig.appType = SDLAppHMITypeMedia;
    
    SDLConfiguration* config = [SDLConfiguration configurationWithLifecycle:lifecycleConfig lockScreen:SDLLockScreenConfiguration.disabledConfiguration logging:SDLLogConfiguration.defaultConfiguration];
    self.sdlManager = [[SDLManager alloc] initWithConfiguration:config delegate:self];
    
    return self;
}

- (void)connect {
    __weak typeof (self) weakSelf = self;
    
    [self.sdlManager startWithReadyHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            // Your app has successfully connected with the SDL Core
            _isFirstTimeHMIFull = YES;
            
            SDLDisplayCapabilities *displayCapabilities = weakSelf.sdlManager.registerResponse.displayCapabilities;
            if (displayCapabilities) {
                _areGraphicsSupported = displayCapabilities.graphicSupported.boolValue;
            }
        }
        else {
            NSLog(@"sdlManager connects failed, %@", error.debugDescription);
        }
    }];
}

#pragma mark - SDLManagerDelegate
- (void)hmiLevel:(nonnull SDLHMILevel)oldLevel didChangeToLevel:(nonnull SDLHMILevel)newLevel {
    if (([oldLevel isEqualToEnum:SDLHMILevelNone] || [oldLevel isEqualToEnum:SDLHMILevelBackground])
        && [newLevel isEqualToEnum:SDLHMILevelFull]) {
        // From HMI NONE/BACKGROUND to FULL
        if (_isFirstTimeHMIFull) {
            _isFirstTimeHMIFull = NO;
            [self sdlSubcribeMediaButton];
        }
        
        [self sdlSetDisplayLayout:@"MEDIA"];
    }
    else if (([oldLevel isEqualToEnum:SDLHMILevelFull] || [oldLevel isEqualToEnum:SDLHMILevelLimited])
             && [newLevel isEqualToEnum:SDLHMILevelNone]) {
        // From HMI FULL/LIMITED to NONE
    }
}

- (void)managerDidDisconnect {
    _isFirstTimeHMIFull = YES;
}

#pragma mark - SDL button subcribe
- (void)sdlSubcribeMediaButton {
    SDLSubscribeButton* subscribeButtonOK = [[SDLSubscribeButton alloc] initWithButtonName:SDLButtonNameOk handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if ([buttonPress.buttonPressMode isEqualToEnum:SDLButtonPressModeShort]) {
            [self postAlertControllerNotification:@"Media Play/Pause"];
        }
    }];
    [self.sdlManager sendRequest:subscribeButtonOK];
    
    SDLSubscribeButton* subscribeButtonSeekLeft = [[SDLSubscribeButton alloc] initWithButtonName:SDLButtonNameSeekLeft handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if ([buttonPress.buttonPressMode isEqualToEnum:SDLButtonPressModeShort]) {
            [self postAlertControllerNotification:@"Media Seek left"];
        }
    }];
    [self.sdlManager sendRequest:subscribeButtonSeekLeft];
    
    SDLSubscribeButton* subcribeButtonSeekRight = [[SDLSubscribeButton alloc] initWithButtonName:SDLButtonNameSeekRight handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if ([buttonPress.buttonPressMode isEqualToEnum:SDLButtonPressModeShort]) {
            [self postAlertControllerNotification:@"Media Seek right"];
        }
    }];
    [self.sdlManager sendRequest:subcribeButtonSeekRight];
}

#pragma mark - private
- (void)sdlSetDisplayLayout:(NSString*)layout {
    SDLSetDisplayLayout* setDisplayLayout = [[SDLSetDisplayLayout alloc] initWithLayout:layout];
    [self.sdlManager sendRequest:setDisplayLayout withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            [self sdlShowTrackInfo];
        }
    }];
}

- (void)sdlShowTrackInfo {
    SDLShow* show = [[SDLShow alloc] initWithMainField1:@"Track title" mainField2:@"artist" alignment:SDLTextAlignmentLeft];
    [show setMediaTrack:@"1/5"];
    
    // Set default album image
    SDLImage* image = [[SDLImage alloc] initWithName:@"default_album.png" ofType:SDLImageTypeDynamic];
    if (image) {
        [show setGraphic:image];
    }
    
    // Set soft button
    SDLSoftButton* softButton1 = [[SDLSoftButton alloc] initWithType:SDLSoftButtonTypeText text:@"Button1" image:nil highlighted:NO buttonId:1 systemAction:SDLSystemActionDefaultAction handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if ([buttonPress.buttonPressMode isEqualToEnum:SDLButtonPressModeShort]) {
            [self postAlertControllerNotification:@"SoftButton1"];
        }
    }];
    SDLSoftButton* softButton2 = [[SDLSoftButton alloc] initWithType:SDLSoftButtonTypeText text:@"Button2" image:nil highlighted:NO buttonId:2 systemAction:SDLSystemActionDefaultAction handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if ([buttonPress.buttonPressMode isEqualToEnum:SDLButtonPressModeShort]) {
            [self postAlertControllerNotification:@"SoftButton2"];
        }
    }];
    NSArray<SDLSoftButton*>* softButton = [NSArray arrayWithObjects:softButton1, softButton2, nil];
    [show setSoftButtons:softButton];
    
    [self.sdlManager sendRequest:show withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess] && _areGraphicsSupported) {
            // Show was created successful
            UIImage* albumImage = [UIImage imageNamed:@"album.png"];
            SDLArtwork* album = [SDLArtwork persistentArtworkWithImage:albumImage name:@"album.png" asImageFormat:SDLArtworkImageFormatPNG];
            [self.sdlManager.fileManager uploadFile:album completionHandler:^(BOOL success,NSUInteger bytesAvailable, NSError * _Nullable error) {
                [self sdlSetMediaClockTimer:3 seconds:15];
                [self sdlShowAlbum];
            }];
        }
    }];
}

- (void)sdlShowAlbum {
    SDLImage* image = [[SDLImage alloc] initWithName:@"album.png" ofType:SDLImageTypeDynamic];
    SDLShow* show = [[SDLShow alloc] initWithMainField1:@"Track name" mainField2:@"artist" alignment:SDLTextAlignmentLeft];
    [show setGraphic:image];
    [self.sdlManager sendRequest:show];
}

- (void)sdlSetMediaClockTimer:(UInt8)minutes seconds:(UInt8)seconds {
    SDLSetMediaClockTimer* setMediaClockTimer = [[SDLSetMediaClockTimer alloc] initWithUpdateMode:SDLUpdateModeCountUp hours:0 minutes:0 seconds:0];
    SDLStartTime* endTime = [[SDLStartTime alloc] initWithHours:0 minutes:minutes seconds:seconds];
    [setMediaClockTimer setEndTime:endTime];
    [self.sdlManager sendRequest:setMediaClockTimer withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            // Set media clock timer successful
        }
    }];
}

- (void)postAlertControllerNotification:(NSString*)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SDL_UIALERT" object:message];
}

@end
