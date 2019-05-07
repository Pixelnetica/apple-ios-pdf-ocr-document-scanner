//
//  SettingsProfileTableViewCell.m
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 18.12.15.
//
//

#import "SettingsProfileTableViewCell.h"

@interface SettingsProfileTableViewCell()
//@property (nonatomic, weak) IBOutlet UIImageView *iconView;
@property (nonatomic, weak) IBOutlet UILabel *profileLabel;
@end

@implementation SettingsProfileTableViewCell
- (void)awakeFromNib {
    // Initialization code
}

- (void) confifureCell:(UIImage*) image andText:(NSString*) text {
    //self.iconView.image = image;
    self.profileLabel.text = text;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
