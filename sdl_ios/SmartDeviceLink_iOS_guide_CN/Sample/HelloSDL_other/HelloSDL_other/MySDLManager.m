//
//  MySDLManager.m
//  HelloSDL_other
//
//  Created by 鲁超 on 2017/12/7.
//  Copyright © 2017年 鲁超. All rights reserved.
//

#import "MySDLManager.h"
#import "SmartDeviceLink.h"

@interface MySDLManager()<SDLManagerDelegate>

@property (strong, nonatomic) SDLManager* sdlManager;
@property BOOL isFirstTimeHMIFull;

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
    
    UIImage* appImage = [UIImage imageNamed:@"sdl_logo.png"];
    SDLArtwork* icon = [SDLArtwork persistentArtworkWithImage:appImage name:@"sdl_logo.png" asImageFormat:SDLArtworkImageFormatPNG];
    lifecycleConfiguration.appIcon = icon;
    
    SDLConfiguration* configuration = [[SDLConfiguration alloc] initWithLifecycle:lifecycleConfiguration lockScreen:[SDLLockScreenConfiguration disabledConfiguration] logging:[SDLLogConfiguration defaultConfiguration]];
    
    self.sdlManager = [[SDLManager alloc] initWithConfiguration:configuration delegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveKeyboardInputNotification:) name:SDLDidReceiveKeyboardInputNotification object:nil];
    
    return self;
}

- (void)connect {
    [self.sdlManager startWithReadyHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            // Your app has successfully connected with the SDL Core
            _isFirstTimeHMIFull = YES;
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
            [self sdlSetGlobalProperties];
        }
        
        [self sdlSetDisplayLayout:@"NON-MEDIA"];
    }
}

- (void)managerDidDisconnect {
    _isFirstTimeHMIFull = YES;
}

#pragma mark - private
- (void)sdlSetGlobalProperties {
    SDLSetGlobalProperties* setGlobalProperties = [[SDLSetGlobalProperties alloc] init];
    SDLKeyboardProperties* keyboardProperties = [[SDLKeyboardProperties alloc] initWithLanguage:SDLLanguageZhCn layout:SDLKeyboardLayoutQWERTY keypressMode:SDLKeypressModeSingleKeypress limitedCharacterList:nil autoCompleteText:nil];
    [setGlobalProperties setKeyboardProperties:keyboardProperties];
    
    [self.sdlManager sendRequest:setGlobalProperties withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            // Set keyboard language successful
        }
    }];
}

- (void)sdlSetDisplayLayout:(NSString*)layout {
    SDLSetDisplayLayout* setDisplayLayout = [[SDLSetDisplayLayout alloc] initWithLayout:layout];
    [self.sdlManager sendRequest:setDisplayLayout withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            [self sdlShow];
        }
    }];
}

- (void)sdlShow {
    SDLShow* show = [[SDLShow alloc] initWithMainField1:@"HelloSDL" mainField2:@"SmartDeviceLink Sample" alignment:SDLTextAlignmentLeft];
    
    // Soft buttons
    SDLSoftButton* softButtonAlert = [[SDLSoftButton alloc] initWithType:SDLSoftButtonTypeText text:@"Alert" image:nil highlighted:NO buttonId:1 systemAction:SDLSystemActionDefaultAction handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if ([buttonPress.buttonPressMode isEqualToEnum:SDLButtonPressModeShort]) {
            [self sdlAlert];
        }
    }];
    SDLSoftButton* softButtonKeyboard = [[SDLSoftButton alloc] initWithType:SDLSoftButtonTypeText text:@"Input" image:nil highlighted:NO buttonId:2 systemAction:SDLSystemActionDefaultAction handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if ([buttonPress.buttonPressMode isEqualToEnum:SDLButtonPressModeShort]) {
            [self sdlPerformInteraction];
        }
    }];
    SDLSoftButton* softButtonAPT = [[SDLSoftButton alloc] initWithType:SDLSoftButtonTypeText text:@"APT" image:nil highlighted:NO buttonId:3 systemAction:SDLSystemActionDefaultAction handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if ([buttonPress.buttonPressMode isEqualToEnum:SDLButtonPressModeShort]) {
            [self sdlPerformAudioPassThru];
        }
    }];
    NSArray<SDLSoftButton*>* softButtons = [NSArray arrayWithObjects:softButtonAlert, softButtonKeyboard, softButtonAPT, nil];
    [show setSoftButtons:softButtons];
    
    [self.sdlManager sendRequest:show withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            // Show was send successful
        }
    }];
}

