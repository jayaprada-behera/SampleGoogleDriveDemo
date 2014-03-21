//
//  WAChildViewController.m
//  SampleGoogleDriveDemo
//
//  Created by Jayaprada Behera on 19/03/14.
//  Copyright (c) 2014 Webileapps. All rights reserved.
//

#import "WAChildViewController.h"
#import "WATableViewCell.h"
#import <AssetsLibrary/ALAsset.h>

#define download_url_link_index             3
#define mime_type_index                     2
#define link_Idntifier_index                1
#define isFolder_index                      4
#define file_name                           0

@interface WAChildViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray *array_;
}
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@end

@implementation WAChildViewController
@synthesize myTableView;
@synthesize childDriveFileArray;

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
    self.myTableView.delegate = self;
    self.myTableView.dataSource = self;
    array_ = [[NSMutableArray alloc]init];
    [array_ addObjectsFromArray:self.childDriveFileArray];
    self.title = [NSString stringWithFormat:@"Folder :%d",array_.count];
    NSLog(@"%@",array_);
    
    
}

- (GTLServiceDrive *)driveService {
    static GTLServiceDrive *service = nil;
    
    if (!service) {
        service = [[GTLServiceDrive alloc] init];
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them.
        service.shouldFetchNextPages = YES;
        // Have the service object set tickets to retry temporary error conditions
        // automatically.
        service.retryEnabled = YES;
    }
    return service;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  array_.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    
    WATableViewCell *customCell = (WATableViewCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (customCell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"WATableViewCell" owner:self options:nil];
        customCell = [nib objectAtIndex:0];
    }
    customCell.selectionStyle = UITableViewCellSelectionStyleNone;
    customCell.accessoryType = UITableViewCellAccessoryNone;
    customCell.cellButtonTappedFromCellCallBack = ^(){
        [self cellDownloadButtonTouchUpInside:indexPath.row];
    };
    NSArray *a = [[self.childDriveFileArray objectAtIndex:indexPath.row] allValues];
    customCell.nameLbl.text =[[a objectAtIndex:0] objectAtIndex:file_name];
    return customCell;
}

-(void)cellDownloadButtonTouchUpInside:(NSInteger )cellIndex{
    
    NSArray *a = [[self.childDriveFileArray objectAtIndex:cellIndex] allValues];
    
    NSString *downloadUrl = [[a objectAtIndex:0] objectAtIndex:download_url_link_index];
    NSString *mime_Type = [[a objectAtIndex:0] objectAtIndex:mime_type_index];
    BOOL isFolder =  [[[a objectAtIndex:0] objectAtIndex:isFolder_index] boolValue];
    
    if (isFolder) {
        [[[UIAlertView alloc]initWithTitle:@"" message:@"Its a folder" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil]show];
        return;
    }
    __block NSString *alertMsg = @"";
    
    NSLog(@"\n\ngoogle drive file download url link = %@", downloadUrl);
    GTMHTTPFetcher *fetcher =
    [self.driveService.fetcherService fetcherWithURLString:downloadUrl];
    
    //async call to download the file data
    [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
        if (error == nil) {
            //            NSLog(@"\nfile %@ downloaded successfully from google drive", self.selectedFileName);
            
            //            [self.downloadedDataFileArray addObject:data];
            alertMsg = @"File successfully downloaded";
            
            if ([mime_Type isEqualToString:@"image/png"] || [mime_Type isEqualToString:@"image/jpeg"] ) {
                //saving the downloaded data into Photos Album
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                
                NSDictionary *dict;
                [library writeImageDataToSavedPhotosAlbum:data metadata:dict completionBlock:^(NSURL *assetURL, NSError *error) {
                    
                    if (error) {
                        alertMsg = [error description];
                    }else {
                        alertMsg = @"Succesfully saved to Photos Album";
                    }
                }];
            }
            
            //            [data writeToFile:@"" atomically:YES];
        } else
            alertMsg = [error description];
        [WAEditUtilities showErrorMessageWithTitle:@""
                                           message:alertMsg
                                          delegate:self];
    }];
}

//UIDocumentInteractionController to open files


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
