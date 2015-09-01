//
//  AppDelegate.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 6/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "sys/utsname.h"
#import "MobClick.h"

#define UMENG_APPKEY @"55b24ecbe0f55ab20d001c72"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // not sleep
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    // umeng
    [self umengTrack];
    return YES;
}

- (void)umengTrack {
    [MobClick startWithAppkey:UMENG_APPKEY reportPolicy:BATCH channelId:nil];
    // version
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [MobClick setAppVersion:version];
    [MobClick updateOnlineConfig];
    [MobClick getConfigParams];
    [MobClick event:@"Launched"];
    //[self getDeviceInfo];
    //[MobClick setLogEnabled:YES]; // test
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onlineConfigCallBack:) name:UMOnlineConfigDidFinishedNotification object:nil];
    
}

- (void)getDeviceInfo {
    Class cls = NSClassFromString(@"UMANUtil");
    SEL deviceIDSelector = @selector(openUDIDString);
    NSString *deviceID = nil;
    if (cls && [cls respondsToSelector:deviceIDSelector]) {
        deviceID = [cls performSelector:deviceIDSelector];
    }
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:@{@"oid" : deviceID}
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    
    NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
}

// need to send umeng event before session is closed
// the code in this method is faster than get notification in view controller class
- (void)applicationWillResignActive:(UIApplication *)application {
    ViewController* viewController = (ViewController *)self.window.rootViewController;
    [viewController applicationWillResignActive];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

+ (NSString*)deviceString
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    if ([deviceString rangeOfString:@"iPhone"].location != NSNotFound) {
        if ([deviceString rangeOfString:@"iPhone3"].location != NSNotFound)
            return @"iPhone4";
        if ([deviceString rangeOfString:@"iPhone4"].location != NSNotFound)
            return @"iPhone4S";
        if ([deviceString rangeOfString:@"iPhone5"].location != NSNotFound)
            return @"iPhone5";
        if ([deviceString rangeOfString:@"iPhone6"].location != NSNotFound)
            return @"iPhone5S";
        if ([deviceString isEqualToString:@"iPhone7,2"])
            return @"iPhone6";// this is actually iPhone 6
        if ([deviceString isEqualToString:@"iPhone7,1"])
            return @"iPhone6+";// this is actually iPhone 6 plus
    }
    if ([deviceString rangeOfString:@"iPad"].location != NSNotFound) {
        return @"iPad";
    }
    return @"iPhone4";
}

+ (BOOL)isIphone4 {
    NSString *device = [self deviceString];
    NSRange range = [device rangeOfString:@"iPhone4"];
    if (range.location != NSNotFound) {
        return true;
    }
    return false;
}

+ (BOOL) isIpad {
    NSString *device = [self deviceString];
    NSRange range = [device rangeOfString:@"iPad"];
    if (range.location != NSNotFound) {
        return true;
    }
    else
        return false;
}

@end