- (void)sdlAlert {
    SDLAlert* alert = [[SDLAlert alloc] initWithAlertText1:@"Text 1" alertText2:@"Text 2" duration:5000];
    
    // Soft button
    SDLSoftButton* softButtonOk = [[SDLSoftButton alloc] initWithType:SDLSoftButtonTypeText text:@"OK" image:nil highlighted:NO buttonId:10 systemAction:SDLSystemActionDefaultAction handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if ([buttonPress.buttonPressMode isEqualToEnum:SDLButtonPressModeShort]) {
            [self postAlertControllerNotification:@"Alert - OK"];
        }
    }];
    SDLSoftButton* softButtonCancel = [[SDLSoftButton alloc] initWithType:SDLSoftButtonTypeText text:@"Cancel" image:nil highlighted:NO buttonId:11 systemAction:SDLSystemActionDefaultAction handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if ([buttonPress.buttonPressMode isEqualToEnum:SDLButtonPressModeShort]) {
            [self postAlertControllerNotification:@"Alert - Cancel"];
        }
    }];
    NSArray<SDLSoftButton*>* softButtons = [NSArray arrayWithObjects:softButtonOk, softButtonCancel, nil];
    [alert setSoftButtons:softButtons];
    
    [alert setPlayTone:@YES];
    [alert setProgressIndicator:@YES];
    
    [self.sdlManager sendRequest:alert withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            // Alert was dismissed successful
        }
    }];
}

- (void)sdlPerformInteraction {
    SDLPerformInteraction* performInteraction = [[SDLPerformInteraction alloc] initWithInitialPrompt:@"prompt" initialText:@"Hello" interactionChoiceSetIDList:@[] helpPrompt:@"help" timeoutPrompt:@"hurry up" interactionMode:SDLInteractionModeManualOnly timeout:10000];
    [performInteraction setInteractionLayout:SDLLayoutModeKeyboard];
    
    [self.sdlManager sendRequest:performInteraction withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            SDLPerformInteractionResponse* res = (SDLPerformInteractionResponse*)response;
            [self postAlertControllerNotification:res.manualTextEntry];
        }
    }];
}

- (void)didReceiveKeyboardInputNotification:(SDLRPCNotificationNotification*)notification {
    SDLOnKeyboardInput* onKeyboardInput = notification.notification;
    if ([onKeyboardInput.event isEqualToEnum:SDLKeyboardEventVoice]) {
        // User press voice button on keyboard
    }
    else if ([onKeyboardInput.event isEqualToEnum:SDLKeyboardEventKeypress]) {
        NSString* input = onKeyboardInput.data;
        [self postAlertControllerNotification:input];
    }
}

- (void)sdlPerformAudioPassThru {
    SDLPerformAudioPassThru* performAudioPassThru = [[SDLPerformAudioPassThru alloc] initWithInitialPrompt:@"Speak" audioPassThruDisplayText1:@"Text 1" audioPassThruDisplayText2:@"Text 2" samplingRate:SDLSamplingRate16KHZ bitsPerSample:SDLBitsPerSample16Bit audioType:SDLAudioTypePCM maxDuration:8000 muteAudio:YES];
    
    [performAudioPassThru setAudioDataHandler:^(NSData * _Nullable audioData) {
        // handle audio data
    }];
    
    [self.sdlManager sendRequest:performAudioPassThru withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            // APT was ended by timeout or user done-operation
        }
    }];
}

- (void)postAlertControllerNotification:(NSString*)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SDL_UIALERT" object:message];
}

@end
