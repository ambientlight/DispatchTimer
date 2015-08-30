##DispatchTimer
__DispatchTimer__ is a GCD-based NSTimer analogue that you can also __pause__/__resume__ and set a finite number of invocations. 



##Examples
Please take a look at __DispatchTimer.playground__.

####Non-repeating or Infinite timer

```swift
let timerQueue:dispatch_queue_t = dispatch_queue_create("timerQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0))

let singleTimer = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: 1000, queue: timerQueue, repeats: false) { (timer:DispatchTimer) in
    NSLog("singleTimer: Fired")
}
```

####Finite timer(multiple # of invocations)
```swift
let timerQueue:dispatch_queue_t = dispatch_queue_create("timerQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0))

let finiteTimer = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: 1000, queue: timerQueue, fireCount:10){ (timer:DispatchTimer) in
    NSLog("finiteTimer: Fired (remaining:\(timer.remainingFireCount))")
}

sleep(2)
finiteTimer.pause()

sleep(1)
finiteTimer.resume()

sleep(5)
finiteTimer.invalidate()

```

####More examples
In a bit longer factory method you can specify __startOffset__ to let timer start earlier.  
__tolerance__ specifies an allowable leeway for each invocation scheduling.  
(Please note the __tolerance__ of 0 does not guarantee precise sceduling. Usually each invocation will have a small deviation)

```swift
let timerQueue:dispatch_queue_t = dispatch_queue_create("timerQueue", 

let completionHandler = { (timer:DispatchTimer) in NSLog("anotherTimer: Done") }
let anotherTimer = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: 1000, startOffset: -1000, tolerance: 0, queue: timerQueue, isFinite: true, fireCount: 10, userInfoº: nil, completionHandlerº: completionHandler) { (timer:DispatchTimer) in
    NSLog("anotherTimer: Fired (remaining:\(timer.remainingFireCount))")
}
```

Alternatively you can also create a timer and start it later.
Lets take a look at the infinite timer which shows its invocation count

```swift
let infiniteTimer = DispatchTimer.timerWithTimeInterval(milliseconds: 1000, queue: timerQueue, repeats: true) { (timer:DispatchTimer) in
    if var userInfo = timer.userInfoº as? UInt {
        NSLog("infiniteTimer: Invocation #\(userInfo)")
        userInfo++
        timer.userInfoº = userInfo
    }
}

infiniteTimer.userInfoº = UInt(0)
infiniteTimer.start()
```
###Requirement
* Swift 2.0 (Xcode 7+)
* iOS 7+