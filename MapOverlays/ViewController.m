//
//  ViewController.m
//  MapOverlays
//
//  Created by Adam Eisfeld on 1/20/16.
//  Copyright © 2016 Adam Eisfeld. All rights reserved.
//

#import "ViewController.h"
#import "GMSGroundOverlay+Scale.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

@interface ViewController ()

// The map view associated with the controller
@property (nonatomic, strong) GMSMapView *mapView;

// The current overlay selected (if any)
@property (nonatomic, strong) GMSGroundOverlay *currentOverlay;

// An array of all overlays added so far
@property (nonatomic, strong) NSMutableArray *overlays;

// This is needed to allow for incremental rotation changes
@property (nonatomic, assign) CGFloat lastRotation;

// This is needed to allow for incremental scale changes
@property (nonatomic, assign) CGFloat scaleOffset;

@end

@implementation ViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view, typically from a nib.
	[self setupData];
	[self setupMap];
	[self setupGestures];
	
	[self addOverlayAtLocation:CLLocationCoordinate2DMake(-33.86, 151.20)];
	
}

#pragma mark - Setup

- (void)setupData {
	self.overlays = [[NSMutableArray alloc] init];
}

- (void)setupMap {
	GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.86
															longitude:151.20
																 zoom:6];
	
	GMSMapView *mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
	mapView.myLocationEnabled = YES;
	mapView.delegate = self;
	mapView.settings.consumesGesturesInView = NO;
	mapView.settings.rotateGestures = NO;
	self.mapView = mapView;
	self.view = self.mapView;
}

- (void)setupGestures {
	// A pan gesture to slide our overlays around
	UIPanGestureRecognizer *recognizerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	[self.view addGestureRecognizer:recognizerPan];
	
	// A rotation gesture to rotate our overlays around their center
	UIRotationGestureRecognizer *recognizerRotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotateGesture:)];
	[self.view addGestureRecognizer:recognizerRotate];
	
	// A pinch gesture to scale our overlays
	UIPinchGestureRecognizer *recognizerPinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
	[self.view addGestureRecognizer:recognizerPinch];
}

- (void)addOverlayAtLocation:(CLLocationCoordinate2D )location {
	
	CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(location.latitude - 0.5,location.longitude - 0.5);
	CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(location.latitude + 0.5,location.longitude + 0.5);
	GMSCoordinateBounds *initialBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:southWest
																			  coordinate:northEast];
	UIImage *image = [UIImage imageNamed:@"overlayStar.png"];
	GMSGroundOverlay *overlay = [GMSGroundOverlay groundOverlayWithBounds:initialBounds icon:image];
	overlay.bearing = 45;
	overlay.map = self.mapView;
	overlay.tappable = YES;
	
	self.currentOverlay = overlay;
	[self.overlays addObject:overlay];
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
	// Add a new overlay to the long pressed coordinate. This could be replaced with a presentation of a UIImagePickerController to let the user select an image from their camera roll, or you could
	// go further and have a different controller that lists all "registered" images for this map, allowing the user to add new images from that controller, and pick an image to be placed from that controller via a tableview.
	[self addOverlayAtLocation:coordinate];
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
	// Deselect logic here
}

- (void)mapView:(GMSMapView *)mapView didTapOverlay:(GMSOverlay *)overlay {
	if ([overlay isKindOfClass:[GMSGroundOverlay class]]) {
		// This isn't the greatest logic as it just relies on the class. A better method would be to subclass GMSGroundOverlay and either check for that class or add a property on it that signifies that it
		// was placed by the user.
		self.currentOverlay = (GMSGroundOverlay *)overlay;
	}
}

