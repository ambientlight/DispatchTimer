
import Foundation
import XCPlayground

//: __DispatchTimer__ is a GCD-based NSTimer analogue that you can also __pause()__ / __resume()__ and set the finite number of invocations. 

XCPSetExecutionShouldContinueIndefinitely(true)
let timerQueue:dispatch_queue_t = dispatch_queue_create("timerQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0))

//: Non-repeating or forever repeating timer

let singleTimer = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: 1000, queue: timerQueue, repeats: false) { (timer:DispatchTimer) in
    
    NSLog("singleTimer: Fired")
}

sleep(2)
//: Finite timer with multiple invocations(__fireCount__)

let finiteTimer = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: 1000, queue: timerQueue, fireCount:10){ (timer:DispatchTimer) in
    NSLog("finiteTimer: Fired (remaining:\(timer.remainingFireCount))")
}

sleep(2)
finiteTimer.pause()

sleep(1)
finiteTimer.resume()

sleep(5)
finiteTimer.invalidate()

//: A bit more customizable factory method  
//: You can specify __startOffset__ to let timer start earlier.
//: __tolerance__ specifies an allowable leeway for each invocation scheduling.
//: (Please note the __tolerance__ of 0 does not guarantee precise sceduling. Usually each invocation will have a small deviation)

let completionHandler = { (timer:DispatchTimer) in NSLog("anotherTimer: Done") }
let anotherTimer = DispatchTimer.scheduledTimerWithTimeInterval(milliseconds: 1000, startOffset: -1000, tolerance: 0, queue: timerQueue, isFinite: true, fireCount: 10, userInfoº: nil, completionHandlerº: completionHandler) { (timer:DispatchTimer) in

    NSLog("anotherTimer: Fired (remaining:\(timer.remainingFireCount))")
}


//: Alternatively you can create a timer and start it later.
//: Let's take a look at infinite timer which shows its invocation count
let infiniteTimer = DispatchTimer.timerWithTimeInterval(milliseconds: 1000, queue: timerQueue, repeats: true) { (timer:DispatchTimer) in

    if var userInfo = timer.userInfoº as? UInt {
        NSLog("infiniteTimer: Invocation #\(userInfo)")
        userInfo++
        timer.userInfoº = userInfo
    }
}

infiniteTimer.userInfoº = UInt(0)
infiniteTimer.start()

