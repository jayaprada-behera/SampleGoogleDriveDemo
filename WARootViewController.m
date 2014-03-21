//
//  WARootViewController.m
//  SampleGoogleDriveDemo
//
//  Created by Jayaprada Behera on 18/03/14.
//  Copyright (c) 2014 Webileapps. All rights reserved.
//

#import "WARootViewController.h"
#import "WAChildViewController.h"
#import "WAAttachmentViewController.h"

#import "WATableViewCell.h"
#import <AssetsLibrary/ALAsset.h>


#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "WAEditUtilities.h"

#define download_url_link_index             2
#define mime_type_index                     1
#define link_Idntifier_index                0
#define isFolder_index                      3

#define FILE_SECTION                        0
#define FOLDER_SECTION                      1

// Constants used for OAuth 2.0 authorization.
static NSString *const kKeychainItemName = @"<My app>: Google Drive";
static NSString *const kClientId = @"<Client ID>";
static NSString *const kClientSecret = @"<Client Secret>";


//https://console.developers.google.com/project/apps~gleaming-glass-523/apiui/credential
//https://groups.google.com/forum/#!topic/adwords-api/_kd-BaK1-Ok
//https://developers.google.com/drive/web/search-parameters

@interface WARootViewController ()<UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    NSString *mimeType;
    NSMutableArray *childrenFolder;
    UIImagePickerController *imagePickerController;
}
@property BOOL isAuthorized;
@property(strong,nonatomic)UIBarButtonItem *authButton;
@property(strong,nonatomic)UIBarButtonItem *refreshButton;
@property(strong,nonatomic)UIBarButtonItem *addButton;

@property (weak, nonatomic) IBOutlet UITableView *driveTableView;
@property (strong,nonatomic)NSMutableArray *driveFiles;
@property (strong,nonatomic)NSMutableArray *driveChildren;
@property (strong,nonatomic)NSMutableArray *fileNames;
@property (strong,nonatomic)NSMutableArray *folderArray;
@property (strong,nonatomic)NSMutableArray *fileArray;
@property (strong,nonatomic)NSMutableArray *downloadedDataFileArray;
@property (strong,nonatomic)NSMutableArray *childFolderDriveFileArray;


@end

@implementation WARootViewController
@synthesize authButton;
@synthesize isAuthorized;
@synthesize driveFiles;
@synthesize driveChildren;
@synthesize fileNames;
@synthesize folderArray;
@synthesize fileArray;
@synthesize downloadedDataFileArray;
@synthesize childFolderDriveFileArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.driveTableView reloadData];
}
-(void)initialiseArray{
    childrenFolder= [NSMutableArray new];
    
    if (self.folderArray == nil)
        self.folderArray = [[NSMutableArray alloc] init];
    
    if (self.fileArray == nil)
        self.fileArray = [[NSMutableArray alloc] init];
    
    if (self.driveFiles == nil)
        self.driveFiles = [[NSMutableArray alloc] init];
    
    if (self.driveChildren == nil)
        self.driveChildren = [NSMutableArray new];
    
    if (self.fileNames == nil)
        self.fileNames = [NSMutableArray new];
    
    if (self.childFolderDriveFileArray == nil)
        self.childFolderDriveFileArray = [NSMutableArray new];
    
    
    if (self.downloadedDataFileArray == nil)
        self.downloadedDataFileArray = [NSMutableArray new];

}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Drive:0";
    
    self.driveTableView.delegate = self;
    self.driveTableView.dataSource = self;
    
    
    [self initialiseArray];
    
    NSString *buttonTitle = @"";
    GTMOAuth2Authentication *auth =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                          clientID:kClientId
                                                      clientSecret:kClientSecret];
    if ([auth canAuthorize]) {
        buttonTitle = @"Sign out";
        [self isAuthorizedWithAuthentication:auth];
    }else{
        buttonTitle = @"Sign in";
    }
    
    //Add  buttons
    UIBarButtonItem *downloadButton= [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"DownloadIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(downloadButtonTaped:)];
    self.authButton = [[UIBarButtonItem alloc]initWithTitle:buttonTitle style:UIBarButtonItemStylePlain target:self action:@selector(authButtonClicked:)];
    self.refreshButton =[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonClicked:)];
    [self.navigationItem setLeftBarButtonItem:self.authButton];
    self.addButton =[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonClicked:)];
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:downloadButton,self.refreshButton,self.addButton, nil]];
    
    
    // Do any additional setup after loading the view from its nib.
}
- (void)isAuthorizedWithAuthentication:(GTMOAuth2Authentication *)auth {
    [[self driveService] setAuthorizer:auth];
    self.authButton.title = @"Sign out";
    self.isAuthorized = YES;
    [self loadDriveFiles];
}

