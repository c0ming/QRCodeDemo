//
//  QRMainViewController.m
//  QRCodeDemo
//
//  Created by c0ming on 10/30/15.
//  Copyright © 2015 c0ming. All rights reserved.
//

#import "QRMainViewController.h"

@import CoreImage;

@interface QRMainViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation QRMainViewController

#pragma mark - Actions

- (IBAction)generateAction:(UIButton *)sender {
	[self.view endEditing:YES];

	NSString *QRCodeString = self.textField.text;
	if (![QRCodeString isEqualToString:@""]) {
		NSData *data = [QRCodeString dataUsingEncoding:NSUTF8StringEncoding];

		CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
		[filter setValue:data forKey:@"inputMessage"];
		CIImage *outputImage = filter.outputImage;

		CGFloat scale = CGRectGetWidth(self.imageView.bounds) / CGRectGetWidth(outputImage.extent);
		CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
		CIImage *transformImage = [outputImage imageByApplyingTransform:transform];

		self.imageView.image = [UIImage imageWithCIImage:transformImage];

//		CIContext *context = [CIContext contextWithOptions:nil];
//		CGImageRef imageRef = [context createCGImage:transformImage fromRect:transformImage.extent];
//		UIImage *QRCodeImage = [UIImage imageWithCGImage:imageRef];
//		[UIImagePNGRepresentation(QRCodeImage) writeToFile:path atomically:NO];
//		CGImageRelease(imageRef);

		self.textField.text = @"";
	} else {
		NSLog(@"QRCodeString is empty.");
	}
}

#pragma mark -

- (void)viewDidLoad {
	[super viewDidLoad];
}

#pragma mark -

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

@end
