//
//  WatcherSettingsController.m
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherSettingsController.h"
#import "WatcherSettingsCell.h"

@implementation WatcherSettingsController

@synthesize settings;

static NSString *settingsSections[] = { @"personal_info", @"ballot_district_info" };

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if ( self ) {
        self.title = @"Профиль"; // NSLocalizedString(@"First", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"profile"];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


-(void)dealloc {
    [settings release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    [self loadSettings];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Settings management

- (void) saveSettings {
    if ( self.settings ) {
        NSArray*  paths     = NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory, NSUserDomainMask, YES );
        NSString* settingsPath = [[paths lastObject] stringByAppendingPathComponent: @"WatcherSettings.plist"];
        
        [self.settings writeToFile: settingsPath atomically: YES];
    }
}

- (void) loadSettings {
    NSFileManager *fm   = [NSFileManager defaultManager];
    NSArray*  paths     = NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString* settingsPath = [[paths lastObject] stringByAppendingPathComponent: @"WatcherSettings.plist"];
    
    NSError *error = nil;
    NSPropertyListFormat format = kCFPropertyListXMLFormat_v1_0;
    
    if ( [fm fileExistsAtPath: settingsPath] ) {
        self.settings = [NSPropertyListSerialization propertyListWithData: [NSData dataWithContentsOfFile: settingsPath] 
                                                                  options: NSPropertyListMutableContainersAndLeaves 
                                                                   format: &format
                                                                    error: &error];
        if ( error ) 
            NSLog ( @"error opening settings: %@", error.description );
        
    } else {
        NSString *defaultPath = [[NSBundle mainBundle] pathForResource: @"WatcherSettings" 
                                                                ofType: @"plist"];
        
        self.settings = [NSPropertyListSerialization propertyListWithData: [NSData dataWithContentsOfFile: defaultPath] 
                                                                  options: NSPropertyListMutableContainersAndLeaves 
                                                                   format: &format
                                                                    error: &error];
        
        if ( error ) 
            NSLog ( @"error opening settings: %@", error.description );
        
        [fm copyItemAtPath: defaultPath toPath: settingsPath error: &error];
        
        if ( error ) 
            NSLog ( @"error copying settings to docs path: %@", error.description );
    }
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewController

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[section]];
    return [sectionInfo objectForKey: @"title"];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ( section == [[self.settings allKeys] count] - 1 ) {
        UIView *footerView      = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, tableView.bounds.size.width, 60)] autorelease];
        UIButton *saveButton    = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        UIButton *resetButton   = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        
        CGRect saveButtonFrame, resetButtonFrame;
        CGRectDivide(footerView.bounds, &saveButtonFrame, &resetButtonFrame, footerView.bounds.size.width/2, CGRectMinXEdge);
        
        saveButton.frame = CGRectInset(saveButtonFrame, 10, 10);
        resetButton.frame = CGRectInset(resetButtonFrame, 10, 10);
        
        [saveButton setTitle: @"Сохранить" forState: UIControlStateNormal];
        [resetButton setTitle: @"Сменить участок" forState: UIControlStateNormal];
        
        [footerView addSubview: saveButton];
        [footerView addSubview: resetButton];
        
        return footerView;
    } else {
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return ( section == [[self.settings allKeys] count] - 1 ) ? 60 : 0;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    return [[self.settings allKeys] count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[section]];
    return [[sectionInfo objectForKey: @"items"] count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    NSString *itemTitle = [itemInfo objectForKey: @"title"];
    
    CGSize labelSize = [itemTitle sizeWithFont: [UIFont boldSystemFontOfSize: 13] 
                             constrainedToSize: CGSizeMake(280, 120) 
                                 lineBreakMode: UILineBreakModeWordWrap];
    
    return labelSize.height + 70;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    NSString *cellId = [NSString stringWithFormat: @"SettingsCell_%d_%d", indexPath.section, indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    
    if ( cell == nil ) {
        cell = [[WatcherSettingsCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellId withItemInfo: itemInfo];
    }
    
    return cell;
}

@end
