
//
//  WAEditUtilities.h
//  SampleGoogleDriveDemo
//
//  Created by Jayaprada Behera on 20/03/14.
//  Copyright (c) 2014 Webileapps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WAEditUtilities : NSObject
+ (UIAlertView *)showLoadingMessageWithTitle:(NSString *)title
                                    delegate:(id)delegate;
+ (void)showErrorMessageWithTitle:(NSString *)title 
                          message:(NSString *)message
                         delegate:(id)delegate;
@end
