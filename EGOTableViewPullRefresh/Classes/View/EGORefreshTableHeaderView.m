//
//  EGORefreshTableHeaderView.m
//  Demo
//
//  Created by Devin Doty on 10/14/09October14.
//  Copyright 2009 enormego. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGORefreshTableHeaderView.h"

#define EGO_RGBA(r,g,b,a)  \
    [UIColor colorWithRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:a]
//#define TEXT_COLOR       [UIColor colorWithRed:87.0/255.0 green:108.0/255.0 blue:137.0/255.0 alpha:1.0]
//#define TEXT_SHADOW      [UIColor colorWithWhite:0.9f alpha:1.0f];

#define TEXT_COLOR         EGO_RGBA(180, 180, 180, 1);
#define TEXT_SHADOW_COLOR  [UIColor blackColor];

#define FLIP_ANIMATION_DURATION 0.18f


@interface EGORefreshTableHeaderView (Private)
- (void)setState:(EGOPullRefreshState)aState;
@end

@implementation EGORefreshTableHeaderView

@synthesize delegate=_delegate;


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		
        self.originalInset = UIEdgeInsetsMake(0, 0, 0, 0);
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor clearColor];

		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 30.0f, self.frame.size.width, 20.0f)];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		label.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
		label.textColor = TEXT_COLOR;
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = NSTextAlignmentCenter;
		[self addSubview:label];
		_lastUpdatedLabel=label;
		[label release];
		
		label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 48.0f, self.frame.size.width, 20.0f)];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		label.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
		label.textColor = TEXT_COLOR;
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = NSTextAlignmentCenter;
		[self addSubview:label];
		_statusLabel=label;
		[label release];
		
		CALayer *layer = [CALayer layer];
		layer.frame = CGRectMake(25.0f, frame.size.height - 65.0f, 30.0f, 55.0f);
		layer.contentsGravity = kCAGravityResizeAspect;
		layer.contents = (id)[UIImage imageNamed:@"ic_refresh_arrow.png"].CGImage;
		
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
			layer.contentsScale = [[UIScreen mainScreen] scale];
		}
#endif
		
		[[self layer] addSublayer:layer];
		_arrowImage=layer;
		
		UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		view.frame = CGRectMake(25.0f, frame.size.height - 38.0f, 20.0f, 20.0f);
		[self addSubview:view];
		_activityView = view;
		[view release];
		
		
		[self setState:EGOOPullRefreshNormal];
		
    }
	
    return self;
	
}


#pragma mark -
#pragma mark Setters

- (void)refreshLastUpdatedDate {
	
	NSString *dateString = nil;
    
    if ([_delegate respondsToSelector:@selector(egoRefreshTableHeaderDataSourceLastUpdated:)]) {
		
		NSDate *date = [_delegate egoRefreshTableHeaderDataSourceLastUpdated:self];
		
        if (date) {
            NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
            [formatter setAMSymbol:@"AM"];
            [formatter setPMSymbol:@"PM"];
            [formatter setDateFormat:@"MM/dd/yyyy hh:mm:a"];
            dateString = [NSString stringWithFormat:@"Last Updated: %@", [formatter stringFromDate:date]];
        }
    }
    if (dateString)
        [[NSUserDefaults standardUserDefaults] setObject:dateString forKey:@"EGORefreshTableView_LastRefresh"];
    else
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"EGORefreshTableView_LastRefresh"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    _lastUpdatedLabel.text = dateString;
    [self updateSubviews];
}

- (void)setState:(EGOPullRefreshState)aState{
	
	switch (aState) {
		case EGOOPullRefreshPulling:
			
			_statusLabel.text = NSLocalizedString(@"Release to refresh...", @"Release to refresh status");
			[CATransaction begin];
			[CATransaction setAnimationDuration:FLIP_ANIMATION_DURATION];
			_arrowImage.transform = CATransform3DMakeRotation((M_PI / 180.0) * 180.0f, 0.0f, 0.0f, 1.0f);
			[CATransaction commit];
			
			break;
		case EGOOPullRefreshNormal:
			
			if (_state == EGOOPullRefreshPulling) {
				[CATransaction begin];
				[CATransaction setAnimationDuration:FLIP_ANIMATION_DURATION];
				_arrowImage.transform = CATransform3DIdentity;
				[CATransaction commit];
			}
			
			_statusLabel.text = NSLocalizedString(@"Pull down to refresh...", @"Pull down to refresh status");
			[_activityView stopAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions]; 
			_arrowImage.hidden = NO;
			_arrowImage.transform = CATransform3DIdentity;
			[CATransaction commit];
			
			[self refreshLastUpdatedDate];
			
			break;
		case EGOOPullRefreshLoading:
			
			_statusLabel.text = NSLocalizedString(@"Loading...", @"Loading Status");
			[_activityView startAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions]; 
			_arrowImage.hidden = YES;
			[CATransaction commit];
			
			break;
		default:
			break;
	}
	
	_state = aState;
}

