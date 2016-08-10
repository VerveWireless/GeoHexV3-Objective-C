//
//  GeoHexV3Tests.m
//  GeoHexV3Tests
//
//  Created by Adam Allen on 8/8/16.
//  Copyright © 2016 Verve Wireless. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GeoHexV3.h"

@interface GeoHexV3Tests : XCTestCase

@end

@implementation GeoHexV3Tests

+(BOOL)doubleEqualityValue1:(double)value1 value2:(double)value2 {
    double diff = fabs(value1-value2);
    if (diff < 0.0000000001) {
        return YES;
    } else {
        NSLog(@"diff too large %f,%f = %f",value1,value2,diff);
        return NO;
    }
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

+(NSArray*)jsonArrayFromFile:(NSString*)fileName {
    NSString *filepath = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:filepath];
    return [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
}

+(NSArray*)arrayForPerformanceTesting:(NSArray*)array {
    //makes the array bigger so performance testing is accurate enough
    NSArray *performanceTestingArray = array;
    for (int i = 0; i < 6; ++i) {
        performanceTestingArray = [performanceTestingArray arrayByAddingObjectsFromArray:performanceTestingArray];
    }
    return performanceTestingArray;
}

- (void)testCodeToLatLon {
    NSArray *jsonArray = [GeoHexV3Tests jsonArrayFromFile:@"GeoHex32CodeToCoordTest"];
    for (NSArray *thisRow in jsonArray) {
        GeoHexV3 *geoHex = [GeoHexV3 geoHexWithCode:thisRow[0]];
        XCTAssertTrue([GeoHexV3Tests doubleEqualityValue1:geoHex.coordinate.latitude value2:[thisRow[1] doubleValue]] && [GeoHexV3Tests doubleEqualityValue1:geoHex.coordinate.longitude value2:[thisRow[2] doubleValue]],@"Coordinates are wrong");
    }
}

- (void)testCodeToXY {
    NSArray *jsonArray = [GeoHexV3Tests jsonArrayFromFile:@"GeoHex32CodeToXYTest"];
    for (NSArray *thisRow in jsonArray) {
        GeoHexV3 *geoHex = [GeoHexV3 geoHexWithCode:thisRow[0]];
        XCTAssertTrue((geoHex.position.x == [thisRow[1] intValue] && geoHex.position.y == [thisRow[2] intValue]),@"X Y coordinate is wrong");
    }
}

-(void) testPerformanceGeoHexWithCode {
    NSArray *jsonArray = [GeoHexV3Tests jsonArrayFromFile:@"GeoHex32CodeToXYTest"];
    jsonArray = [GeoHexV3Tests arrayForPerformanceTesting:jsonArray];
    [self measureBlock:^{
        dispatch_queue_t qq = dispatch_queue_create("com.vervemobile.qq",DISPATCH_QUEUE_CONCURRENT);
        NSUInteger rowCount = [jsonArray count];
        NSUInteger processorCount = [[NSProcessInfo processInfo] activeProcessorCount];
        dispatch_apply(processorCount, qq, ^(size_t i) {
            NSUInteger rowIndexMax = MIN(rowCount,(i + 1)*rowCount/processorCount);
            NSUInteger rowIndexMin = i*rowCount/processorCount;
            for (NSUInteger rowIndex = rowIndexMin; rowIndex < rowIndexMax; ++rowIndex) {
                NSArray *thisRow = jsonArray[rowIndex];
                [GeoHexV3 geoHexWithCode:thisRow[0]];
            }
        });
    }];
}

- (void)testLatLonToXY {
    NSArray *jsonArray = [GeoHexV3Tests jsonArrayFromFile:@"GeoHex32CoordToXYTest"];
    for (NSArray *thisRow in jsonArray) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([thisRow[1] doubleValue], [thisRow[2] doubleValue]);
        int level = [thisRow[0] intValue];
        MKMapPoint point = [GeoHexV3 xyFromCoordinate:coordinate level:level];
        XCTAssertTrue((point.x == [thisRow[3] intValue] && point.y == [thisRow[4] intValue]),@"X Y coordinate is wrong");
    }
}

