//
//  MMPDFPageDecoder.m
//  MMFlowViewDemo
//
//  Created by Markus Müller on 18.12.13.
//  Copyright (c) 2013 www.isnotnil.com. All rights reserved.
//

#import "MMPDFPageDecoder.h"
#import <Quartz/Quartz.h>

@implementation MMPDFPageDecoder

- (CGImageRef)imageFromPDFPage:(CGPDFPageRef)pdfPage withSize:(CGSize)imageSize andTransparentBackground:(BOOL)transparentBackground
{
	NSParameterAssert(pdfPage != NULL);

	if ( CFGetTypeID(pdfPage) != CGPDFPageGetTypeID() ) {
		return NULL;
	}
	size_t width = imageSize.width;
	size_t height = imageSize.height;
	size_t bytesPerLine = width * 4;
	uint64_t size = (uint64_t)height * (uint64_t)bytesPerLine;
	
	if ((size == 0) || (size > SIZE_MAX))
		return NULL;
	
	void *bitmapData = calloc( 1, size );
	if (!bitmapData)
		return NULL;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(&kCGColorSpaceSRGB ? kCGColorSpaceSRGB : kCGColorSpaceGenericRGB);
	
	CGContextRef context = CGBitmapContextCreate(bitmapData, width, height, 8, bytesPerLine, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorSpace);
	
	if ( transparentBackground ) {
		CGContextClearRect( context, CGRectMake(0, 0, width, height) );
	}
	else {
		CGContextSetRGBFillColor( context, 1, 1, 1, 1 ); // white
		CGContextFillRect( context, CGRectMake(0, 0, imageSize.width, imageSize.height) );
	}
	CGRect imageRect = CGRectMake( 0, 0, imageSize.width, imageSize.height );
	CGRect boxRect = CGPDFPageGetBoxRect( pdfPage, kCGPDFCropBox );
	CGAffineTransform drawingTransform;
	if ( imageSize.width <= boxRect.size.width ) {
		drawingTransform = CGPDFPageGetDrawingTransform(pdfPage, kCGPDFCropBox, imageRect, 0, kCFBooleanTrue );
	}
	else {
		CGFloat scaleX = imageSize.width / boxRect.size.width;
		//CGFloat scaleY = imageSize.height / boxRect.size.height;
		
		drawingTransform = CGAffineTransformMakeTranslation( -boxRect.origin.x, -boxRect.origin.y );
		drawingTransform = CGAffineTransformScale(drawingTransform, scaleX, scaleX );
	}
	CGContextConcatCTM( context, drawingTransform );
	
	CGContextDrawPDFPage( context, pdfPage );
	
	CGImageRef pdfImage = CGBitmapContextCreateImage( context );
	
	CGContextRelease(context);
	
	free(bitmapData);
	
	return pdfImage;
}

- (CGImageRef)newImageFromItem:(id)anItem withSize:(CGSize)imageSize
{
	CGPDFPageRef pageRef = NULL;
	if ( [anItem isKindOfClass:[PDFPage class]] ) {
		pageRef = [((PDFPage*)anItem) pageRef];
	}
	else if ( CFGetTypeID((__bridge CFTypeRef)(anItem)) == CGPDFPageGetTypeID() ) {
		pageRef = (__bridge CGPDFPageRef)(anItem);
	}
	return pageRef ? [self imageFromPDFPage:pageRef
								   withSize:imageSize
					andTransparentBackground:NO] : NULL;
}

@end
