//
//  CBDocument.m
//  ComicBook
//
//  Created by cbreak on 01.03.10.
//  Copyright 2010 cbreak. All rights reserved.
//

#import "CBDocument.h"

#import "Controllers/CBListController.h"
#import "Controllers/CBPageController.h"

#import "CBPage.h"
#import "CBURLPage.h"

#import "CBPageOperation.h"

const NSUInteger preloadWindowSize = 11;

@implementation CBDocument

- (id)init
{
	self = [super init];
	if (self)
	{
		pages = [[NSMutableArray alloc] init];
		preloadQueue = [[NSOperationQueue alloc] init];
		preloadQueue.name = @"preloadQueue";
		preloadedPages = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[listController release];
	[pageController release];
	[pages release];
	[baseURL release];
	[preloadQueue release];
	[preloadedPages release];
	[super dealloc];
}

- (void)makeWindowControllers
{
	CBListController * lc = [[CBListController alloc] init];
	CBPageController * pc = [[CBPageController alloc] init];
	[self setListController:lc];
	[self setPageController:pc];
	[self addWindowController:lc];
	[self addWindowController:pc];
	[lc release];
	[pc release];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	if ( outError != NULL )
	{
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	NSNumber * isDirectory;
	[absoluteURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
	if ([isDirectory boolValue])
	{
		if (baseURL != absoluteURL)
		{
			[baseURL release];
			baseURL = [absoluteURL retain];
		}
		[self addDirectoryURL:absoluteURL];
	}
	else
	{
		[baseURL release];
		baseURL = [[absoluteURL URLByDeletingLastPathComponent] retain];
		[self addFileURL:absoluteURL];
	}
    return YES;
}

// Add files
- (void)addDirectoryURL:(NSURL *)url
{
	NSFileManager * fm = [[NSFileManager alloc] init];
	NSDirectoryEnumerator * de =
		[fm enumeratorAtURL:url includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLTypeIdentifierKey,NSURLIsDirectoryKey,nil]
					options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:^(NSURL *url, NSError *error)
	{
		NSLog(@"addDirectoryURL enumerator error: %@", error);
		return YES;
	}];
	for (NSURL * url in de)
	{
		NSNumber * isDirectory;
		if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL])
		{
			if (![isDirectory boolValue]) // Some kind of file
			{
				[self addFileURL:url];
			};
		};
	};
	[fm release];
	[self willChangeValueForKey:@"pages"];
	[pages sortWithOptions:NSSortConcurrent usingComparator:^(id o1, id o2){return [[o1 path] localizedStandardCompare:[o2 path]];}];
	[self didChangeValueForKey:@"pages"];
	[self preloadPages];
}

- (void)addFileURL:(NSURL *)url
{
	CBPage * page = [[CBURLPage alloc] initWithURL:url];
	if (page)
	{
		NSIndexSet * insertionIndex = [NSIndexSet indexSetWithIndex:[pages count]];
		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:insertionIndex forKey:@"pages"];
		[pages addObject:page];
		[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:insertionIndex forKey:@"pages"];
		[page release];
	}
}

// Accessors pages
- (NSInteger)countOfPages
{
	return [pages count];
}

- (CBPage *)pageAtIndex:(NSUInteger)number
{
	if (number < [pages count])
	{
		return (CBPage *)[pages objectAtIndex:number];
	}
	else
	{
		return nil;
	}
}

- (CBPage *)objectInPagesAtIndex:(NSUInteger)number
{
	return [self pageAtIndex:number];
}

- (void)getPages:(CBPage **)buffer range:(NSRange)inRange
{
	[pages getObjects:buffer range:inRange];
}

// Accessors currentPage
- (void)advancePage:(NSInteger)offset
{
	if (offset != 0)
	{
		[self willChangeValueForKey:@"currentPage"];
		if (offset < 0 && currentPage < (NSUInteger)-offset)
			currentPage = 0;
		else if (currentPage + offset >= [pages count])
			currentPage = [pages count] - 1;
		else
			currentPage += offset;
		[self preloadPages];
		[self didChangeValueForKey:@"currentPage"];
	}
}

- (void)setCurrentPage:(NSUInteger)number
{
	if (number >= [pages count])
		currentPage = [pages count] - 1;
	else
		currentPage = number;
	[self preloadPages];
}

@synthesize currentPage; // Only synthesize getter

- (void)preloadPages
{
	NSMutableArray * preloadOps = [NSMutableArray arrayWithCapacity:preloadWindowSize];
	NSMutableArray * preloadPages = [NSMutableArray arrayWithCapacity:preloadWindowSize];
	// Determine window position
	NSUInteger pagesBack = preloadWindowSize/2;
	if (pagesBack > currentPage) // further back than 0
	{
		pagesBack = currentPage; // only go back to 0
	}
	NSUInteger pageStart = currentPage-pagesBack;
	NSUInteger pageEnd = pageStart+preloadWindowSize;
	if (pageEnd > [pages count]) // goes past pages end
	{
		pageEnd = [pages count]; // stop at end
		// Since the end was shortened, compensate
		if (pageEnd > preloadWindowSize)
			pageStart = pageEnd - preloadWindowSize;
		else
			pageStart = 0;
	}
	// Create load operations
	for (NSUInteger i = pageStart; i < pageEnd; i++)
	{
		CBPageOperation * po = [[CBPreloadOperation alloc] init];
		CBPage * p = [pages objectAtIndex:i];
		po.page = p;
		[preloadPages addObject:p];
		[preloadOps addObject:po];
		[po release];
	}
	[preloadQueue addOperations:preloadOps waitUntilFinished:NO];
	// Create barrier op
	NSOperation * barrierOp = [[NSOperation alloc] init];
	for (NSOperation * op in preloadOps)
	{
		[barrierOp addDependency:op];
	}
	[preloadQueue addOperation:barrierOp];
	// Create unload operations
	for (CBPage * p in preloadedPages)
	{
		CBPageOperation * po = [[CBUnloadOperation alloc] init];
		po.page = p;
		[po addDependency:barrierOp];
		[preloadQueue addOperation:po];
		[po release];
	}
	// Book Keeping
	[preloadedPages release];
	preloadedPages = [preloadPages retain];
	[barrierOp release];
}

// Misc Accessors
@synthesize listController;
@synthesize pageController;
@synthesize baseURL;

@end
