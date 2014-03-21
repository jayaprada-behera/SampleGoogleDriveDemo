//
//  WATableViewCell.h
//  SampleGoogleDriveDemo
//
//  Created by Jayaprada Behera on 19/03/14.
//  Copyright (c) 2014 Webileapps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WATableViewCell : UITableViewCell
@property(strong,nonatomic)IBOutlet UILabel *nameLbl;
@property(strong,nonatomic)IBOutlet UIButton *cell_button;
@property (readwrite, copy) void (^cellButtonTappedFromCellCallBack)(void);

-(IBAction)cellButtonTapped:(id)sender;
@end
