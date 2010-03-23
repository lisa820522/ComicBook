//
//  CBCAView.h
//  ComicBook
//
//  Created by cbreak on 09.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@protocol CBInputDelegate;
@class CBPage;

// Settings constants
extern NSString * kCBLayoutKey;
extern NSString * kCBLayoutSingle;
extern NSString * kCBLayoutLeft;
extern NSString * kCBLayoutRight;

// Scale
extern NSString * kCBScaleKey;
extern NSString * kCBScaleOriginal;
extern NSString * kCBScaleWidth;
extern NSString * kCBScaleFull;

// Layout Enums
typedef enum {
	CBLayoutSingle,
	CBLayoutLeft,
	CBLayoutRight,
} CBLayout;

// Scale Enums
typedef enum {
	CBScaleOriginal,
	CBScaleWidth,
	CBScaleFull,
} CBScale;

typedef struct
{
	CALayer * container;
	CALayer * left;
	CALayer * right;
	unsigned int pageCount;
}
CBCAViewLayerSet;

@interface CBCAView : NSView
{
	CAScrollLayer * scrollLayer;
	CBCAViewLayerSet layers[3];
	unsigned int currentLayerSet;

	CBLayout layout;
	CBScale scale;

	CGPoint scrollPosition;
	CGFloat zoomFactor;

	id<CBInputDelegate> delegate;
}

- (void)dealloc;

// Initialisation
- (void)awakeFromNib;

// Events
- (BOOL)acceptsFirstResponder;
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (void)defaultsChanged:(NSNotification *)notification;
@property (assign) id<CBInputDelegate> delegate;

// Image display
- (void)pageChanged;
- (void)setPage:(CBPage*)page;
- (void)setPageLeft:(CBPage*)pageLeft right:(CBPage*)pageRight;

// Scrolling & Zooming
- (void)resetView;
- (void)scrollToPoint:(CGPoint)point;
- (void)scrollByOffsetX:(float)x Y:(float)y;
- (void)zoomIn;
- (void)zoomOut;
- (void)zoomTo:(float)scaleFactor;
- (void)zoomReset;

// Full Screen
- (IBAction)toggleFullscreen:(id)sender;
- (BOOL)enterFullScreen;
- (void)exitFullScreen;

@end
