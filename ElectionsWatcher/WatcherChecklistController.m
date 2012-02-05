//
//  FirstViewController.m
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherChecklistController.h"
#import "WatcherChecklistSectionController.h"
#import "AppDelegate.h"

@implementation WatcherChecklistController

@synthesize checklistTableView;
@synthesize watcherChecklist;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if ( self ) {
        self.title = @"Наблюдатель"; // NSLocalizedString(@"First", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
        self.watcherChecklist = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"WatcherChecklist" 
                                                                                                            ofType: @"plist"]];
    }
    
    return self;
}
							
- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void) dealloc {
    [checklistTableView release];
    [watcherChecklist release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.rightBarButtonItem = 
        [[[UIBarButtonItem alloc] initWithTitle: @"S.O.S." style: UIBarButtonItemStylePlain target: nil action: nil] autorelease];
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
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
    return [watcherChecklist count];
}

- (void) tableView: (UITableView *) tableView willDisplayCell: (UITableViewCell *) cell forRowAtIndexPath: (NSIndexPath *) indexPath {
    NSArray *values = [watcherChecklist allValues];
    NSArray *sortedValues = [values sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"order" 
                                                                                                                         ascending: YES]]];
    NSDictionary *screenInfo = [sortedValues objectAtIndex: indexPath.row];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSDictionary *bindParams = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: indexPath.row], @"SECTION_INDEX", nil];
    NSArray *results = [appDelegate executeFetchRequest: @"findItemsBySection" forEntity: @"ChecklistItem" withParameters: bindParams];
                        
    
    cell.textLabel.text = [screenInfo objectForKey: @"title"];
    cell.detailTextLabel.text = [NSString stringWithFormat: @"Отмечено %d пунктов", [results count]];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    static NSString *cellId = @"sectionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
    
    if ( cell == nil ) {
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: cellId] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    
    return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    NSArray *values = [watcherChecklist allValues];
    NSArray *sortedValues = [values sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"order" 
                                                                                                                         ascending: YES]]];
    WatcherChecklistSectionController *sectionController = [[WatcherChecklistSectionController alloc] initWithStyle: UITableViewStylePlain];
    sectionController.sectionData = [sortedValues objectAtIndex: indexPath.row];
    sectionController.sectionIndex = indexPath.row;
    
    [self.navigationController pushViewController: sectionController animated: YES];
    [sectionController release];
}


@end
