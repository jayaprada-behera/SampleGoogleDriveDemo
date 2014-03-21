//
//  WAAttachmentViewController.m
//  SampleGoogleDriveDemo
//
//  Created by Jayaprada Behera on 20/03/14.
//  Copyright (c) 2014 Webileapps. All rights reserved.
//

#import "WAAttachmentViewController.h"

@interface WAAttachmentViewController ()<UITableViewDelegate,UITableViewDataSource,UIDocumentInteractionControllerDelegate,QLPreviewControllerDataSource,QLPreviewControllerDelegate>

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
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc]initWithTitle:@"Share" style:UIBarButtonItemStylePlain target:self action:@selector(shareButtonTouchUpInside:)];
    [self.navigationItem setRightBarButtonItem:shareButton];
    
}
-(IBAction)shareButtonTouchUpInside:(id)sender{
    
    NSIndexPath *selectedIndexPath = [self.attachmentTableView indexPathForSelectedRow];
    if (selectedIndexPath == nil) {
        [[[UIAlertView alloc]initWithTitle:@"Please select one file to share" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil]show];
        return;
    }
    NSURL *fileURL = [self.urlArray objectAtIndex:selectedIndexPath.row];
    
    self.docInteractionController.URL = fileURL;
    
    [self.docInteractionController presentOptionsMenuFromRect:self.view.frame
                                                       inView:self.view
                                                     animated:YES];
    
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
    NSLog(@"dataLength %d",[[NSData dataWithContentsOfURL:fileURL] length]);
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
   
    
    // three ways to present a preview:
    // 1. Don't implement this method and simply attach the canned gestureRecognizers to the cell
    //
    // 2. Don't use canned gesture recognizers and simply use UIDocumentInteractionController's
    //      presentPreviewAnimated: to get a preview for the document associated with this cell
    //
    // 3. Use the QLPreviewController to give the user preview access to the document associated
    //      with this cell and all the other documents as well.
    
    // for case 2 use this, allowing UIDocumentInteractionController to handle the preview:
    /*
     NSURL *fileURL;
     if (indexPath.section == 0)
     {
     fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:documents[indexPath.row] ofType:nil]];
     }
     else
     {
     fileURL = [self.documentURLs objectAtIndex:indexPath.row];
     }
     [self setupDocumentControllerWithURL:fileURL];
     [self.docInteractionController presentPreviewAnimated:YES];
     */
    
    // for case 3 we use the QuickLook APIs directly to preview the document -
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    previewController.dataSource = self;
    previewController.delegate = self;
    
    // start previewing the document at the current section index
    previewController.currentPreviewItemIndex = indexPath.row;
    [[self navigationController] pushViewController:previewController animated:YES];
    

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
#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    return self;
}


#pragma mark - QLPreviewControllerDataSource

// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
    NSInteger numToPreview  = self.urlArray.count;
    
    return numToPreview;
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    // if the preview dismissed (done button touched), use this method to post-process previews
}

// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    NSURL *fileURL  = [self.urlArray objectAtIndex:idx];
    return fileURL;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
