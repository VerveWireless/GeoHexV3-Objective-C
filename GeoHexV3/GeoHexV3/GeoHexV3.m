//
//	GeoHex.m
//  GeoHex-ObjectiveC
//
//  Created by Adam Allen on 08/08/2016
//

#import "GeoHexV3.h"

#define h_key   @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
#define h_base	20037508.34
#define h_deg	M_PI*(30.0/180.0)
#define h_k		tan(h_deg)

//this is a cross flatform (ios - MacOSX) point object. Saves the trouble of encoding structs into NSValues for use in collections.
@interface XYObject : NSObject

@property (nonatomic,assign) double x;
@property (nonatomic,assign) double y;

+(XYObject*)objectWithX:(double)x y:(double)y;

@end

@implementation XYObject

+(XYObject*)objectWithX:(double)x y:(double)y {
    XYObject *obj = [XYObject new];
    obj.x = x;
    obj.y = y;
    return obj;
}

@end

@interface GeoHexV3 ()

@property(nonatomic, strong, readwrite) NSString *code;
@property(nonatomic,readwrite) CLLocationCoordinate2D coordinate;
@property(nonatomic,readwrite) MKMapPoint position;

@end

@implementation GeoHexV3

#pragma mark Class methods

+(CLLocationCoordinate2D)xyToLoc:(MKMapPoint) point {
	double lon = (point.x / h_base) * 180.0;
	double lat = (point.y / h_base) * 180.0;
	lat = 180.0 / M_PI * (2.0 * atan(exp(lat * M_PI / 180.0)) - M_PI / 2.0);
    while (lon > 180.0) {
        lon -= 360.0;
    }
    while (lon <= -180.0) {
        lon += 360.0;
    }
	return CLLocationCoordinate2DMake(lat,lon);
}

+(MKMapPoint)locToXY:(CLLocationCoordinate2D) coordinate {
	double x = coordinate.longitude * h_base / 180.0;
	double y = log( tan((90.0+coordinate.latitude) * M_PI / 360.0))/(M_PI / 180.0);
	y *= h_base / 180.0;
	return MKMapPointMake(x,y);
}

+(MKMapPoint) adjustXY:(MKMapPoint)xy level:(int)level {
    int x = xy.x;
    int y = xy.y;
    int max_hsteps = pow(3,level+2);
    int hsteps = abs(x - y);
    if (hsteps == max_hsteps && x > y) {
        int tmp = x;
        x = y;
        y = tmp;
    } else if (hsteps > max_hsteps) {
        int dif = hsteps - max_hsteps;
        int dif_x = dif/2;
        int dif_y = dif - dif_x;
        int edge_x;
        int edge_y;
        if (x > y) {
            edge_x = x - dif_x;
            edge_y = y + dif_y;
            int h_xy = edge_x;
            edge_x = edge_y;
            edge_y = h_xy;
            x = edge_x + dif_x;
            y = edge_y - dif_y;
        } else if (y > x) {
            edge_x = x + dif_x;
            edge_y = y - dif_y;
            int h_xy = edge_x;
            edge_x = edge_y;
            edge_y = h_xy;
            x = edge_x - dif_x;
            y = edge_y + dif_y;
        }
    }
    return MKMapPointMake(x, y);
}

+(MKMapPoint)xyFromCoordinate:(CLLocationCoordinate2D)coordinate level:(int)level {
    double h_size = [GeoHexV3 hexSizeForLevel:level];
    MKMapPoint z_xy = [GeoHexV3 locToXY:coordinate];
    double lon_grid = z_xy.x;
    double lat_grid = z_xy.y;
    double unit_x = 6 * h_size;
    double unit_y = 6 * h_size * h_k;
    double h_pos_x = (lon_grid + lat_grid / h_k) / unit_x;
    double h_pos_y = (lat_grid - h_k * lon_grid) / unit_y;
    double h_x_0 = floor(h_pos_x);
    double h_y_0 = floor(h_pos_y);
    double h_x_q = h_pos_x - h_x_0;
    double h_y_q = h_pos_y - h_y_0;
    double h_x = round(h_pos_x);
    double h_y = round(h_pos_y);
    
    if (h_y_q > -h_x_q + 1) {
        if ((h_y_q < 2 * h_x_q) && (h_y_q > 0.5 * h_x_q)) {
            h_x = h_x_0 + 1;
            h_y = h_y_0 + 1;
        }
    } else if (h_y_q < -h_x_q + 1) {
        if ((h_y_q > (2 * h_x_q) - 1) && (h_y_q < (0.5 * h_x_q) + 0.5)) {
            h_x = h_x_0;
            h_y = h_y_0;
        }
    }
    
    MKMapPoint adjustedXY = [GeoHexV3 adjustXY:MKMapPointMake(h_x, h_y) level:level];
    return adjustedXY;
}