#pragma mark -
#pragma mark Subviews

- (void)updateSubviews
{
    _lastUpdatedLabel.hidden = (_lastUpdatedLabel.text.length == 0) ? YES : NO;

    if ([_delegate respondsToSelector:@selector(egoRefreshTableHeaderShouldShowLastUpdated:)] &&
        ![_delegate egoRefreshTableHeaderShouldShowLastUpdated:self]) {
        _lastUpdatedLabel.hidden = YES;
    }
    
    CGRect statusLabelFrame = CGRectMake(0.0f, self.frame.size.height - 48.0f,
                                         self.frame.size.width, 20.0f);
    NSTextAlignment statusLabelTextAlignment = NSTextAlignmentCenter;
    if (_lastUpdatedLabel.hidden) {
        statusLabelTextAlignment = NSTextAlignmentLeft;
        statusLabelFrame = CGRectMake(_activityView.frame.origin.x + _activityView.frame.size.width + 10,
                                      _activityView.frame.origin.y,
                                      _statusLabel.frame.size.width,
                                      _statusLabel.frame.size.height);
    }
    _statusLabel.frame = statusLabelFrame;
    _statusLabel.textAlignment = statusLabelTextAlignment;
}


#pragma mark -
#pragma mark ScrollView Methods

- (void)egoRefreshScrollView:(UIScrollView *)scrollView ForState:(EGOPullRefreshState)state
{
    [self setState:state];
    UIEdgeInsets contentInset = self.originalInset;
    switch (state) {
        case EGOOPullRefreshLoading:
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.2];
            contentInset.top += 60;
            scrollView.contentInset = contentInset;
            scrollView.scrollIndicatorInsets = self.originalInset;
            [UIView commitAnimations];
            break;
        case EGOOPullRefreshNormal:
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.3];
            scrollView.contentInset = contentInset;
            scrollView.scrollIndicatorInsets = self.originalInset;
            [UIView commitAnimations];
            break;
        default:
            break;
    }
}

- (void)egoRefreshScrollViewDidScroll:(UIScrollView *)scrollView {	
	
	if (_state == EGOOPullRefreshLoading) {
		
		CGFloat offset = MAX(scrollView.contentOffset.y * -1, 0);
		offset = MIN(offset, 60);
        UIEdgeInsets contentInset = self.originalInset;
        contentInset.top += offset;
		scrollView.contentInset = contentInset;
        scrollView.scrollIndicatorInsets = self.originalInset;
		
	} else if (scrollView.isDragging) {
		
		BOOL _loading = NO;
		if ([_delegate respondsToSelector:@selector(egoRefreshTableHeaderDataSourceIsLoading:)]) {
			_loading = [_delegate egoRefreshTableHeaderDataSourceIsLoading:self];
		}
		
		if (_state == EGOOPullRefreshPulling && scrollView.contentOffset.y > -65.0f && scrollView.contentOffset.y < 0.0f && !_loading) {
			[self setState:EGOOPullRefreshNormal];
		} else if (_state == EGOOPullRefreshNormal && scrollView.contentOffset.y < -65.0f && !_loading) {
			[self setState:EGOOPullRefreshPulling];
		}
		
		if (scrollView.contentInset.top != 0) {
			scrollView.contentInset = self.originalInset;
            scrollView.scrollIndicatorInsets = self.originalInset;
		}
		
	}
	
}

- (void)egoRefreshScrollViewDidEndDragging:(UIScrollView *)scrollView {
	
	BOOL _loading = NO;
	if ([_delegate respondsToSelector:@selector(egoRefreshTableHeaderDataSourceIsLoading:)]) {
		_loading = [_delegate egoRefreshTableHeaderDataSourceIsLoading:self];
	}
	
	if (scrollView.contentOffset.y <= - 65.0f && !_loading) {
		
		if ([_delegate respondsToSelector:@selector(egoRefreshTableHeaderDidTriggerRefresh:)]) {
			[_delegate egoRefreshTableHeaderDidTriggerRefresh:self];
		}
		
		[self setState:EGOOPullRefreshLoading];
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
        UIEdgeInsets contentInset = self.originalInset;
        contentInset.top += 60;
		scrollView.contentInset = contentInset;
        scrollView.scrollIndicatorInsets = self.originalInset;
		[UIView commitAnimations];
		
	}
	
}

- (void)egoRefreshScrollViewDataSourceDidFinishedLoading:(UIScrollView *)scrollView {	
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.3];
    scrollView.contentInset = self.originalInset;
    scrollView.scrollIndicatorInsets = self.originalInset;
	[UIView commitAnimations];
	
	[self setState:EGOOPullRefreshNormal];

}


#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	
	_delegate=nil;
	_activityView = nil;
	_statusLabel = nil;
	_arrowImage = nil;
	_lastUpdatedLabel = nil;
    [super dealloc];
}


@end
