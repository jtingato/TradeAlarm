//
//  AppLifecycleManager.swift
//  CgmKit
//
//  Created by Daniel Flynn on 11/12/20.
//  Copyright © 2020 Dexcom. All rights reserved.
//

import Foundation
import Combine
import UIKit

/**
 The subset of application lifecycle events to which a CGM application might care to respond.
 Case names mirror the event names reported to an AppDelegate or published via NotificationCenter.
 */
@frozen
enum AppLifecycleEvent {
    /// A passthrough for UIApplication.ApplicationDidBecomeActive
    case applicationDidBecomeActive

    /// A passthrough for UIApplication.ApplicationWillEnterForeground
    case applicationWillEnterForeground

    /// A passthrough for UIApplication.ApplicationWillResignActive
    case applicationWillResignActive

    /// A passthrough for UIApplication.ApplicationDidEnterBackground
    case applicationDidEnterBackground

    /// A passthrough for UIApplication.ApplicationWillTerminate
    case applicationWillTerminate

    /// Published when a CBCentralManager moves an app from suspended to running in the background.
    case applicationWillRestoreFromBluetooth
}

/// A test-friendly substitute for UIApplication.shared.applicationState that can also be accessed on a background thread.
@frozen
enum AppForegroundStatus {
    /// The app is in the foreground
    case foreground

    /// The app is in the foreground but is inactive
    case foregroundInactive

    /// The app is in the background
    case background
}

/**
 This protocol provides a Combine publisher version of application life cycle notifications and centralizes background task management.
 */
protocol AppLifecycleManagerProtocol: Injectable {
    /// Provides a simplified method for subscribing to lifecycle notifications.
    var appLifecycleEvent: AnyPublisher<AppLifecycleEvent, Never> { get }
}

/**
 Monitors a subset of application lifecycle events and reduces them to a simple Combine publisher.
 */
final class AppLifecycleManager: InjectableContainer, AppLifecycleManagerProtocol {
    /// Stores the notification observers.
    private var observers = [AnyObject]()
    
    
    /// Provides a simplified method for subscribing to lifecycle notifications.
    @PassThroughPublisher var appLifecycleEventSubject: PassThroughPublisher<AppLifecycleEvent, AppLifecycleManagerProtocol>
    
    
    /// Provides a simplified method for subscribing to lifecycle notifications.
    var appLifecycleEvent: AnyPublisher<AppLifecycleEvent, Never> {
        $appLifecycleEventSubject
    }
    
    func sendAppLifecycleEvent(_ appLifecycleEvent: AppLifecycleEvent) {
        appLifecycleEventSubject.send(appLifecycleEvent)
    }
    
    /// Keeps track of the current foregrounded state of the application.
    var appForegroundStatus: AppForegroundStatus = .background
    
    override init() {
        super.init()
        observers.append(NotificationCenter.default.addObserver(
            forName: Notification.ApplicationDidBecomeActive,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            
            self.appForegroundStatus = .foreground
            self.appLifecycleEventSubject.send(.applicationDidBecomeActive)
        })
        
        observers.append(NotificationCenter.default.addObserver(
            forName: Notification.ApplicationWillEnterForeground,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            
            self.appLifecycleEventSubject.send(.applicationWillEnterForeground)
        })
        
        observers.append(NotificationCenter.default.addObserver(
            forName: Notification.ApplicationWillResignActive,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            
            self.appForegroundStatus = .foregroundInactive
            self.appLifecycleEventSubject.send(.applicationWillResignActive)
        })
        
        observers.append(NotificationCenter.default.addObserver(
            forName: Notification.ApplicationDidEnterBackground,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            
            self.appForegroundStatus = .background
            self.appLifecycleEventSubject.send(.applicationDidEnterBackground)
        })
        
        observers.append(NotificationCenter.default.addObserver(
            forName: Notification.ApplicationWillTerminate,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            
            self.appLifecycleEventSubject.send(.applicationWillTerminate)
        })
    }
}

    

// MARK: - Utility Extensions
extension AppLifecycleManager {
    private struct Notification {
        #if os(iOS)
        static let ApplicationDidBecomeActive = UIApplication.didBecomeActiveNotification
        static let ApplicationWillEnterForeground = UIApplication.willEnterForegroundNotification
        static let ApplicationWillResignActive = UIApplication.willResignActiveNotification
        static let ApplicationDidEnterBackground = UIApplication.didEnterBackgroundNotification
        static let ApplicationWillTerminate = UIApplication.willTerminateNotification
        #elseif os(watchOS)
        static let ApplicationDidBecomeActive = WKApplication.didBecomeActiveNotification
        static let ApplicationWillEnterForeground = WKApplication.willEnterForegroundNotification
        static let ApplicationWillResignActive = WKApplication.willResignActiveNotification
        static let ApplicationDidEnterBackground = WKApplication.willResignActiveNotification
        #endif
    }
}

extension AppForegroundStatus {
    #if os(iOS)
    init(_ state: UIApplication.State) {
        switch state {
        case .active:
            self = .foreground
        case .inactive:
            self = .foregroundInactive
        case .background:
            self = .background
        default:
            self = .background
        }
    }
    #elseif os(watchOS)
    init(_ state: WKApplicationState) {
        switch state {
        case .active:
            self = .foreground
        case .inactive:
            self = .foregroundInactive
        case .background:
            self = .background
        default:
            self = .background
        }
    }
    #endif
}
