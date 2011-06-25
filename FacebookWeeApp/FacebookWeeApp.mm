// -----------------------------------------------------------------------------
//  FacebookWeeApp.mm
//  
//  Created by Manuel Gebele on 25.06.11.
//  Copyright 2011 Manuel Gebele. All rights reserved.
// -----------------------------------------------------------------------------

/*
 * TODO:
 * iPad compatibility
 */

#import "FacebookWeeApp.h"

#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>

#import "dlfcn.h"

#define FACEBOOK_URL \
[NSURL URLWithString:@"http://m.facebook.com"]

#define FACEBOOKWEEAPPHOOKER_DYLIB_PATH \
@"/Library/FacebookWeeAppHooker/FacebookWeeAppHooker.dylib"

#define STRETCHABLE_BACKGROUND_IMAGE \
@"/System/Library/WeeAppPlugins/FacebookWeeApp.bundle/FacebookWeeAppBackground.png"

#define SHRINK_BUTTON_IMAGE \
@"/System/Library/WeeAppPlugins/FacebookWeeApp.bundle/Hide.png"

#define EXPAND_BUTTON_IMAGE \
@"/System/Library/WeeAppPlugins/FacebookWeeApp.bundle/Show.png"

#define HOME_BUTTON_IMAGE \
@"/System/Library/WeeAppPlugins/FacebookWeeApp.bundle/Home.png"

#define LANDSCAPE_WIDTH 476.0f
#define PORTRAIT_WIDTH  316.0f

#define WEEAPP_SECTION_ID @"com.manuelgebele.facebookweeApp"

#define HOME_BUTTON_TAG       1 >> 8

#define RELEASE_SAFELY(__POINTER) { \
 if (__POINTER)                     \
 {                                  \
  [__POINTER release];              \
  __POINTER = nil;                  \
 }                                  \
}

@interface SBBulletinListController /* AvoidCompilerWarnings) */

+(id)sharedInstance;
-(id)_weeAppForSectionID:(id)sectionID;
-(void)_removeWeeAppForSectionID:(id)sectionID;
-(void)_loadSections;

@end

@interface SBWeeApp /* AvoidCompilerWarnings) */

- (NSString *)sectionID;

@end

@implementation FacebookWeeApp

// -----------------------------------------------------------------------------
#pragma mark Dealloc
// -----------------------------------------------------------------------------

- (void)dealloc
{
    [self logMethodCallForSelector:_cmd];
    
    RELEASE_SAFELY(_homeButton);
    RELEASE_SAFELY(_visibilityButton);
    RELEASE_SAFELY(_facebookWebView);
    RELEASE_SAFELY(_containerView);
    RELEASE_SAFELY(_widgetView);
    dlclose(_dylibHandler);
    [super dealloc];
}


// -----------------------------------------------------------------------------
#pragma mark Init
// -----------------------------------------------------------------------------

static FacebookWeeApp *sharedInstance = nil;

- (id)init
{
    [self logMethodCallForSelector:_cmd];
    
    sharedInstance = [super init];
    if (sharedInstance)
    {}
    return sharedInstance;
}


+ (id)sharedInstance
{
    return sharedInstance;
}


// -----------------------------------------------------------------------------
#pragma mark Hooker
// -----------------------------------------------------------------------------

- (void)loadDlyb
{
    [self logMethodCallForSelector:_cmd];
    
    _dylibHandler
    = dlopen([FACEBOOKWEEAPPHOOKER_DYLIB_PATH UTF8String],
             RTLD_LOCAL);
    
    if (!_dylibHandler)
    {
        NSLog(@"%@:%@ - Error hooking Helper: %s",
              dlerror(),
              NSStringFromClass([self class]),
              NSStringFromSelector(_cmd));
	}
}


// -----------------------------------------------------------------------------
#pragma mark Protocol: BBWeeAppController
// -----------------------------------------------------------------------------

- (void)viewWillAppear
{
    [self logMethodCallForSelector:_cmd];
    
    // Prepare the dynamic lib as one
    // of the first steps.
    [self loadDlyb];
}


