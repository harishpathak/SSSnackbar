//
//  SSSnackBar.m
//  SSSnackBar Example
//
//  Created by Sam Stone on 04/07/2015.
//  Copyright (c) 2015 Sam Stone. All rights reserved.
//

#import "SSSnackbar.h"
//#import "SSSeparatorView.h"

static SSSnackbar *currentlyVisibleSnackbar = nil;

@interface SSSnackbar ()
@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIButton *actionButton;
@property (strong, nonatomic) UIView *separator;
@property (strong, nonatomic) NSTimer *dismissalTimer;

@property (strong, nonatomic) NSArray *hiddenVerticalLayoutConstraints;
@property (strong, nonatomic) NSArray *visibleVerticalLayoutConstraints;
@property (strong, nonatomic) NSArray *horizontalLayoutConstraints;
@end

@implementation SSSnackbar

- (instancetype)initWithMessage:(NSString *)message
                     actionText:(NSString *)actionText
                       duration:(NSTimeInterval)duration
                    actionBlock:(void (^)(SSSnackbar *sender))actionBlock
                 dismissalBlock:(void (^)(SSSnackbar *sender))dismissalBlock {
    if (self = [super initWithFrame:CGRectMake(0, 0, 0, 0)]) {
        _actionBlock = actionBlock;
        _dismissalBlock = dismissalBlock;
        _duration = duration;
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _messageLabel.text = message;
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _messageLabel.font = [UIFont systemFontOfSize:14.0];
        _messageLabel.textColor = [UIColor whiteColor];
        [_messageLabel sizeToFit];
        
        _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_actionButton setTitle:actionText forState:UIControlStateNormal];
        _actionButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_actionButton addTarget:self
                          action:@selector(executeAction:)
                forControlEvents:UIControlEventTouchUpInside];
        [_actionButton sizeToFit];
        _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        _separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _separator.backgroundColor = [UIColor colorWithWhite:0.99 alpha:.1];
        _separator.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:_messageLabel];
        [self addSubview:_actionButton];
        [self addSubview:_separator];
        
        self.backgroundColor = [UIColor clearColor];
        
        
    }
    
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    [[UIColor colorWithWhite:0.1 alpha:0.9] setFill];
    UIBezierPath *clippath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:3];
    [clippath fill];
    CGContextRestoreGState(ctx);
}

- (void)show {
    
    UIView *superview = [UIApplication sharedApplication].delegate.window.rootViewController.view;
    BOOL shouldReplaceExistingSnackbar = currentlyVisibleSnackbar != nil;
    
    if (shouldReplaceExistingSnackbar) {
        [currentlyVisibleSnackbar invalidateTimer];
        [currentlyVisibleSnackbar _dismissCallingDismissalBlock:YES animated:NO];
    }
    
    [superview addSubview:self];
    [superview addConstraints:self.horizontalLayoutConstraints];
    [superview addConstraints:shouldReplaceExistingSnackbar ? self.visibleVerticalLayoutConstraints : self.hiddenVerticalLayoutConstraints];
    [superview layoutIfNeeded];
    [self setupContentLayout];
    
    if (!shouldReplaceExistingSnackbar) {
        [superview removeConstraints:self.hiddenVerticalLayoutConstraints];
        [superview addConstraints:self.visibleVerticalLayoutConstraints];
        
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [superview layoutIfNeeded];
                         }
                         completion:nil];
    }
    self.dismissalTimer = [NSTimer scheduledTimerWithTimeInterval:self.duration
                                                           target:self
                                                         selector:@selector(dismissalTimer)
                                                         userInfo:nil
                                                          repeats:NO];
    currentlyVisibleSnackbar = self;
}

- (void)replaceExistingSnackbar {
    UIView *superview = [UIApplication sharedApplication].delegate.window.rootViewController.view;
    [currentlyVisibleSnackbar invalidateTimer];
    [currentlyVisibleSnackbar removeFromSuperview];
    [superview addSubview:self];
    [superview addConstraints:self.horizontalLayoutConstraints];
    [superview addConstraints:self.visibleVerticalLayoutConstraints];
    [superview layoutIfNeeded];
    [self setupContentLayout];
}