+(double)hexSizeForLevel: (int) level {
	return h_base/pow(3, level+3);
}

+(NSString *) version {
	return kGeoHexV3Version;
}

#pragma mark Initializer methods
+(GeoHexV3*)geoHexWithCode:(NSString *)code {
    int level = (int)[code length] - 2;
    double h_size = h_base/pow(3, level+3);
    double unit_x = 6 * h_size;
    double unit_y = 6 * h_size * h_k;
    int h_x = 0;
    int h_y = 0;
    
    int i;
    
    NSMutableString *h_dec9 = [NSMutableString stringWithFormat:@"%li%@",(long)[GeoHexV3 indexOfChar:[GeoHexV3 charAtIndex:0 ofString:code] inString:h_key] * 30 + (long)[GeoHexV3 indexOfChar:[GeoHexV3 charAtIndex:1 ofString:code] inString:h_key],[code substringFromIndex:2]];
    
    NSRegularExpression *expression1 = [NSRegularExpression regularExpressionWithPattern:@"[15]" options:0 error:nil];
    NSRegularExpression *expression2 = [NSRegularExpression regularExpressionWithPattern:@"[^125]" options:0 error:nil]; 
    
    NSString *firstCharacter = [GeoHexV3 charAtIndex:0 ofString:h_dec9];
    NSString *secondCharacter = [GeoHexV3 charAtIndex:1 ofString:h_dec9];
    NSString *thirdCharacter = [GeoHexV3 charAtIndex:2 ofString:h_dec9];

    if(([expression1 numberOfMatchesInString:firstCharacter options:0 range:NSMakeRange(0,1)] > 0) &&
       ([expression2 numberOfMatchesInString:secondCharacter options:0 range:NSMakeRange(0,1)] > 0) &&
       ([expression2 numberOfMatchesInString:thirdCharacter options:0 range:NSMakeRange(0,1)] > 0)) {
        
        if([firstCharacter intValue] == 5){
            [h_dec9 replaceCharactersInRange:NSMakeRange(0, 1) withString:@"7"];

        } else if([firstCharacter intValue] == 1){
            [h_dec9 replaceCharactersInRange:NSMakeRange(0, 1) withString:@"3"];
        }
    }
    
    int d9xlen = (int)[h_dec9 length];
    
    for(i=0;i<level + 3 - d9xlen;i++){
        [h_dec9 insertString:@"0" atIndex:0];
        d9xlen++;
    }
    
    NSMutableString* h_dec3 = [NSMutableString string];
    
    for(i=0;i<d9xlen;i++){
        int dec9i = [[GeoHexV3 charAtIndex:i ofString:h_dec9] intValue];
        NSString *h_dec0=[GeoHexV3 toString3:dec9i];
        [h_dec3 appendString:h_dec0];
    }
    
    NSMutableArray *h_decx = [NSMutableArray array];
    NSMutableArray *h_decy = [NSMutableArray array];
    
    for(i=0;i<h_dec3.length/2;i++){
        [h_decx addObject:[GeoHexV3 charAtIndex:i*2 ofString:h_dec3]];
        [h_decy addObject:[GeoHexV3 charAtIndex:i*2+1 ofString:h_dec3]];
    }
    
    for(i=0;i<=level+2;i++){
        double h_pow = pow(3,level+2-i);
        if ([h_decx count] <= level+2) {
            NSLog(@"%@ not enough digits in h_decx h_dec3 length: %lu",code, [h_dec3 length]);
            return nil;
        }
        if([[h_decx objectAtIndex:i] isEqualToString:@"0"]){
            h_x -= h_pow;
        }else if([[h_decx objectAtIndex:i] isEqualToString:@"2"]){
            h_x += h_pow;
        }
        if([[h_decy objectAtIndex:i] isEqualToString:@"0"]){
            h_y -= h_pow;
        }else if([[h_decy objectAtIndex:i] isEqualToString:@"2"]){
            h_y += h_pow;
        }
    }
    
    double h_lat_y = (h_k * h_x * unit_x + h_y * unit_y) / 2;
    double h_lon_x = (h_lat_y - h_y * unit_y) / h_k;
    
    CLLocationCoordinate2D h_loc = [GeoHexV3 xyToLoc:MKMapPointMake(h_lon_x, h_lat_y)];
    
    MKMapPoint adjustedXY = [GeoHexV3 adjustXY:MKMapPointMake(h_x, h_y) level:level];
    
    GeoHexV3 *geoHex = [[GeoHexV3 alloc] init];
    geoHex.code = code;
    geoHex.coordinate = h_loc;
    geoHex.position = adjustedXY;
	
	return geoHex;
}

