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
//  MMFlowViewItemLayer.h
//
//  Created by Markus Müller on 29.10.13.
//  Copyright (c) 2013 www.isnotnil.com. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class MMFlowViewImageLayer;

@interface MMFlowViewItemLayer : CAReplicatorLayer

@property (nonatomic) CGFloat reflectionOffset;
@property (nonatomic) NSUInteger index;
@property (nonatomic) NSString *imageUID;
@property (nonatomic, weak, readonly) MMFlowViewImageLayer *imageLayer;

+ (instancetype)layerWithImageUID:(NSString*)anImageUID andIndex:(NSUInteger)index;
- (id)initWithUID:(NSString*)anImageUID andIndex:(NSUInteger)anIndex;
- (void)setImage:(CGImageRef)anImage;

@end
