/*
 
 The MIT License (MIT)
 
 Copyright (c) 2014 Markus Müller https://github.com/mmllr All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this
 software and associated documentation files (the "Software"), to deal in the Software
 without restriction, including without limitation the rights to use, copy, modify, merge,
 publish, distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies
 or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
 FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 
 */
//
//  MMFlowView+NSResponder.m
//
//  Created by Markus Müller on 13.02.14.
//  Copyright (c) 2014 www.isnotnil.com. All rights reserved.
//

#import "MMFlowView+NSResponder.h"
#import "MMFlowView_Private.h"
#import "MMFlowViewImageCache.h"
#import "MMScrollBarLayer.h"
#import "NSEvent+MMAdditions.h"

@implementation MMFlowView (NSResponder)

#pragma mark - class methods

+ (Class)cellClass
{
    return [NSActionCell class];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

#pragma mark - NSResponder overrides

- (void)mouseDown:(NSEvent *)theEvent
{
	[self handleScrollBarClick:theEvent];
	[self handleItemClick:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint locationInWindow = [theEvent locationInWindow];
	CGPoint mouseInView = NSPointToCGPoint([self convertPoint:locationInWindow fromView:nil]);

	CGPoint pointInScrollBarLayer = [self.layer convertPoint:mouseInView toLayer:self.scrollBarLayer];

	[self.scrollBarLayer mouseDraggedToPoint:pointInScrollBarLayer];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[self.scrollBarLayer endDrag];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	if (![self.delegate respondsToSelector:@selector
		(flowView:itemWasRightClickedAtIndex:withEvent:)]) {
		return;
	}
	NSPoint pointInView = [self convertPoint:[theEvent locationInWindow]
									fromView:nil];
	NSUInteger clickedIndex = [self indexOfItemAtPoint:pointInView];

	if (clickedIndex == NSNotFound) {
		return;
	}
	[self.delegate flowView:self itemWasRightClickedAtIndex:clickedIndex withEvent:theEvent];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[self mouseEnteredSelection];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[self mouseExitedSelection];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if (self.canControlQuickLookPanel &&
		[[theEvent characters] isEqualToString:@" "]) {
		[self togglePreviewPanel:self];
	}
	[super keyDown:theEvent];
}

- (IBAction)moveLeft:(id)sender
{
	self.selectedIndex -= 1;
}

- (IBAction)moveRight:(id)sender
{
	self.selectedIndex += 1;
}

- (void)swipeWithEvent:(NSEvent *)event
{
	[self changeSelectionFromEvent:event];
}

- (void)scrollWheel:(NSEvent *)event
{
	[self changeSelectionFromEvent:event];
}

#pragma mark - helpers

- (void)changeSelectionFromEvent:(NSEvent *)event
{
	self.selectedIndex += event.dominantDeltaInXYSpace;
}

- (void)scrollBarClicked:(CGPoint)mouseInView
{
	CGPoint pointInScrollBarLayer = [[self layer] convertPoint:mouseInView toLayer:self.scrollBarLayer];
	[self.scrollBarLayer mouseDownAtPoint:pointInScrollBarLayer];
}

- (CGRect)scrollBarFrame
{
	return [self.layer convertRect:self.scrollBarLayer.frame fromLayer:self.scrollBarLayer.superlayer];
}

- (void)handleItemClick:(NSEvent*)theEvent
{
	CGPoint mouseInView = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow]
													 fromView:nil]);

	NSUInteger clickedItemIndex = [self indexOfItemAtPoint:mouseInView];
	if (clickedItemIndex == NSNotFound) {
		return;
	}
	if (clickedItemIndex != self.selectedIndex) {
		self.selectedIndex = clickedItemIndex;
		return;
	}
	if ([theEvent clickCount] == 2) {
		[self doubleClickOnSelection];
		return;
	}
	[self singleClickOnSelectionWithEvent:theEvent];
}

- (void)handleScrollBarClick:(NSEvent*)theEvent
{
	CGPoint mouseInView =  NSPointToCGPoint([self convertPoint:[theEvent locationInWindow]
													  fromView:nil]);
	if (CGRectContainsPoint([self scrollBarFrame], mouseInView)) {
		[self scrollBarClicked:mouseInView];
	}
}

- (void)singleClickOnSelectionWithEvent:(NSEvent *)theEvent
{
	if ([self initiateDragFromSelection]) {
		[self dragImage:[self draggedImageForSelection]
					 at:self.selectedItemFrame.origin
				 offset:NSZeroSize
				  event:theEvent
			 pasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]
				 source:self
			  slideBack:YES];
	}
}

- (void)doubleClickOnSelection
{
	if ([self.delegate respondsToSelector:@selector(flowView:itemWasDoubleClickedAtIndex:)]) {
		[self.delegate flowView:self itemWasDoubleClickedAtIndex:self.selectedIndex];
		return;
	}
	if (self.target && self.action) {
		[self sendAction:self.action to:self.target];
		return;
	}
	[[NSWorkspace sharedWorkspace] openURL:self.urlFromSelection];
}

- (NSImage*)draggedImageForSelection
{
	id<MMFlowViewItem> item = self.contentAdapter[self.selectedIndex];
	CGImageRef imageRef = [self.imageCache imageForUUID:item.imageItemUID];
	return [[NSImage alloc] initWithCGImage:imageRef
									   size:self.selectedItemFrame.size];
}

- (BOOL)initiateDragFromSelection
{
	if ([self.dataSource respondsToSelector:@selector(flowView:writeItemAtIndex:toPasteboard:)]) {
		return [self.dataSource flowView:self writeItemAtIndex:self.selectedIndex toPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]];
	}
	return [self dragURLFromSelection];
}

- (BOOL)dragURLFromSelection
{
	NSURL *url = self.urlFromSelection;

	if (!url) {
		return NO;
	}
	NSPasteboard *dragBoard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[dragBoard declareTypes:@[NSURLPboardType] owner:nil];
	[url writeToPasteboard:dragBoard];
	return YES;
}

- (NSURL*)urlFromSelection
{
	id<MMFlowViewItem> item = self.contentAdapter[self.selectedIndex];
	
	if (![[self.class pathRepresentationTypes] containsObject:item.imageItemRepresentationType]) {
		return nil;
	}
	id representation = item.imageItemRepresentation;
	return [representation isKindOfClass:[NSURL class]] ? representation : [NSURL fileURLWithPath:representation];
}

@end
