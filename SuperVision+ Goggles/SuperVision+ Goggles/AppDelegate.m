//
//  AppDelegate.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 6/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "AppDelegate.h"
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
    /*//  umeng
    [MobClick startWithAppkey:@"55b24ecbe0f55ab20d001c72" reportPolicy:BATCH channelId:nil];
    // version
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [MobClick setAppVersion:version];
    [MobClick updateOnlineConfig];
    [MobClick getConfigParams];
    //[MobClick setLogEnabled:YES];  // 打开友盟sdk调试，注意Release发布时需要注释掉此行,减少io消耗
    
    NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);*/
    [MobClick startWithAppkey:UMENG_APPKEY reportPolicy:BATCH channelId:nil];
    //[MobClick setLogEnabled:YES];  // 打开友盟sdk调试，注意Release发布时需要注释掉此行,减少io消耗
    [MobClick updateOnlineConfig];  //在线参数配置
    [MobClick getConfigParams];
    [MobClick event:@"Launched"];
    //[self getDeviceInfo];
    
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


/*- (void)onlineConfigCallBack:(NSNotification *)note {
    
    NSLog(@"online config has fininshed and note = %@", note.userInfo);
}*/

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
