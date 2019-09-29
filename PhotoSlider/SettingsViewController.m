//
//  SettingsViewController.m
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 18.12.15.
//
//

#import "SettingsViewController.h"
#import "SettingsTableViewCell.h"
#import "SettingsProfileTableViewCell.h"
#import "AboutViewController.h"

static NSString *identifier = @"settingsCell";
static NSString *identifier_ = @"settingsProfileCell";
static NSString *textcell = @"textSettingsProfileCell";

@interface SettingsViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"SettingsTableViewCell" bundle:nil] forCellReuseIdentifier:identifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"SettingsProfileTableViewCell" bundle:nil] forCellReuseIdentifier:identifier_];
    [self.tableView registerNib:[UINib nibWithNibName:@"TextTableViewCell" bundle:nil] forCellReuseIdentifier:textcell];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeView:(id)sender {
    [self complete:nil];
}

- (void)complete:(NSString*) reason {
    if (_completion)
        _completion(reason);
    self.completion = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch( section )
	{
		case 0:
			return 1;

		case 1:
			return 4;

		case 2:
			return 2;

		case 3:
			return 1;

		case 4:
			return 5;

		default:
			return 1;
	}
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if( section == 0)
	{
        return @"Turn «SmartCrop» ON to automatically process images with well detected borders. Manual correction will be offered only in case of low quality document border detection. When «SmartCrop» is OFF - image will always be processed after manual confirmation.";
	}
	else if( section == 4 )
	{
		return @"The «Simulate multi-page file» setting simulates multi-page files by writing the same image three times in a row. Applicable for PDF files only.";
    }

	return @"";
}

 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 
     SettingsTableViewCell*cell;
     SettingsProfileTableViewCell *cell_;
	 if(indexPath.section == 0) {
		 if(indexPath.row == 0) {
			cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
			cell.tag = 100;
			[cell setLabelText];
			return cell;
		}
		else if(indexPath.row == 1) {
			cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
			cell.tag = 101;
         
			[cell setLabelText];
         
			return cell;
		}
	 } else if (indexPath.section == 1) {
         cell_ = [tableView dequeueReusableCellWithIdentifier:identifier_ forIndexPath:indexPath];
         
         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         NSInteger row_ = [defaults integerForKey:@"selectedProfile"];
         
         if(row_ == indexPath.row) {
             cell_.accessoryType = UITableViewCellAccessoryCheckmark;
         } else {
             cell_.accessoryType = UITableViewCellAccessoryNone;
         }

         if(indexPath.row == 0) {
             [cell_ configureCell:[UIImage imageNamed:@"profile_button_original"] andText:@"Original"];
         }
         else if(indexPath.row == 1) {
             [cell_ configureCell:[UIImage imageNamed:@"profile_button_bw"] andText:@"Black & White"];
         }
         else if(indexPath.row == 2) {
             [cell_ configureCell:[UIImage imageNamed:@"profile_button_gray"] andText:@"Gray"];
         }
         else if(indexPath.row == 3) {
             [cell_ configureCell:[UIImage imageNamed:@"profile_button_color"] andText:@"Color"];
             
         }
         return cell_;
     } else if (indexPath.section == 2) {
         if (indexPath.row == 0) {
             cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
             cell.accessoryType = UITableViewCellAccessoryNone;
             cell.tag = 102;
             [cell setLabelText];
             return cell;
         } else  {
             cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
             cell.accessoryType = UITableViewCellAccessoryNone;
             cell.tag = 103;
             [cell setLabelText];
             return cell;
         }
     } else if (indexPath.section == 3) {
         if (indexPath.row == 0) {
             cell = [tableView dequeueReusableCellWithIdentifier:textcell forIndexPath:indexPath];
             cell.accessoryType = UITableViewCellAccessoryNone;
             cell.tag = 104;
         }
         [cell setLabelText];
         return cell;
     } else if (indexPath.section == 4) {
		 cell_ = [tableView dequeueReusableCellWithIdentifier:identifier_ forIndexPath:indexPath];

		 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

		 NSInteger row_ = [defaults integerForKey:@"selectedSaveFormat"];

		 cell_.accessoryType =
			row_ == indexPath.row ?
			UITableViewCellAccessoryCheckmark :
			UITableViewCellAccessoryNone
			;

		 switch( indexPath.row )
		 {
			 case 0:
			 {
				 [cell_ configureCell:[UIImage imageNamed:@"save_format_button_pdf"] andText:@"PDF"];
				 break;
			 }

			 case 1:
			 {
				 [cell_ configureCell:[UIImage imageNamed:@"save_format_button_pdf_from_png"] andText:@"PDF from PNG"];
				 break;
			 }

			 case 2:
			 {
				 [cell_ configureCell:[UIImage imageNamed:@"save_format_button_tiff"] andText:@"TIFF G4"];
				 break;
			 }

			 case 3:
			 {
				 [cell_ configureCell:[UIImage imageNamed:@"save_format_button_png"] andText:@"PNG"];
				 break;
			 }

			 case 4:
			 {
				 [cell_ configureCell:[UIImage imageNamed:@"save_format_button_jpg"] andText:@"JPG"];
				 break;
			 }
		 }

		 return cell_;
	 } else if (indexPath.section == 5) {
		 cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
		 cell.accessoryType = UITableViewCellAccessoryNone;
		 cell.tag = 104;
		 [cell setLabelText];
		 return cell;
	 } else if (indexPath.section == 6) {
		 cell_ = [tableView dequeueReusableCellWithIdentifier:identifier_ forIndexPath:indexPath];

		 [cell_ configureCell:@"About product"];

		 cell_.accessoryType = UITableViewCellAccessoryNone;

		 return cell_;
	 }

     return nil;
}

 #pragma mark - Table view delegate

 // In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
 - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Navigation logic may go here, for example:
	// Create the next view controller.

	switch( indexPath.section )
	{
		case 1:
		{
			NSArray* cells = [tableView visibleCells];

			for( UITableViewCell* cell in cells )
			{
				cell.accessoryType = UITableViewCellAccessoryNone;
			}

			[tableView deselectRowAtIndexPath:indexPath animated:YES];

			SettingsProfileTableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

			cell.accessoryType = UITableViewCellAccessoryCheckmark;

			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

			[defaults setInteger:indexPath.row forKey:@"selectedProfile"];
			[defaults synchronize];
			
			break;
		}
			
		case 4:
		{
			NSArray* cells = [tableView visibleCells];

			for( UITableViewCell* cell in cells )
				cell.accessoryType = UITableViewCellAccessoryNone;

			[tableView deselectRowAtIndexPath:indexPath animated:YES];

			SettingsProfileTableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

			cell.accessoryType = UITableViewCellAccessoryCheckmark;

			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

			[defaults setInteger:indexPath.row forKey:@"selectedSaveFormat"];
			[defaults synchronize];
			
			break;
		}

		case 6:
		{
			AboutViewController* vc = [AboutViewController new];

			vc.modalPresentationStyle = UIModalPresentationFullScreen;

			[self presentViewController:vc animated:YES completion:nil];

			break;
		}

		default:
		{
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
			break;
		}
	}
 }

@end
