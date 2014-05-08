//
//  iCal_MAC_TestAppDelegate.m
//  iCal_MAC_Test
//
//  Created by artwalk on 4/29/14.
//  Copyright (c) 2014 artwalk. All rights reserved.
//

#import "iCal_MAC_TestAppDelegate.h"


@implementation iCal_MAC_TestAppDelegate

@synthesize ibArrayController, ibButtonStartStop,ibTableView,ibTextFieldNotification,ibTextFieldTaskToDo,ibTextFieldTime;

@synthesize ibTableColumn,ibTextFieldCell,ibiCalAnalytics,ibiReminders, ibCircularProgressIndicator;

@synthesize isStart, mCountingTimer, mEndDate, mStartDate, mTitle, mEventStore, mReminderStore;

@synthesize window;

static NSString *keyReminders = @"Reminders";
static NSString *keyiCal = @"iCal";

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [ibTableView setDoubleAction:NSSelectorFromString(@"doubleClick:")];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	if (flag) {
		return NO;
	}
    else	{
        [window makeKeyAndOrderFront:self];
        return YES;
	}
}

- (void) doubleClick: (id)sender
{
    if ([ibTableView selectedRow] >= 0) {
        NSString *s = [ibTextFieldCell stringValue];
        ibTextFieldTaskToDo.stringValue = s;
        ibTextFieldNotification.stringValue = @"Click Start";
        NSLog(@"cell value:%@", s);
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    [self getAuthority];
    isStart = NO;
    [ibTableColumn setEditable:NO];
    [ibTextFieldCell setSelectable:YES];
    mTitle = @"";
    ibTextFieldNotification.stringValue = @"Click 'iReminders' or Type in 'TaskToDo' bar";
}

- (void)getAuthority {
    EKEventStore *store = [[EKEventStore alloc]
                           initWithAccessToEntityTypes:EKEntityMaskReminder];
    
    [store requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted,
                                                                       NSError *error) {
        mEventStore = store;
    }];
    
    
    store = [[EKEventStore alloc]
             initWithAccessToEntityTypes:EKEntityMaskEvent];
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted,
                                                                    NSError *error) {
        mReminderStore =  store;
    }];
    
}

- (void) showReminders : (NSArray *) data {
    [self updateTableView:keyReminders withData:data];
}

- (void) showiCal : (NSArray *) data {
    [self updateTableView:keyiCal withData:data];
}

- (void)updateTableView : (NSString *) key withData:(NSArray *) data  {
    [self clearTableView];
    
    for (NSString *str in data) {
        //        [mMutableDictionary setObject:str forKey:key];
        [ibArrayController addObjects:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:str, key, nil]]];
    }
}

- (void)clearTableView {
    NSRange range = NSMakeRange(0, [[ibArrayController arrangedObjects] count]);
    [ibArrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
}

- (IBAction)startStop:(id)sender {
    if (!isStart) {
        if ([self startTask]) {
            ibTextFieldNotification.stringValue =  [NSString stringWithFormat:@"Starting: %@ task", ibTextFieldTaskToDo.stringValue];
            ibButtonStartStop.title = @"Stop";
            isStart = !isStart;
            [self setButton:NO];
        }
        
    } else {
        ibButtonStartStop.title = @"Start";
        [self stopTask];
        [self setButton:YES];
        isStart = !isStart;
    }
    
}

- (void) setButton:(BOOL) onOff{
    [ibiReminders setEnabled:onOff];
    [ibiCalAnalytics setEnabled:onOff];
    //    [ibTextFieldTaskToDo setEnabled:onOff];
    [ibTableView setEnabled:onOff];
}

- (void) paint:(NSTimer *)paramTimer{
    NSDate *now = [NSDate date];
    
    int secondsInterval = [now timeIntervalSinceDate:mStartDate];
    
    //    int iSeconds = secondsInterval  % 60;
    int iMinutes = secondsInterval / 60 %60;
    int iHours = secondsInterval / 3600;
    NSString *textFieldTime = [NSString stringWithFormat:@"%02d:%02d", iHours, iMinutes];
    
    //    NSLog(@"%@", textFieldTime);
    
    ibTextFieldTime.stringValue = textFieldTime;
}

- (void) startCounting{
    
    self.mCountingTimer = [NSTimer
                           scheduledTimerWithTimeInterval:60
                           target:self selector:@selector(paint:) userInfo:nil repeats:YES];
}

- (void) stopCounting{
    if (self.mCountingTimer != nil){
        [self.mCountingTimer invalidate];
    }
    
    ibTextFieldTime.stringValue = @"00:00";
}

- (BOOL) startTask {
    if ([ibTextFieldTaskToDo.stringValue isEqualToString:@""]) {
        ibTextFieldNotification.stringValue = [NSString stringWithFormat:@"Task is empty! DoubleClick a reminder"];
        return  NO;
    } else {
        mStartDate = [NSDate date];
        NSLog(@"%@", mStartDate);
        
        [self startCounting];
        
        return YES;
    }
}

- (void) stopTask {
    mEndDate = [NSDate date];
    NSLog(@"%@", mEndDate);
    [self stopCounting];
    
    mTitle = ibTextFieldTaskToDo.stringValue;
    
    NSString *notification;
    
    NSTimeInterval secondsInterval = [mEndDate timeIntervalSinceDate:mStartDate];
    
    if (secondsInterval > 10*60) {
        notification = [NSString stringWithFormat:@"TrueMan! %dm, '%@' insert to iCal...", (int)secondsInterval/60, mTitle ];
        [self writeEvent2iCal];
    } else {
        notification = [NSString stringWithFormat:@"Oh, Man, only %.0fs...",  secondsInterval];
        NSLog(@"hehe");
    }
    
    ibTextFieldNotification.stringValue = notification;
}

- (void) writeEvent2iCal {
    
    EKEvent *event = [EKEvent eventWithEventStore:mEventStore];
    
    event.title = mTitle;
    event.endDate = mEndDate;
    event.startDate = mStartDate;
    
    //    NSTimeInterval interval = (60 *60)* -3 ;
    //    EKAlarm *alarm = [EKAlarm alarmWithRelativeOffset:interval];  //Create object of alarm
    //    [event addAlarm:alarm]; //Add alarm to your event
    
    [event setCalendar:[mEventStore defaultCalendarForNewEvents]];
    NSError *err;
    NSString *ical_event_id;
    //save your event
    if([mEventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&err]){
        ical_event_id = event.eventIdentifier;
        NSLog(@"%@",ical_event_id);
    }
    
    
}

- (IBAction)iCalAnalytics:(id)sender {
    [self setButton:NO];
    [ibCircularProgressIndicator startAnimation:nil];
    
    static dispatch_once_t once;
    static dispatch_queue_t queue;
    
    //create download queue
    dispatch_once(&once, ^{
        queue =dispatch_queue_create("com.xxx.download.background", DISPATCH_QUEUE_CONCURRENT);
    });
    
    //__block type
    __block NSArray *array;
    dispatch_async(queue, ^{
        // long time task
        array = [self printEvents:mEventStore];
    });
    
    dispatch_barrier_async(queue, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Update UI");
            [self showiCal: array];
            [self setButton:YES];
            [ibCircularProgressIndicator stopAnimation:nil];
        });
    });
    
}

