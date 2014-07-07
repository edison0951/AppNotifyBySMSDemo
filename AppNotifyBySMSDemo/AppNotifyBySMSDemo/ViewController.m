//
//  ViewController.m
//  AppNotifyBySMSDemo
//
//  Created by 王河云 on 14-7-7.
//  Copyright (c) 2014年 jumei. All rights reserved.
//

#import "ViewController.h"
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "CTMessageCenter.h"

@interface ViewController ()
@property(nonatomic, strong)UILabel *infoLabel;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
    _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 50)];
    _infoLabel.backgroundColor = [UIColor clearColor];
    _infoLabel.textColor = [UIColor blackColor];
    [self.view addSubview:_infoLabel];
    [self addTelephoneAndSMSObserver];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addTelephoneAndSMSObserver{
    // TelephonyNetworkInfo
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = info.subscriberCellularProvider;
    NSLog(@"carrier:%@", [carrier description]);
    self.infoLabel.text = [NSString stringWithFormat:@"checking telephone and sms %@",[carrier description]];
    
    
    info.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier *carrier) {
        NSLog(@"carrier:%@", [carrier description]);
        self.infoLabel.text = [NSString stringWithFormat:@"checking telephone and sms %@",[carrier description]];
    };
    CTCallCenter *center = [[CTCallCenter alloc] init];
    center.callEventHandler = ^(CTCall *call){
        NSLog(@"Call State : %@",[call description]);
    };
    CTTelephonyCenterAddObserver(CTTelephonyCenterGetDefault(), NULL, callBack, NULL, NULL, CFNotificationSuspensionBehaviorDrop);
}

static void callBack(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
    
    NSString *notifyname=(__bridge NSString *)name;
    if ([notifyname isEqualToString:@"kCTCallStatusChangeNotification"]){//电话
        NSDictionary *info = (__bridge NSDictionary*)userInfo;
        
        NSString *state=[[info objectForKey:@"kCTCallStatus"] stringValue];
        if ([state isEqualToString:@"5"])//disconnect
            NSLog(@"missed call:%@",state);
        
    }else if ([notifyname isEqualToString:@"kCTCallIdentificationChangeNotification"]){
        //        CTCallCenter *center = [[CTCallCenter alloc] init];
        //        center.callEventHandler = ^(CTCall *call) {
        //            NSLog(@"call:%@", [call description]);
        //        };
        NSDictionary *info = (__bridge NSDictionary *)userInfo;
        CTCall *call = (CTCall *)[info objectForKey:@"kCTCall"];
        int caller = CTCallCopyAddress(NULL, call);
        NSLog(@"telephone number:%d",caller);
        //CTCallDisconnect(call);
        /* or one of the following functions: CTCallAnswer
         CTCallAnswerEndingActive
         CTCallAnswerEndingAllOthers
         CTCallAnswerEndingHeld
         */
    }
    else if ([notifyname isEqualToString:@"kCTRegistrationDataStatusChangedNotification"]){
        
    }else if ([notifyname isEqualToString:@"kCTSMSMessageReceivedNotification"]){
        //api expire
        //        if ([[(NSDictionary *)userInfo allKeys]
        //             containsObject:@"kCTSMSMessage"]) // SMS Message
        //        {
        //            CTSMSMessage *message = (CTSMSMessage *)
        //            [(NSDictionary *)userInfo objectForKey:@"kCTSMSMessage"];
        //            NSString *address = CTSMSMessageCopyAddress(NULL, message);
        //            NSString *text = CTSMSMessageCopyText(NULL, message);
        //            //NSArray *lines = [text componentsSeparatedByString:@"\n"];
        //
        //            //printf("  %s %d\n", [address cString], [lines count]);
        //            //printf("  %s\n", [text cString]);
        //            fflush(stdout);
        //
        //        }
    }else if ([notifyname isEqualToString:@"kCTMessageReceivedNotification"]){//receive sms
        /*
         kCTMessageIdKey = "-2147483636";
         kCTMessageTypeKey = 1;
         */
        NSDictionary *info = (__bridge NSDictionary *)userInfo;
        CFNumberRef msgID = (CFNumberRef)CFBridgingRetain([info objectForKey:@"kCTMessageIdKey"]);
        int result;
        CFNumberGetValue((CFNumberRef)msgID, kCFNumberSInt32Type, &result);
        
        NSLog(@"result:%i",result);
        Class CTMessageCenter = NSClassFromString(@"CTMessageCenter");
        id mc = [CTMessageCenter sharedMessageCenter];
        id incMsg = [mc incomingMessageWithId: result];
        
        int msgType = (int)[incMsg performSelector:@selector(messageType)];
        
        if (msgType == 1){//experimentally detected number
            id phonenumber = [incMsg sender];
            
            NSString *senderNumber = (NSString *)[phonenumber performSelector:@selector(canonicalFormat)];
            
            id incMsgPart = [[incMsg items] objectAtIndex:0];
            NSData *smsData = [incMsgPart data];
            NSString *smsText = [[NSString alloc] initWithData:smsData encoding:NSUTF8StringEncoding];
            
            NSLog(@"%@",smsText);

        }
    }
}
@end
