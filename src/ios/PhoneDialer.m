//
//  PhoneDialer.m

#import <Cordova/CDV.h>
#import <CallKit/CallKit.h>
#import <Cordova/CDVPlugin.h>
#import <AVFoundation/AVFoundation.h>
#import "PhoneDialer.h"

BOOL monitorAudioRouteChange = NO;


@implementation PhoneDialer

+ (BOOL)available {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]];
}

- (void)handleAudioRouteChange:(NSNotification *) notification
{
    if(monitorAudioRouteChange) {
        NSNumber* reasonValue = notification.userInfo[@"AVAudioSessionRouteChangeReasonKey"];
        AVAudioSessionRouteDescription* previousRouteKey = notification.userInfo[@"AVAudioSessionRouteChangePreviousRouteKey"];
        NSArray* outputs = [previousRouteKey outputs];
        if([outputs count] > 0) {
            AVAudioSessionPortDescription *output = outputs[0];
            if(![output.portType isEqual: @"Speaker"] && [reasonValue isEqual:@4]) {
                 AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
                 BOOL success = [sessionInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];  
                 if (success) {
                    NSLog(@"Configuring Speaker On");      
                 }
            } else if([output.portType isEqual: @"Speaker"] && [reasonValue isEqual:@3]) {
                AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
                BOOL success = [sessionInstance overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];                                        
                if (success) {
                NSLog(@"Configuring Speaker Off");      
                }  
            }
        }
    }
}

- (void)call:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        
        __block CDVPluginResult* pluginResult = nil;
        NSString* number = [command.arguments objectAtIndex:0];
        number = [number stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if(![number hasPrefix:@"tel:"]){
            number =  [NSString stringWithFormat:@"tel:%@", number];
        }

        // run in mainthread as below 
        dispatch_async(dispatch_get_main_queue(), ^{
            if(![PhoneDialer available]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"NoFeatureCallSupported"];
            }
            else if(![[UIApplication sharedApplication] openURL:[NSURL URLWithString:number]]) {
                // missing phone number
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"CouldNotCallPhoneNumber"];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
        });
        // return result
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
    }];
}


- (void)dial:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{

        CDVPluginResult* pluginResult = nil;
        
        if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"feature"];
        } else {
            
            NSString* url;
            NSString* number = [command.arguments objectAtIndex:0];
            NSString* appChooser = [command.arguments objectAtIndex:1];

            if (number != nil && [number length] > 0) {
                if ([number hasPrefix:@"tel:"] || [number hasPrefix:@"telprompt://"]) {
                    url = number;
                } else {
                    // escape characters such as spaces that may not be accepted by openURL
                    url = [NSString stringWithFormat:@"tel:%@",
                   [number stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                }

                // openURL is expected to fail on devices that do not have the Phone app, such as simulators, iPad, iPod touch
                if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:url]]) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"feature"];
                }
                else if(![[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]]) {
                    // missing phone number
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"notcall"];
                } else {                    
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                }                                

            } else {
                // missing phone number
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"empty"];
            }
        }
        
        // return result
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

@end
