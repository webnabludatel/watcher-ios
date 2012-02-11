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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if ( self ) {
        self.title = @"Профиль"; // NSLocalizedString(@"First", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

# pragma mark - UITableViewController

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return @"Информация о наблюдателе";
        case 1:
            return @"Информация об участке";
        default:
            return nil;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ( section == 1 ) {
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
    return section == 1 ? 60 : 0;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return 3;
        case 1:
            return 5;
        default:
            return 0;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    static NSString *cellId = @"SettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
    
    if ( cell == nil ) {
        cell = [[WatcherSettingsCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellId];
    }
    
    return cell;
}

@end