- (void)timeoutForDismissal:(NSTimer *)sender {
    [self invalidateTimer];
    [self _dismissCallingDismissalBlock:YES animated:YES];
}
- (void)_dismissCallingDismissalBlock:(BOOL)callDismissalBlock animated:(BOOL)animated {
    [self.superview removeConstraints:self.visibleVerticalLayoutConstraints];
    [self.superview addConstraints:self.hiddenVerticalLayoutConstraints];
    currentlyVisibleSnackbar = nil;
    
    if (!animated) {
        if (callDismissalBlock)
            [self executeDismissalBlock];
        [self removeFromSuperview];
    } else {
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.superview layoutIfNeeded];
                         }
                         completion:^(BOOL finished) {
                             if (callDismissalBlock)
                                 [self executeDismissalBlock];
                             [self removeFromSuperview];
                         }];
    }
}

- (void)dismiss {
    [self invalidateTimer];
    [self _dismissCallingDismissalBlock:YES animated:YES];
}

- (IBAction)executeAction:(id)sender {
    [self invalidateTimer];
    if (self.shouldShowActivityIndictatorDuringAction) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        indicator.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:indicator];
        [self addConstraint:
         [NSLayoutConstraint constraintWithItem:indicator
                                      attribute:NSLayoutAttributeCenterX
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.actionButton
                                      attribute:NSLayoutAttributeCenterX
                                     multiplier:1
                                       constant:0]];
        [self addConstraint:
         [NSLayoutConstraint constraintWithItem:indicator
                                      attribute:NSLayoutAttributeCenterY
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self
                                      attribute:NSLayoutAttributeCenterY
                                     multiplier:1
                                       constant:0]];
        
        [self.actionButton setHidden:YES];
        [indicator startAnimating];
    }
    
    [self executeActionBlock];
    [self _dismissCallingDismissalBlock:NO animated:YES];

}

- (void)executeDismissalBlock {
    if (self.dismissalBlock)
        self.dismissalBlock(self);
}

- (void)executeActionBlock {
    if (self.actionBlock)
        self.actionBlock(self);
}

- (NSArray *)hiddenVerticalLayoutConstraints {
    if (!_hiddenVerticalLayoutConstraints) {
    
        _hiddenVerticalLayoutConstraints =
        [NSLayoutConstraint constraintsWithVisualFormat:@"V:[self(44)]-(-50)-|"
                                                options:0
                                                metrics:nil
                                                  views:NSDictionaryOfVariableBindings(self)];
    }
    
    return _hiddenVerticalLayoutConstraints;
}

- (NSArray *)visibleVerticalLayoutConstraints {
    if (!_visibleVerticalLayoutConstraints) {
        
        _visibleVerticalLayoutConstraints =
        [NSLayoutConstraint constraintsWithVisualFormat:@"V:[self(44)]-(5)-|"
                                                options:0
                                                metrics:nil
                                                  views:NSDictionaryOfVariableBindings(self)];
    }
    
    return _visibleVerticalLayoutConstraints;
}

- (NSArray *)horizontalLayoutConstraints {
    if (!_horizontalLayoutConstraints) {
        
        _horizontalLayoutConstraints =
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[self]-(5)-|"
                                                options:0
                                                metrics:nil
                                                  views:NSDictionaryOfVariableBindings(self)];
    }
    
    return _horizontalLayoutConstraints;
}

- (void)invalidateTimer {
    [self.dismissalTimer invalidate];
    self.dismissalTimer = nil;
}

- (void)setupContentLayout {
    NSMutableArray *constraints = [NSMutableArray new];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"|-8-[_messageLabel]-(>=8)-[_separator(1)]-8-[_actionButton]-8-|"
                                             options:NSLayoutFormatAlignAllCenterY
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(_messageLabel, _actionButton, _separator)]];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_separator]-0-|"
                                             options:0
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(_separator)]];
    
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_messageLabel
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1
                                                         constant:0]];
    
    [self addConstraints:constraints];
    [self layoutIfNeeded];
}

@end