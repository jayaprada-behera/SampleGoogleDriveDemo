//
//  WAAttachmentViewController.m
//  SampleGoogleDriveDemo
//
//  Created by Jayaprada Behera on 20/03/14.
//  Copyright (c) 2014 Webileapps. All rights reserved.
//

#import "WAAttachmentViewController.h"

@interface WAAttachmentViewController ()<UITableViewDelegate,UITableViewDataSource,UIDocumentInteractionControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *attachmentTableView;
@end

@implementation WAAttachmentViewController
@synthesize docInteractionController;
@synthesize attachmentTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.attachmentTableView .delegate = self;
    self.attachmentTableView.dataSource = self;
    
    // Do any additional setup after loading the view from its nib.
}
- (void)setupDocumentControllerWithURL:(NSURL *)url{
    
    if (self.docInteractionController == nil){
        
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        self.docInteractionController.delegate = self;
        
    }else{
        
        self.docInteractionController.URL = url;
    }
    
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return  self.urlArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellIdentifier = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    NSURL *fileURL = [self.urlArray objectAtIndex:indexPath.row];
//    NSLog(@"dataLength %d",[[NSData dataWithContentsOfURL:fileURL] length]);
    [self setupDocumentControllerWithURL:fileURL];

    cell.textLabel.text = [[fileURL path] lastPathComponent];
    NSInteger iconCount = [self.docInteractionController.icons count];
    
    if (iconCount > 0)
    {
        cell.imageView.image = [self.docInteractionController.icons objectAtIndex:iconCount - 1];
    }
    NSString *fileURLString = [self.docInteractionController.URL path];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURLString error:nil];
    NSInteger fileSize = [[fileAttributes objectForKey:NSFileSize] intValue];
    NSString *fileSizeStr = [NSByteCountFormatter stringFromByteCount:fileSize
                                                           countStyle:NSByteCountFormatterCountStyleFile];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", fileSizeStr, self.docInteractionController.UTI];

    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSURL *fileURL = [self.urlArray objectAtIndex:indexPath.row];

self.docInteractionController.URL = fileURL;

[self.docInteractionController presentOptionsMenuFromRect:self.view.frame
                                                   inView:self.view
                                                 animated:YES];
}

//None of these delegate methods are ever called which is weird:
- (void) documentInteractionController: (UIDocumentInteractionController *) controller
         willBeginSendingToApplication: (NSString *) application
{
    NSLog(@"willBeginSendingToApplication %@", application);
}

- (void) documentInteractionController: (UIDocumentInteractionController *) controller
            didEndSendingToApplication: (NSString *) application
{
    NSLog(@"didEndSendingToApplication %@", application);
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    NSLog(@"documentInteractionControllerDidDismissOptionsMenu ");

}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    NSLog(@"documentInteractionControllerDidDismissOpenInMenu ");

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
