//
//  QRScanViewController.m
//  QRCodeDemo
//
//  Created by c0ming on 10/30/15.
//  Copyright © 2015 c0ming. All rights reserved.
//

#import "QRScanViewController.h"

#import "QRScanView.h"

@import AVFoundation;

@interface QRScanViewController () <AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, assign) CGRect scanRect;
@property (nonatomic, assign) BOOL isQRCodeCaptured;

@end

@implementation QRScanViewController

#pragma mark - Actions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)pickAction:(UIBarButtonItem *)sender {
	UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePickerController.delegate = self;
//	imagePickerController.allowsEditing = YES;
	[self presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - Setup

- (void)setup {
	AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
	switch (authorizationStatus) {
		case AVAuthorizationStatusNotDetermined: {
			[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler: ^(BOOL granted) {
			    if (granted) {
			        [self setupCapture];
				} else {
			        NSLog(@"%@", @"访问受限");
				}
			}];
			break;
		}

		case AVAuthorizationStatusAuthorized: {
			[self setupCapture];
			break;
		}

		case AVAuthorizationStatusRestricted:
		case AVAuthorizationStatusDenied: {
			NSLog(@"%@", @"访问受限");
			break;
		}

		default: {
			break;
		}
	}

	self.scanRect = CGRectMake(0.0f, 100.0f, 200.0f, 200.0f);
}

- (void)setupCapture {
	dispatch_async(dispatch_get_main_queue(), ^{
		AVCaptureSession *session = [[AVCaptureSession alloc] init];
		AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		NSError *error;
		AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
		if (deviceInput) {
		    [session addInput:deviceInput];

		    AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
		    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
		    [session addOutput:metadataOutput]; // 这行代码要在设置 metadataObjectTypes 前
		    metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];

		    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
		    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
		    previewLayer.frame = self.view.frame;
		    [self.view.layer insertSublayer:previewLayer atIndex:0];

		    __weak typeof(self) weakSelf = self;
		    [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureInputPortFormatDescriptionDidChangeNotification
		                                                      object:nil
		                                                       queue:[NSOperationQueue currentQueue]
		                                                  usingBlock: ^(NSNotification *_Nonnull note) {
		        metadataOutput.rectOfInterest = [previewLayer metadataOutputRectOfInterestForRect:weakSelf.scanRect]; // 如果不设置，整个屏幕都可以扫
			}];

		    QRScanView *scanView = [[QRScanView alloc] initWithScanRect:self.scanRect];
		    [self.view addSubview:scanView];

		    [session startRunning];
		} else {
		    NSLog(@"%@", error);
		}
	});
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
	AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
	if ([metadataObject.type isEqualToString:AVMetadataObjectTypeQRCode] && !self.isQRCodeCaptured) {
		self.isQRCodeCaptured = YES;

		[self showAlertViewWithMessage:metadataObject.stringValue];
	}
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];

	CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy:CIDetectorAccuracyHigh }];
	CIImage *image = [[CIImage alloc] initWithImage:originalImage];
	NSArray *features = [detector featuresInImage:image];
	CIQRCodeFeature *feature = [features firstObject];
	if (feature) {
		[self showAlertViewWithMessage:feature.messageString];
		[picker dismissViewControllerAnimated:YES completion:nil];
	} else {
		NSLog(@"没有二维码");
		[picker dismissViewControllerAnimated:YES completion:NULL];
	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	self.isQRCodeCaptured = NO;
}

#pragma mark - Private Methods

- (void)showAlertViewWithMessage:(NSString *)message {
	NSLog(@"%@", message);

	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
	alertView.delegate = self;
	[alertView show];
}

#pragma mark -

- (void)viewDidLoad {
	[super viewDidLoad];

	[self setup];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	NSLog(@"%s", __func__);
}

@end