+(GeoHexV3*)geoHexWithXY:(MKMapPoint)point level:(int)level {
    double h_size = [GeoHexV3 hexSizeForLevel:level];
    
    int h_x = point.x;
    int h_y = point.y;
    
    double unit_x = 6 * h_size;
    double unit_y = 6 * h_size * h_k;
    
    double h_lat = (h_k * h_x * unit_x + h_y * unit_y) / 2;
    double h_lon = (h_lat - h_y * unit_y) / h_k;
    
    CLLocationCoordinate2D z_loc = [GeoHexV3 xyToLoc:MKMapPointMake(h_lon, h_lat)];
    
    double z_loc_x = z_loc.longitude;
    double z_loc_y = z_loc.latitude;
    
    int max_hsteps = pow(3,level+2);
    int hsteps = abs(h_x - h_y);
    
    if (hsteps == max_hsteps) {
        if (h_x > h_y) {
            int tmp = h_x;
            h_x = h_y;
            h_y = tmp;
        }
        z_loc_x = -180.0;
    }
    
    NSString *h_code = @"";
    
    //analyzer is complaining because level in an int and not an unsigned int, which could cause array to have zero or negative size.
    int code3_x[level+3];
    int code3_y[level+3];
    for (int i = 0; i <= level+2; i++) {
        code3_x[i] = 0;
        code3_y[i] = 0;
    }
    int mod_x = h_x;
    int mod_y = h_y;
    
    for(int i = 0;i <= level+2 ; i++){
        int h_pow = pow(3,level+2-i);
        if(mod_x >= ceil((double)h_pow/2.0)){
            code3_x[i] =2;
            mod_x -= h_pow;
        }else if(mod_x <= -ceil((double)h_pow/2.0)){
            code3_x[i] =0;
            mod_x += h_pow;
        }else{
            code3_x[i] =1;
        }
        if(mod_y >= ceil((double)h_pow/2.0)){
            code3_y[i] =2;
            mod_y -= h_pow;
        }else if(mod_y <= -ceil((double)h_pow/2.0)){
            code3_y[i] =0;
            mod_y += h_pow;
        }else{
            code3_y[i] =1;
        }
        if(i==2&&(z_loc_x==-180 || z_loc_x>=0)){
            if(code3_x[0]==2&&code3_y[0]==1&&code3_x[1]==code3_y[1]&&code3_x[2]==code3_y[2]){
                code3_x[0]=1;
                code3_y[0]=2;
            }else if(code3_x[0]==1&&code3_y[0]==0&&code3_x[1]==code3_y[1]&&code3_x[2]==code3_y[2]){
                code3_x[0]=0;
                code3_y[0]=1;
            }
        }
    }
    
    for (int i=0; i <= level+2; i++) {
        h_code = [h_code stringByAppendingString:[GeoHexV3 parseInt3x:code3_x[i] y:code3_y[i]]];
    }
    
    NSString *h_1 = [h_code substringToIndex:3];
    int h_a1 = [h_1 intValue] / 30;
    int h_a2 = [h_1 intValue] % 30;
    
    h_code = [NSString stringWithFormat:@"%@%@%@",[h_key substringWithRange:NSMakeRange(h_a1, 1)],[h_key substringWithRange:NSMakeRange(h_a2, 1)],[h_code substringFromIndex:3]];
    
    GeoHexV3 *geoHex = [[GeoHexV3 alloc] init];
    geoHex.code = h_code;
    geoHex.coordinate = CLLocationCoordinate2DMake(z_loc_y, z_loc_x);
    geoHex.position = point;
    return geoHex;
}

+(GeoHexV3*)geoHexWithCoordinate:(CLLocationCoordinate2D)coordinate level:(int)level {
    MKMapPoint xy = [GeoHexV3 xyFromCoordinate:coordinate level:level];
    return [GeoHexV3 geoHexWithXY:xy level:level];
}

-(int)level {
	return (int)[[self code] length] - 2;
}

