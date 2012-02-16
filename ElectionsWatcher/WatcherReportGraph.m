//
//  WatcherReportGraph.m
//  ElectionsWatcher
//
//  Created by xfire on 14.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherReportGraph.h"

@implementation WatcherReportGraph

@synthesize goodCount, badCount;

- (id) initWithFrame: (CGRect) frame {
    self = [super initWithFrame:frame];
    if ( self ) {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return self;
}

- (void) drawRect: (CGRect) rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    if ( self.goodCount == 0 && self.badCount == 0 ) {
        CGContextAddArc(ctx, rect.size.width/2, rect.size.height/2, rect.size.height/2, 0, 2*M_PI, 1);
        CGContextSetRGBFillColor(ctx, 0.7, 0.7, 0.7, 1);
        CGContextFillPath(ctx);
    } else if ( self.goodCount == 0 && self.badCount > 0) {
        CGContextAddArc(ctx, rect.size.width/2, rect.size.height/2, rect.size.height/2, 0, 2*M_PI, 1);
        CGContextSetRGBFillColor(ctx, 1, 0, 0, 1);
        CGContextFillPath(ctx);
    } else if ( self.goodCount > 0 && self.badCount == 0 ) {
        CGContextAddArc(ctx, rect.size.width/2, rect.size.height/2, rect.size.height/2, 0, 2*M_PI, 1);
        CGContextSetRGBFillColor(ctx, 0, 0, 1, 1);
        CGContextFillPath(ctx);
    } else {
        double n = sqrt((double)self.goodCount);
        double m = sqrt((double)self.badCount);
        double x = (n+m)/2.0f;
        
        if ( n > m ) {
            CGContextScaleCTM(ctx, rect.size.width/(2*n+2*m+x), rect.size.height/(2*n));
            CGContextTranslateCTM(ctx, n, n);
        } else {
            CGContextScaleCTM(ctx, rect.size.width/(2*n+2*m+x), rect.size.height/(2*m));
            CGContextTranslateCTM(ctx, n, m);
        }
        
        CGPoint p1 = CGPointMake(-n, 0);
        CGPoint p2 = CGPointMake(0, n);
        CGPoint p3 = CGPointMake(n+x*n/(n+m), 0);
        CGPoint p4 = CGPointMake(0, -n);
        
        CGPoint p5 = CGPointMake(n+x*n/(n+m), 0);
        CGPoint p6 = CGPointMake(n+m+x, m);
        CGPoint p7 = CGPointMake(n+2*m+x, 0);
        CGPoint p8 = CGPointMake(n+m+x, -m);
        
        CGMutablePathRef path1 = CGPathCreateMutable();
        CGPathMoveToPoint(path1, nil, p1.x, p1.y);
        CGPathAddCurveToPoint(path1, NULL, p1.x, p1.y+n*11/20, p2.x-n*11/20, p2.y, p2.x, p2.y);
        CGPathAddCurveToPoint(path1, NULL, p2.x+n*11/20, p2.y, p3.x, p3.y, p3.x, p3.y);
        CGPathAddCurveToPoint(path1, NULL, p3.x, p3.y, p4.x+n*11/20, p4.y, p4.x, p4.y);
        CGPathAddCurveToPoint(path1, NULL, p4.x-n*11/20, p4.y, p1.x, p1.y-n*11/20, p1.x, p1.y);
        CGPathCloseSubpath(path1);
        CGContextSetRGBFillColor(ctx, 0, 0, 1, 1);
        CGContextAddPath(ctx, path1);
        CGContextFillPath(ctx);
        
        CGMutablePathRef path2 = CGPathCreateMutable();
        CGPathMoveToPoint(path2, nil, p5.x, p5.y);
        CGPathAddCurveToPoint(path2, NULL, p5.x, p5.y, p6.x-m*11/20, p6.y, p6.x, p6.y);
        CGPathAddCurveToPoint(path2, NULL, p6.x+m*11/20, p6.y, p7.x, p7.y+m*11/20, p7.x, p7.y);
        CGPathAddCurveToPoint(path2, NULL, p7.x, p7.y-m*11/20, p8.x+m*11/20, p8.y, p8.x, p8.y);
        CGPathAddCurveToPoint(path2, NULL, p8.x-m*11/20, p8.y, p5.x, p5.y, p5.x, p5.y);
        CGPathCloseSubpath(path2);
        CGContextSetRGBFillColor(ctx, 1, 0, 0, 1);
        CGContextAddPath(ctx, path2);
        CGContextFillPath(ctx);
        
        CGPathRelease(path1);
        CGPathRelease(path2);
    }
    
    CGContextRestoreGState(ctx);
}

@end
