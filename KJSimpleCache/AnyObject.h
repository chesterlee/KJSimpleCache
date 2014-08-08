//
//  AnyObject.h
//  KJSimpleCache
//
//  Created by chester lee on 7.8.14.
//

/*
    Test Object
 */
@interface AnyObject : NSObject<NSCopying,NSCoding>

@property(nonatomic,copy) NSString *objectID;
@property(nonatomic,copy) NSString *objectName;
@property(nonatomic,copy) NSString *objectParam;


@end
