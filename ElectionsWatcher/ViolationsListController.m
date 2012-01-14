//
//  FirstViewController.m
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViolationsListController.h"

@implementation ViolationsListController

@synthesize violationsTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"First", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}
							
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void) dealloc {
    [violationsTableView release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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
    return 2;
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section {
    switch ( section ) {
        case 0:
            return @"Замеченные нарушения";
        case 1:
            return @"Зарегистрированные нарушения";
        default:
            return @"---";
    }
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
    return 5;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
    static NSString *cellId = @"violationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
    
    if ( cell == nil ) {
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: cellId] autorelease];
    }
    
    return cell;
}


@end
