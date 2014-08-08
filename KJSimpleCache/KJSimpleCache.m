//
//  KJSimpleCache.h
//  Version 0.1
//  Created by chester lee on 7.8.14.
//

#import "KJSimpleCache.h"
#import <CommonCrypto/CommonDigest.h>

#define ArchiveKey @"archiveKey"

@interface KJSimpleCache ()

@property (nonatomic) NSString *diskCachePath;          // disk pach
@property (nonatomic) NSCache *memoryCache;             // memory cache
@property (nonatomic) NSFileManager *fileManager;       // file manager
@property (nonatomic) dispatch_queue_t ioQueue;         // queue for io 
@end

@implementation KJSimpleCache

/**
 *  get share instance
 */
+ (KJSimpleCache *)shareKJSimpleCache
{
    static KJSimpleCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[KJSimpleCache alloc] init];
    });
    return instance;
}

-(instancetype)init
{
    if (self = [super init])
    {
        // cache initialize
        _memoryCache = [[NSCache alloc] init];
        [_memoryCache setCountLimit:KJSCACHE_MEMORY_COST_LIMIT];
        
        // disk path initialize
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [paths[0] stringByAppendingPathComponent:KJDISK_NAME];
        
        // file manager initialize
        _fileManager = [[NSFileManager alloc] init];
        
        if (![_fileManager fileExistsAtPath:_diskCachePath])
        {
            [_fileManager createDirectoryAtPath:_diskCachePath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:NULL];
        }
        
        // queue initialize
        _ioQueue = dispatch_queue_create("KJCache_IO_queue", DISPATCH_QUEUE_SERIAL);
        
#if TARGET_OS_IPHONE
        
        // observer the system message
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanExpirationDisk:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundCleanDisk)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
#endif

    }
    return self;
}


#pragma mark - extern interface

/**
 *  get cached object asynchronously
 *
 *  @param name   unique name
 *  @param fBlock KJQueryCompletedBlock callback function
 */
-(void)cachedObjectByGivenName:(NSString *)name finishBlock:(KJQueryCompletedBlock)fBlock
{
    if (!fBlock || !name || [name isEqualToString:@""])
    {
        return;
    }
    
    // check if object existed in memory
    id<NSCoding> anyObject = [self cachedObjectByGivenNameInMemmory:name];
    
    // if existed, return things in memory
    if (anyObject)
    {
       return fBlock(anyObject,KJSimpleCacheTypeMemory);
    }
    
    // else check object in disk
    dispatch_async(self.ioQueue, ^{
        
        @autoreleasepool {
            
            id<NSCoding> diskCachedObject = nil;
            
            // find object with key
            NSString *fileUniqueName = [self cachedFileNameForKey:name];
            NSString *path = [NSString stringWithFormat:@"%@/%@",_diskCachePath,fileUniqueName];
            
            //if find the thing in disk
            if ([_fileManager fileExistsAtPath:path])
            {
                // cache in memory
                NSMutableData *data = [NSMutableData dataWithContentsOfFile:path];
                NSKeyedUnarchiver *unArchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
                diskCachedObject = [unArchiver decodeObjectForKey:ArchiveKey];
                [self.memoryCache setObject:diskCachedObject forKey:fileUniqueName];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    fBlock(diskCachedObject, KJSimpleCacheTypeDisk);
                });
            }
            else
            {
                fBlock(nil, KJSimpleCacheTypeNothing);
            }
        }
    });
}

/**
 *  get cached object
 */
- (id) cachedObjectByGivenNameInMemmory:(NSString *)name
{
    if (!name || [name isEqualToString:@""])
    {
        return nil;
    }
    
    NSString *fileUniqueName = [self cachedFileNameForKey:name];
    
    // find in memory
    id object = [self.memoryCache objectForKey:fileUniqueName];
    if (object)
    {
        return object;
    }
    else
    {
        return nil;
    }
}

/**
 *  update cached object
 */
- (void)addCacheObject:(id<NSCoding>) anyObject withName:(NSString *)name
{
    if (!anyObject || !name || [name isEqualToString:@""])
    {
        return;
    }
    
    NSString *fileUniqueName = [self cachedFileNameForKey:name];

    // save to memory cache
    [self.memoryCache setObject:anyObject forKey:fileUniqueName];

    dispatch_async(_ioQueue, ^{
        
        // write file to destination path
        NSMutableData *writeData  = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:writeData];
        [archiver encodeObject:anyObject forKey:ArchiveKey];
        [archiver finishEncoding];
        NSString *path = [NSString stringWithFormat:@"%@/%@",_diskCachePath,fileUniqueName];
        [_fileManager createFileAtPath:path contents:writeData attributes:nil];
    });
    
}

/**
 *  clean All Caches in memory and disk
 */
- (void) cleanAllCache
{
    [_memoryCache removeAllObjects];
    NSError *error = nil;
    [_fileManager removeItemAtPath:_diskCachePath error:&error];
}

/**
 *  the cache size in disk in bytes
 */
- (NSUInteger)diskSize
{
    NSUInteger size = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}


#pragma mark - private
#pragma mark - Event Handler
/**
 *  clean memory
 */
- (void)clearMemory
{
    [self.memoryCache removeAllObjects];
}

/**
 *  clean disk when file date is out of the living time
 */
- (void)cleanExpirationDisk:(void (^)(void)) finishBlock;
{
    dispatch_async(self.ioQueue, ^{
        
        NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
        NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
        

        NSDirectoryEnumerator *fEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
        // expiration date
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow: - KJSCACHE_DISK_MAXAGE];
        
        // mark path
        NSMutableArray *fileNeededToDelete = [[NSMutableArray alloc] init];
        
        for (NSURL *fileURL in fEnumerator)
        {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
            
            // Skip directories.
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            
            // Remove files that are older than the expiration date;
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate])
            {
                [fileNeededToDelete addObject:fileURL];
                continue;
            }
        }
        
        for (NSURL *filePath in fileNeededToDelete)
        {
            [_fileManager removeItemAtURL:filePath error:nil];
        }
        
        if (finishBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                finishBlock();
            });
        }
    });
}

/**
 *  when app is in back ground task, it will do clean disk
 */
- (void)backgroundCleanDisk
{
    UIApplication *application = [UIApplication sharedApplication];
    
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Start the long-running task and return immediately.
    [self cleanExpirationDisk:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

#pragma mark - tools function
/**
 *  key string by MD5
 */
- (NSString *)cachedFileNameForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}
@end
