//
//  GMSGroundOverlay+Scale.m
//  MapOverlays
//
//  Created by Adam Eisfeld on 1/20/16.
//  Copyright © 2016 Adam Eisfeld. All rights reserved.
//

#import "GMSGroundOverlay+Scale.h"

@implementation GMSGroundOverlay (Scale)

- (void)setRadius:(CGFloat)radius {
	CLLocationCoordinate2D oldPosition = self.position;
	
	CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(self.position.latitude - (radius), self.position.longitude - (radius));
	CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(self.position.latitude + (radius), self.position.longitude + (radius));
	
	GMSCoordinateBounds *overlayBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:southWest
																			  coordinate:northEast];
	self.bounds = overlayBounds;
	self.position = oldPosition;
}

- (CGFloat)radius {
	return fabs(self.position.latitude - self.bounds.southWest.latitude);
}

@end
