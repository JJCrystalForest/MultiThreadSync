//
//  ViewController.m
//  MultiThreadSync
//
//  Created by r_瑞 on 2019/6/11.
//  Copyright © 2019 yangfurui. All rights reserved.
//

#import "ViewController.h"
#import <pthread.h>
#import <libkern/OSAtomic.h>
#import <os/lock.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //    [self useOSSpinlock];
    
    //    [self useOS_Unfair_Lock];
    
    //    [self usePthread_mutex_normal];
    
    //    [self usePthread_mutex_recursive];
    
    //    [self semaphoreTest1];
    
    //    [self semaphoreTest2];
    
    //    [self semaphoreTest3];
    
    //    [self useDispatch_queue_serial];
    
    //    [self userOperationQueue];
    
    //    [self useNSLock];
    
    //    [self useNSRecursiveLock];
    
    //    [self usePthreadCond];
    
    //    [self useNSCondition];
    
    //    [self useNSConditionLock];
    
    [self useSynchronized];
    
}

- (void)dealloc {
    // 销毁锁
    pthread_mutex_destroy(&pNormalLock);
    // 销毁递归锁
    pthread_mutex_destroy(&pRecursiveLock);
}

#pragma mark - OSSpinLock
- (void)useOSSpinlock {
    
    __block OSSpinLock oslock = OS_SPINLOCK_INIT;
    
    OSSpinLockLock(&oslock);
    [self doSomeThingForFlag:1 finish:^{
        OSSpinLockUnlock(&oslock);
    }];
    
    OSSpinLockLock(&oslock);
    [self doSomeThingForFlag:2 finish:^{
        OSSpinLockUnlock(&oslock);
    }];
    
    OSSpinLockLock(&oslock);
    [self doSomeThingForFlag:3 finish:^{
        OSSpinLockUnlock(&oslock);
    }];
    
    OSSpinLockLock(&oslock);
    [self doSomeThingForFlag:4 finish:^{
        OSSpinLockUnlock(&oslock);
    }];
    
}

#pragma mark - os_unfair_lock
os_unfair_lock unfairLock;
- (void)useOS_Unfair_Lock {
    // 初始化锁
    unfairLock = OS_UNFAIR_LOCK_INIT;
    
    NSThread *thread1 = [[NSThread alloc] initWithTarget:self selector:@selector(request1) object:nil];
    [thread1 start];
    
    NSThread *thread2 = [[NSThread alloc] initWithTarget:self selector:@selector(request2) object:nil];
    [thread2 start];
}

- (void)request1 {
    // 加锁
    os_unfair_lock_lock(&unfairLock);
    NSLog(@"do:1");
    sleep(2+arc4random_uniform(4));
    NSLog(@"finish:1");
    // 解锁
    os_unfair_lock_unlock(&unfairLock);
}

- (void)request2 {
    // 加锁
    os_unfair_lock_lock(&unfairLock);
    NSLog(@"do:2");
    sleep(2+arc4random_uniform(4));
    NSLog(@"finish:2");
    // 解锁
    os_unfair_lock_unlock(&unfairLock);
}

#pragma mark - pthread_mutex_normal
pthread_mutex_t pNormalLock;
- (void)usePthread_mutex_normal {
    
    // 初始化锁的属性
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);
    
    // 初始化锁
    pthread_mutex_init(&pNormalLock, &attr);
    
    // 销毁 attr
    pthread_mutexattr_destroy(&attr);
    
    pthread_mutex_lock(&pNormalLock);
    [self doSomeThingForFlag:1 finish:^{
        pthread_mutex_unlock(&pNormalLock);
    }];
    
    pthread_mutex_lock(&pNormalLock);
    [self doSomeThingForFlag:2 finish:^{
        pthread_mutex_unlock(&pNormalLock);
    }];
    
    pthread_mutex_lock(&pNormalLock);
    [self doSomeThingForFlag:3 finish:^{
        pthread_mutex_unlock(&pNormalLock);
    }];
    
    pthread_mutex_lock(&pNormalLock);
    [self doSomeThingForFlag:4 finish:^{
        pthread_mutex_unlock(&pNormalLock);
    }];
    
}

