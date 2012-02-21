//
//  WatcherTwitterSetupController.m
//  ElectionsWatcher
//
//  Created by xfire on 19.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherTwitterSetupController.h"
#import "AppDelegate.h"
#import "WatcherProfile.h"

@implementation WatcherTwitterSetupController

@synthesize twitterAccounts = _twitterAccounts;
@synthesize selectedUsername = _selectedUsername;
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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
    [_twitterAccounts release];
    [_selectedUsername release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Twitter";
    self.twitterAccounts = [NSMutableArray array];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle: @"Сохранить"
                                                                               style: UIBarButtonItemStyleDone
                                                                              target: self
                                                                              action: @selector(handleDoneButton:)] autorelease];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle: @"Отменить"
                                                                              style: UIBarButtonItemStylePlain
                                                                             target: self
                                                                             action: @selector(handleCancelButton:)] autorelease];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    //  Request access from the user for access to his Twitter accounts
    [self.twitterAccounts removeAllObjects];
    [self.twitterAccounts addObjectsFromArray: [store accountsWithAccountType: twitterAccountType]];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.selectedUsername = appDelegate.watcherProfile.twNickname;
    

    [self.tableView reloadData];
    
    [store release];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.twitterAccounts.count;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ACAccount *twitterAccount = [self.twitterAccounts objectAtIndex: indexPath.row]; 
    cell.textLabel.text = twitterAccount.username;
    
    if ( [self.selectedUsername isEqualToString: twitterAccount.username] )
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if ( cell == nil ) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.textLabel.text = nil;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedUsername = [[self.twitterAccounts objectAtIndex: indexPath.row] username]; 
    
    [self.tableView reloadData];
}

#pragma mark - Done/cancel

- (void) handleCancelButton: (id) sender {
    [self.delegate watcherTwitterSetupControllerDidCancel: self];
}

- (void) handleDoneButton: (id) sender {
    [self.delegate watcherTwitterSetupController: self didSelectUsername: self.selectedUsername];
}

@end