- (UIView *)view
{
    [self logMethodCallForSelector:_cmd];
    
    BOOL widgetViewWasInitialized
    = (nil != _widgetView);
    if (widgetViewWasInitialized) { goto wasInitialized; }
    
    // Setup all initial values as well
    // as all GUI components.
    [self setupInitialValues];
    [self setupGui];
    
    // Fire the first facebook request.
    [self loadFacebookRequest];
wasInitialized:
    return _widgetView;
}


- (float)viewHeight
{
    [self logMethodCallForSelector:_cmd];
    
    /*
     * Remark:
     * The view's height depends on the
     * current visibility state.  In
     * case the user shrinks the view,
     * we only need a visible area to
     * show the <code>_visibilityButton</code>.
     */
    float viewHeight = 325.0f;
    
    if (_visibilityContext == VisibilityContextShrink)
    {
        [self shrinkView];
        viewHeight = 71.0f;
    }
    else if (_visibilityContext == VisibilityContextExpand)
    {
        if (_viewWasShrinked)
        {
            [self expandView];
        }
    }
    
    return viewHeight;
}


- (id)launchURLForTapLocation:(CGPoint)point
{
    [self logMethodCallForSelector:_cmd];
	
    // Dirty hack to fix the "TouchHandler" bug.
    UIButton *button
    = (UIButton *)
    [[self view].window
     hitTest:
     [[self view].window
      convertPoint:point
      fromView:[self view]]
     withEvent:nil];
    
    SEL selector = @selector(sendActionsForControlEvents:);
    BOOL canHandleSelector = [button respondsToSelector:selector];
    if(canHandleSelector)
    {
        [button sendActionsForControlEvents:
         UIControlEventTouchUpInside];
    }
    return nil;
}


- (void)willAnimateRotationToInterfaceOrientation:(int)arg1
{
    [self logMethodCallForSelector:_cmd];
	
    if (UIInterfaceOrientationIsLandscape(arg1))
    {
        CGRect rect = [self view].frame;
        rect.size.width = LANDSCAPE_WIDTH;
        [self view].frame = rect;
        // Also resize all subviews.
        [self resizeSubviewsForInterfaceOrientation:arg1];
    }
    else
    {
        CGRect rect = [self view].frame;
        rect.size.width = PORTRAIT_WIDTH;
        [self view].frame = rect;
        // Also resize all subviews.
        [self resizeSubviewsForInterfaceOrientation:arg1];
    }
}


// -----------------------------------------------------------------------------
#pragma mark Resizing
// -----------------------------------------------------------------------------

- (void)resizeSubviewsForInterfaceOrientation:
  (int)interfaceOrientation
{
    [self logMethodCallForSelector:_cmd];
    
    NSArray *subviews
    = [[self view] subviews];
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
    {
        for(UIView *subview in subviews)
        {
            CGRect rect = subview.frame;
            rect.size.width = LANDSCAPE_WIDTH;
            subview.frame = rect;
        }
    }
    else
    {
        for(UIView *subview in subviews)
        {
            CGRect rect = subview.frame;
            rect.size.width = PORTRAIT_WIDTH;
            subview.frame = rect;
        }
    }
    
    [self updateHomeButtonPositionForInterfaceOrientation:
     interfaceOrientation];
}


- (void)updateHomeButtonPositionForInterfaceOrientation:
  (int)interfaceOrientation
{
    [self logMethodCallForSelector:_cmd];
    
    NSArray *subviews = [_containerView subviews];
    for(UIView *subview in subviews)
    {
        if (subview.tag == HOME_BUTTON_TAG)
        {
            UIImage *image
            = [UIImage imageWithContentsOfFile:HOME_BUTTON_IMAGE];
            
            CGRect frame =
            CGRectMake(275.0f, 10.0f,
                       image.size.width, image.size.height);
         
            if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
            {
                frame.origin.x = 435.0f;
            }
            
            _homeButton.frame = frame;
        }
    }
}


- (void)shrinkView
{
    [self logMethodCallForSelector:_cmd];
#pragma mark TODO: Add animation
    [_facebookWebView setHidden:YES];
    _viewWasShrinked = YES;
}


