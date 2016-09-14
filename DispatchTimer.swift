//
//  DispatchTimer.swift
//  AmbientUPNP
//
//  Created by Taras Vozniuk on 7/11/15.
//  Copyright (c) 2015 ambientlight. All rights reserved.
//

import Foundation

public class DispatchTimer: Equatable {
    
    public enum Status {
        case NotStarted
        case Active
        case Paused
        case Done
        case Invalidated
    }
    
    private var _timerSource:dispatch_source_t
    private var _isInvalidating:Bool = false
    //either startDate or lastFire or lastResume date
    private var _lastActiveDateº:NSDate?
    private var _elapsedAccumulatedTime: Double = Double(0)
    
    
    //MARK: PROPERTIES
    
    public private(set) var remainingFireCount:UInt
    public private(set) var status:DispatchTimer.Status = .NotStarted
    public private(set) var startDateº:NSDate?
    
    public let queue:dispatch_queue_t
    public let isFinite:Bool
    public let fireCount:UInt
    public let interval:UInt
    public let invocationBlock:(timer:DispatchTimer) -> Void
    
    public var completionHandlerº:((timer:DispatchTimer) -> Void)?
    public var userInfoº:Any?
    
    public var valid:Bool { return (self.status != .Done || self.status != .Invalidated) }
    public var started:Bool { return (self.status != .NotStarted) }
    public var startAbsoluteTimeº:Double? { return (startDateº != nil) ? self.startDateº!.timeIntervalSince1970 : nil }

    
    