- (IBAction)iReminders:(id)sender {
    
    [self showReminders:[self printIncompleteReminders:mReminderStore]];
    
    ibTextFieldNotification.stringValue = @"DoubleClick a reminder";
}

- (NSArray *)printIncompleteReminders : (EKEventStore *) store {
    
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:5];
    
    NSPredicate *predicate = [store predicateForIncompleteRemindersWithDueDateStarting:nil ending:nil calendars:nil];
    [store fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders) {
        
        for (EKReminder *reminder in reminders) {
            NSString *title = [NSString stringWithFormat:@"%@", reminder.title];
            NSLog(@"%@", title);
            [result addObject:title];
        }
    }];
    
    return result;
}

- (NSArray *)printEvents : (EKEventStore *) store {
    // Get the appropriate calendar
    NSCalendar *calendar = [NSCalendar currentCalendar];
    // Create the start date components
    NSDateComponents *yearsAgoComponents = [[NSDateComponents alloc] init];
    yearsAgoComponents.year= -4;
    NSDate *yearsAgo = [calendar dateByAddingComponents:yearsAgoComponents
                                                 toDate:[NSDate date]
                                                options:0];
    
    // Create the end date components
    NSDateComponents *onedayFromNowComponents = [[NSDateComponents alloc] init];
    onedayFromNowComponents.day = 1;
    NSDate *oneDayFromNow = [calendar dateByAddingComponents:onedayFromNowComponents
                                                      toDate:[NSDate date]
                                                     options:0];
    // Create the predicate from the event store's instance method
    NSPredicate *predicate = [store predicateForEventsWithStartDate:yearsAgo
                                                            endDate:oneDayFromNow
                                                          calendars:nil];
    
    // Fetch all events that match the predicate
    NSArray *events = [store eventsMatchingPredicate:predicate];
    
    return [self analytics:events];
}

- (NSArray *)analytics : (NSArray *)events {
    NSMutableDictionary *calTimeDict = [NSMutableDictionary dictionary];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    
    for (EKEvent * event in events) {
        NSString *title = event.calendar.title;
        if ([title isEqualToString:@"US Holidays"]) {
            continue;
        }
        NSDateComponents *comps = [gregorian components:NSMinuteCalendarUnit fromDate:event.startDate  toDate:event.endDate  options:0];
        long minute = [comps minute];
        
        
        minute += [[calTimeDict objectForKey:title] longValue];
        [calTimeDict setObject:[NSNumber numberWithLong:minute] forKey:title];
    }
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:5];
    
    __block long sum = 0;
    [calTimeDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        long l = [obj longValue]/60;
        sum += l;
        NSString *s = [NSString stringWithFormat:@"%@ : already %ld h,%ld h remained", key,l,10000-l];
        NSLog(@"%@", s);
        [result addObject:s];
    }];
    
    NSString *s = [NSString stringWithFormat:@"%ld h in Total", sum];
    [result addObject:s];
    NSLog(@"%@", s);
    
    [calTimeDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        double f  = [obj longValue]/60 *100.0 / sum;
        NSString *s = [NSString stringWithFormat:@"%@ : %0.2f%%", key,f];
        NSLog(@"%@", s);
        [result addObject:s];
    }];
    
    return result;
}

@end