- (void)loadDriveFiles {
    
    [self.driveChildren removeAllObjects];
    [self.driveFiles removeAllObjects];
    [self.fileNames removeAllObjects];
    [self.folderArray removeAllObjects];
    [self.fileArray removeAllObjects];
    
    NSLog(@"array%@",self.driveFiles);
    
    GTLQueryDrive *query = [GTLQueryDrive queryForChildrenListWithFolderId:@"root"];
    //    query.maxResults = 1000;
    
    UIAlertView *alert = [WAEditUtilities showLoadingMessageWithTitle:@"Loading files"
                                                             delegate:self];
    
    [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveChildList *children,//GTLDriveFileList
                                                              NSError *error) {
        
        NSLog(@"\nGoogle Drive: file count in the folder: %lu", (unsigned long)children.items.count);
        //incase there is no files under this folder then we can avoid the fetching process
        if (!children.items.count) {
            NSLog(@"An error occurred: %@", error);
            [WAEditUtilities showErrorMessageWithTitle:@"Unable to load files"
                                               message:[error description]
                                              delegate:self];
        }
        if (error == nil) {
            __block int count = 0;
            [self.driveChildren addObjectsFromArray:children.items];
            
            for (GTLDriveChildReference *child in children) {
                
                GTLQuery *query = [GTLQueryDrive queryForFilesGetWithFileId:child.identifier];
                count++;
                // queryTicket can be used to track the status of the request.
                [self trackStatusOfRequest:query forGTLDriveChildList:children withAlert:alert forCount:count];
            }
        }
    }];
}

-(void)trackStatusOfRequest:(GTLQuery *)query forGTLDriveChildList:(GTLDriveChildList *)children withAlert:(UIAlertView *)alert forCount:(int)_count{
    
    __block int count =_count;
    
    int totalChildren = children.items.count;
    
    [self.driveService executeQuery:query
                  completionHandler:^(GTLServiceTicket *ticket,
                                      GTLDriveFile *file,
                                      NSError *error) {
                      
                      if (error == nil) {
                          if (file != nil) { //checking the file resource is available or not
                              //only add the file info if that file was not in trash
                              if (file.labels.trashed.intValue != 1){
                                  [self addFileMetaDataInfo:file withGTLDriveChildList:children];
                              }
                          }
                          if (count  == totalChildren) {
                              [alert dismissWithClickedButtonIndex:0 animated:YES];
                              
                              [self.driveTableView reloadData];
                              self.title = [NSString stringWithFormat:@"Drive:%lu",(unsigned long)self.folderArray.count + self.fileArray.count];
                          }
                          //                          NSLog(@"\noriginal name = %@,\n lastmodifiedUsername %@ \n title%@", file.originalFilename,file.lastModifyingUserName,file.title);
                          
                      }else{
                          if (count == totalChildren) {
                              NSLog(@"Google Drive: processed all children, now stopping HUDView - 2");
                          }
                      }
                  }];
    
}

-(void)addFileMetaDataInfo:(GTLDriveFile*)file withGTLDriveChildList:(GTLDriveChildList *)children {
    
    NSString *fileName = @"";
    NSString *downloadURL = @"";
    NSString *mimeType_ = @"";
    BOOL isFolder = NO;
    if (file.originalFilename.length)
        fileName = file.originalFilename;
    else
        fileName = file.title;
    
    mimeType_ = file.mimeType;
    
    if ([mimeType_ isEqualToString:@"application/vnd.google-apps.folder"]) {
        
        [folderArray addObject:fileName];
        isFolder = YES;

    } else {
        
        //the file download url not exists for native google docs. Sicne we can set the import file mime type
        //here we set the mime as pdf. Since we can download the file content in the form of pdf
        
        if (!file.downloadUrl) {
            
            GTLDriveFileExportLinks *fileExportLinks;
            
            NSString    *exportFormat=@"application/pdf";
            
            fileExportLinks = [file exportLinks];
            
            downloadURL = [fileExportLinks JSONValueForKey:exportFormat];
            
        } else {
            downloadURL = file.downloadUrl;
            
        }
        if (downloadURL.length) {
            
            [fileArray addObject:fileName];
            NSArray *fileInfoArray = [NSArray arrayWithObjects:file.identifier, file.mimeType, downloadURL,
                                      [NSNumber numberWithBool:isFolder], nil];
            
            NSDictionary *dict = [NSDictionary dictionaryWithObject:fileInfoArray forKey:fileName];
            
            [self.driveFiles addObject:dict];
        }
        
    }
    
    if (![fileNames containsObject:fileName]) {
        
        [fileNames addObject:fileName];
    }
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
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    if (error == nil) {
        [self isAuthorizedWithAuthentication:auth];
    }
}

