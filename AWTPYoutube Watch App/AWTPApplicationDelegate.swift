//
//  AWTPExtensionDelegate.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 30/03/2023.
//

import WatchKit
import WatchConnectivity
import CocoaLumberjackSwift

class AWTPApplicationDelegate: NSObject, WKApplicationDelegate {
    
    private lazy var sessionDelegator: AWTPWCSessionDelegator = {
        return AWTPWCSessionDelegator()
    }()
    
    private var activationStateObservation: NSKeyValueObservation?
    private var hasContentPendingObservation: NSKeyValueObservation?
    private var wcBackgroundTasks = [WKWatchConnectivityRefreshBackgroundTask]()
    
    override init() {
        super.init()
        assert(WCSession.isSupported(), "This sample requires a platform supporting Watch Connectivity!")
        
        activationStateObservation = WCSession.default.observe(\.activationState) { _, _ in
            DispatchQueue.main.async {
                self.completeBackgroundTasks()
            }
        }
        hasContentPendingObservation = WCSession.default.observe(\.hasContentPending) { _, _ in
            DispatchQueue.main.async {
                self.completeBackgroundTasks()
            }
        }
        
        //Setup WCSession
        WCSession.default.delegate = sessionDelegator
        WCSession.default.activate()
        
        //Setup log
#if DEBUG
        DDLog.add(DDOSLogger.sharedInstance)
#else
        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
#endif
    }
    
    
    func completeBackgroundTasks() {
        guard !wcBackgroundTasks.isEmpty else { return }
        
        guard WCSession.default.activationState == .activated,
              WCSession.default.hasContentPending == false else { return }
        
        wcBackgroundTasks.forEach { $0.setTaskCompletedWithSnapshot(false) }
        
        iLog("\(wcBackgroundTasks) was completed!")
        
        let date = Date(timeIntervalSinceNow: 1)
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: date, userInfo: nil) { error in
            if let error = error {
                print("scheduleSnapshotRefresh error: \(error)!")
            }
        }
        
        wcBackgroundTasks.removeAll()
    }
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let wcTask = task as? WKWatchConnectivityRefreshBackgroundTask {
                wcBackgroundTasks.append(wcTask)
                iLog("\(wcTask.description) was appended!")
            } else {
                task.setTaskCompletedWithSnapshot(false)
                iLog("\(task.description) was completed!")
            }
        }
        
        completeBackgroundTasks()
    }
}
