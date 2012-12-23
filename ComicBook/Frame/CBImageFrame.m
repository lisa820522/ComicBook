//
//  CBImageFrame.m
//  ComicBook
//
//  Created by cbreak on 2012.12.22.
//  Copyright (c) 2012 the-color-black.net. All rights reserved.
//

#import "CBImageFrame.h"

static BOOL canLoadFrameFromFormat(NSString * extension)
{
	NSArray * imageTypes = [NSImage imageTypes];
	return [imageTypes containsObject:extension];
}

static BOOL canLoadFramesFromURL(NSURL * url)
{
	NSString * urlType;
	BOOL success = [url getResourceValue:&urlType forKey:NSURLTypeIdentifierKey error:NULL];
	if (success && urlType)
	{
		return canLoadFrameFromFormat(urlType);
	}
	return NO;
}

// URL Loader

@implementation CBURLImageFrameLoader

- (BOOL)canLoadFramesFromURL:(NSURL*)url
{
	return canLoadFramesFromURL(url);
}

- (NSArray*)loadFramesFromURL:(NSURL*)url error:(NSError **)error
{
	CBURLImageFrame * urlFrames = [[CBURLImageFrame alloc] initWithURL:url];
	if (urlFrames)
		return @[urlFrames];
	return nil;
}

@end

// Data Loader

@implementation CBDataImageFrameLoader

- (BOOL)canLoadFramesFromData:(NSData*)data withPath:(NSString*)path
{
	NSString * fileExtension = [path pathExtension];
	return canLoadFrameFromFormat(fileExtension);
}

- (NSArray*)loadFramesFromData:(NSData*)data withPath:(NSString*)path error:(NSError **)error
{
	CBDataImageFrame * dataFrames = [[CBDataImageFrame alloc] initWithData:data withPath:path];
	if (dataFrames)
		return @[dataFrames];
	return nil;
}

@end

// URL Frame
@implementation CBURLImageFrame

- (id)initWithURL:(NSURL *)frameURL
{
	if (self = [super init])
	{
		if (canLoadFramesFromURL(frameURL))
		{
			url = frameURL;
		}
		else
		{
			self = nil;
		}
	}
	return self;
}

- (NSImage*)image
{
	NSImage * image = [[NSImage alloc] initWithContentsOfURL:url];
	if (image && [image isValid])
	{
		return image;
	}
	else
	{
		NSLog(@"Error loading image from url %@", [self path]);
		return [super image];
	}
}

- (NSString *)path;
{
	return [url path];
}

@end

// Data Frame
@implementation CBDataImageFrame

- (id)initWithData:(NSData*)data_ withPath:(NSString*)path_
{
	if (self = [super init])
	{
		NSString * fileExtension = [path pathExtension];
		if (canLoadFrameFromFormat(fileExtension))
		{
			data = data_;
			path = path_;
		}
		else
		{
			self = nil;
		}
	}
	return self;
}

- (NSImage*)image
{
	NSImage * image = [[NSImage alloc] initWithData:data];
	if (image && [image isValid])
	{
		return image;
	}
	else
	{
		NSLog(@"Error loading image from url %@", [self path]);
		return [super image];
	}
}

@synthesize path;

@end