-(NSArray<CLLocation*>*)locations {
	double h_lat = self.coordinate.latitude;
	
	MKMapPoint h_xy = [GeoHexV3 locToXY: self.coordinate];
	
	double h_x = h_xy.x;
	double h_y = h_xy.y;
	
	double h_angle = tan(M_PI*(60.0/180.0));
    double h_size = [GeoHexV3 hexSizeForLevel:[self level]]; //level might need adjustment here.
	
	double h_top = [GeoHexV3 xyToLoc:MKMapPointMake(h_x, (h_y + h_angle* h_size) )].latitude;
	double h_btm = [GeoHexV3 xyToLoc:MKMapPointMake(h_x, (h_y - h_angle* h_size) )].latitude;
	
	double h_l = [GeoHexV3 xyToLoc:MKMapPointMake( (h_x - 2* h_size), h_y)].longitude;
	double h_r = [GeoHexV3 xyToLoc:MKMapPointMake( (h_x + 2* h_size), h_y)].longitude;
	double h_cl = [GeoHexV3 xyToLoc:MKMapPointMake( (h_x - 1* h_size), h_y)].longitude;
	double h_cr = [GeoHexV3 xyToLoc:MKMapPointMake( (h_x + 1* h_size), h_y)].longitude;
	
	NSArray *locations = @[[[CLLocation alloc] initWithLatitude:h_lat longitude:h_l],
						  [[CLLocation alloc] initWithLatitude:h_top longitude:h_cl],
						  [[CLLocation alloc] initWithLatitude:h_top longitude:h_cr],
						  [[CLLocation alloc] initWithLatitude:h_lat longitude:h_r],
						  [[CLLocation alloc] initWithLatitude:h_btm longitude:h_cr],
						  [[CLLocation alloc] initWithLatitude:h_btm longitude:h_cl]];
	return locations;
}

#pragma mark - Perimeter

-(NSArray<GeoHexV3*>*)perimeterHexes {
    MKMapPoint centerPoint = MKMapPointMake(self.position.x, self.position.y);
    MKMapPoint point1 = MKMapPointMake(centerPoint.x+1, centerPoint.y);
    MKMapPoint point2 = MKMapPointMake(centerPoint.x+1, centerPoint.y+1);
    MKMapPoint point3 = MKMapPointMake(centerPoint.x, centerPoint.y+1);
    MKMapPoint point4 = MKMapPointMake(centerPoint.x-1, centerPoint.y);
    MKMapPoint point5 = MKMapPointMake(centerPoint.x-1, centerPoint.y-1);
    MKMapPoint point6 = MKMapPointMake(centerPoint.x, centerPoint.y-1);
    
    GeoHexV3 *hex1 = [GeoHexV3 geoHexWithXY:point1 level:self.level];
    GeoHexV3 *hex2 = [GeoHexV3 geoHexWithXY:point2 level:self.level];
    GeoHexV3 *hex3 = [GeoHexV3 geoHexWithXY:point3 level:self.level];
    GeoHexV3 *hex4 = [GeoHexV3 geoHexWithXY:point4 level:self.level];
    GeoHexV3 *hex5 = [GeoHexV3 geoHexWithXY:point5 level:self.level];
    GeoHexV3 *hex6 = [GeoHexV3 geoHexWithXY:point6 level:self.level];
    
    return @[hex1,hex2,hex3,hex4,hex5,hex6];
}

-(NSArray<GeoHexV3*>*)perimeterHexesWithRings:(int)numberOfRings {
    //TODO: What if the user specifies more layers than it possible at the given level? (eg. requesting 10 layers of GeoHexes at Level 0)  There is current behavior is undefined.
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    MKMapPoint mapPoint;
    MKMapPoint centerPoint = MKMapPointMake(self.position.x, self.position.y);
    
    int numberOfRingsIncludingCenter = numberOfRings+1;
    
    for (int i = 0; i < numberOfRingsIncludingCenter; i++){
        for(int j = 0; j < numberOfRingsIncludingCenter; j++){
            if (i > 0 || j > 0) {
                if (i >= j) {
                    mapPoint = MKMapPointMake(centerPoint.x + i, centerPoint.y + j);
                } else {
                    mapPoint = MKMapPointMake(centerPoint.x + i, centerPoint.y + j);
                }
                GeoHexV3 *geoHex = [GeoHexV3 geoHexWithXY:mapPoint level:self.level];
                NSString *code = geoHex.code;
                if (code != nil) {
                    dict[code] = geoHex;
                }
                
                if (i >= j) {
                    mapPoint = MKMapPointMake(centerPoint.x - i, centerPoint.y - j);
                } else {
                    mapPoint = MKMapPointMake(centerPoint.x - i, centerPoint.y - j);
                }
                geoHex = [GeoHexV3 geoHexWithXY:mapPoint level:self.level];
                code = geoHex.code;
                if (code != nil) {
                    dict[code] = geoHex;
                }
                
                if (i > 0 && j > 0 && (i + j <= numberOfRingsIncludingCenter - 1)) {
                    mapPoint = MKMapPointMake(centerPoint.x - i, centerPoint.y + j);
                    geoHex = [GeoHexV3 geoHexWithXY:mapPoint level:self.level];
                    code = geoHex.code;
                    if (code != nil) {
                        dict[code] = geoHex;
                    }

                    mapPoint = MKMapPointMake(centerPoint.x + i, centerPoint.y - j);
                    geoHex = [GeoHexV3 geoHexWithXY:mapPoint level:self.level];
                    code = geoHex.code;
                    if (code != nil) {
                        dict[code] = geoHex;
                    }
                }
            }
        }
    }
    return [dict allValues];
}

