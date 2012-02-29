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
#import "TSAlertView.h"
#import "WatcherDataManager.h"
#import "WatcherInfoHeaderView.h"

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
    appDelegate.watcherProfile.currentPollingPlace.titleString : @"Меня удаляют";
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.sosReport = nil;
    self.sosItems = nil;
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
        return 34;
    else
        return 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ( section == 0 ) {
        NSDictionary *sectionInfo = [self.sosReport objectForKey: sosReportSections[section]];
        
        WatcherInfoHeaderView *headerView = [[[WatcherInfoHeaderView alloc] initWithFrame: CGRectZero 
                                                                                withTitle: [sectionInfo objectForKey: @"title"]] 
                                             autorelease];
        
        [headerView.infoButton addTarget: self 
                                  action: @selector(showInstructions) 
                        forControlEvents: UIControlEventTouchUpInside];
        
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
            labelSize.height + 135 : 
        itemTitle.length ? 
            labelSize.height + 70 : 60;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *sectionInfo   = [self.sosReport objectForKey: sosReportSections[indexPath.section]];
    NSDictionary *itemInfo      = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    
    AppDelegate *appDelegate    = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSPredicate *itemPredicate  = [NSPredicate predicateWithFormat: @"SELF.name LIKE %@", [itemInfo objectForKey: @"name"]];
    NSArray *existingItems      = [[self.sosItems allObjects] filteredArrayUsingPredicate: itemPredicate];
    
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
        [(WatcherChecklistScreenCell *) cell setChecklistCellDelegate: self];
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
    
    if ( appDelegate.watcherProfile.userId != nil ) {
        NSPredicate *itemPredicate = [NSPredicate predicateWithFormat: @"SELF.name LIKE %@", @"sos_report_text"];
        ChecklistItem *sosReportText = [[[sosItems allObjects] filteredArrayUsingPredicate: itemPredicate] lastObject];
        
        if ( sosReportText.value.length > 0 ) {
            NSError *error = nil;
            
            [appDelegate.managedObjectContext save: &error];
            if ( error ) 
                NSLog(@"error saving emergency message: %@", error.description);
            
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
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Ошибка" 
                                                            message: @"Приложение должно пройти регистрацию на сервере прежде, чем можно будет вести наблюдение. При подключении к сети WiFi или GPRS регистрация будет выполнена автоматически."  
                                                           delegate: nil 
                                                  cancelButtonTitle: @"OK" 
                                                  otherButtonTitles: nil];
        [alertView show];
        [alertView release];
    }
}

- (void) cleanupSOSMessage {
    [HUD hide: YES];
    [self.sosItems removeAllObjects];
    [self.tableView reloadData];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Сообщение отправлено" 
                                                        message: @"Сообщение будет передано на сервер в течение нескольких минут, если вы находитесь в зоне действия WiFi или GPRS/EDGE/3G. Если вы указали в настройках контактный телефон, мы свяжемся с вами в ближайшее время." 
                                                       delegate: nil 
                                              cancelButtonTitle: @"OK" 
                                              otherButtonTitles: nil];
    
    [alertView show];
    [alertView release];
}

- (void) hudWasHidden {
    [HUD release];
}

#pragma mark - Instructions

- (void) showInstructions {
    TSAlertView *alertView = [[TSAlertView alloc] initWithTitle: @"Инструкции" 
                                                        message: @"Если Вас удаляют с участка:\n1. Попросите объяснить, чем конкретно Вы препятствуете работе комиссии\n2. Получите письменное решение комиссии со ссылкой на пункт закона о выборах и печатью комиссии\n3. Добейтесь составления акта об административном правонарушении\n4. Помните, если вы член комиссии, вас не имеют право удалить, только отстранить от работы\n5. Если вас удалили, сообщите об этом нам." 
                                                       delegate: nil 
                                              cancelButtonTitle: @"OK" 
                                              otherButtonTitles: nil];
    
    alertView.usesMessageTextView = YES;
    
    [alertView show];
    [alertView release];
}

@end
