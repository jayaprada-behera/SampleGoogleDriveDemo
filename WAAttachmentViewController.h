//
//  WAAttachmentViewController.h
//  SampleGoogleDriveDemo
//
//  Created by Jayaprada Behera on 20/03/14.
//  Copyright (c) 2014 Webileapps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAAttachmentViewController : UIViewController
@property (nonatomic, strong) UIDocumentInteractionController *docInteractionController;
@property(nonatomic,strong)NSMutableArray *urlArray;
@end
