//
//  STFTPRemoveRequest.h
//  STFTPNetwork
//
//  Created by Suta on 2017/4/14.
//  Copyright © 2017年 Suta. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STFTPRemoveRequest : NSObject

typedef void(^STFTPConnectHandler)(BOOL success);
typedef void(^STFTPQuerySuccessHandler)(NSArray *results);
typedef void(^STFTPFailHandler)(NSInteger errorCode);
typedef void(^STFTPCreateSuccessHandler)(void);
typedef STFTPCreateSuccessHandler STFTPRemoveSuccessHandler;
typedef void(^STFTPProgressHandler)(unsigned long long bytesCompleted, unsigned long long bytesTotal);
typedef void(^STFTPDownloadSuccessHandler)(NSData *data);
typedef STFTPCreateSuccessHandler STFTPUploadSuccessHandler;
+ (instancetype)remove:(NSString *)urlString successHandler:(STFTPRemoveSuccessHandler)successHandler failHandler:(STFTPFailHandler)failHandler;

@end
