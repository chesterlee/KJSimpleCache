//
//  AnyObject.m
//  KJSimpleCache
//
//  Created by chester lee on 7.8.14.
//

#import "AnyObject.h"

@implementation AnyObject

-(id)copyWithZone:(NSZone *)zone
{
    AnyObject *goods = [[AnyObject allocWithZone:zone] init];
    
    goods.objectID    = self.objectID;
    goods.objectName  = self.objectName;
    goods.objectParam = self.objectParam;
    
    return goods;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.objectID forKey:@"objectID"];
    [aCoder encodeObject:self.objectName forKey:@"objectName"];
    [aCoder encodeObject:self.objectParam forKey:@"objectParam"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.objectID = [aDecoder decodeObjectForKey:@"objectID"];
        self.objectName = [aDecoder decodeObjectForKey:@"objectName"];
        self.objectParam = [aDecoder decodeObjectForKey:@"objectParam"];
    }
    return self;
}

@end

