//
//  FirstViewController.m
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherChecklistController.h"
#import "WatcherChecklistSectionController.h"
#import "WatcherPollingPlaceController.h"
#import "AppDelegate.h"
#import "PollingPlace.h"
#import "WatcherProfile.h"
#import "WatcherTools.h"
#import "WatcherInfoHeaderView.h"
#import "TSAlertView.h"

#define ELECTIONS_DAY           @"04.03.2012"
#define DATE_FORMAT             @"dd.MM.yyyy"
#define TEST_ITEMS_PREDICATE    @"(SELF.timestamp < %@) && (SELF.sectionName != NULL) && (SELF.sectionName != 'sos_report')"

@implementation WatcherChecklistController

@synthesize watcherChecklist;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if ( self ) {
        self.tabBarItem.image = [UIImage imageNamed:@"checklist"];
        self.tabBarItem.title = @"Наблюдение";
    }
    
    return self;
}
							
- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void) dealloc {
    [watcherChecklist release];
    
    [super dealloc];
}

#pragma mark - Check for test data on elections day

- (void) checkForTestDataOnElectionsDay {
    NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
    [df setFormatterBehavior: NSDateFormatterBehavior10_4];
    [df setDateFormat: DATE_FORMAT];
    
    NSDate *electionsDate = [df dateFromString: ELECTIONS_DAY];
    NSDate *currentDate   = [NSDate date];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ( appDelegate.watcherProfile.currentPollingPlace && ( [currentDate compare: electionsDate] == NSOrderedDescending ) ) {
        NSLog(@"checking for items before elections date: %@", electionsDate);
        NSPredicate *predicate = [NSPredicate predicateWithFormat: TEST_ITEMS_PREDICATE, electionsDate];
        NSSet *testItems = [appDelegate.watcherProfile.currentPollingPlace.checklistItems filteredSetUsingPredicate: predicate];
        if ( testItems.count > 0 ) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Тестовые данные" 
                                                                message: @"Для выбранного участка обнаруженые тестовые данные, введенные до начала выборов. Тестовые данные не учитываются в статистике системы и публикуемых отчетах. Удалить тестовые данные?" 
                                                               delegate: self 
                                                      cancelButtonTitle: @"Не удалять" 
                                                      otherButtonTitles: @"Удалить", nil];
            [alertView setTag: 666];
            [alertView show];
            [alertView release];
        }
    }
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ( buttonIndex == 1 && alertView.tag == 666 ) {
        NSDateFormatter* df = [[[NSDateFormatter alloc] init] autorelease];
        [df setFormatterBehavior: NSDateFormatterBehavior10_4];
        [df setDateFormat: DATE_FORMAT];
        
        NSDate *electionsDate = [df dateFromString: ELECTIONS_DAY];
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: TEST_ITEMS_PREDICATE, electionsDate];
        NSSet *testItems = [appDelegate.watcherProfile.currentPollingPlace.checklistItems filteredSetUsingPredicate: predicate];
        
        for ( ChecklistItem *item in testItems )
            [appDelegate.managedObjectContext deleteObject: item];
        
        NSError *error = nil;
        [appDelegate.managedObjectContext save: &error];
        if ( error ) 
            NSLog(@"error removing test data: %@", error.description);
        
        [self.tableView reloadData];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle: @"Назад" 
                                                                              style: UIBarButtonItemStylePlain 
                                                                             target: nil 
                                                                             action: nil] autorelease];

    self.watcherChecklist = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"WatcherChecklist" 
                                                                                                        ofType: @"plist"]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.navigationItem.backBarButtonItem = nil;
    self.watcherChecklist = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.navigationItem.title = appDelegate.watcherProfile.currentPollingPlace ? 
    appDelegate.watcherProfile.currentPollingPlace.titleString : @"Наблюдение";
    
    [self checkForTestDataOnElectionsDay];
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

#pragma mark - Helper methods

- (NSArray *) sortedAndFilteredSections {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSArray *sortDescriptors = [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"order" ascending: YES]];
    NSArray *sortedSections  = [[watcherChecklist allValues] sortedArrayUsingDescriptors: sortDescriptors];
    
    NSPredicate *pollingPlaceTypePredicate = [NSPredicate predicateWithFormat: @"ANY SELF.district_types LIKE %@", 
                                              appDelegate.watcherProfile.currentPollingPlace.type];
    
    return [sortedSections filteredArrayUsingPredicate: pollingPlaceTypePredicate];
}