#pragma mark - Rectangle Search

+(int) getXStepsMinLon:(double)minLon maxLon:(double)maxLon min:(GeoHexV3*)min max:(GeoHexV3*)max {
    double minsteps = fabs(min.position.x - min.position.y);
    double maxsteps = fabs(max.position.x - max.position.y);
    NSString *code = min.code;
    double base_steps = pow(3, code.length)*2;
    
    double steps = 0;
    
    if (min.coordinate.longitude == -180 && max.coordinate.longitude == -180.0) {
        if ((minLon > maxLon && minLon * maxLon >= 0.0) || (minLon < 0.0 && maxLon > 0.0)) {
            steps = base_steps;
        } else {
            steps = 0;
        }
    } else if (fabs(min.coordinate.longitude - max.coordinate.longitude) < 0.0000000001) {
        if (min.coordinate.longitude != -180.0 && minLon > maxLon) {
            steps = base_steps;
        }else{
            steps = 0;
        }
    } else if (min.coordinate.longitude < max.coordinate.longitude) {
        if (min.coordinate.longitude <= 0.0 && max.coordinate.longitude <= 0.0) {
            steps = minsteps - maxsteps;
        } else if (min.coordinate.longitude <= 0.0 && max.coordinate.longitude >= 0.0) {
            steps = minsteps + maxsteps;
        } else if (min.coordinate.longitude >= 0.0 && max.coordinate.longitude >= 0.0) {
            steps = maxsteps - minsteps;
        }
    } else if (min.coordinate.longitude > max.coordinate.longitude) {
        if (min.coordinate.longitude <= 0.0 && max.coordinate.longitude <= 0.0) {
            steps = base_steps - maxsteps + minsteps;
        } else if (min.coordinate.longitude >= 0.0 && max.coordinate.longitude <= 0.0) {
            steps = base_steps-(minsteps + maxsteps);
        } else if (min.coordinate.longitude >= 0.0 && max.coordinate.longitude >= 0.0) {
            steps = base_steps + maxsteps - minsteps;
        }
    }
    return steps + 1;
}

+(double) getYStepsLon:(double)lon min:(GeoHexV3*)min max:(GeoHexV3*)max {
    double min_x = min.position.x;
    double min_y = min.position.y;
    double max_x = max.position.x;
    double max_y = max.position.y;
    
    if (lon > 0.0) {
        if (min.coordinate.longitude != -180.0 && max.coordinate.longitude == -180.0) {
            max_x = max.position.y;
            max_y = max.position.x;
        }
        if (min.coordinate.longitude == -180.0 && max.coordinate.longitude != -180.0) {
            min_x = min.position.y;
            min_y = min.position.x;
        }
    }
    double steps = fabs(min_y - max_y);
    double half = fabs(max_x - min_x) - fabs(max_y - min_y);
    return steps + half * 0.5 + 1;
}

+(NSArray*) getXList:(MKMapPoint)minPoint xSteps:(double)xSteps edge:(double)edge {
    NSMutableArray *list = [NSMutableArray array];
    for (int i = 0; i < xSteps; i++){
        double x = (edge)? minPoint.x + floor((double)i/2.0) : minPoint.x + ceil((double)i/2.0);
        double y = (edge)? minPoint.y + floor((double)i/2.0) - i : minPoint.y + ceil((double)i/2.0) - i;
        [list addObject:[XYObject objectWithX:x y:y]];
    }
    return list;
}

+(NSArray*) getYList:(MKMapPoint)minPoint ySteps:(double)ySteps edge:(double)edge {
    NSMutableArray *list = [NSMutableArray array];
    double steps_base = floor(ySteps);
    double steps_half = ySteps - steps_base;
    
    for(int i=0; i < steps_base; i++){
        double x = minPoint.x + i;
        double y = minPoint.y + i;
        [list addObject:[XYObject objectWithX:x y:y]];
        
        if(edge != 0.0){
            if ((steps_half == 0) && (i == steps_base-1)) {
                
            } else {
                x = (edge>0)?minPoint.x+ i + 1:minPoint.x + i;
                y = (edge<0)?minPoint.y + i + 1:minPoint.y + i;
                XYObject *obj = [XYObject objectWithX:x y:y];
                [list addObject:obj];
            }
        }
    }
    return list;
}

