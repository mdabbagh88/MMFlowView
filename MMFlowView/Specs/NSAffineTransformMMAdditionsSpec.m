//
//  NSAffineTransformMMAdditionsSpec.m
//  MMFlowViewDemo
//
//  Created by Markus Müller on 23.01.14.
//  Copyright 2014 www.isnotnil.com. All rights reserved.
//

#import "Kiwi.h"
#import "NSAffineTransform+MMAdditions.h"

#ifndef DEGREES2RADIANS
#define DEGREES2RADIANS(angle) ((angle) * M_PI / 180.)
#endif

SPEC_BEGIN(NSAffineTransformMMAdditionsSpec)

context(@"NSAffineTransform+MMAdditions", ^{
	__block NSAffineTransform *sut = nil;

	afterEach(^{
		sut = nil;
	});
	context(@"affineTransformWithCGAffineTransform:", ^{
		const CGAffineTransform testCGTransform = CGAffineTransformMake(10, 20, 30, 40, 10, 10);

		beforeEach(^{
			sut = [NSAffineTransform affineTransformWithCGAffineTransform:testCGTransform];
		});
		it(@"should exist", ^{
			[[sut shouldNot] beNil];
		});
		it(@"should be a NSAffineTransform", ^{
			[[sut should] beKindOfClass:[NSAffineTransform class]];
		});
		context(@"matching the CGAffineTranaform", ^{
			__block NSAffineTransformStruct transform;
			beforeEach(^{
				transform = [sut transformStruct];
			});
			it(@"should have m11==a", ^{
				[[theValue(transform.m11) should] equal:theValue(testCGTransform.a)];
			});
			it(@"should have m12==b", ^{
				[[theValue(transform.m12) should] equal:theValue(testCGTransform.b)];
			});
			it(@"should have m21==c", ^{
				[[theValue(transform.m21) should] equal:theValue(testCGTransform.c)];
			});
			it(@"should have m22==d", ^{
				[[theValue(transform.m22) should] equal:theValue(testCGTransform.d)];
			});
			it(@"should have tX==tx", ^{
				[[theValue(transform.tX) should] equal:theValue(testCGTransform.tx)];
			});
			it(@"should have tY==ty", ^{
				[[theValue(transform.tY) should] equal:theValue(testCGTransform.ty)];
			});
		});
		context(@"performing calculations", ^{
			context(@"points", ^{
				CGPoint testPoint = {10, 10};
				CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(DEGREES2RADIANS(30));
				CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(50, 50);

				it(@"should match the rotation", ^{
					NSValue *expectedPoint = [NSValue valueWithPoint:CGPointApplyAffineTransform(testPoint, rotationTransform)];
					sut = [NSAffineTransform affineTransformWithCGAffineTransform:rotationTransform];
					[[[NSValue valueWithPoint:[sut transformPoint:testPoint]] should] equal:expectedPoint];
				});
				it(@"should match the translation", ^{
					NSValue *expectedPoint = [NSValue valueWithPoint:CGPointApplyAffineTransform(testPoint, translationTransform)];
					sut = [NSAffineTransform affineTransformWithCGAffineTransform:translationTransform];
					[[[NSValue valueWithPoint:[sut transformPoint:testPoint]] should] equal:expectedPoint];
				});
			});

			it(@"should match the scale", ^{
				CGSize testSize = {150, 150};
				CGAffineTransform scaleTransform = CGAffineTransformMakeScale(20, 20);

				NSValue *expectedSize = [NSValue valueWithSize:CGSizeApplyAffineTransform(testSize, scaleTransform)];
				sut = [NSAffineTransform affineTransformWithCGAffineTransform:scaleTransform];
				[[[NSValue valueWithSize:[sut transformSize:testSize]] should] equal:expectedSize];
			});
			
		});
	});
	context(@"mm_CGAffineTransform", ^{
		beforeEach(^{
			sut = [NSAffineTransform transform];
		});
		it(@"should respond to -mm_CGAffineTransform", ^{
			[[sut should] respondToSelector:@selector(mm_CGAffineTransform)];
		});
		it(@"should match with a rotation transform", ^{
			CGAffineTransform expectedTransform = CGAffineTransformMakeRotation(DEGREES2RADIANS(30));
			[sut rotateByDegrees:30];
			[[theValue((BOOL)CGAffineTransformEqualToTransform(sut.mm_CGAffineTransform, expectedTransform)) should] beYes];
		});
		it(@"should match with a translation transform", ^{
			CGAffineTransform expectedTransform = CGAffineTransformMakeTranslation(40, 40);
			[sut translateXBy:40 yBy:40];
			[[theValue((BOOL)CGAffineTransformEqualToTransform(sut.mm_CGAffineTransform, expectedTransform)) should] beYes];
		});
		it(@"should match with a scale transform", ^{
			CGAffineTransform expectedTransform = CGAffineTransformMakeScale(50, 50);
			[sut scaleXBy:50 yBy:50];
			[[theValue((BOOL)CGAffineTransformEqualToTransform(sut.mm_CGAffineTransform, expectedTransform)) should] beYes];
		});
	});
});

SPEC_END