#pragma mark - pthread_mutex_recursive
pthread_mutex_t pRecursiveLock;
- (void)usePthread_mutex_recursive {
    // 初始化锁属性
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    
    // 初始化锁
    pthread_mutex_init(&pRecursiveLock, &attr);
    
    // 销毁attr
    pthread_mutexattr_destroy(&attr);
    
    [self thread1];
    
}

- (void)thread1 {
    pthread_mutex_lock(&pRecursiveLock);
    static int count = 0;
    count ++;
    if (count < 10) {
        NSLog(@"do:%d",count);
        [self thread1];
    }
    pthread_mutex_unlock(&pRecursiveLock);
    NSLog(@"finish:%d",count);
}

#pragma mark - semaphores
/**
 保持线程同步，将异步操作转换为同步操作
 */
- (void)semaphoreTest1 {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block int i = 0;
    dispatch_async(queue, ^{
        i = 100;
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"i = %d",i);
}

/**
 为线程加锁
 */
- (void)semaphoreTest2 {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [self doSomeThingForFlag:1 finish:^{
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [self doSomeThingForFlag:2 finish:^{
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [self doSomeThingForFlag:3 finish:^{
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [self doSomeThingForFlag:4 finish:^{
        dispatch_semaphore_signal(semaphore);
    }];
    
}

/**
 限制线程最大并发数
 */
- (void)semaphoreTest3 {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(3);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    for (int i = 0; i < 100; i++) {
        dispatch_async(queue, ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            NSLog(@"running");
            sleep(1);
            NSLog(@"completed...................");
            dispatch_semaphore_signal(semaphore);
        });
    }
}

#pragma mark - dispatch_queue
- (void)useDispatch_queue_serial {
    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    
    for (int i = 0; i < 100; i++) {
        dispatch_async(queue, ^{
            dispatch_suspend(queue);
            [self doSomeThingForFlag:i finish:^{
                dispatch_resume(queue);
            }];
        });
    }
}

#pragma mark - NSOperationQueue
- (void)userOperationQueue {
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];
    
    __weak typeof(self) weakSekf = self;
    
    NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^{
        [queue setSuspended:YES];
        [weakSekf doSomeThingForFlag:1 finish:^{
            [queue setSuspended:NO];
        }];
    }];
    
    NSBlockOperation *operation2 = [NSBlockOperation blockOperationWithBlock:^{
        [queue setSuspended:YES];
        [weakSekf doSomeThingForFlag:2 finish:^{
            [queue setSuspended:NO];
        }];
    }];
    
    NSBlockOperation *operation3 = [NSBlockOperation blockOperationWithBlock:^{
        [queue setSuspended:YES];
        [weakSekf doSomeThingForFlag:3 finish:^{
            [queue setSuspended:NO];
        }];
    }];
    
    NSBlockOperation *operation4 = [NSBlockOperation blockOperationWithBlock:^{
        [queue setSuspended:YES];
        [weakSekf doSomeThingForFlag:4 finish:^{
            [queue setSuspended:NO];
        }];
    }];
    
    [operation4 addDependency:operation3];
    [operation3 addDependency:operation2];
    [operation2 addDependency:operation1];
    
    [queue addOperation:operation1];
    [queue addOperation:operation2];
    [queue addOperation:operation3];
    [queue addOperation:operation4];
    
}

#pragma mark - NSLock
//NSLock *nsLock;
- (void)useNSLock {
    NSLock *nsLock = [[NSLock alloc] init];
    
    [nsLock lock];
    [self doSomeThingForFlag:1 finish:^{
        [nsLock unlock];
    }];
    
    [nsLock lock];
    [self doSomeThingForFlag:2 finish:^{
        [nsLock unlock];
    }];
    
    [nsLock lock];
    [self doSomeThingForFlag:3 finish:^{
        [nsLock unlock];
    }];
    
    [nsLock lock];
    [self doSomeThingForFlag:4 finish:^{
        [nsLock unlock];
    }];
}

#pragma mark - NSRecursiveLock
NSRecursiveLock *recursiveLock;
- (void)useNSRecursiveLock {
    recursiveLock = [[NSRecursiveLock alloc] init];
    [self thread2];
}

- (void)thread2 {
    [recursiveLock lock];
    static int count = 0;
    count ++;
    if (count < 10) {
        NSLog(@"do:%d",count);
        [self thread2];
    }
    [recursiveLock unlock];
    NSLog(@"finish:%d",count);
}

#pragma mark - pthread_cond_t
pthread_mutex_t pMutex;
pthread_cond_t pCond;
NSData *data;
int count = 1;
- (void)usePthreadCond {
    //    // 初始化锁属性
    pthread_mutexattr_t mutexAttr;
    pthread_mutexattr_init(&mutexAttr);
    pthread_mutexattr_settype(&mutexAttr, PTHREAD_MUTEX_NORMAL);
    
    // 初始化条件变量属性
    pthread_condattr_t condAttr;
    pthread_condattr_init(&condAttr);
    
    // 初始化条件变量
    pthread_cond_init(&pCond, &condAttr);
    // 初始化锁
    pthread_mutex_init(&pMutex, &mutexAttr);
    
    // 销毁 attr
    pthread_mutexattr_destroy(&mutexAttr);
    pthread_condattr_destroy(&condAttr);
    
    data = nil;
    [self producter];  // 保证模型能走动，先执行一次生产者的操作
    
    for (int i = 0; i < 10; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self consumer];
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self producter];
        });
    }
    
}

