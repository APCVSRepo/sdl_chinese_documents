//
//  MySDLManager.m
//  HelloSDL_menu
//
//  Created by 鲁超 on 2017/12/1.
//  Copyright © 2017年 鲁超. All rights reserved.
//

#import "MySDLManager.h"
#import "SmartDeviceLink.h"

@interface MySDLManager()<SDLManagerDelegate>

@property (strong, nonatomic) SDLManager* sdlManager;
@property BOOL isFirstTimeHMIFull;

@end

@implementation MySDLManager

static UInt32 commandId = 1;

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
            [self sdlAddCommand:@"Command 1" parentId:0 position:0];
            [self sdlAddCommand:@"Command 2" parentId:0 position:1];
            [self sdlAddSubMenu];
            [self sdlAddCommand:@"Command 5" parentId:0 position:3];
            [self sdlCreateInteractionChoiceSet];
        }
    }
    else if (([oldLevel isEqualToEnum:SDLHMILevelFull] || [oldLevel isEqualToEnum:SDLHMILevelLimited])
             && [newLevel isEqualToEnum:SDLHMILevelNone]) {
        // From HMI FULL/LIMITED to NONE
    }
}

- (void)managerDidDisconnect {
    _isFirstTimeHMIFull = YES;
    commandId = 1;
}

#pragma mark - open to ViewController
- (void)uiAddCommand {
    [self sdlAddCommand:@"New Command" parentId:0 position:0];
}

- (void)uiDeleteCommand {
    commandId = commandId - 1;
    [self sdlDeleteCommand:commandId];
}

- (void)uiPerformInteraction {
    [self sdlPerformInteraction];
}

#pragma mark - SDL Private
- (void)sdlAddCommand:(NSString*)menuName parentId:(UInt32)parentId position:(UInt16)position {
    NSArray<NSString*>* vrCommands = [NSArray arrayWithObjects:menuName, nil];
    SDLAddCommand* addCommand = [[SDLAddCommand alloc] initWithId:commandId vrCommands:vrCommands  handler:^(SDLOnCommand * _Nonnull command) {
        if ([command.triggerSource isEqualToEnum:SDLTriggerSourceMenu]) {
            [self postAlertControllerNotification:menuName];
        }
    }];
    
    SDLMenuParams* menuParam = [[SDLMenuParams alloc] initWithMenuName:menuName parentId:parentId position:position];
    addCommand.menuParams = menuParam;
    
    commandId = commandId + 1;
    [self.sdlManager sendRequest:addCommand withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            // The Menu Item was created successfully
        }
    }];
}

- (void)sdlAddSubMenu {
    SDLAddSubMenu* addSubMenu = [[SDLAddSubMenu alloc] initWithId:commandId menuName:@"SubMenu 1"];
    UInt32 parentId = commandId;
    commandId = commandId + 1;
    
    [self.sdlManager sendRequest:addSubMenu withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            // The submenu was created successfully
            [self sdlAddCommand:@"Command 3" parentId:parentId position:0];
            [self sdlAddCommand:@"Command 4" parentId:parentId position:1];
        }
    }];
}

- (void)sdlDeleteCommand:(UInt32)commandId {
    SDLDeleteCommand* deleteCommand = [[SDLDeleteCommand alloc] initWithId:commandId];
    [self.sdlManager sendRequest:deleteCommand withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            // The Menu Item was deleted successfully
        }
    }];
}

- (void)sdlCreateInteractionChoiceSet {
    NSArray<NSString*>* ChoiceSetList = [NSArray arrayWithObjects:@"Choice 1", @"Choice 2", @"Choice 3", nil];
    NSMutableArray<SDLChoice*>* choiceSet = [NSMutableArray arrayWithCapacity:ChoiceSetList.count];
    
    UInt16 choiceId = 1;
    for (NSString* choiceName in ChoiceSetList) {
        NSArray<NSString*>* vrCommands = [NSArray arrayWithObjects:choiceName, nil];
        SDLChoice* choice = [[SDLChoice alloc] initWithId:choiceId menuName:choiceName vrCommands:vrCommands];
        choiceId = choiceId + 1;
        [choiceSet addObject:choice];
    }
    
    SDLCreateInteractionChoiceSet* createInteractionChoiceSet = [[SDLCreateInteractionChoiceSet alloc] initWithId:1 choiceSet:choiceSet];
    [self.sdlManager sendRequest:createInteractionChoiceSet withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        // The create choice set request was successful
    }];
}

- (void)sdlPerformInteraction {
    SDLPerformInteraction* performInteraction = [[SDLPerformInteraction alloc] initWithInitialPrompt:@"Hello S D L" initialText:@"HelloSDL" interactionChoiceSetID:1];
    
    performInteraction.interactionLayout = SDLLayoutModeListOnly;
    performInteraction.interactionMode = SDLInteractionModeManualOnly;
    performInteraction.timeout = @10000;
    
    [self.sdlManager sendRequest:performInteraction withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            SDLPerformInteractionResponse* res = (SDLPerformInteractionResponse*)response;
            if ([res.resultCode isEqualToEnum:SDLResultSuccess]) {
                NSString* message = [NSString stringWithFormat:@"Choice %@", res.choiceID];
                [self postAlertControllerNotification:message];
            }
        }
    }];
}

- (void)postAlertControllerNotification:(NSString*)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SDL_UIALERT" object:message];
}

@end