#pragma mark - UITableView

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    return appDelegate.watcherProfile.currentPollingPlace ? 2 : 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ( section == 0 ) {
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        return [pollingPlaces count]+1;
    } else {
        return [[self sortedAndFilteredSections] count];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title = section == 0 ? @"Избирательные участки" : @"Наблюдение";
    WatcherInfoHeaderView *headerView = [[[WatcherInfoHeaderView alloc] initWithFrame: CGRectZero 
                                                                            withTitle: title] 
                                         autorelease];

    
    [headerView.infoButton setTag: section];
    [headerView.infoButton addTarget: self 
                              action: @selector(showSectionHelp:) 
                    forControlEvents: UIControlEventTouchUpInside];
    
    return headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? 40 : 60;
}

- (void) tableView: (UITableView *) tableView willDisplayCell: (UITableViewCell *) cell forRowAtIndexPath: (NSIndexPath *) indexPath {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ( indexPath.section == 1 && appDelegate.watcherProfile.currentPollingPlace ) {
        
        NSDictionary *sectionInfo = [[self sortedAndFilteredSections] objectAtIndex: indexPath.row];
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *checklistItems = [[appDelegate.watcherProfile.currentPollingPlace checklistItems] allObjects];
        NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat: @"SELF.sectionName LIKE %@ && SELF.value != NULL", [sectionInfo objectForKey: @"name"]];
        NSArray *sectionItems = [checklistItems filteredArrayUsingPredicate: sectionPredicate];
        
        cell.textLabel.text = [sectionInfo objectForKey: @"title"];
        cell.detailTextLabel.text = [sectionItems count] ? [WatcherTools countOfMarksString: [sectionItems count]] : @"Отметок нет";
    }
    
    if ( indexPath.section == 0 ) {
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        
        if ( indexPath.row < pollingPlaces.count ) {
            PollingPlace *pollingPlace = [pollingPlaces objectAtIndex: indexPath.row];
            cell.textLabel.text = pollingPlace.titleString;
            cell.textLabel.textAlignment = UITextAlignmentLeft;
            
            if ( pollingPlace == appDelegate.watcherProfile.currentPollingPlace ) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                cell.detailTextLabel.text = @"активен";
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.detailTextLabel.text = nil;
            }
        } else {
            cell.textLabel.text = @"Добавить участок...";
            cell.textLabel.textAlignment = UITextAlignmentLeft;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.detailTextLabel.text = nil;
        }
    }

}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    if ( indexPath.section == 0 ) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        
        NSString *cellId = [NSString stringWithFormat: @"PollingPlaceCell_%d_%d", indexPath.section, indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
        
        if ( cell == nil ) {
            cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleValue1 reuseIdentifier: cellId] autorelease];
        }
        
        if ( indexPath.row < pollingPlaces.count ) {
            UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(editPollingPlace:)];
            gr.minimumPressDuration = 0.8f;
            
            [cell.contentView addGestureRecognizer: gr];
            [gr release];
        }
        
        cell.textLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = nil;
        
        return cell;
    } else {
        static NSString *cellId = @"sectionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
        
        if ( cell == nil ) {
            cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: cellId] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        }
        
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        
        return cell;
    }
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    if ( indexPath.section == 0 ) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        if ( indexPath.row < pollingPlaces.count ) {
            appDelegate.watcherProfile.currentPollingPlace = [pollingPlaces objectAtIndex: indexPath.row];
            NSError *error = nil;
            [appDelegate.managedObjectContext save: &error];
            if ( error ) 
                NSLog(@"error saving current polling place: %@", error.description);
            [self.tableView reloadData];
            
            // update title
            self.navigationItem.title = appDelegate.watcherProfile.currentPollingPlace ?
                    appDelegate.watcherProfile.currentPollingPlace.titleString : @"Наблюдение";
            
            [self checkForTestDataOnElectionsDay];
        } else {
            if ( appDelegate.watcherProfile.userId.length > 0 ) {
                WatcherPollingPlaceController *pollingPlaceController = [[WatcherPollingPlaceController alloc] initWithNibName: @"WatcherPollingPlaceController" bundle: nil];
                pollingPlaceController.pollingPlaceControllerDelegate = self;
                pollingPlaceController.pollingPlace = [NSEntityDescription insertNewObjectForEntityForName: @"PollingPlace" 
                                                                                    inManagedObjectContext: [appDelegate managedObjectContext]];
                
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController: pollingPlaceController];
                nc.navigationBar.tintColor = [UIColor blackColor];
                nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                [self presentModalViewController: nc animated: YES];
                [pollingPlaceController release];
                [nc release];
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
    } else {
        WatcherChecklistSectionController *sectionController = [[WatcherChecklistSectionController alloc] initWithStyle: UITableViewStyleGrouped];
        sectionController.sectionData = [[self sortedAndFilteredSections] objectAtIndex: indexPath.row];
        
        [self.navigationController pushViewController: sectionController animated: YES];
        [sectionController release];
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                    forEntity: @"PollingPlace" 
                                               withParameters: nil];
    
    return indexPath.section == 0 && indexPath.row < pollingPlaces.count;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( editingStyle == UITableViewCellEditingStyleDelete ) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        PollingPlace *pollingPlaceToRemove = [pollingPlaces objectAtIndex: indexPath.row];

        /*
        if ( pollingPlaceToRemove == appDelegate.watcherProfile.currentPollingPlace ) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Ошибка" 
                                                                message: @"Нельзя удалить активный избирательный участок" 
                                                               delegate: nil 
                                                      cancelButtonTitle: @"OK" 
                                                      otherButtonTitles: nil];
            [alertView show];
            [alertView release];
        } else {
         */
        [appDelegate.managedObjectContext deleteObject: pollingPlaceToRemove];
        
        NSError *error = nil;
        [appDelegate.managedObjectContext save: &error];
        if ( error ) 
            NSLog(@"error removing polling place: %@", error.description);
        
        [self.tableView reloadData];
