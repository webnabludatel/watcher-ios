//
//  WatcherSOSController.m
//  ElectionsWatcher
//
//  Created by xfire on 11.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherSOSController.h"
#import "WatcherChecklistScreenCell.h"
#import "AppDelegate.h"
#import "PollingPlace.h"
#import "WatcherProfile.h"

@implementation WatcherSOSController

static NSString *sosReportSections[] = { @"sos_report" };

@synthesize sosReport;
@synthesize latestActiveResponder;
@synthesize HUD;
@synthesize sosItems;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if ( self ) {
        self.tabBarItem.image = [UIImage imageNamed:@"sos"];
        self.tabBarItem.title = @"S.O.S.";
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
    [sosReport release];
    [sosItems release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *defaultPath = [[NSBundle mainBundle] pathForResource: @"WatcherSOS" ofType: @"plist"];
    self.sosReport = [NSDictionary dictionaryWithContentsOfFile: defaultPath];
    self.sosItems = [NSMutableSet set];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    [self.tableView reloadData];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.navigationItem.title = appDelegate.watcherProfile.currentPollingPlace ?
        [NSString stringWithFormat: @"%@ № %@", 
         appDelegate.watcherProfile.currentPollingPlace.type, appDelegate.watcherProfile.currentPollingPlace.number] :
        @"Меня удаляют";
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view controller

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.sosReport allKeys] count];
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ( section > 0 ) {
    NSDictionary *sectionInfo = [self.sosReport objectForKey: sosReportSections[section]];
        return [sectionInfo objectForKey: @"title"];
    } else {
        return nil;
    }
}
 */

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ( section == 0 ) 
        return 40;
    else
        return 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ( section == 0 ) {
        NSDictionary *sectionInfo = [self.sosReport objectForKey: sosReportSections[section]];
        UIView *headerView = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, tableView.bounds.size.width, 40)] autorelease];
        UILabel *textLabel = [[[UILabel alloc] initWithFrame: CGRectMake(10, 0, tableView.bounds.size.width-50, 40)] autorelease];
        UIButton *infoButton = [UIButton buttonWithType: UIButtonTypeInfoDark];
        
        textLabel.text = [sectionInfo objectForKey: @"title"];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.textColor = [UIColor colorWithRed:0.265 green:0.294 blue:0.367 alpha:1.000];
        textLabel.font = [UIFont boldSystemFontOfSize: 15];
        textLabel.numberOfLines = 1;
        textLabel.textAlignment = UITextAlignmentLeft;
        
        infoButton.frame = CGRectMake(tableView.bounds.size.width-40, 0, 40, 40);
        
        [infoButton addTarget: self action: @selector(showInstructions) forControlEvents: UIControlEventTouchUpInside];
        
        headerView.backgroundColor = [UIColor clearColor];
        
        [headerView addSubview: textLabel];
        [headerView addSubview: infoButton];
        
        return headerView;
    } else {
        return nil;
    }
    
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ( section == [[self.sosReport allKeys] count] - 1 ) {
        UIView *footerView      = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, tableView.bounds.size.width, 60)] autorelease];
        UIButton *sendButton    = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        sendButton.frame = CGRectInset(footerView.bounds, 10, 10);
        [sendButton setTitle: @"Отправить сообщение" forState: UIControlStateNormal];
        [sendButton addTarget: self action: @selector(handleSendButton:) forControlEvents: UIControlEventTouchUpInside];
        [footerView addSubview: sendButton];
        
        return footerView;
    } else {
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return ( section == [[self.sosReport allKeys] count] - 1 ) ? 60 : 0;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [self.sosReport objectForKey: sosReportSections[section]];
    return [[sectionInfo objectForKey: @"items"] count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *sectionInfo = [self.sosReport objectForKey: sosReportSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    NSString *itemTitle = [itemInfo objectForKey: @"title"];
    
    int controlType = [[itemInfo objectForKey: @"control"] intValue];
    
    CGSize labelSize = [itemTitle sizeWithFont: [UIFont boldSystemFontOfSize: 13] 
                             constrainedToSize: CGSizeMake(280, 120) 
                                 lineBreakMode: UILineBreakModeWordWrap];
    
    return controlType == INPUT_COMMENT ? 
            labelSize.height + 120 : 
        itemTitle.length ? 
            labelSize.height + 70 : 60;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *sectionInfo = [self.sosReport objectForKey: sosReportSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSArray *checklistItems = self.sosItems ? 
        [self.sosItems allObjects] :
        [[appDelegate.watcherProfile.currentPollingPlace checklistItems] allObjects];
    
    NSPredicate *itemPredicate = [NSPredicate predicateWithFormat: @"SELF.name LIKE %@", [itemInfo objectForKey: @"name"]];
    NSArray *existingItems = [checklistItems filteredArrayUsingPredicate: itemPredicate];
    
    if ( existingItems.count ) {
        [(WatcherChecklistScreenCell *) cell setChecklistItem: [existingItems lastObject]];
    } else {
        ChecklistItem *checklistItem = [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                                     inManagedObjectContext: appDelegate.managedObjectContext];
        
        [(WatcherChecklistScreenCell *) cell setChecklistItem: checklistItem];
    }
    
    [cell setNeedsLayout];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId = [NSString stringWithFormat: @"SosCell_%d_%d", indexPath.section, indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
    NSDictionary *sectionInfo = [self.sosReport objectForKey: sosReportSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    
    if ( cell == 0 ) {
        cell = [[[WatcherChecklistScreenCell alloc] initWithStyle: UITableViewCellStyleDefault 
                                                  reuseIdentifier: cellId 
                                                     withItemInfo: itemInfo] autorelease];
        [(WatcherChecklistScreenCell *) cell setSaveDelegate: self];
        [(WatcherChecklistScreenCell *) cell setSectionName: sosReportSections[indexPath.section]];
    }
    
    return cell;
}

#pragma mark - Save delegate

-(void)didSaveAttributeItem:(ChecklistItem *)item {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ( ! [appDelegate.watcherProfile.currentPollingPlace.checklistItems containsObject: item] )
        [appDelegate.watcherProfile.currentPollingPlace addChecklistItemsObject: item];
    
    [self.sosItems addObject: item];
}

-(BOOL)isCancelling {
    return NO;
}

#pragma mark - Save & send

- (void) handleSendButton: (id) sender {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSPredicate *itemPredicate = [NSPredicate predicateWithFormat: @"SELF.name LIKE %@", @"sos_report_text"];
    ChecklistItem *sosReportText = [[[sosItems allObjects] filteredArrayUsingPredicate: itemPredicate] lastObject];
    
    if ( sosReportText.value.length > 0 ) {
        NSError *error = nil;
        [appDelegate.managedObjectContext save: &error];
        if ( error ) 
            NSLog(@"error saving emergency message: %@", error.description);
        
        [self.sosItems removeAllObjects];

        HUD = [[MBProgressHUD alloc] initWithWindow: [UIApplication sharedApplication].keyWindow];
        HUD.delegate = self;
        HUD.labelText = @"Отправка";
        
        [[UIApplication sharedApplication].keyWindow addSubview: HUD];
        
        [HUD show: YES];
        [self performSelector: @selector(cleanupSOSMessage) withObject: nil afterDelay: 5];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Ошибка" 
                                                            message: @"Не введен текст сообщения" 
                                                           delegate: nil 
                                                  cancelButtonTitle: @"OK" 
                                                  otherButtonTitles: nil];
        [alertView show];
        [alertView release];
    }
}

- (void) cleanupSOSMessage {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    NSArray *checklistItems = [[appDelegate.watcherProfile.currentPollingPlace checklistItems] allObjects];
    NSPredicate *itemPredicate = [NSPredicate predicateWithFormat: @"SELF.sectionName LIKE %@", @"sos_report"];
    for ( ChecklistItem *item in [checklistItems filteredArrayUsingPredicate: itemPredicate] )
        [appDelegate.managedObjectContext deleteObject: item];
    
    NSError *error = nil;
    [appDelegate.managedObjectContext save: &error];
    if ( error ) 
        NSLog(@"error cleaning up emergency message: %@", error.description);
    
    
    [HUD hide: YES];
    [self.tableView reloadData];
}

- (void) hudWasHidden {
    [HUD release];
}

#pragma mark - Instructions

- (void) showInstructions {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Инструкции" 
                                                        message: @"Вашингтонский обком рекомендует\n\n1. Накрывайтесь белой простыней\n2. Ползите в направлениии кладбища\n3. Все равно мы все умрем.\n" 
                                                       delegate: nil 
                                              cancelButtonTitle: @"OK" 
                                              otherButtonTitles: nil];
    
    [alertView show];
    [alertView release];
}

@end
