//
//  GuideAppDelegate.m
//  Guide
//
//  Created by Scott Andrus on 6/12/12.
//  Copyright (c) 2012 Vanderbilt University. All rights reserved.
//

#import "GuideAppDelegate.h"
#import "AgendaViewController.h"
#import "Location.h"
#import <QuartzCore/QuartzCore.h>
#import "ZXingWidgetController.h"
#import "QRCodeReader.h"

@implementation GuideAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize root = _root;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Set status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    
    // Set the background image for *all* UINavigationItems
    UIImage *buttonBack30 = [[UIImage imageNamed:@"NewBackButton"] 
                             resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 5)];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:buttonBack30 forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    UIImage *button30 = [[UIImage imageNamed:@"NewBarButton"] 
                         resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, -1, 5)];
    [[UIBarButtonItem appearance] setBackgroundImage:button30 forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    UIImage *navImage = [UIImage imageNamed:@"NewNavBar4"];
    [[UINavigationBar appearance] setBackgroundImage:navImage forBarMetrics:UIBarMetricsDefault];
    
    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"NewTabBarV3"]];

    [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:@"NewTabBarSelectedThin"]];

    
//    // Test data
//    Location *fgh = [[Location alloc] init];
//    fgh.name = @"Featheringill Hall";
//    fgh.imagePath = @"blah";
//    fgh.category = @"Classroom Building";
//    
//    Location *myHouse = [[Location alloc] init];
//    myHouse.name = @"My House";
//    myHouse.category = @"Residence";
//    
//    NSArray *places = [[NSArray alloc] initWithObjects:fgh, myHouse, nil];

    // Core data insert
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest * all = [[NSFetchRequest alloc] init];
    [all setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:context]];
    [all setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * contextLocations = [context executeFetchRequest:all error:&error];
    
    //error handling goes here
    for (NSManagedObject * loc in contextLocations) {
        [context deleteObject:loc];
    }
    NSError *saveError = nil;
    [context save:&saveError];
    //more error handling here

    NSError* err = nil;
    NSString* dataPath = [[NSBundle mainBundle] pathForResource:@"Places" ofType:@"json"];
    NSArray* places = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath]
                                                     options:kNilOptions
                                                       error:&err];
    NSLog(@"Imported places: %@", places);
    
    [places enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Location *location = [NSEntityDescription
                                 insertNewObjectForEntityForName:@"Location"
                                 inManagedObjectContext:context];
        
        location.name = [obj objectForKey:@"name"];
        location.category = [obj objectForKey:@"category"];
        location.hours = [obj objectForKey:@"hours"];
        location.placeDescription = [obj objectForKey:@"placeDescription"];
        location.imagePath = [obj objectForKey:@"imagePath"];
        location.videoPath = [obj objectForKey:@"videoPath"];
        
        NSError *error;
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
    }];
    

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *newError;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&newError];
    for (Location *place in fetchedObjects) {
        NSLog(@"Name: %@", [place valueForKey:@"name"]);
        NSLog(@"Category: %@", [place valueForKey:@"category"]);
    }
    
    // Grab the root view controller
    self.root = (RootViewController *)self.window.rootViewController;
    self.root.view.clipsToBounds = YES;
    
    // Instantiate guide button
    UIButton *guideButton = [[UIButton alloc] initWithFrame:CGRectMake(127, 419, 64, 60)];
    
    
    guideButton.clipsToBounds = YES;
    
    // Activate guide button target
    [guideButton addTarget:self action:@selector(guidePressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.root.view addSubview:guideButton];
    [guideButton setImage:[UIImage imageNamed:@"NewCenterButtonGuide"] forState:UIControlStateNormal];
    
    AgendaViewController *avc = (AgendaViewController *)[[[self.root.viewControllers objectAtIndex:0] viewControllers] objectAtIndex:0];
    
    NSMutableArray *locations = [fetchedObjects mutableCopy];
    avc.agenda = locations;
    
    NSMutableDictionary *locDict = [NSMutableDictionary dictionary];
    for (Location *location in locations) {
        [locDict setObject:location forKey:location.name];
        NSLog(@"%@", location.name);
    }
    self.root.locationDictionary = [locDict copy];
    
    return YES;
}

- (IBAction)guidePressed:(id)sender {
    [self.root performSegueWithIdentifier:@"guidePressed" sender:self.root];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Guide" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Guide.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end