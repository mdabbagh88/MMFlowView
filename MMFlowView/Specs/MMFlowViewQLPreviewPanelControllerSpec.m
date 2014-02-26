//
//  MMFlowViewQLPreviewPanelControllerSpec.m
//  MMFlowViewDemo
//
//  Created by Markus Müller on 16.02.14.
//  Copyright 2014 www.isnotnil.com. All rights reserved.
//

#import "Kiwi.h"
#import "MMFlowView+QLPreviewPanelController.h"
#import "MMFlowView_Private.h"

SPEC_BEGIN(MMFlowViewQLPreviewPanelControllerSpec)

describe(@"MMFlowView+QLPreviewPanelController", ^{
	__block MMFlowView *sut = nil;
	__block QLPreviewPanel *mockedPanel = nil;

	beforeEach(^{
		sut = [[MMFlowView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
		mockedPanel = [QLPreviewPanel nullMock];
	});
	afterEach(^{
		sut = nil;
	});
	it(@"should respond to endPreviewPanelControl:", ^{
		[[sut should] respondToSelector:@selector(endPreviewPanelControl:)];
	});
	context(@"acceptsPreviewPanelControl:", ^{
		__block id mockedItem = nil;
		beforeAll(^{
			mockedItem = [KWMock nullMockForProtocol:@protocol(MMFlowViewItem)];
		});
		beforeEach(^{
			[sut stub:@selector(imageItemForIndex:) andReturn:mockedItem];
		});
		context(@"supported representationTypes", ^{
			__block NSArray *supportedRepresentationTypes = nil;
			beforeAll(^{
				supportedRepresentationTypes = @[kMMFlowViewURLRepresentationType,
												 kMMFlowViewPathRepresentationType,
												 kMMFlowViewQTMoviePathRepresentationType,
												 kMMFlowViewQCCompositionPathRepresentationType,
												 kMMFlowViewQuickLookPathRepresentationType,
												 kMMFlowViewIconRefPathRepresentationType];
			});
			it(@"should accept preview panel control", ^{
				for ( NSString *representationType in supportedRepresentationTypes ) {
					[mockedItem stub:@selector(imageItemRepresentationType) andReturn:representationType];
					[[theValue([sut acceptsPreviewPanelControl:[QLPreviewPanel nullMock]]) should] beYes];
				}
			});
		});
		context(@"unsupported representation types", ^{
			__block NSArray *unsupportedRepresentationTypes = nil;
			beforeAll(^{
				unsupportedRepresentationTypes = @[kMMFlowViewCGImageRepresentationType,
												 kMMFlowViewPDFPageRepresentationType,
												 kMMFlowViewNSImageRepresentationType,
												 kMMFlowViewCGImageSourceRepresentationType,
												 kMMFlowViewNSBitmapRepresentationType,
												 kMMFlowViewQCCompositionRepresentationType,
												   kMMFlowViewIconRefRepresentationType,
												   kMMFlowViewNSDataRepresentationType,
												   kMMFlowViewQTMovieRepresentationType];
			});
			it(@"should not accept preview panel control", ^{
				for ( NSString *representationType in unsupportedRepresentationTypes ) {
					[mockedItem stub:@selector(imageItemRepresentationType) andReturn:representationType];
					[[theValue([sut acceptsPreviewPanelControl:[QLPreviewPanel nullMock]]) should] beNo];
				}
			});
		});
	});
	context(@"beginPreviewPanelControl:", ^{
		it(@"should be the preview panels datasource", ^{
			[[mockedPanel should] receive:@selector(setDataSource:) withArguments:sut];
			[sut beginPreviewPanelControl:mockedPanel];
		});
		it(@"should be the preview panels delegate", ^{
			[[mockedPanel should] receive:@selector(setDelegate:) withArguments:sut];
			[sut beginPreviewPanelControl:mockedPanel];
		});
	});
	context(@"endPreviewPanelControl:", ^{
		it(@"should be the preview panels datasource to nil", ^{
			[[mockedPanel should] receive:@selector(setDataSource:) withArguments:[KWNull null]];
			[sut endPreviewPanelControl:mockedPanel];
		});
		it(@"should be the preview panels delegate to nil", ^{
			[[mockedPanel should] receive:@selector(setDelegate:) withArguments:[KWNull null]];
			[sut endPreviewPanelControl:mockedPanel];
		});
	});
});

SPEC_END