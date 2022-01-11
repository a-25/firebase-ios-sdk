
// Copyright 2022 Google
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "FIRSceneHelper.h"
#import <UIKit/UIKit.h>

//API_AVAILABLE(ios(13.0))
//@interface FIRSceneSearchResult : NSObject
//@property BOOL areAllScenesUnattached;
//@property(nullable, nonatomic) UIWindowScene *foregroundedScene;
//@end
//
//API_AVAILABLE(ios(13.0))
//@implementation FIRSceneSearchResult
//
//- (instancetype)initWithForegroundedScene:(UIWindowScene*)foregroundedScene areAllScenesUnattached:(BOOL)areAllScenesUnattached {
//    self = [super init];
//    self.foregroundedScene = foregroundedScene;
//    return self;
//}
//
//@end

API_AVAILABLE(ios(13.0))
typedef void(^FindSceneCompletionBlock)(UIWindowScene *scene);

API_AVAILABLE(ios(13.0))
@interface FIRSceneHelper()
@property(nonatomic, copy) FindSceneCompletionBlock pendingCompletion;
@end

@implementation FIRSceneHelper

- (void)findForegroundedSceneWithCompletionBlock:(void (^)(UIWindowScene *scene))completionBlock
    API_AVAILABLE(ios(13.0)) {
  if (@available(iOS 13.0, *)) {
    UIWindowScene *foregroundedScene = nil;
    BOOL areAllScenesUnattached = true;
    [self findScene](foregroundedScene, areAllScenesUnattached);
    
    if (foregroundedScene == nil && areAllScenesUnattached) {
        self.pendingCompletion = completionBlock;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFirstSceneActivated) name:UISceneDidActivateNotification object:nil];
    } else {
      completionBlock(foregroundedScene);
    }
  } else {
    completionBlock(nil);
  }
}

- (void)onFirstSceneActivated API_AVAILABLE(ios(13.0)) {
    UIWindowScene *foregroundedScene = nil;
    BOOL areAllScenesUnattached = true;
    [self findScene](foregroundedScene, areAllScenesUnattached);
    if (foregroundedScene != nil || !areAllScenesUnattached) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UISceneDidActivateNotification object:nil];
        if (self.pendingCompletion != nil) {
            self.pendingCompletion(foregroundedScene);
            self.pendingCompletion = nil;
        }
    }
}

- (void (^)(UIWindowScene*, BOOL))findScene API_AVAILABLE(ios(13.0)) {
    return ^(UIWindowScene *foregroundedScene, BOOL areAllScenesUnattached){
        foregroundedScene = nil;
        areAllScenesUnattached = true;
        for (UIWindowScene *connectedScene in [UIApplication sharedApplication].connectedScenes) {
          if (connectedScene.activationState != UISceneActivationStateUnattached) {
            areAllScenesUnattached = false;
          }
          if (connectedScene.activationState == UISceneActivationStateForegroundActive) {
            foregroundedScene = connectedScene;
            break;
          }
        }
    };
}

@end