-(void)addFile:(UIImage *)image{
    
    // We need data to upload it so convert it into data
    // If you are getting your file from any path then use "dataWithContentsOfFile:" method
    if (mimeType.length == 0) {
        return;
    }
    UIAlertView *alert = [WAEditUtilities showLoadingMessageWithTitle:@"Please wait while uploading"
                                                             delegate:self];
    NSData *data;// = [NSData dataWithContentsOfFile:filePath];
    
    if (image ==nil) {
        NSString *title = @"IRCTC Ltd,Booked Ticket Printing";
        NSString *filePath = [[NSBundle mainBundle] pathForResource:title ofType:@"pdf"];//foofile;
        data= [NSData dataWithContentsOfFile:filePath];
    }else{// if([mimeType isEqualToString:@"application/pdf"]){
        data = UIImagePNGRepresentation(image);
    }
    
    // This is just because of unique name you can give it whatever you want
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd-MMM-yyyy-hh-mm-ss"];
    NSString *fileName = [df stringFromDate:[NSDate date]];//name of the file
    
    fileName =  [fileName stringByAppendingPathExtension:[[mimeType componentsSeparatedByString:@"/"] objectAtIndex:1]];//either png/pdf
    
    // Initialize newFile like this
    GTLDriveFile *newFile = [[GTLDriveFile alloc] init];
    newFile.mimeType = mimeType;
    newFile.originalFilename = fileName;
    newFile.title = fileName;
    
    // Query and UploadParameters
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:data MIMEType:mimeType];
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:newFile uploadParameters:uploadParameters];
    
    // This is for uploading into specific folder, I set it "root" for root folder.
    // You can give any "folderIdentifier" to upload in that folder
    GTLDriveParentReference *parentReference = [GTLDriveParentReference object];
    parentReference.identifier = @"root";
    newFile.parents = @[parentReference];
    
    // And at last this is the method to upload the file
    [[self driveService] executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        
        [alert dismissWithClickedButtonIndex:0 animated:YES];
        NSString *msg = @"";
        if (error){
            msg = error.description;
            NSLog(@"Error: %@", error.description);
        }
        else{
            msg = @"File has been uploaded successfully in root folder.";
        }
        [WAEditUtilities showErrorMessageWithTitle:msg
                                           message:[error description]
                                          delegate:nil];
    }];
}
/*
 Printing description of a:
 <__NSArrayI 0x14526ff0>(
 <__NSArrayI 0x146c1920>(
 0B6VjnmePsu00THQ4OTJ1UTlldTg,
 application/pdf,
 https://doc-14-a4-docs.googleusercontent.com/docs/securesc/35an07ajimpht1f1i5ef8355do0ahjkg/h1pq5iuogcegeehh5qr35d1v43dnjk96/1395309600000/03885075835892874531/03885075835892874531/0B6VjnmePsu00THQ4OTJ1UTlldTg?h=12873800080832014203&e=download&gd=true,
 0
 )
 )
 */
#pragma mark - UIButton Actions
-(IBAction)downloadButtonTaped:(id)sender{
    
    WAAttachmentViewController *attachmentVC = [[WAAttachmentViewController alloc]initWithNibName:@"WAAttachmentViewController" bundle:nil];
    
    attachmentVC.urlArray = self.downloadedDataFileArray;
    
    [self.navigationController pushViewController:attachmentVC animated:YES];
}

-(void)cellDownloadButtonTouchUpInside:(NSInteger )cellIndex{
    
    NSArray *a = [[self.driveFiles objectAtIndex:cellIndex] allValues];
    
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
            
           
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"dd-MMM-yyyy-hh-mm-ss"];
            NSString *fileName = [df stringFromDate:[NSDate date]];//name of the file
            
            fileName =  [fileName stringByAppendingPathExtension:[[mime_Type componentsSeparatedByString:@"/"] objectAtIndex:1]];//either png/pdf
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];

            //replace existing file if we have to.
            BOOL success = [data writeToFile:filePath atomically:YES];
            if (success) {
                NSLog(@"%@ saved to disk successfully.", [[mime_Type componentsSeparatedByString:@"/"] objectAtIndex:1]);
                NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:filePath];
                NSData *data1 = [NSData dataWithContentsOfURL:outputURL];
                NSLog(@"data length%d",data1.length);
                [self.downloadedDataFileArray addObject:outputURL];
            }

        } else
            alertMsg = [error description];
        [WAEditUtilities showErrorMessageWithTitle:@""
                                           message:alertMsg
                                          delegate:self];
    }];
}

