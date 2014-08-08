//
//  KJSimpleCache.h
//  Version 0.1
//  Created by chester lee on 7.8.14.
//

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2014 chester lee<chester.lee0218@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

#define KJSCACHE_MEMORY_COST_LIMIT (10 * 1024 * 1024)           // Memory cost  (in bytes)
#define KJSCACHE_DISK_MAXAGE       (60 * 60 * 24 * 1)           // one DAY      (in seconds)
#define KJDISK_NAME                @"KJSimpleCacheDEFAULT"      // Cache Default Folder name

typedef NS_ENUM(NSInteger, KJSimpleCacheType)
{
    KJSimpleCacheTypeNothing,      // if didn't find object
    KJSimpleCacheTypeMemory,       // finded in memory
    KJSimpleCacheTypeDisk,         // finded in disk
};

typedef void(^KJQueryCompletedBlock)(id<NSCoding> anyObject, KJSimpleCacheType cacheType);

/**
 *  KJSimpleCache - which divided into two layers: the one is memory cache and the other is the disk
 *  NOTICE:KJSimpleCache is NOT suitable for caching the Huge number(like above a million) 
 *         of object because of the disk cache.
 *
 *  IF the number is huge, I suggest to use database for store the object, but if the single file is so big like a image
 *  Maybe you should use disk cache the single object.
 */
@interface KJSimpleCache : NSObject

/**
 *  instance of KJSimpleCache
 */
+(KJSimpleCache *)shareKJSimpleCache;

/**
 *  get cached object asynchronously
 *
 *  @param name   unique name
 *  @param fBlock KJQueryCompletedBlock callback function
 */
-(void)cachedObjectByGivenName:(NSString *)name finishBlock:(KJQueryCompletedBlock)fBlock;

/**
 *  get cached object synchronously in memory
 *
 *  @param name unique name
 *
 *  @return cached object. return nil if it is not exist.
 */
- (id)cachedObjectByGivenNameInMemmory:(NSString *)name;

/**
 *  addCacheObject cached object
 *
 *  @param object object needed to be cached
 *  @param name   unique name
 */
- (void)addCacheObject:(id<NSCoding>) anyObject withName:(NSString *)name;

/**
 *  clean All Caches both in memory and disk
 */
- (void)cleanAllCache;

/**
 *  the cache size in disk in bytes
 */
- (NSUInteger)diskSize;

@end