    //all parameters are in milliseconds
    private func _setupTimerSource(timeInterval:UInt, startOffset:UInt, leeway: UInt) {
        
        dispatch_source_set_timer(_timerSource, dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(startOffset) * NSEC_PER_MSEC)), UInt64(timeInterval) * NSEC_PER_MSEC, UInt64(leeway) * NSEC_PER_MSEC)
        dispatch_source_set_event_handler(_timerSource) {
            
            self._elapsedAccumulatedTime = 0
            self._lastActiveDateº = NSDate()
            
            self.invocationBlock(timer: self)
            if(self.isFinite){
                
                self.remainingFireCount -= 1
                if(self.remainingFireCount == 0){
                    dispatch_source_cancel(self._timerSource)
                }
            }
        }
        
        dispatch_source_set_cancel_handler(_timerSource){
            if(self._isInvalidating){
                self.status = .Invalidated
                self._isInvalidating = false
            } else {
                self.status = .Done
            }
            
            self.completionHandlerº?(timer: self)
        }
    }
    
    //MARK:
    
    public init(milliseconds:UInt, startOffset:Int, tolerance:UInt, queue: dispatch_queue_t, isFinite:Bool, fireCount:UInt, userInfoº:Any?, completionHandlerº:((timer:DispatchTimer) -> Void)?,invocationBlock: (timer:DispatchTimer) -> Void) {
        
        self.queue = queue
        
        self.userInfoº = userInfoº
        self.isFinite = isFinite
        self.fireCount = fireCount;
        self.remainingFireCount = self.fireCount
        
        self.userInfoº = userInfoº
        self.completionHandlerº = completionHandlerº
        self.invocationBlock = invocationBlock
        
        self.interval = milliseconds
        _timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
        
        
        let offset:Int = ( (startOffset < 0) && (abs(startOffset) > Int(self.interval)) ) ? -Int(self.interval) : startOffset
        _setupTimerSource(self.interval, startOffset: UInt( Int(self.interval) + offset), leeway: tolerance)
    }
    
    
    public class func timerWithTimeInterval(milliseconds  milliseconds: UInt, queue: dispatch_queue_t, repeats: Bool, invocationBlock: (timer:DispatchTimer) -> Void) -> DispatchTimer {
        
        
        let timer = DispatchTimer(milliseconds: milliseconds, startOffset: 0, tolerance: 0, queue: queue, isFinite: !repeats, fireCount: (repeats) ? 0 : 1, userInfoº: nil, completionHandlerº:nil, invocationBlock: invocationBlock)
        return timer
    }
    
    public class func timerWithTimeInterval(milliseconds  milliseconds: UInt, queue: dispatch_queue_t, fireCount: UInt, invocationBlock: (timer:DispatchTimer) -> Void) -> DispatchTimer {
        
        let timer = DispatchTimer(milliseconds: milliseconds, startOffset: 0, tolerance: 0, queue: queue, isFinite: true, fireCount: fireCount, userInfoº: nil, completionHandlerº:nil, invocationBlock: invocationBlock)
        return timer
    }
    
    
    
    
    public class func scheduledTimerWithTimeInterval(milliseconds milliseconds: UInt, queue: dispatch_queue_t, repeats: Bool, invocationBlock: (timer:DispatchTimer) -> Void) -> DispatchTimer {
        
        let timer = DispatchTimer(milliseconds: milliseconds, startOffset: 0, tolerance: 0, queue: queue, isFinite: !repeats, fireCount: (repeats) ? 0 : 1, userInfoº: nil, completionHandlerº:nil, invocationBlock: invocationBlock)
        timer.start()
        return timer
    }
    
    public class func scheduledTimerWithTimeInterval(milliseconds milliseconds: UInt, queue: dispatch_queue_t, fireCount: UInt, invocationBlock: (timer:DispatchTimer) -> Void) -> DispatchTimer {
        
        let timer = DispatchTimer(milliseconds: milliseconds, startOffset: 0, tolerance: 0, queue: queue, isFinite: true, fireCount: fireCount, userInfoº: nil, completionHandlerº:nil, invocationBlock: invocationBlock)
        timer.start()
        return timer
    }
    
    public class func scheduledTimerWithTimeInterval(milliseconds milliseconds:UInt, startOffset:Int, tolerance:UInt, queue: dispatch_queue_t, isFinite:Bool, fireCount:UInt, userInfoº:Any?, completionHandlerº:((timer:DispatchTimer) -> Void)?, invocationBlock: (timer:DispatchTimer) -> Void) -> DispatchTimer {
        
        let timer = DispatchTimer(milliseconds: milliseconds, startOffset: startOffset, tolerance: tolerance, queue: queue, isFinite: isFinite, fireCount: fireCount, userInfoº: userInfoº, completionHandlerº:completionHandlerº, invocationBlock: invocationBlock)
        timer.start()
        return timer
    }
    
    //MARK: METHODS
    
    public func start(){
        
        if (!self.started){
            dispatch_resume(_timerSource)
            
            self.startDateº = NSDate()
            _lastActiveDateº = self.startDateº
            self.status = .Active
        }
    }
    
    public func pause(){
        
        if (self.status == .Active){
            
            dispatch_source_set_cancel_handler(_timerSource){ }
            dispatch_source_cancel(_timerSource)
            self.status = .Paused
            
            let pauseDate = NSDate()
            
            _elapsedAccumulatedTime += (pauseDate.timeIntervalSince1970 - _lastActiveDateº!.timeIntervalSince1970) * 1000
            
            //print("%ld milliseconds elapsed", UInt(_elapsedAccumulatedTime))
        }
    }
    
    public func resume(){
        
        if (self.status == .Paused){
            let startOffset: UInt = self.interval < UInt(_elapsedAccumulatedTime) ? 0 : self.interval - UInt(_elapsedAccumulatedTime)
            //print("%ld milliseconds left till fire", startOffset)
            
            _timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
            _setupTimerSource(self.interval, startOffset: startOffset, leeway: 0)
            dispatch_resume(_timerSource)
            
            _lastActiveDateº = NSDate()
            self.status = .Active
        }
    }
    
    public func invalidate(handlerº:((timer:DispatchTimer)-> Void)? = nil){
        
        _isInvalidating = true;
        
        // reassigning completionHandler if has been passed(non-nil)
        if let handler = completionHandlerº {
            self.completionHandlerº = handler
        }
        
        dispatch_source_cancel(_timerSource)
    }
}

//MARK: Equatable
public func ==(lhs: DispatchTimer, rhs: DispatchTimer) -> Bool {
    return (lhs._timerSource === rhs._timerSource)
}