- (void)expandView
{
    [self logMethodCallForSelector:_cmd];
#pragma mark TODO: Add animation
    [_facebookWebView setHidden:NO];
    _viewWasShrinked = NO;
}


// -----------------------------------------------------------------------------
#pragma mark Setup
// -----------------------------------------------------------------------------

- (void)setupWidgetView
{
    [self logMethodCallForSelector:_cmd];
    
    CGRect frame
    = (CGRect){(CGPoint){2.0f, .0f},(CGSize){316.0f, 71.0f}};
    
    _widgetView
    = [[UIView alloc] initWithFrame:frame];
    _widgetView.autoresizesSubviews = YES;
    [self setAutoresizingMaskForView:_widgetView];
}


- (void)setupBackgroundImage
{
    [self logMethodCallForSelector:_cmd];
    
    UIImage *image
    = [[UIImage imageWithContentsOfFile:STRETCHABLE_BACKGROUND_IMAGE]
       stretchableImageWithLeftCapWidth:5 topCapHeight:71];
    
    UIImageView *imageView
    = [[UIImageView alloc] initWithImage:image];
    imageView.frame = [self containerViewFrame]; 
    [self setAutoresizingMaskForView:imageView];
    [_containerView addSubview:imageView];
    [imageView release];
}


- (void)setupContainerView
{
    [self logMethodCallForSelector:_cmd];
    
    CGRect frame
    = [self containerViewFrame];
    _containerView
    = [[UIView alloc] initWithFrame:frame];
    [self setupBackgroundImage];
    [_widgetView addSubview:_containerView];
}


- (void)setupFacebookWebView
{
    [self logMethodCallForSelector:_cmd];
    
    CGRect frame
    = (CGRect){(CGPoint){.0f, 71.0f},(CGSize){316.0f, 254.0f}};
    _facebookWebView
    = [[UIWebView alloc] initWithFrame:frame];
    _facebookWebView.delegate = self;
    [_widgetView addSubview:_facebookWebView];
}


- (void)setupVisibilityButton
{
    [self logMethodCallForSelector:_cmd];
    
    _visibilityButton
    = [UIButton buttonWithType:UIButtonTypeCustom];
            
    UIImage *image
    = [UIImage imageWithContentsOfFile:EXPAND_BUTTON_IMAGE];
    
    CGRect frame
    = [self containerViewFrame];
    frame.size = image.size;
    
    _visibilityButton.frame = frame;
    
    _visibilityButton.center = _containerView.center;
        
    [_visibilityButton
     setImage:image
     forState:UIControlStateNormal];
    
    [self setAutoresizingMaskForView:_visibilityButton];
    
    [_visibilityButton
     addTarget:self
     action:@selector(visibilityAction)
     forControlEvents:UIControlEventTouchUpInside];
    
    [_containerView addSubview:_visibilityButton];
}


- (void)setupHomeButton
{
    [self logMethodCallForSelector:_cmd];
    
    _homeButton
    = [UIButton buttonWithType:UIButtonTypeCustom];
    
    _homeButton.tag = HOME_BUTTON_TAG;
    
    UIImage *image
    = [UIImage imageWithContentsOfFile:HOME_BUTTON_IMAGE];
    
    CGRect frame =
    CGRectMake(275.0f, 10.0f,
               image.size.width, image.size.height);
    
    _homeButton.frame = frame;
    
    [_homeButton
     setImage:image
     forState:UIControlStateNormal];
    
    [_homeButton
     addTarget:self
     action:@selector(homeAction)
     forControlEvents:UIControlEventTouchUpInside];
    
    [_containerView addSubview:_homeButton];
}


- (void)setupGui
{
    [self logMethodCallForSelector:_cmd];
    
    [self setupWidgetView];
    [self setupContainerView];
    [self setupVisibilityButton];
    [self setupHomeButton];
    [self setupFacebookWebView];
}