- (void)consumer {  // 消费者
    pthread_mutex_lock(&pMutex);
    while (data == nil) {
        pthread_cond_wait(&pCond, &pMutex);  // 等待数据
    }
    
    // 处理数据
    NSLog(@"data is finish");
    data = nil;
    
    pthread_mutex_unlock(&pMutex);
}

- (void)producter {  // 生产者
    pthread_mutex_lock(&pMutex);
    // 生产数据
    data = [[NSData alloc] init];
    NSLog(@"preparing data");
    sleep(1);
    
    pthread_cond_signal(&pCond);  // 发出信号，数据已完成
    pthread_mutex_unlock(&pMutex);
}

#pragma mark - NSCondition
NSCondition *cond;
NSData *ns_data;
- (void)useNSCondition {
    
    cond = [[NSCondition alloc] init];
    ns_data = nil;
    
    [self ns_producter];
    
    for (int i = 0; i < 10; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self ns_consumer];
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self ns_producter];
        });
    }
    
}

- (void)ns_consumer {
    [cond lock];
    while (ns_data == nil) {
        [cond wait];  // 等待数据
    }
    // 处理数据
    NSLog(@"data is finish");
    [cond unlock];
}

- (void)ns_producter {
    [cond lock];
    // 生产数据
    ns_data = [[NSData alloc] init];
    NSLog(@"preparing data");
    sleep(1);
    
    [cond signal];  // 发出信号，数据已完成
    [cond unlock];
}

#pragma mark - NSConditionLock
- (void)useNSConditionLock {
    NSConditionLock *condLock = [[NSConditionLock alloc] initWithCondition:1];
    
    [condLock lockWhenCondition:1];
    [self doSomeThingForFlag:1 finish:^{
        [condLock unlockWithCondition:2];
    }];
    
    [condLock lockWhenCondition:2];
    [self doSomeThingForFlag:2 finish:^{
        [condLock unlockWithCondition:3];
    }];
    
    [condLock lockWhenCondition:3];
    [self doSomeThingForFlag:3 finish:^{
        [condLock unlockWithCondition:4];
    }];
    
    [condLock lockWhenCondition:4];
    [self doSomeThingForFlag:4 finish:^{
        [condLock unlock];
    }];
    
}

#pragma mark - @synchronized
- (void)useSynchronized {
    [self thread5];
}

- (void)thread5 {
    static int count = 0;
    @synchronized (self) {
        count ++;
        if (count < 10) {
            NSLog(@"%d",count);
            [self thread5];
        }
    }
    NSLog(@"finish:%d",count);
}

#pragma mark - async 方法
- (void)doSomeThingForFlag:(int)flag finish:(void(^)(void))finish {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"do:%d",flag);
        sleep(2+arc4random_uniform(4));
        NSLog(@"finish:%d",flag);
        if (finish) finish();
    });
}

@end
