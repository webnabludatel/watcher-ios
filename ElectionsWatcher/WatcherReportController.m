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
        self.title = @"Отчет";
        self.tabBarItem.image = [UIImage imageNamed:@"report"];
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
        
        return self.badItems.count ?
            [NSString stringWithFormat: @"Нарушения на %@ № %@", 
             appDelegate.currentPollingPlace.type, appDelegate.currentPollingPlace.number] :
            [NSString stringWithFormat: @"На %@ № %@ не отмечено нарушений", 
             appDelegate.currentPollingPlace.type, appDelegate.currentPollingPlace.number] ;
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
            goodCountLabel.textColor = [UIColor blueColor];
            goodCountLabel.font = [UIFont boldSystemFontOfSize: 16];
            goodCountLabel.backgroundColor = [UIColor clearColor];
            goodCountLabel.tag = 12;
            goodCountLabel.textAlignment = UITextAlignmentLeft;
            [cell.contentView addSubview: goodCountLabel];
            [goodCountLabel release];
            
            UILabel *badCountLabel = [[UILabel alloc] init];
            badCountLabel.textColor = [UIColor redColor];
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
