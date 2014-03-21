//
//  WATableViewCell.m
//  SampleGoogleDriveDemo
//
//  Created by Jayaprada Behera on 19/03/14.
//  Copyright (c) 2014 Webileapps. All rights reserved.
//

#import "WATableViewCell.h"

@implementation WATableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(IBAction)cellButtonTapped:(id)sender{
    
    self.cellButtonTappedFromCellCallBack();
    
}
@end