- (void)setupInitialValues
{
    [self logMethodCallForSelector:_cmd];
    
    _visibilityContext = VisibilityContextShrink;
    _viewWasShrinked = NO;
}


// -----------------------------------------------------------------------------
#pragma mark SBBulletinListController
// -----------------------------------------------------------------------------

- (void)triggerContentReload
{
    [self logMethodCallForSelector:_cmd];
    
    Class $SBBulletinListController
    = objc_getClass("SBBulletinListController");
    SBBulletinListController *bulletinListController
    = [$SBBulletinListController sharedInstance];
    
    SBWeeApp *weeApp
    = [bulletinListController _weeAppForSectionID:WEEAPP_SECTION_ID];
    
    [bulletinListController _removeWeeAppForSectionID:[weeApp sectionID]];
    [bulletinListController _loadSections];
}


// -----------------------------------------------------------------------------
#pragma mark Target-Action
// -----------------------------------------------------------------------------

- (void)visibilityAction
{
    [self logMethodCallForSelector:_cmd];
    
    [self triggerContentReload];
    
    if (_visibilityContext == VisibilityContextShrink)
    {
        _visibilityContext = VisibilityContextExpand;
    }
    else if (_visibilityContext == VisibilityContextExpand)
    {
        _visibilityContext = VisibilityContextShrink;
    }
    
    [self exchangeVisibilityButtonImages];
}


- (void)homeAction
{
    [self logMethodCallForSelector:_cmd];
    
    [self loadFacebookRequest];
}


// -----------------------------------------------------------------------------
#pragma mark UIWebViewDelegate
// -----------------------------------------------------------------------------

- (void)webViewDidStartLoad:(UIWebView *)wv
{
    [self logMethodCallForSelector:_cmd];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)wv
{
    [self logMethodCallForSelector:_cmd];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error
{
    [self logMethodCallForSelector:_cmd];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self presentLoadingDidFailedAlert:error];
}


// -----------------------------------------------------------------------------
#pragma mark Miscellaneous
// -----------------------------------------------------------------------------

- (void)setAutoresizingMaskForView:(UIView *)view
{
    [self logMethodCallForSelector:_cmd];

    view.autoresizingMask
    =
    UIViewAutoresizingFlexibleHeight
    |
    UIViewAutoresizingFlexibleWidth
    ;
}


- (CGRect)containerViewFrame
{
    [self logMethodCallForSelector:_cmd];
    
    return
    (CGRect){(CGPoint){.0f, .0f},(CGSize){316.0f, 71.0f}};
}


- (void)loadFacebookRequest
{
    [self logMethodCallForSelector:_cmd];
    
    NSURLRequest *facebookRequest
    = [NSURLRequest requestWithURL:FACEBOOK_URL];
    [_facebookWebView loadRequest:facebookRequest];
}


- (void)exchangeVisibilityButtonImages
{
    [self logMethodCallForSelector:_cmd];
    
    UIImage *image = nil;
    if (_visibilityContext == VisibilityContextShrink)
    {
        image
        = [UIImage imageWithContentsOfFile:EXPAND_BUTTON_IMAGE];
    }
    else if (_visibilityContext == VisibilityContextExpand)
    {
        image
        = [UIImage imageWithContentsOfFile:SHRINK_BUTTON_IMAGE];
    }
    
    [_visibilityButton
     setImage:image
     forState:UIControlStateNormal];
}


- (void)presentLoadingDidFailedAlert:(NSError *)error
{
    [self logMethodCallForSelector:_cmd];

    NSString *title   = @"WeeFacebook";
    NSString *message = error.localizedDescription;
    NSString *buttonTitle = @"OK";
    
    UIAlertView *alertView
    = [[[UIAlertView alloc] init] autorelease];
    
    [alertView setTitle:title];
    [alertView setMessage:message];
    [alertView addButtonWithTitle:buttonTitle];
    
    [alertView show];
}


- (void)logMethodCallForSelector:(SEL)selector
{
    NSLog(@"%@:%@ - %@",
          NSStringFromClass([self class]),
          NSStringFromSelector(_cmd),
          NSStringFromSelector(selector));
}


@end

