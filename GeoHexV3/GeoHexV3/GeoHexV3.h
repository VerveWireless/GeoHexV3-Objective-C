//
//  GeoHex.h
//  GeoHex-ObjectiveC
//
//  Created by Adam Allen on 08/08/2016
//

#import <Foundation/Foundation.h>
#import <MapKit/MKMapView.h>

#define kGeoHexV3Version			@"3.2"

//TODO: make level an unsigned int
//TODO: replace MKMapPoints used as an x/y geohex struct because they are not real MKMapPoints, they could be confusing to the user.

@interface GeoHexV3 : NSObject

/** The GeoHex code */
@property(nonatomic, strong, readonly) NSString *code;

/** Center coordinate of the GeoHex */
@property(nonatomic,readonly) CLLocationCoordinate2D coordinate;

/** Internal X,Y position of the GeoHex. This is not a real MKMapPoint for use in a MKMapView. */
@property(nonatomic,readonly) MKMapPoint position;

/* Calculates an internal GeoHex x,y value from a coordinate */
+(MKMapPoint)xyFromCoordinate:(CLLocationCoordinate2D)coordinate level:(int)level;

/**
 * Creates a GeoHex obect from a latitude/longitude coordinate and a level. Level is positive and starts at 0.
 * @param	coordinate  A latitude/longitude position.
 * @param	level       The level of the GeoHex to generate.
 * @return	GeoHexV3    A GeoHex object.
 */
+(GeoHexV3*)geoHexWithCoordinate:(CLLocationCoordinate2D)coordinate level:(int)level;

/**
 * Creates a GeoHex object from an internal GeoHex x/y value and a level. In theory level should not be required since X/Y pairs are not duplicated across levels. But maybe it is needed for the calculation
 * @param   point       An internal GeoHex X/Y. Not to be confused with a real MKMapPoint from a MKMapView.
 * @param   level       The level of the GeoHex to generate.
 * @return	GeoHexV3    A GeoHex object.
 */
+(GeoHexV3*)geoHexWithXY:(MKMapPoint)point level:(int)level;

/**
 * Creates a GeoHex object from a GeoHex code.
 * @param	code	A GeoHex encoding.
 * @return	GeoHexV3    A GeoHex object.
 */
+(GeoHexV3*)geoHexWithCode:(NSString *)code;

/**
 * Returns an array of GeoHex X,Y values given the sw and ne corners of a lat/lon rectangle
 * @param   sw  Lat/Lon coordinate of the sw (bottom left) corner
 * @param   ne  Lat/Lon coorindate of the ne (top right) corner
 */
//TODO: this should return an array of geo hexes.
+(NSArray*)getXYListWithSWCorner:(CLLocationCoordinate2D)sw neCorner:(CLLocationCoordinate2D)ne level:(int)level;

+(double)hexSizeForLevel: (int) level;

/* Returns the current GeoHex version as a string */
+(NSString *)version;

/** Returns the level of this GeoHex. Levels start at 0. */
-(int)level;

/** Returns an array with each of the six corners of the GeoHex, represented as CLLocation objects.*/
-(NSArray<CLLocation*>*)locations;

/** Returns the 6 nearby geohexes */
-(NSArray<GeoHexV3*>*)perimeterHexes;

-(NSArray<GeoHexV3*>*)perimeterHexesWithRings:(int)numberOfRings;

@end