-(void)addButtonClicked:(id)sender{
    
    UIAlertView *alertView =  [[UIAlertView alloc] initWithTitle:@"" message:@"Choose type of file to add to Google Drive" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"PDF",@"Image or Photo from Device",nil];
    [alertView show];
    
}
//https://developers.google.com/drive/web/manage-downloads

- (IBAction)refreshButtonClicked:(id)sender {
    
    [self loadDriveFiles];
}

- (IBAction)authButtonClicked:(id)sender {
    if (!self.isAuthorized) {
        // Sign in.
        SEL finishedSelector = @selector(viewController:finishedWithAuth:error:);
        GTMOAuth2ViewControllerTouch *authViewController =
        [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDrive//kGTLAuthScopeDriveFile
                                                   clientID:kClientId
                                               clientSecret:kClientSecret
                                           keychainItemName:kKeychainItemName
                                                   delegate:self
                                           finishedSelector:finishedSelector];
        [self presentViewController:authViewController animated:YES completion:nil];
    } else {
        // Sign out
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
        [[self driveService] setAuthorizer:nil];
        self.authButton.title = @"Sign in";
        self.isAuthorized = NO;
        [self.driveFiles removeAllObjects];
        [self.driveTableView reloadData];
        
        self.title = [NSString stringWithFormat:@"Drive:%lu",(unsigned long)self.folderArray.count + self.fileArray.count];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    switch (section) {
        case FILE_SECTION:
            return self.fileArray.count;
            break;
            
        case FOLDER_SECTION:
            return self.folderArray.count;
            break;
        default:
            break;
    }
    return 0;
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
    switch (indexPath.section) {
            
        case FILE_SECTION:{
            customCell.selectionStyle = UITableViewCellSelectionStyleNone;
            customCell.accessoryType = UITableViewCellAccessoryNone;
            customCell.cell_button.hidden = NO;
            customCell.cellButtonTappedFromCellCallBack = ^(){
                [self cellDownloadButtonTouchUpInside:indexPath.row];
            };
            if (self.fileArray.count >0)
                customCell.nameLbl.text =[self.fileArray objectAtIndex:indexPath.row];
            break;
        }
        case FOLDER_SECTION:{
            customCell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            customCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            customCell.cell_button.hidden = YES;
            if (self.folderArray.count >0)
                customCell.nameLbl.text =[self.folderArray objectAtIndex:indexPath.row];
            break;
        }
        default:
            break;
    }
    return customCell;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NSString *headerText = @"";
    
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    switch (section) {
        case FILE_SECTION:{
            headerText = [NSString stringWithFormat:@"File Number:%lu",(unsigned long)self.fileArray.count];
            break;
        }
        case FOLDER_SECTION:{
            headerText = [NSString stringWithFormat:@"Folder Number:%lu",(unsigned long)self.folderArray.count];
            break;
        }
        default:
            break;
    }
    headerLabel.text = headerText;
    return headerLabel;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30.f;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"drivefilesArray.count %d",self.driveChildren.count);
    switch (indexPath.section) {
        case FOLDER_SECTION:{
            GTLDriveChildReference *ref = [self.driveChildren objectAtIndex:indexPath.row];
            [self getFileListFromSpecifiedParentFolder:ref.identifier];
            break;
        }
        default:
            break;
    }
}
-(void)getFileListFromSpecifiedParentFolder:(NSString *)folderID {
    
    [childrenFolder removeAllObjects];
    
    UIAlertView *alert = [WAEditUtilities showLoadingMessageWithTitle:@"Please wait while retriving files"
                                                             delegate:self];
    
    GTLQueryDrive *query2 = [GTLQueryDrive queryForChildrenListWithFolderId:folderID];
    query2.maxResults = 1000;
    
    // queryTicket can be used to track the status of the request.
    [self.driveService executeQuery:query2
                  completionHandler:^(GTLServiceTicket *ticket,
                                      GTLDriveChildList *children, NSError *error) {
                      NSLog(@"\nGoogle Drive: children file count in the folder: %lu", (unsigned long)children.items.count);
                      //incase there is no files under this folder then we can avoid the fetching process
                      if (!children.items.count) {
                          
                          NSLog(@"Error:%@",error.description);
                          [alert dismissWithClickedButtonIndex:0 animated:YES];
                          [WAEditUtilities showErrorMessageWithTitle:@"No files to show"
                                                             message:[error description]
                                                            delegate:self];
                          return ;
                      }
                      if (error == nil) {
                          
                          for (GTLDriveChildReference *child in children) {
                              
                              GTLQuery *query = [GTLQueryDrive queryForFilesGetWithFileId:child.identifier];
                              // queryTicket can be used to track the status of the request.
                              [self trackStatusOfChildFolderRequest:query forGTLDriveChildList:children withAlert:alert ];
                          }
                      }
                  }];
}

