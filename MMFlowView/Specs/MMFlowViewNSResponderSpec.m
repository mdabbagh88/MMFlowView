//
//  MMFlowViewNSResponderSpec.m
//  MMFlowViewDemo
//
//  Created by Markus Müller on 19.02.14.
//  Copyright 2014 www.isnotnil.com. All rights reserved.
//

#import <objc/runtime.h>

#import "Kiwi.h"
#import "MMFlowView+NSResponder.h"
#import "MMFlowView_Private.h"
#import "NSEvent+MMAdditions.h"
#import "MMScrollBarLayer.h"
#import "MMFlowViewImageCache.h"
#import "MMMacros.h"

static BOOL testingSuperInvoked = NO;

@interface MMFlowView (MMResponderTests)

- (void)mmTesting_keyDown:(NSEvent *)theEvent;

@end

@implementation MMFlowView (MMResponderTests)

- (void)mmTesting_keyDown:(NSEvent *)theEvent
{
	testingSuperInvoked = YES;
}

@end

SPEC_BEGIN(MMFlowViewNSResponderSpec)

describe(@"MMFlowView+NSResponder", ^{
	__block MMFlowView *sut = nil;
	__block NSEvent *mockedEvent = nil;
	__block CALayer *mockedLayer = nil;

	beforeEach(^{
		sut = [[MMFlowView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
		mockedEvent = [NSEvent nullMock];
		mockedLayer = [CALayer nullMock];
		[sut stub:@selector(layer) andReturn:mockedLayer];
	});
	afterEach(^{
		sut = nil;
		mockedEvent = nil;
		mockedLayer = nil;
	});
	it(@"should have an action cell class", ^{
		[[[[sut class] cellClass] should] equal:[NSActionCell class]];
	});
	it(@"should accept being first responder", ^{
		[[theValue([sut acceptsFirstResponder]) should] beYes];
	});
	context(NSStringFromSelector(@selector(mouseEntered:)), ^{
		it(@"should invoke mouseEnteredSelection", ^{
			[[sut should] receive:@selector(mouseEnteredSelection)];
			[sut mouseEntered:mockedEvent];
		});
	});
	context(NSStringFromSelector(@selector(mouseExited:)), ^{
		it(@"should invoke mouseEnteredSelection", ^{
			[[sut should] receive:@selector(mouseExitedSelection)];
			[sut mouseExited:mockedEvent];
		});
	});
	context(NSStringFromSelector(@selector(keyDown:)), ^{
		context(@"invoking supers implementation", ^{
			__block Method supersMethod;
			__block Method testingMethod;
			
			beforeEach(^{
				supersMethod = class_getInstanceMethod([sut superclass], @selector(keyDown:));
				testingMethod = class_getInstanceMethod([sut class], @selector(mmTesting_keyDown:));
				method_exchangeImplementations(supersMethod, testingMethod);
			});
			afterEach(^{
				method_exchangeImplementations(testingMethod, supersMethod);
			});
			it(@"should call up to super", ^{
				testingSuperInvoked = NO;
				[sut keyDown:mockedEvent];
				[[theValue(testingSuperInvoked) should] beYes];
			});
		});
		context(@"quicklook panel", ^{
			context(@"when controlling quicklook panel is turned off", ^{
				beforeEach(^{
					sut.canControlQuickLookPanel = NO;
				});
				it(@"should not invoke togglePreview:", ^{
					[[sut shouldNot] receive:@selector(togglePreviewPanel:)];
				});
			});
			context(@"when controlling quicklook panel is turned on", ^{
				beforeEach(^{
					sut.canControlQuickLookPanel = YES;
				});
				context(@"when the space key is pressed", ^{
					beforeEach(^{
						[mockedEvent stub:@selector(characters) andReturn:@" "];
					});
					it(@"should receive togglePreviewPanel:", ^{
						[[sut should] receive:@selector(togglePreviewPanel:) withArguments:sut];
						[sut keyDown:mockedEvent];
					});
				});
				it(@"should not invoke togglePreview:", ^{
					[[sut shouldNot] receive:@selector(togglePreviewPanel:)];
					[sut keyDown:mockedEvent];
				});
			});
		});
	});
	context(@"scrolling and swiping", ^{
		beforeEach(^{
			[mockedEvent stub:@selector(dominantDeltaInXYSpace) andReturn:theValue(3)];
			[sut stub:@selector(selectedIndex) andReturn:theValue(3)];
		});
		context(NSStringFromSelector(@selector(swipeWithEvent:)), ^{
			it(@"should ask the event for its dominant delta", ^{
				[[mockedEvent should] receive:@selector(dominantDeltaInXYSpace)];
				[sut swipeWithEvent:mockedEvent];
			});
			it(@"should add the dominant delta to the selected index", ^{
				[[sut should] receive:@selector(setSelectedIndex:) withArguments:theValue(3+3)];
				[sut swipeWithEvent:mockedEvent];
			});
		});
		context(NSStringFromSelector(@selector(scrollWheel:)), ^{
			it(@"should ask the event for its dominant delta", ^{
				[[mockedEvent should] receive:@selector(dominantDeltaInXYSpace)];
				[sut swipeWithEvent:mockedEvent];
			});
			it(@"should add the dominant delta to the selected index", ^{
				[[sut should] receive:@selector(setSelectedIndex:) withArguments:theValue(3+3)];
				[sut scrollWheel:mockedEvent];
			});
		});
	});
	context(NSStringFromSelector(@selector(mouseUp:)), ^{
		it(@"should disable dragging", ^{
			[[sut.scrollBarLayer should] receive:@selector(endDrag)];
			[sut mouseUp:mockedEvent];
		});
	});
	context(NSStringFromSelector(@selector(rightMouseUp:)), ^{
		__block id mockedDelegate = nil;

		afterEach(^{
			mockedDelegate = nil;
		});

		context(@"when the delegate supports right clicks", ^{
			NSPoint pointInWindow = NSMakePoint(10, 10);

			beforeEach(^{
				mockedDelegate = [KWMock nullMockForProtocol:@protocol(MMFlowViewDelegate)];
				sut.delegate = mockedDelegate;
				[mockedEvent stub:@selector(locationInWindow) andReturn:theValue(pointInWindow)];
			});
			it(@"should ask the event for the mouse location", ^{
				[[mockedEvent should] receive:@selector(locationInWindow)];
				[sut rightMouseUp:mockedEvent];
			});
			it(@"should ask for the item at the mouse position in view coordinates", ^{
				NSPoint expectedPoint = [sut convertPoint:pointInWindow fromView:nil];
				[[sut should] receive:@selector(indexOfItemAtPoint:) withArguments:theValue(expectedPoint)];
				[sut rightMouseUp:mockedEvent];
			});
			context(@"when an item was clicked", ^{
				const NSUInteger expectedItemIndex = 3;
				beforeEach(^{
					[sut stub:@selector(indexOfItemAtPoint:) andReturn:theValue(expectedItemIndex)];
				});
				it(@"should ask the delegate to handle the click", ^{
					[[mockedDelegate should] receive:@selector(flowView:itemWasRightClickedAtIndex:withEvent:) withArguments:sut, theValue(expectedItemIndex), mockedEvent];
					[sut rightMouseUp:mockedEvent];
				});
			});
			context(@"when no item was clicked", ^{
				beforeEach(^{
					[sut stub:@selector(indexOfItemAtPoint:) andReturn:theValue(NSNotFound)];
				});
				it(@"should ask the delegate to handle the click", ^{
					[[mockedDelegate shouldNot] receive:@selector(flowView:itemWasRightClickedAtIndex:withEvent:)];
					[sut rightMouseUp:mockedEvent];
				});
			});
		});
		context(@"when the delegate does supports right clicks", ^{
			beforeEach(^{
				mockedDelegate = [KWMock nullMock];
				sut.delegate = mockedDelegate;
			});
			it(@"should not ask the delegate to handle the click", ^{
				[[mockedDelegate shouldNot] receive:@selector(flowView:itemWasRightClickedAtIndex:withEvent:)];
				[sut rightMouseUp:mockedEvent];
			});
		});
	});
	context(NSStringFromSelector(@selector(mouseDragged:)), ^{
		context(@"scroll bar layer interaction", ^{
			__block MMScrollBarLayer *mockedScrollBarLayer = nil;
			__block CGPoint pointInScrollLayer;
			NSPoint pointInWindow = NSMakePoint(10, 10);

			beforeEach(^{
				[mockedEvent stub:@selector(locationInWindow) andReturn:theValue(pointInWindow)];

				pointInScrollLayer = CGPointMake(30, 7);
				[mockedLayer stub:@selector(convertPoint:toLayer:) andReturn:theValue(pointInScrollLayer)];
				mockedScrollBarLayer = [MMScrollBarLayer nullMock];
				sut.scrollBarLayer = mockedScrollBarLayer;
			});
			afterEach(^{
				mockedScrollBarLayer = nil;
			});
			it(@"should ask the layer to convert the mouse point to the scrollbar layers coordinate space", ^{
				[[mockedLayer should] receive:@selector(convertPoint:toLayer:) withArguments:[KWAny any], mockedScrollBarLayer];
				[sut mouseDragged:mockedEvent];
			});
			it(@"should notify the scroll bar layer about the drag", ^{
				[[mockedScrollBarLayer should] receive:@selector(mouseDraggedToPoint:) withArguments:theValue(pointInScrollLayer)];
				[sut mouseDragged:mockedEvent];
			});
		});
	});
	context(NSStringFromSelector(@selector(mouseDown:)), ^{
		context(@"when clicking on scroll bar", ^{
			__block id mockedScrollBar = nil;
			CGRect scrollBarRect = CGRectMake(0, 0, 200, 20);
			CGPoint pointInScrollBar = CGPointMake(CGRectGetMidX(scrollBarRect), CGRectGetMidY(scrollBarRect));

			beforeEach(^{
				mockedScrollBar = [MMScrollBarLayer nullMock];
				[mockedScrollBar stub:@selector(frame) andReturn:theValue(scrollBarRect)];
				sut.scrollBarLayer = mockedScrollBar;
				[sut stub:@selector(hitLayerAtPoint:) andReturn:mockedScrollBar];
				[mockedLayer stub:@selector(convertRect:fromLayer:) andReturn:theValue(scrollBarRect)];
				[mockedLayer stub:@selector(convertPoint:toLayer:) andReturn:theValue(pointInScrollBar)];
			});
			afterEach(^{
				mockedScrollBar = nil;
			});
			it(@"should convert the scroll bar rect to view coordinates", ^{
				CALayer *mockedSuperLayer = [CALayer nullMock];
				[mockedScrollBar stub:@selector(superlayer) andReturn:mockedSuperLayer];

				[[mockedLayer should] receive:@selector(convertRect:fromLayer:) withArguments:theValue(scrollBarRect), mockedSuperLayer];

				[sut mouseDown:mockedEvent];
			});
			it(@"should convert the mouse point to the scroll bars coordinate space", ^{
				[[mockedLayer should] receive:@selector(convertPoint:toLayer:) withArguments:[KWAny any], mockedScrollBar];

				[sut mouseDown:mockedEvent];
			});
			it(@"should pass the click to the scroll bar layer", ^{
				[[mockedScrollBar should] receive:@selector(mouseDownAtPoint:) withArguments:theValue(pointInScrollBar)];

				[sut mouseDown:mockedEvent];
			});
		});
		context(@"when clicking on item layers", ^{
			context(@"when clicking on an item", ^{
				beforeEach(^{
					[sut stub:@selector(indexOfItemAtPoint:) andReturn:theValue(3)];
				});
				it(@"should ask for the index of the item", ^{
					[[sut should] receive:@selector(indexOfItemAtPoint:)];

					[sut mouseDown:mockedEvent];
				});
				it(@"should should change the selection to the clicked layer", ^{
					[[sut should] receive:@selector(setSelectedIndex:) withArguments:theValue(3)];

					[sut mouseDown:mockedEvent];
				});
			});
			context(@"when clicking on the selected item", ^{
				__block id mockedDatasource = nil;
				__block NSPasteboard *mockedPasteboard = nil;
				const NSUInteger selectedIndex = 2;

				beforeEach(^{
					mockedPasteboard = [NSPasteboard nullMock];
					[[NSPasteboard stubAndReturn:mockedPasteboard] pasteboardWithName:NSDragPboard];

					[sut stub:@selector(indexOfItemAtPoint:) andReturn:theValue(selectedIndex)];
					[sut stub:@selector(selectedIndex) andReturn:theValue(selectedIndex)];

					mockedDatasource = [KWMock nullMockForProtocol:@protocol(MMFlowViewDataSource)];
					sut.dataSource = mockedDatasource;
				});
				afterEach(^{
					mockedDatasource = nil;
				});
				context(@"drag image", ^{
					__block id imageCacheMock = nil;
					__block id itemMock = nil;
					__block id dragImageMock = nil;
					__block CGImageRef imageRefMock = NULL;
					NSString *imageUID = @"testImageUID";
					NSRect stubbedItemFrame = NSMakeRect(10, 10, 300, 200);

					beforeAll(^{
						NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage01" withExtension:@"jpg"];
						NSDictionary *quickLookOptions = @{(id)kQLThumbnailOptionIconModeKey: (id)kCFBooleanFalse};
						imageRefMock = QLThumbnailImageCreate(NULL, (__bridge CFURLRef)(imageURL), CGSizeMake(400, 400), (__bridge CFDictionaryRef)quickLookOptions );
					});
					afterAll(^{
						SAFE_CGIMAGE_RELEASE(imageRefMock);
					});
					beforeEach(^{
						itemMock = [KWMock nullMockForProtocol:@protocol(MMFlowViewItem)];
						[itemMock stub:@selector(imageItemUID) andReturn:imageUID];
						[mockedDatasource stub:@selector(flowView:itemAtIndex:) andReturn:itemMock];

						imageCacheMock = [MMFlowViewImageCache nullMock];
						
						[imageCacheMock stub:@selector(imageForUUID:) andReturn:(__bridge id)(imageRefMock)];
						sut.imageCache = imageCacheMock;
						
						dragImageMock = [NSImage nullMock];
						[NSImage stub:@selector(alloc) andReturn:dragImageMock];

						[sut stub:@selector(selectedItemFrame) andReturn:theValue(stubbedItemFrame)];
					});
					afterEach(^{
						dragImageMock = nil;
						itemMock = nil;
						imageCacheMock = nil;
					});
					it(@"should ask the image cache for an drag image", ^{
						[[imageCacheMock should] receive:@selector(imageForUUID:) withArguments:@"testImageUID"];

						[sut mouseDown:mockedEvent];
					});
					it(@"should create an image from the cached image", ^{
						[[dragImageMock should] receive:@selector(initWithCGImage:size:) withArguments:theValue(imageRefMock), theValue(stubbedItemFrame.size)];

						[sut mouseDown:mockedEvent];
					});
					it(@"should drag the image", ^{
						[dragImageMock stub:@selector(initWithCGImage:size:) andReturn:dragImageMock];

						[[sut should] receive:@selector(dragImage:at:offset:event:pasteboard:source:slideBack:) withArguments:dragImageMock, theValue(stubbedItemFrame.origin), theValue(NSZeroSize), mockedEvent, mockedPasteboard, sut, theValue(YES)];

						[sut mouseDown:mockedEvent];
					});
				});
				context(@"when the datasource supports writing items to the pasteboard", ^{
					it(@"should ask the datasource to write the item to the dragging pasteboard", ^{
						[[mockedDatasource should] receive:@selector(flowView:writeItemAtIndex:toPasteboard:) withArguments:sut, theValue(sut.selectedIndex), mockedPasteboard];
						
						[sut mouseDown:mockedEvent];
					});
				});
				
				context(@"when the datasource does not handle -flowView:writeItemAtIndex:toPasteboard:", ^{
					beforeEach(^{
						mockedDatasource = [KWMock nullMock];
						sut.dataSource = mockedDatasource;
					});
					it(@"should not ask the datasource for writing the item to the pasteboard", ^{
						[[mockedDatasource shouldNot] receive:@selector(flowView:writeItemAtIndex:toPasteboard:)];
						
						[sut mouseDown:mockedEvent];
					});
				});
			});
			context(@"when not clicking to an item", ^{
				beforeEach(^{
					[sut stub:@selector(indexOfItemAtPoint:) andReturn:theValue(NSNotFound)];
				});
				it(@"should should mot change the selection", ^{
					[[sut shouldNot] receive:@selector(setSelectedIndex:)];
					
					[sut mouseDown:mockedEvent];
				});
			});
			
		});
	});
});

SPEC_END
