//
//  WatcherReportController.m
//  ElectionsWatcher
//
//  Created by xfire on 11.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherReportController.h"
#import "WatcherReportGraph.h"
#import "AppDelegate.h"
#import "ChecklistItem.h"
#import "PollingPlace.h"

@implementation WatcherReportController

@synthesize goodItems, badItems;
@synthesize watcherChecklist;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    
    if ( self ) {
        self.tabBarItem.image = [UIImage imageNamed:@"report"];
        self.tabBarItem.title = @"Отчет";
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
    [goodItems release];
    [badItems release];
    [watcherChecklist release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.watcherChecklist = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"WatcherChecklist" 
                                                                                                        ofType: @"plist"]];
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
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSArray *checklistItems = [appDelegate.currentPollingPlace.checklistItems allObjects];
    
    NSPredicate *badPredicate   = [NSPredicate predicateWithFormat: @"SELF.sectionIndex >= 0 && SELF.screenIndex >= 0 && SELF.value LIKE 'false'"];
    NSPredicate *goodPredicate  = [NSPredicate predicateWithFormat: @"SELF.sectionIndex >= 0 && SELF.screenIndex >= 0 && SELF.value LIKE 'true'"];
    
    self.goodItems = [checklistItems filteredArrayUsingPredicate: goodPredicate];
    self.badItems = [checklistItems filteredArrayUsingPredicate: badPredicate];
    
    [self.tableView reloadData];
    
    self.navigationItem.title = appDelegate.currentPollingPlace ?
        [NSString stringWithFormat: @"Отчет по %@ № %@", 
         appDelegate.currentPollingPlace.type, appDelegate.currentPollingPlace.number] :
        @"Отчет";
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ( section == 1 ) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        if ( appDelegate.currentPollingPlace )
            return self.badItems.count ?
                [NSString stringWithFormat: @"Нарушения на %@ № %@", 
                 appDelegate.currentPollingPlace.type, appDelegate.currentPollingPlace.number] :
                [NSString stringWithFormat: @"На %@ № %@ не отмечено нарушений", 
                 appDelegate.currentPollingPlace.type, appDelegate.currentPollingPlace.number] ;
        else
            return @"Нет данных";
    } else {
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return ( section == 1 && self.badItems.count ) ? 80 : 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ( section == 1 && self.badItems.count ) {
        UIView *footerView = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, tableView.bounds.size.width, 80)] autorelease];
        
        CGRect labelFrame = CGRectMake(15, 0, footerView.bounds.size.width-30, 20);
        UILabel *label1 = [[[UILabel alloc] initWithFrame: labelFrame] autorelease];
        UILabel *label2 = [[[UILabel alloc] initWithFrame: CGRectOffset(labelFrame, 0, 20)] autorelease];
        UILabel *label3 = [[[UILabel alloc] initWithFrame: CGRectOffset(labelFrame, 0, 40)] autorelease];
        UILabel *label4 = [[[UILabel alloc] initWithFrame: CGRectOffset(labelFrame, 0, 60)] autorelease];
        
        NSArray *labels = [NSArray arrayWithObjects: label1, label2, label3, label4, nil];
        for ( UILabel *label in labels ) {
            label.backgroundColor = [UIColor clearColor];
            label.font = [UIFont boldSystemFontOfSize: 15];
            label.textColor = [UIColor darkTextColor];
            [footerView addSubview: label];
        }
        
        label1.text = @"Чтобы подать жалобу по нарушениям:";
        label2.text = @"1. Заполните жалобу.";
        label3.text = @"2. Передайте её председателю.";
        label4.text = @"3. Оставьте один экземпляр у себя.";
        
        return footerView;
    } else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( section == 0 ) {
        return 1;
    } else {
        return self.badItems.count;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ( indexPath.section == 0 && indexPath.row == 0 ) ? 200 : 50;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.section == 1 ) {
        ChecklistItem *item = [self.badItems objectAtIndex: indexPath.row];
        
        NSArray *values = [watcherChecklist allValues];
        NSArray *sortedValues = [values sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"order" 
                                                                                                                             ascending: YES]]];
        
        NSDictionary *sectionInfo = [sortedValues objectAtIndex: [item.sectionIndex intValue]];
        NSArray *sectionScreens = [sectionInfo objectForKey: @"screens"];
        NSDictionary *screenInfo = [sectionScreens objectAtIndex: [item.screenIndex intValue]];
        NSArray *screenItems = [screenInfo objectForKey: @"items"];
        NSPredicate *itemPredicate = [NSPredicate predicateWithFormat: @"SELF.name LIKE %@", item.name];
    
        cell.textLabel.text = [[[screenItems filteredArrayUsingPredicate: itemPredicate] lastObject] objectForKey: @"title"];
    }
    
    if ( indexPath.section == 0 && indexPath.row == 0 ) {
        CGRect cb = cell.contentView.bounds;
        
        WatcherReportGraph *graph = (WatcherReportGraph *) [cell.contentView viewWithTag: 11];
        graph.superview.frame = CGRectInset(cb,10,40);
        graph.frame = graph.superview.bounds;
        graph.goodCount = self.goodItems.count;
        graph.badCount = self.badItems.count;
        
        [graph setNeedsDisplay];
        
        UILabel *goodCountLabel = (UILabel *) [cell.contentView viewWithTag: 12];
        UILabel *badCountLabel = (UILabel *) [cell.contentView viewWithTag: 13];
        
        
        goodCountLabel.frame = CGRectMake(10, 0, cb.size.width-20, 30);
        goodCountLabel.text = self.goodItems.count ? 
            [NSString stringWithFormat: @"%d требований выполнено", self.goodItems.count] : @"Нет отметок";
        
        badCountLabel.frame = CGRectMake(10, cb.size.height-30, cb.size.width-20, 30);
        badCountLabel.text = self.badItems.count ? 
            [NSString stringWithFormat: @"%d нарушений", self.badItems.count] : @"Нет отметок";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = ( indexPath.section == 0 && indexPath.row == 0 ) ? @"GraphCell" : @"ReportCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
        if ( indexPath.section == 0 && indexPath.row == 0 ) {
            UIView *graphHolder = [[UIView alloc] init];
            WatcherReportGraph *graph = [[WatcherReportGraph alloc] init];
            [graph setTag: 11];
            [graphHolder addSubview: graph];
            [graph release];
            [cell.contentView addSubview: graphHolder];
            [graphHolder release];
            
            UILabel *goodCountLabel = [[UILabel alloc] init];
            goodCountLabel.textColor = [UIColor colorWithRed: 0 green: 0x77/255.0f blue: 0xcb/255.0f alpha: 1];
            goodCountLabel.font = [UIFont boldSystemFontOfSize: 16];
            goodCountLabel.backgroundColor = [UIColor clearColor];
            goodCountLabel.tag = 12;
            goodCountLabel.textAlignment = UITextAlignmentLeft;
            [cell.contentView addSubview: goodCountLabel];
            [goodCountLabel release];
            
            UILabel *badCountLabel = [[UILabel alloc] init];
            badCountLabel.textColor = [UIColor colorWithRed: 0xdf/255.0f green: 0x2a/255.0f blue: 0 alpha: 1];
            badCountLabel.font = [UIFont boldSystemFontOfSize: 16];
            badCountLabel.backgroundColor = [UIColor clearColor];
            badCountLabel.tag = 13;
            badCountLabel.textAlignment = UITextAlignmentRight;
            [cell.contentView addSubview: badCountLabel];
            [badCountLabel release];
            
        } else {
            cell.textLabel.font = [UIFont boldSystemFontOfSize: 12];
            cell.textLabel.numberOfLines = 3;
        }
    }
    
    cell.textLabel.text = nil;

    return cell;
}

@end
