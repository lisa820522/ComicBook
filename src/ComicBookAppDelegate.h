//
//  ComicBookAppDelegate.h
//  ComicBook
//
//  Created by cbreak on 23.02.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ComicBookGLView;

@interface ComicBookAppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow * window;
	ComicBookGLView * view;
}

@property (assign) IBOutlet NSWindow * window;
@property (assign) IBOutlet ComicBookGLView * view;

@end
