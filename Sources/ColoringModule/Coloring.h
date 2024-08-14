//
//  Header.h
//  
//
//  Created by Hong Seong Ho on 8/11/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Coloring: NSObject

+(UIColor* _Nullable) getPixelColor:(nullable void *) data
                              width:(int)width
                             height:(int)height
                        bytesPerRow:(int)bytesPerRow
                              point:(CGPoint)point;

+(NSMutableArray* _Nonnull) setImage:(nullable void *) data
                               width:(int)width
                              height:(int)height
                         bytesPerRow:(int)bytesPerRow
                           threshold:(int)threshold;

+(void) setPattern:(nullable void *) data
             width:(int)width
            height:(int)height
       bytesPerRow:(int)bytesPerRow;

+(UIImage* _Nullable) fill:(CGPoint)point
                         r:(int)r
                         g:(int)g
                         b:(int)b;

+(void) makeMask:(CGPoint)point;

+(void) updatePoint:(CGPoint)point;

+(UIImage* _Nullable) erase:(double)size;

+(UIImage* _Nullable) drawLine:(double)size
                             r:(int)r
                             g:(int)g
                             b:(int)b;

+(UIImage* _Nullable) drawPencil:(double)size
                               r:(int)r
                               g:(int)g
                               b:(int)b;

+(UIImage* _Nullable) drawCrayon:(double)size
                               r:(int)r
                               g:(int)g
                               b:(int)b;

+(UIImage* _Nullable) drawBrush:(double)size
                              r:(int)r
                              g:(int)g
                              b:(int)b;

+(void) touchEnded;

@end