//        }
    }
}

#pragma mark - Edit polling place

- (void) editPollingPlace: (UIGestureRecognizer *) sender {
    if ( sender.state == UIGestureRecognizerStateBegan ) {
        CGPoint gestureLocation = [sender locationInView: self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: gestureLocation];
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        if ( indexPath.row < pollingPlaces.count ) {
            WatcherPollingPlaceController *pollingPlaceController = [[WatcherPollingPlaceController alloc] initWithNibName: @"WatcherPollingPlaceController" bundle: nil];
            pollingPlaceController.pollingPlaceControllerDelegate = self;
            pollingPlaceController.pollingPlace = [pollingPlaces objectAtIndex: indexPath.row];
            
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController: pollingPlaceController];
            nc.navigationBar.tintColor = [UIColor blackColor];
            nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentModalViewController: nc animated: YES];
            [pollingPlaceController release];
            [nc release];
        }
    }
}

#pragma mark - Polling place controller delegate

-(void)watcherPollingPlaceController:(WatcherPollingPlaceController *)controller didSavePollingPlace:(PollingPlace *)pollinngPlace {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    if ( ! appDelegate.watcherProfile.currentPollingPlace )
        appDelegate.watcherProfile.currentPollingPlace = controller.pollingPlace;

    NSError *error = nil;
    [appDelegate.managedObjectContext save: &error];
    
    if ( error )
        NSLog(@"error saving polling place info: %@", error.description);
    
    
    [self dismissModalViewControllerAnimated: YES];
    [self.tableView reloadData];
}

-(void)watcherPollingPlaceControllerDidCancel:(WatcherPollingPlaceController *)controller {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    if ( controller.pollingPlace.isInserted )
        [appDelegate.managedObjectContext deleteObject: controller.pollingPlace];
    [self dismissModalViewControllerAnimated: YES];
    [self.tableView reloadData];
}

#pragma mark - Section help

-(void) showSectionHelp: (UIButton *) sender {
    NSString *text = nil, *title = nil;
    
    if ( sender.tag == 0 ) {
        text = @"Вы можете добавлять, делать активным (короткое нажатие), редактировать (длинное нажатие) и удалять (жестом поперек экрана) избирательные участки.\n\nДля того, чтобы вести наблюдение, необходимо добавить хотя бы один избирательный участок.\n\n";
        title = @"Участки";
    }
    
    if ( sender.tag == 1 ) {
        text = @"Вы можете отмечать пункты переключателями, вводить текстовую информацию, снимать или загружать из альбома на телефоне фото и видео. Вся введенная в приложение информация синхронизируется с сервером в фоновом режиме.\n\nВ случае возникновения ошибок передача данных производится повторно до тех пор, пока все данные не будут переданы.\n\n";
        title = @"Наблюдение";
    }
    
    TSAlertView *alertView = [[TSAlertView alloc] initWithTitle: title 
                                                        message: text
                                                       delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
    
    alertView.usesMessageTextView = YES;
    
    [alertView show];
    [alertView release];
}

@end
