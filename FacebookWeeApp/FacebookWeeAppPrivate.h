// -----------------------------------------------------------------------------
//  FacebookWeeAppPrivate.h
//  
//  Created by Manuel Gebele on 25.06.11.
//  Copyright 2011 Manuel Gebele. All rights reserved.
// -----------------------------------------------------------------------------

@protocol FacebookWeeAppPrivate

- (void)logMethodCallForSelector:(SEL)selector;
- (void)shrinkView;
- (void)expandView;
- (void)setupGui;
- (void)setupInitialValues;
- (void)loadFacebookRequest;
- (void)resizeSubviewsForInterfaceOrientation:
  (int)interfaceOrientation;
- (void)updateHomeButtonPositionForInterfaceOrientation:
  (int)interfaceOrientation;
- (void)setAutoresizingMaskForView:(UIView *)view;
- (CGRect)containerViewFrame;
- (void)exchangeVisibilityButtonImages;
- (void)presentLoadingDidFailedAlert:(NSError *)error;

@end
