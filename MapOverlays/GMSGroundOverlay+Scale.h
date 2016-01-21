//
//  GMSGroundOverlay+Scale.h
//  MapOverlays
//
//  Created by Adam Eisfeld on 1/20/16.
//  Copyright © 2016 Adam Eisfeld. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>

@interface GMSGroundOverlay (Scale)

/** A convenience property for setting / getting the overlay's radius */
@property (nonatomic, assign) CGFloat radius;

@end