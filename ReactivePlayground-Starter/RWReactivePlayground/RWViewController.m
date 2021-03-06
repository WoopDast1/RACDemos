//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveObjC.h>

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.signInService = [RWDummySignInService new];
    
    RACSignal *isUserNameTextValid = [self.usernameTextField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return @(value.length > 3);
    }];
    RAC(self.usernameTextField, backgroundColor) = [isUserNameTextValid map:^id _Nullable(NSNumber *  _Nullable value) {
        return value.boolValue ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    RACSignal *isPasswordTextValid = [self.passwordTextField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return @(value.length > 3);
    }];
    RAC(self.passwordTextField, backgroundColor) = [isPasswordTextValid map:^id _Nullable(NSNumber *  _Nullable value) {
        return value.boolValue ? [UIColor clearColor] :  [UIColor yellowColor];
    }];
    
    @weakify(self);
    RACSignal *isSignInBtnEnableSig = [RACSignal combineLatest:@[isUserNameTextValid, isPasswordTextValid] reduce:^(NSNumber *va4User, NSNumber *va4Pass){
        return @(va4User.boolValue && va4Pass.boolValue);
    }];
//    [isSignInBtnEnableSig subscribeNext:^(NSNumber *  _Nullable x) {
//        @strongify(self);
//        self.signInButton.enabled = x.boolValue;
//    }];
    
//    [[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
//      doNext:^(__kindof UIControl * _Nullable x) {
//        @strongify(self);
//        self.signInButton.enabled = NO;
//    }]
//     subscribeNext:^(__kindof UIControl * _Nullable x) {
//        [[self signInServiceSignal] subscribeNext:^(NSNumber *  _Nullable x) {
//            @strongify(self);
//            self.signInButton.enabled = YES;
//            self.signInFailureText.hidden = [x boolValue];
//            if ([x boolValue]) {
//                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
//            }
//        }];
//    }];
    //转换信号，用flattenMap，代码结构更简洁！！！效果同上。用map只是转换，会导致signal ouf signal问题，导致被订阅对象容易搞成转换前的信号。
    //    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
    //       doNext:^(__kindof UIControl * _Nullable x) {
    //     @strongify(self);
    //        self.signInButton.enabled = NO;
    //    }]
    //
    //      flattenMap:^__kindof RACSignal * _Nullable(__kindof UIControl * _Nullable value) {
    //     @strongify(self);
    //        return  [self signInServiceSignal];
    //    }]
    //     subscribeNext:^(NSNumber *  _Nullable x) {
    //     @strongify(self);
    //        self.signInButton.enabled = YES;
    //        self.signInFailureText.hidden = [x boolValue];
    //        if ([x boolValue]) {
    //            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
    //        }
    //    }];
    
    self.signInButton.rac_command = [[RACCommand alloc] initWithEnabled:isSignInBtnEnableSig signalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        @strongify(self);
        return [self signInServiceSignal];
    }];
    
    [[self.signInButton.rac_command.executionSignals switchToLatest] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        self.signInButton.enabled = YES;
        self.signInFailureText.hidden = [x boolValue];
        if ([x boolValue]) {
            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
        }
    }];
    
    // initially hide the failure message
    self.signInFailureText.hidden = YES;
}


- (RACSignal *)signInServiceSignal{
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
                                      complete:^(BOOL success) {
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

@end