+(NSArray*) mergeList:(NSArray*)arr level:(int)level {
    NSMutableArray *newArr = [[NSMutableArray alloc] init];
    NSMutableDictionary *mrgArr = [NSMutableDictionary dictionary];
    
    /*
     _arr.sort(function(a, b) {
     return ( a.x > b.x ? 1 : a.x < b.x ? -1 : a.y < b.y ? 1 : -1 );
     });
     */
    NSArray *sortedArray = [arr sortedArrayUsingComparator:^NSComparisonResult(XYObject *a, XYObject *b) {
        //TODO: flip these ascending descending if tests don't pass
        if (a.x > b.x) {
            return NSOrderedDescending;
        } else if (a.x < b.x) {
            return NSOrderedAscending;
        } else if (a.y < b.y) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
    
    for (NSUInteger i=0; i < [sortedArray count]; i++) {
        XYObject *thisPoint = sortedArray[i];
        if (!i) {
            //var inner_xy = GEOHEX.adjustXY(sortedArray[i].x,sortedArray[i].y,_level);
            MKMapPoint inner_xy = [GeoHexV3 adjustXY:MKMapPointMake(thisPoint.x, thisPoint.y) level:level];
            double x = inner_xy.x;
            NSString *xString = [NSString stringWithFormat:@"%f",x];
            double y = inner_xy.y;
            NSString *yString = [NSString stringWithFormat:@"%f",y];
            
            if (!mrgArr[xString]) {
                //TODO: mrgArr will probably need to be a dictionary since x is unlikely to come in order
                mrgArr[xString] = [NSMutableDictionary dictionary];
            }
            
            if (!mrgArr[xString][yString]) {
                mrgArr[xString][yString] = @YES;
                //newArr.push({"x":x,"y":y})
                [newArr addObject:[XYObject objectWithX:x y:y]];
            }
        } else {
            double mrg = [GeoHexV3 mergeCheck:sortedArray[i-1] next:sortedArray[i]];
            for (int j = 0; j < mrg; j++){
                //var inner_xy = GEOHEX.adjustXY(sortedArray[i].x,sortedArray[i].y+j,_level);
                XYObject *point = sortedArray[i];
                MKMapPoint inner_xy = [GeoHexV3 adjustXY:MKMapPointMake(point.x, point.y+j) level:level];
                double x = inner_xy.x;
                NSString *xString = [NSString stringWithFormat:@"%f",x];
                double y = inner_xy.y;
                NSString *yString = [NSString stringWithFormat:@"%f",y];
                if (!mrgArr[xString]) {
                    //TODO: mrgArr will probably need to be a dictionary since x is unlikely to come in order
                    mrgArr[xString] = [NSMutableDictionary dictionary];
                }
                if (!mrgArr[xString][yString]) {
                    mrgArr[xString][yString] = @YES;
                    //newArr.push({"x":x,"y":y})
                    
                    [newArr addObject:[XYObject objectWithX:x y:y]];
                }
            }
        }
    }
    return newArr;
}

+(double)mergeCheck:(XYObject*)pre next:(XYObject*)next {
    if (pre.x == next.x) {
        if (pre.y == next.y) {
            return 0;
        } else {
            return fabs(next.y -pre.y);
        }
    } else {
        return 1.0;
    }
}

+(NSArray*)getXYListWithSWCorner:(CLLocationCoordinate2D)sw neCorner:(CLLocationCoordinate2D)ne level:(int)level {
    //var h_deg = Math.tan(Math.PI * (60 / 180));
    //var h_base = 20037508.34;
    int base_steps =  pow(3, level+2)*2;
    //NSMutableArray *list = [NSMutableArray array];
    //int steps_x =0;
    //int steps_y =0;
    
    double min_lat= (sw.latitude > ne.latitude)?ne.latitude:sw.latitude;
    double max_lat=(sw.latitude < ne.latitude)?ne.latitude:sw.latitude;
    double min_lon = sw.longitude;
    double max_lon = ne.longitude;
    
    GeoHexV3 *zone_tl = [GeoHexV3 geoHexWithCoordinate:CLLocationCoordinate2DMake(max_lat, min_lon) level:level];
    GeoHexV3 *zone_bl = [GeoHexV3 geoHexWithCoordinate:CLLocationCoordinate2DMake(min_lat, min_lon) level:level];
    GeoHexV3 *zone_br = [GeoHexV3 geoHexWithCoordinate:CLLocationCoordinate2DMake(min_lat, max_lon) level:level];
    GeoHexV3 *zone_tr = [GeoHexV3 geoHexWithCoordinate:CLLocationCoordinate2DMake(max_lat, max_lon) level:level];
    
    //int start_x = zone_bl.position.x;
    //int start_y = zone_bl.position.y;
    
    double h_size = [GeoHexV3 hexSizeForLevel:level];
    
    //var bl_xy = GEOHEX.loc2xy(zone_bl.lon, zone_bl.lat);
    MKMapPoint bl_xy = [GeoHexV3 locToXY:zone_bl.coordinate];
    
    //var bl_cl = GEOHEX.xy2loc(bl_xy.x - h_size, bl_xy.y).lon;
    double bl_cl = [GeoHexV3 xyToLoc:MKMapPointMake(bl_xy.x-h_size, bl_xy.y)].longitude;
    
    //var bl_cr = GEOHEX.xy2loc(bl_xy.x + h_size, bl_xy.y).lon;
    double bl_cr = [GeoHexV3 xyToLoc:MKMapPointMake(bl_xy.x + h_size, bl_xy.y)].longitude;
    
    //var br_xy = GEOHEX.loc2xy(zone_br.lon, zone_br.lat);
    MKMapPoint br_xy = [GeoHexV3 locToXY:zone_br.coordinate];
    
    //var br_cl = GEOHEX.xy2loc(br_xy.x - h_size, br_xy.y).lon;
    double br_cl = [GeoHexV3 xyToLoc:MKMapPointMake(br_xy.x - h_size, br_xy.y)].longitude;
    
    //var br_cr = GEOHEX.xy2loc(br_xy.x + h_size, br_xy.y).lon;
    double br_cr = [GeoHexV3 xyToLoc:MKMapPointMake(br_xy.x + h_size, br_xy.y)].longitude;
    
    //var s_steps = getXSteps(min_lon, max_lon, zone_bl, zone_br);
    double s_steps = [GeoHexV3 getXStepsMinLon:min_lon maxLon:max_lon min:zone_bl max:zone_br];
    
//    var w_steps = getYSteps(min_lon, zone_bl, zone_tl);
    double w_steps = [GeoHexV3 getYStepsLon:min_lon min:zone_bl max:zone_tl];
    
//    var n_steps = getXSteps(min_lon, max_lon, zone_tl, zone_tr);
    double n_steps = [GeoHexV3 getXStepsMinLon:min_lon maxLon:max_lon min:zone_tl max:zone_tr];
    
//    var e_steps = getYSteps(max_lon, zone_br, zone_tr);
    double e_steps = [GeoHexV3 getYStepsLon:max_lon min:zone_br max:zone_tr];
    
    double edgeL = 0.0;
    double edgeR = 0.0;
    double edgeT = 0.0;
    double edgeB = 0.0;
    
    if (s_steps == n_steps && s_steps >= base_steps) {
        edgeL = 0.0;
        edgeR = 0.0;
    } else {
        if (min_lon > 0 && zone_bl.coordinate.longitude == -180.0) {
            double m_lon = min_lon - 360.0;
            if (bl_cr < m_lon) edgeL = 1.0;
            if (bl_cl > m_lon) edgeL = -1.0;
        } else {
            if (bl_cr < min_lon) edgeL = 1.0;
            if (bl_cl > min_lon) edgeL = -1.0;
        }
        
        if (max_lon > 0.0 && zone_br.coordinate.longitude == -180.0) {
            double m_lon = max_lon - 360.0;
            if (br_cr < m_lon) edgeR = 1.0;
            if (br_cl > m_lon) edgeR = -1.0;
        } else {
            if (br_cr < max_lon) edgeR = 1.0;
            if (br_cl > max_lon) edgeR = -1.0;
        }
    }
    
    if (zone_bl.coordinate.latitude > min_lat) edgeB++;
    if (zone_tl.coordinate.latitude > max_lat) edgeT++;
    
    //var s_list = getXList(zone_bl, s_steps, edge.b);
    NSArray *s_list = [GeoHexV3 getXList:zone_bl.position xSteps:s_steps edge:edgeB];
    
    //var w_list = getYList(zone_bl, w_steps, edge.l);
    NSArray *w_list = [GeoHexV3 getYList:zone_bl.position ySteps:w_steps edge:edgeL];
    
    // ä»®æƒ³HEX_XYåº§æ¨™ç³»ä¸Šã®çŸ©å½¢ç«¯ï¼ˆ NW & SE ï¼‰å–å¾—
    //var tl_end = {"x": w_list[w_list.length-1].x, "y": w_list[w_list.length-1].y};
    XYObject *lastPoint = [w_list lastObject];
    MKMapPoint tl_end = MKMapPointMake(lastPoint.x, lastPoint.y);
    
    //var br_end = {"x": s_list[s_list.length-1].x, "y": s_list[s_list.length-1].y};
    lastPoint = [s_list lastObject];
    MKMapPoint br_end = MKMapPointMake(lastPoint.x, lastPoint.y);
    
    // ä»®æƒ³HEX_XYåº§æ¨™ç³»ä¸Šã®è¾ºãƒªã‚¹ãƒˆï¼ˆ N & E ï¼‰å–å¾—
    //var n_list = getXList(tl_end, n_steps, edge.t);
    NSArray *n_list = [GeoHexV3 getXList:tl_end xSteps:n_steps edge:edgeT];
    
    //var e_list = getYList(br_end, e_steps, edge.r);
    NSArray *e_list = [GeoHexV3 getYList:br_end ySteps:e_steps edge:edgeR];
    
    // S & W & N & E è¾ºãƒªã‚¹ãƒˆã«å›²ã¾ã‚ŒãŸå†…åŒ…HEXãƒªã‚¹ãƒˆã‚’å–å¾—
    //var mrg_list = mergeList(s_list.concat(w_list, n_list, e_list), _level);
    NSArray *swne_list = [s_list arrayByAddingObjectsFromArray:w_list];
    swne_list = [swne_list arrayByAddingObjectsFromArray:n_list];
    swne_list = [swne_list arrayByAddingObjectsFromArray:e_list];
    NSArray *mrg_list = [GeoHexV3 mergeList:swne_list level:level];
    
    return(mrg_list);
}

#pragma mark utility methods

/**
 * A utility method to return the character located at a specific index.
 * @property	anIndex	The desired index
 * @property	aString	The string whose index we should return
 * @return	An NSString with a length of one character contain the character at the given index of the given string.
 */
+(NSString *)charAtIndex:(int)anIndex ofString:(NSString *)aString {
	if (anIndex < [aString length]) {
        return [aString substringWithRange:NSMakeRange(anIndex,1)];
    } else {
        return nil;
    }
}

/**
 * A utility method to return the index where a given character is located.
 * @property	aChar	Should be an NSString with a length of a single character
 * @property	aString	The string in which we search for the character
 * @return	An NSString with a length of one character which contains the character at the given index of the given string.
 */
+(NSInteger)indexOfChar:(NSString *) aChar inString:(NSString *) aString {
	if (nil == aString) {
		return NSNotFound;
	}
	NSRange range = [aString rangeOfString:aChar];
	return (NSInteger)range.location;
}

+(NSString*)parseInt3x:(int)x y:(int)y {
    //x and y will always be 0-2
    if (x == 0) {
        if (y == 0) {
            return @"0";
        } else if (y == 1) {
            return @"1";
        } else if (y == 2) {
            return @"2";
        }
    } else if (x == 1) {
        if (y == 0) {
            return @"3";
        } else if (y == 1) {
            return @"4";
        } else if (y == 2) {
            return @"5";
        }
    } else if (x == 2) {
        if (y == 0) {
            return @"6";
        } else if (y == 1) {
            return @"7";
        } else if (y == 2) {
            return @"8";
        }
    }
    return nil;
}

/**
 * A utility method which takes an integer an converts it to an NSString with the base 3 representation of the integer
 * @property	anInteger   an integer
 * @return	An NSString with the base 3 represention of the given integer
 */
+(NSString*)toString3:(int)anInteger {
    switch (anInteger) {
        case 1:
            return @"01";
            break;
        case 2:
            return @"02";
            break;
        case 3:
            return @"10";
            break;
        case 4:
            return @"11";
            break;
        case 5:
            return @"12";
            break;
        case 6:
            return @"20";
            break;
        case 7:
            return @"21";
            break;
        case 8:
            return @"22";
            break;
        case 0:
        default:
            return @"00";
            break;
    }
}

-(NSString*) description {
    return [NSString stringWithFormat:@"GeoHex %@ level:%i x:%i y:%i (%f,%f) size: %f",self.code,self.level,(int)self.position.x,(int)self.position.y,self.coordinate.latitude,self.coordinate.longitude,[GeoHexV3 hexSizeForLevel:self.level]];
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[GeoHexV3 class]]) {
        GeoHexV3 *otherGeoHex = (GeoHexV3*)object;
        if ([self.code isEqualToString:otherGeoHex.code]) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash {
    return [self.code hash];
}

@end
