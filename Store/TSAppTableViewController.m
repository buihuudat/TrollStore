#import "TSAppTableViewController.h"

#import "TSApplicationsManager.h"

@implementation TSAppTableViewController

- (void)reloadTable
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.tableView reloadData];
    });
}

- (void)loadView
{
    [super loadView];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"ApplicationCell"];
    [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(reloadTable)
            name:@"ApplicationsChanged"
            object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}

- (void)showError:(NSError*)error
{
    UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Error %ld", error.code] message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil];
    [errorAlert addAction:closeAction];
    [self presentViewController:errorAlert animated:YES completion:nil];
}

- (void)uninstallPressedForRowAtIndexPath:(NSIndexPath*)indexPath
{
    TSApplicationsManager* appsManager = [TSApplicationsManager sharedInstance];

    NSString* appPath = [appsManager installedAppPaths][indexPath.row];
    NSString* appId = [appsManager appIdForAppPath:appPath];
    NSString* appName = [appsManager displayNameForAppPath:appPath];

    UIAlertController* confirmAlert = [UIAlertController alertControllerWithTitle:@"Confirm Uninstallation" message:[NSString stringWithFormat:@"Uninstalling the app '%@' will delete the app and all data associated to it.", appName] preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* uninstallAction = [UIAlertAction actionWithTitle:@"Uninstall" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
    {
        if(appId)
        {
            [appsManager uninstallApp:appId];
        }
        else
        {
            [appsManager uninstallAppByPath:appPath];
        }
    }];
    [confirmAlert addAction:uninstallAction];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [confirmAlert addAction:cancelAction];

    [self presentViewController:confirmAlert animated:YES completion:nil];
}

- (void)deselectRow
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[TSApplicationsManager sharedInstance] installedAppPaths].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ApplicationCell" forIndexPath:indexPath];
    
    NSString* appPath = [[TSApplicationsManager sharedInstance] installedAppPaths][indexPath.row];
    
    // Configure the cell...
    cell.textLabel.text = [[TSApplicationsManager sharedInstance] displayNameForAppPath:appPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self uninstallPressedForRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TSApplicationsManager* appsManager = [TSApplicationsManager sharedInstance];

    NSString* appPath = [appsManager installedAppPaths][indexPath.row];
    NSString* appId = [appsManager appIdForAppPath:appPath];
    NSString* appName = [appsManager displayNameForAppPath:appPath];

    UIAlertController* appSelectAlert = [UIAlertController alertControllerWithTitle:appName message:appId preferredStyle:UIAlertControllerStyleActionSheet];

    /*UIAlertAction* detachAction = [UIAlertAction actionWithTitle:@"Detach from TrollStore" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
    {
        int detachRet = [appsManager detachFromApp:appId];
        if(detachRet != 0)
        {
            [self showError:[appsManager errorForCode:detachRet]];
        }
        [self deselectRow];
    }];
    [appSelectAlert addAction:detachAction];*/

    UIAlertAction* uninstallAction = [UIAlertAction actionWithTitle:@"Uninstall App" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
    {
        [self uninstallPressedForRowAtIndexPath:indexPath];
        [self deselectRow];
    }];
    [appSelectAlert addAction:uninstallAction];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action)
    {
        [self deselectRow];
    }];
    [appSelectAlert addAction:cancelAction];

	appSelectAlert.popoverPresentationController.sourceView = tableView;
	appSelectAlert.popoverPresentationController.sourceRect = [tableView rectForRowAtIndexPath:indexPath];

    [self presentViewController:appSelectAlert animated:YES completion:nil];
}

@end