-(void) testPerformanceXYFromCoordinate {
    NSArray *jsonArray = [GeoHexV3Tests jsonArrayFromFile:@"GeoHex32CoordToXYTest"];
    jsonArray = [GeoHexV3Tests arrayForPerformanceTesting:jsonArray];
    [self measureBlock:^{
        for (NSArray *thisRow in jsonArray) {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([thisRow[1] doubleValue], [thisRow[2] doubleValue]);
            int level = [thisRow[0] intValue];
            [GeoHexV3 xyFromCoordinate:coordinate level:level];
        }
    }];
}

- (void)testLatLonToCode {
    NSArray *jsonArray = [GeoHexV3Tests jsonArrayFromFile:@"GeoHex32CoordToCodeTest"];
    for (NSArray *thisRow in jsonArray) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([thisRow[1] doubleValue], [thisRow[2] doubleValue]);
        int level = [thisRow[0] intValue];
        GeoHexV3 *geoHex = [GeoHexV3 geoHexWithCoordinate:coordinate level:level];
        XCTAssertTrue([geoHex.code isEqualToString:thisRow[3]],@"Code is wrong");
    }
}

- (void) testXYToCode {
    NSArray *jsonArray = [GeoHexV3Tests jsonArrayFromFile:@"GeoHex32XYToCodeTest"];
    for (NSArray *thisRow in jsonArray) {
        int level = [thisRow[0] intValue];
        GeoHexV3 *geoHex = [GeoHexV3 geoHexWithXY:MKMapPointMake([thisRow[1] doubleValue], [thisRow[2] doubleValue]) level:level];
        XCTAssertTrue([geoHex.code isEqualToString:thisRow[3]],@"Code is wrong");
    }
}

-(void) testPerformanceGeoHexWithXY {
    NSArray *jsonArray = [GeoHexV3Tests jsonArrayFromFile:@"GeoHex32XYToCodeTest"];
    jsonArray = [GeoHexV3Tests arrayForPerformanceTesting:jsonArray];
    [self measureBlock:^{
        dispatch_queue_t qq = dispatch_queue_create("com.vervemobile.qq",DISPATCH_QUEUE_CONCURRENT);
        NSUInteger rowCount = [jsonArray count];
        NSUInteger processorCount = [[NSProcessInfo processInfo] activeProcessorCount];
        dispatch_apply(processorCount, qq, ^(size_t i) {
            NSUInteger rowIndexMax = MIN(rowCount,(i + 1)*rowCount/processorCount);
            NSUInteger rowIndexMin = i*rowCount/processorCount;
            for (NSUInteger rowIndex = rowIndexMin; rowIndex < rowIndexMax; ++rowIndex) {
                NSArray *thisRow = jsonArray[rowIndex];
                int level = [thisRow[0] intValue];
                [GeoHexV3 geoHexWithXY:MKMapPointMake([thisRow[1] doubleValue], [thisRow[2] doubleValue]) level:level];
            }
        });
    }];
}

- (void) testRectToXY {
    NSArray *jsonArray = [GeoHexV3Tests jsonArrayFromFile:@"GeoHex32RectToXYTest"];
    NSUInteger row = 0;
    for (NSArray *thisRow in jsonArray) {
        int level = [thisRow[4] intValue];
        CLLocationCoordinate2D sw = CLLocationCoordinate2DMake([thisRow[0] doubleValue], [thisRow[1] doubleValue]);
        CLLocationCoordinate2D ne = CLLocationCoordinate2DMake([thisRow[2] doubleValue], [thisRow[3] doubleValue]);
        NSArray *xys = [GeoHexV3 getXYListWithSWCorner:sw neCorner:ne level:level];
        
        NSArray *checkXYs = thisRow[6];
        if ([xys count] >= [checkXYs count]) {
            for (NSDictionary *checkXYDict in checkXYs) {
                int checkX = [checkXYDict[@"x"] intValue];
                int checkY = [checkXYDict[@"y"] intValue];
                BOOL foundMatch = NO;
                for (NSValue *genValue in xys) {
                    CGPoint genPoint = [genValue CGPointValue];
                    if ((int)genPoint.x == checkX && (int)genPoint.y == checkY) {
                        foundMatch = YES;
                        break;
                    }
                }
                if (!foundMatch) {
                    NSLog(@"%lu Couldn't find %i,%i",row,checkX,checkY);
                }
                XCTAssertTrue(foundMatch);
            }
        } else {
            XCTAssertTrue(NO,@"generated array is different size");
            NSLog(@"generated: %lu expected: %lu",[xys count],[checkXYs count]);
        }
        row++;
    }
}

@end
