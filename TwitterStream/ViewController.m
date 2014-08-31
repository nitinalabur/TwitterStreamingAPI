//
//  ViewController.m
//  TwitterStream
//
//  Created by Nitin Alabur on 8/29/14.
//  Copyright (c) 2014 Nitin Alabur. All rights reserved.
//

#import "ViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "STTwitter.h"

#warning Update your consumer key and secret here
#define kConsumerKey @""
#define kConsumerSecret @""

@interface ViewController ()<UIAlertViewDelegate>
@property (nonatomic, strong) NSURLConnection *twitterConnection;
@property (nonatomic, strong) NSMutableArray *tweets;
@end

@implementation ViewController
            
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tweets = [NSMutableArray array];
    [self requestAuthHeader];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Twitter OAuth and Streaming methods
-(void)requestAuthHeader{
    STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil
                                                              consumerKey:kConsumerKey
                                                           consumerSecret:kConsumerSecret];

    __weak typeof(self) weakSelf = self;
    [twitter postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {[weakSelf receivedAuthenticationHeader:authenticationHeader];}
                               errorBlock:^(NSError *error) {NSLog(@"request auth header error: %@", error.debugDescription);}];
}
-(void)receivedAuthenticationHeader:(NSString *)authenticationHeader{
    __block STTwitterAPI *twitterAPIOS = [STTwitterAPI twitterAPIOSWithFirstAccount];
    __weak typeof(self) weakSelf = self;
    
    [twitterAPIOS verifyCredentialsWithSuccessBlock:^(NSString *username) {
        
        [twitterAPIOS postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader
                                                            successBlock:^(NSString *oAuthToken,
                                                                           NSString *oAuthTokenSecret,
                                                                           NSString *userID,
                                                                           NSString *screenName) {
                                                                [weakSelf oAuthSuccessWithOAuthToken:oAuthToken
                                                                                oAuthTokenSecret:oAuthTokenSecret
                                                                                          userID:userID
                                                                                      screenName:screenName];
                                                            }
                                                              errorBlock:^(NSError *error) {
                                                                NSLog(@"reverse auth access token error: %@", error.debugDescription);
                                                            }];}
     
                                         errorBlock:^(NSError *error) {
                                             NSLog(@"verify credentials error: %@", error.debugDescription);
                                             
                                             if (error.code == 0) {
                                                 UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"No Accounts"
                                                                                                    message:@"Go to Settings app --> Twitter and sign in to at least one account"
                                                                                                   delegate:self
                                                                                          cancelButtonTitle:@"OK"
                                                                                          otherButtonTitles:nil];
                                                 [theAlert show];
                                             }
                                         }];
}
-(void)oAuthSuccessWithOAuthToken:(NSString *)oAuthToken
                 oAuthTokenSecret:(NSString *)oAuthTokenSecret
                           userID:(NSString *)userID
                       screenName:(NSString *)screenName{
    
    STTwitterAPI *twitterAPI = [STTwitterAPI twitterAPIWithOAuthConsumerKey:kConsumerKey
                                                              consumerSecret:kConsumerSecret
                                                                  oauthToken:oAuthToken
                                                            oauthTokenSecret:oAuthTokenSecret];
    
    [twitterAPI getStatusesSampleDelimited:nil
                              stallWarnings:nil
                              progressBlock:^(id response) {
                                  if ([response isKindOfClass:[NSDictionary class]] == NO) {
                                      NSLog(@"Invalid tweet (class %@): %@", [response class], response);
                                      return;
                                  }
                                  
                                  
                                  if (![response objectForKey:@"text"]) {
                                      return;
                                  }
                                  BOOL isRetweeted =[[response objectForKey:@"retweeted"] boolValue];
                                  
                                  
                                  if (isRetweeted) {
                                      [self.tweets addObject:response];
                                      printf("-----------------------------------------------------------------\n");
                                      printf("-- user: @%s\n", [[response valueForKeyPath:@"user.screen_name"] cStringUsingEncoding:NSUTF8StringEncoding]);
                                      printf("-- text: %s\n", [[response objectForKey:@"text"] cStringUsingEncoding:NSUTF8StringEncoding]);
                                  }else{
                                      NSLog(@".");
                                  }
                                  
                              } stallWarningBlock:nil
                                 errorBlock:^(NSError *error) {
                                     NSLog(@"get status sample error: %@", error.debugDescription);
                                 }];
}

#pragma mark UIAlertView delegate methods
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    exit(0);
}
@end
