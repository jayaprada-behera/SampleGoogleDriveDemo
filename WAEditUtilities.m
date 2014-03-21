
//
//  WAEditUtilities.m
//  SampleGoogleDriveDemo
//
//  Created by Jayaprada Behera on 19/03/14.
//  Copyright (c) 2014 Webileapps. All rights reserved.
//

#import "WAEditUtilities.h"

@implementation WAEditUtilities
+ (UIAlertView *)showLoadingMessageWithTitle:(NSString *)title 
                                    delegate:(id)delegate {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:@""
                                                 delegate:self
                                        cancelButtonTitle:nil
                                        otherButtonTitles:nil];
  UIActivityIndicatorView *progress= 
  [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(125, 50, 30, 30)];
  progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
  [alert addSubview:progress];
  [progress startAnimating];
  [alert show];
  return alert;
}

+ (void)showErrorMessageWithTitle:(NSString *)title
                          message:(NSString*)message
                         delegate:(id)delegate {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:message
                                                 delegate:self
                                        cancelButtonTitle:@"Dismiss"
                                        otherButtonTitles:nil];
  [alert show];
}
@end
