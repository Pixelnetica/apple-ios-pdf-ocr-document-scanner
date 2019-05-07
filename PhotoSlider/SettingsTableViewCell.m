//
//  SettingsTableViewCell.m
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 18.12.15.
//
//

#import "SettingsTableViewCell.h"

@interface SettingsTableViewCell()
@property (nonatomic, weak) IBOutlet UISwitch *switchCell;
@property (nonatomic, weak) IBOutlet UILabel *cellNameLabel;
//@property (nonatomic, weak) IBOutlet UILabel *commentLabel;

@end

@implementation SettingsTableViewCell


- (void)awakeFromNib {
    // Initialization code
}

- (IBAction)changeSwitch:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if(self.tag == 100) {
        [defaults setBool:self.switchCell.isOn forKey:@"cropState"];
        [defaults synchronize];
    } else if(self.tag == 101) {
        [defaults setBool:self.switchCell.isOn forKey:@"cropMode"];
        [defaults synchronize];
    } else if(self.tag == 102) {
        [defaults setBool:self.switchCell.isOn forKey:@"borderDetector"];
        [defaults synchronize];
	} else if(self.tag == 103) {
		[defaults setBool:self.switchCell.isOn forKey:@"autoShot"];
		[defaults synchronize];
	} else if(self.tag == 104) {
		[defaults setBool:self.switchCell.isOn forKey:@"simulateMultipageFile"];
		[defaults synchronize];
	}
}

- (void) setLabelText {
    if(self.tag == 100) {
        self.cellNameLabel.text = @"Smart crop";
        //self.commentLabel.text = @"Smart crop OFF/ON";
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [self setSwitchCellState: [defaults boolForKey:@"cropState"]];
    } else if (self.tag == 101) {
        self.cellNameLabel.text = @"Crop mode";
        //self.commentLabel.text = @"Custom crop/System crop";
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [self setSwitchCellState: [defaults boolForKey:@"cropMode"]];
    } else if (self.tag == 102) {
        self.cellNameLabel.text = @"Document borders detector";
        //self.commentLabel.text = @"Custom crop/System crop";
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [self setSwitchCellState: [defaults boolForKey:@"borderDetector"]];
    } else if (self.tag == 103) {
        self.cellNameLabel.text = @"AutoShot";
        //self.commentLabel.text = @"Custom crop/System crop";
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [self setSwitchCellState: [defaults boolForKey:@"autoShot"]];
	} else if (self.tag == 104) {
		self.cellNameLabel.text = @"Simulate multi-page file";
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[self setSwitchCellState: [defaults boolForKey:@"simulateMultipageFile"]];
	}

}

- (void) setSwitchCellState:(BOOL) state {
    [self.switchCell setOn:state];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
