// -----------------------------------------------------------------------------
//  FacebookWeeApp.h
//  
//  Created by Manuel Gebele on 25.06.11.
//  Copyright 2011 Manuel Gebele. All rights reserved.
// -----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

#import "FacebookWeeAppPrivate.h"

#import "BBWeeAppController-Protocol.h"

typedef enum
{
    VisibilityContextExpand,
    VisibilityContextShrink
} VisibilityContext;

@interface FacebookWeeApp : NSObject
<
    FacebookWeeAppPrivate,
    UIWebViewDelegate,
    BBWeeAppController
>
{
    UIView      *_widgetView;
    UIView      *_containerView;
    UIWebView   *_facebookWebView;
    UIButton    *_visibilityButton;
    UIButton    *_homeButton;
    
    VisibilityContext _visibilityContext;
    BOOL              _viewWasShrinked;
    
    void *_dylibHandler;
}

+ (id)sharedInstance;

- (UIView *)view;

// Called through the hooker in order to tell us that
// an interface orientation update is coming soon.
- (void)willAnimateRotationToInterfaceOrientation:(int)arg1;

@end
