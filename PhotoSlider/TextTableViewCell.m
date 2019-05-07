//
//  TextTableViewCell.m
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 18.10.16.
//
//

#import "TextTableViewCell.h"

@interface TextTableViewCell()
//@property (nonatomic, weak) IBOutlet UIImageView *iconView;
@property (nonatomic, weak) IBOutlet UILabel *profileLabel;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@end


@implementation TextTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.textField.delegate = self;
}

- (void) setLabelText {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(self.tag == 104) {
        self.profileLabel.text = @"Autoshot delay";
        _textField.text = [defaults objectForKey:@"DelayValue"];
        //self.commentLabel.text = @"Smart crop OFF/ON";
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        [self setSwitchCellState: [defaults boolForKey:@"cropState"]];
    }
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString * searchStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSLog(@"%@",searchStr);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (self.tag == 104)
		[defaults setObject: searchStr forKey:@"DelayValue"];
    [defaults synchronize];
    return YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}



@end