#pragma mark - Gestures

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer {
	
	// GMSMapView provides a convenience method for converting CGPoints to CLLocationCoordinate2Ds (it also has a method to do the reverse)
	CGPoint panLocation = [recognizer locationInView:self.mapView];
	CLLocationCoordinate2D panCoordinate = [self.mapView.projection coordinateForPoint:panLocation];
	
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		
		// Check if the pan starts inside of the current overlay's bounds. This could be replaced with a loop over all of the overlays if you
		// dont want the user to have to tap on one before manipulating it. If you do this I recommend iterating over all overlays and selecting the smallest
		// overlay that contains the coordinate, instead of the first overlay that contains it, as they may be overlapping.
		if ([self.currentOverlay.bounds containsCoordinate:panCoordinate]) {
			// The user is panning an overlay, so we'll disable our map view's scroll gesture (otherwise they would conflict with each other and create strange behavior)
			self.mapView.settings.scrollGestures = NO;
		} else {
			// The user isn't panning an overlay. To stop a UIGestureRecognizer in it's tracks, you set it's enabled property to NO and then immediately after to YES. This will
			// allow our map view's scroll gesture to take priority.
			self.mapView.settings.scrollGestures = YES;
			recognizer.enabled = NO;
			recognizer.enabled = YES;
		}
	} else if (recognizer.state == UIGestureRecognizerStateChanged) {
		// Reposition the current overlay to the location of the pan. A better option here would be to detect how far the user has panned since the last recognition, and then shift the
		// current overlay's position by that x and y distance. This will allow for incremental movement similar to how the scaling and rotation gestures work.
		self.currentOverlay.position = panCoordinate;
	} else {
		// The gesture has finished, ensure our map view is ready to scroll again.
		self.mapView.settings.scrollGestures = YES;
	}
}

- (void)handleRotateGesture:(UIRotationGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		
		// We're not checking if the user's fingers are within the current overlay's bounds here as its a bit finicky for the user to fit their fingers inside of the bounds and perform a rotation.
		// Instead we'll just rotate our overlay as long as there is an overlay to rotate, otherwise we'll fallback to the map's rotation gesture.
		if (self.currentOverlay) {
			self.mapView.settings.zoomGestures = NO;
			self.mapView.settings.scrollGestures = NO;
		} else {
			self.mapView.settings.zoomGestures = YES;
			self.mapView.settings.scrollGestures = YES;
			recognizer.enabled = NO;
			recognizer.enabled = YES;
		}
		
		// We set this to 0 so we can perform incremental rotations.
		self.lastRotation = 0;
	} else if (recognizer.state == UIGestureRecognizerStateChanged) {
		// Basically each time the gesture is recognized, we'll increase our current overlay's bearing (rotation) by the recognizer's current rotation - our last rotation. We use the
		// lastRotation property to calculate how much the gesture has rotated since it's last recognition. This allows us to increment the current overlay's bearing instead of
		// setting it's bearing directly, meaning the user can do multiple rotation gestures and the overlay won't snap back to a bearing of 0 when the user starts each gesture.
		self.currentOverlay.bearing += RADIANS_TO_DEGREES(recognizer.rotation - self.lastRotation);
		self.lastRotation = recognizer.rotation;
	} else {
		self.mapView.settings.zoomGestures = YES;
		self.mapView.settings.scrollGestures = YES;
	}
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
	
	// Similar to the pan gesture, we'll check to see if the user is pinching inside of our overlay's bounds. Perhaps a better method for all of these gestures would be to
	// use the transformation gestures if the user has any overlay selected, otherwise use the map's gestures. You should probably add a "Deselect" button to the UI if thats the case though.
	CGPoint pinchLocation = [recognizer locationInView:self.mapView];
	CLLocationCoordinate2D pinchCoordinate = [self.mapView.projection coordinateForPoint:pinchLocation];
	
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		
		if ([self.currentOverlay.bounds containsCoordinate:pinchCoordinate]) {
			self.mapView.settings.scrollGestures = NO;
			self.mapView.settings.zoomGestures = NO;
		} else {
			self.mapView.settings.scrollGestures = YES;
			self.mapView.settings.zoomGestures = YES;
			recognizer.enabled = NO;
			recognizer.enabled = YES;
		}
		
		// We've got a category on GMSGroundOverlay that has convenience methods for determining the overlay's radius as well as setting it's radius.
		// We set the scaleOffset to the overlay's current radius when this gesture begins, so that we can perform incremental scaling of the overlay as the user
		// repeats this gesture.
		// If we didn't have this scaleOffset, then each time the user began the pinch gesture, the overlay would jump back to it's default scale (you can try this by commenting this line out)
		self.scaleOffset = self.currentOverlay.radius;
		
	} else if (recognizer.state == UIGestureRecognizerStateChanged) {
		
		// Currently this radius means our overlays all have to be squares. It looks like Google is using an Aspect Fit on the image attached to the overlay, meaning this should be fine for images of any shape,
		// but note that the ground overlay's dimensions may not reflect the image's dimensions itself.
		// A better option would be to replace the radius property with a width and height property.
		self.currentOverlay.radius = self.scaleOffset * recognizer.scale;
		
	} else {
		self.mapView.settings.scrollGestures = YES;
		self.mapView.settings.zoomGestures = YES;
	}
}


@end