-(void)trackStatusOfChildFolderRequest:(GTLQuery *)query forGTLDriveChildList:(GTLDriveChildList *)children withAlert:(UIAlertView *)alert{
    
    [self.driveService executeQuery:query
                  completionHandler:^(GTLServiceTicket *ticket,
                                      GTLDriveFile *file,
                                      NSError *error) {
                      if (file != nil) { //checking the file resource is available or not
                          //only add the file info if that file was not in trash
                          if (file.labels.trashed.intValue != 1){
                              [self addChildFileMetaDataInfo:file withGTLDriveChildList:children];
                          }
                      }
                      
//                      NSLog(@"\nfile name = %@", file.title);
                      if (file.title.length > 0) {
                          [childrenFolder addObject:file.title];
                      }
                      if (childrenFolder.count == children.items.count) {
                          [alert dismissWithClickedButtonIndex:0 animated:YES];
                          WAChildViewController *childVC = [[WAChildViewController alloc]initWithNibName:@"WAChildViewController" bundle:nil];
                          childVC.childDriveFileArray = self.childFolderDriveFileArray;
                          [self.navigationController pushViewController:childVC animated:YES];
                      }
                  }];


}
-(void)addChildFileMetaDataInfo:(GTLDriveFile*)file withGTLDriveChildList:(GTLDriveChildList *)children {
    
    NSString *fileName = @"";
    NSString *downloadURL = @"";
    NSString *mimeType_ = @"";
    
    BOOL isFolder = NO;
    
    fileName = file.title;
    
    mimeType_ = file.mimeType;
    
    //the file download url not exists for native google docs. Sicne we can set the import file mime type
    //here we set the mime as pdf. Since we can download the file content in the form of pdf
    
    if (!file.downloadUrl) {
        
        GTLDriveFileExportLinks *fileExportLinks;
        
        NSString    *exportFormat=@"application/pdf";
        
        fileExportLinks = [file exportLinks];
        
        downloadURL = [fileExportLinks JSONValueForKey:exportFormat];
        
    } else {
        downloadURL = file.downloadUrl;
        
    }
    if (downloadURL.length) {
        
        [fileArray addObject:fileName];
        NSArray *fileInfoArray = [NSArray arrayWithObjects:file.title,file.identifier, file.mimeType, downloadURL,
                                  [NSNumber numberWithBool:isFolder], nil];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObject:fileInfoArray forKey:fileName];
        
        [self.childFolderDriveFileArray addObject:dict];
    }
}


#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    
    if (buttonIndex == 2){
        mimeType = @"image/png";
        [self chooseImagefromPickerController];
    }
    else if(buttonIndex == 1){
        mimeType = @"application/pdf";
        [self addFile:nil];

    }
        else if (buttonIndex == alertView.cancelButtonIndex)
            return;
    
}
-(void)chooseImagefromPickerController{
    
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])

        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    else
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;

    [self presentViewController:imagePickerController animated:YES completion:nil];
    
}

#pragma mark - UIImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        [self addFile:chosenImage];
    }];
    
}
/*
 Documents
 HTML	                text/html
 Plain text	            text/plain
 Rich text	            application/rtf
 Open Office doc	    application/vnd.oasis.opendocument.text
 PDF	                application/pdf
 MS Word document	    application/vnd.openxmlformats-officedocument.wordprocessingml.document
 Spreadsheets
 MS Excel	            application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
 Open Office sheet	    application/x-vnd.oasis.opendocument.spreadsheet
 PDF	                application/pdf
 Drawings
 JPEG	                image/jpeg
 PNG	                image/png
 SVG	                image/svg+xml
 PDF	                application/pdf
 Presentations
 MS PowerPoint	        application/vnd.openxmlformats-officedocument.presentationml.presentation
 Open Office, PDF	    application/pdf
 
 */
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
