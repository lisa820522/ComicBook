//
//  CBZipPage.m
//  ComicBook
//
//  Created by cbreak on 19.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBZipPage.h"

#import <ZipKit/ZKDataArchive.h>
#import <ZipKit/ZKCDHeader.h>

@implementation CBZipPage

- (id)initWithArchive:(ZKDataArchive *)fileArchive header:(ZKCDHeader*)fileHeader
{
	self = [super init];
	if (self)
	{
		if (![fileHeader isDirectory] && ![fileHeader isSymLink] && ![fileHeader isResourceFork])
		{
			// Seems to be a file
			archive = [fileArchive retain];
			header = [fileHeader retain];
			img = nil;
			accessCounter = 0; // Should be 1, but this class lazily loads the Data
		}
		else
		{
			// Could not read type
			[self release];
			self = nil;
		}
	}
	return self;
}

- (void)dealloc
{
	[archive release];
	[header release];
	[img release];
	[super dealloc];
}

// Loads the Image lazily (internal)
- (BOOL)loadImage
{
	if (!img)
	{
		NSDictionary * fileAttributes;
		NSData * imgData = [archive inflateFile:header attributes:&fileAttributes];
		img = [[NSImage alloc] initWithData:imgData];
		if (!img || ![img isValid])
		{
			// TODO: Set img to error image
			NSLog(@"Error loading image from archive, file %@", [self path]);
			return NO;
		}
		else
		{
			return YES;
		}
	}
	return img != nil && [img isValid];
}

- (NSImage *)image
{
	NSImage * rImg;
	@synchronized (self)
	{
		[self loadImage];
		rImg = [img retain];
	}
	return [rImg autorelease];
}

- (NSString *)path;
{
	return [[archive archivePath] stringByAppendingPathComponent:[header filename]];
}

// NSDiscardableContent
- (BOOL)beginContentAccess
{
	BOOL r = NO;
	@synchronized (self)
	{
		if ([self loadImage])
		{
			accessCounter++;
			r = YES;
		}
		else
		{
			r = NO;
		}
	}
	return r;
}

- (void)endContentAccess
{
	@synchronized (self)
	{
		accessCounter--;
	}
}

- (void)discardContentIfPossible
{
	@synchronized (self)
	{
		if (accessCounter <= 0)
		{
			[img release];
			img = nil;
		}
	}
}

- (BOOL)isContentDiscarded
{
	return img == nil;
}

// Creation

+ (NSArray*)pagesFromZipFile:(NSURL*)zipPath
{
	ZKDataArchive * zipArchive = [ZKDataArchive archiveWithArchivePath:[zipPath path]];
	if (zipArchive)
	{
		zipArchive.archivePath = [zipPath path];
		NSMutableArray * pages = [NSMutableArray arrayWithCapacity:1];
		for (ZKCDHeader * header in zipArchive.centralDirectory)
		{
			CBZipPage * page = [[CBZipPage alloc] initWithArchive:zipArchive header:header];
			if (page)
			{
				[pages addObject:page];
				[page release];
			}
		}
		return pages;
	}
	else
	{
		return [NSArray array];
	}
}

@end