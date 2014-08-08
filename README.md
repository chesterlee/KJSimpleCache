KJSimpleCache
=============

Simple Cache for cache custom object.
You can open KJSimpleCache.xcodeproj to See how to use and which situation you can use this cache helper.    
### Usage
there are three important interface you can use:  

* -cachedObjectByGivenName:finishBlock:   
  **get the cached object asynchronously**
* -addCacheObject:withName:  
  **addCacheObject cached object**  
* -cleanAllCache  
  **clean All Caches both in memory and disk**  
  
### Notice
you can set KJSCACHE_MEMORY_COST_LIMIT, KJSCACHE_DISK_MAXAGE, KJDISK_NAME  to custom your needs.  

BTW, the AnyObject you need to cached should comform the protocol of the NSCoding.

