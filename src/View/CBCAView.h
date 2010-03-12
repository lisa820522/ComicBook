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

@interface CBCAView : NSView
{
	CAScrollLayer * scrollLayer;
	CALayer * containerLayer;
	CALayer * pageLayerLeft;
	CALayer * pageLayerRight;

	CGPoint scrollPosition;

	NSUInteger pageDisplayCount;

	id<CBInputDelegate> delegate;
}

- (void)dealloc;

// Initialisation
- (void)awakeFromNib;

// Events
- (BOOL)acceptsFirstResponder;
@property (assign) id<CBInputDelegate> delegate;

// UI / Animation
- (void)configureLayers;

// Image display
- (void)pageChanged;
- (void)setImage:(NSImage*)img;
- (void)setImageLeft:(NSImage*)imgLeft right:(NSImage*)imgRight;

// Scrolling
- (void)scrollToPoint:(CGPoint)point;
- (void)scrollByOffsetX:(float)x Y:(float)y;

// Full Screen
- (IBAction)toggleFullscreen:(id)sender;
- (BOOL)enterFullScreen;
- (void)exitFullScreen;

@end