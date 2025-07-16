//
//  BackgroundSyncHandler.swift
//  AIKO
//
//  Created for background cache synchronization
//

import Foundation
#if canImport(UIKit) && canImport(BackgroundTasks)
import UIKit
import BackgroundTasks
#endif
import os.log

/// Handles background synchronization tasks
@MainActor
final class BackgroundSyncHandler {
    /// Background task identifier
    static let syncTaskIdentifier = "com.aiko.cache.sync"
    
    /// Shared instance
    static let shared = BackgroundSyncHandler()
    
    /// Logger
    private let logger = Logger(subsystem: "com.aiko.cache", category: "BackgroundSync")
    
    /// Private initializer
    private init() {}
    
    /// Register background tasks
    func registerBackgroundTasks() {
        #if canImport(UIKit) && canImport(BackgroundTasks)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.syncTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundSync(task: task as! BGProcessingTask)
        }
        
        logger.info("Background sync task registered")
        #else
        logger.info("Background tasks not available on this platform")
        #endif
    }
    
    /// Schedule background sync
    func scheduleBackgroundSync() {
        #if canImport(UIKit) && canImport(BackgroundTasks)
        let request = BGProcessingTaskRequest(identifier: Self.syncTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        // Schedule for next opportunity
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Background sync scheduled")
        } catch {
            logger.error("Failed to schedule background sync: \(error.localizedDescription)")
        }
        #else
        logger.info("Background sync not available on this platform")
        #endif
    }
    
    #if canImport(UIKit) && canImport(BackgroundTasks)
    /// Handle background sync task
    private func handleBackgroundSync(task: BGProcessingTask) {
        logger.info("Starting background sync")
        
        // Set expiration handler
        task.expirationHandler = {
            self.logger.warning("Background sync task expired")
            // Sync functionality removed - was part of VanillaIce integration
            task.setTaskCompleted(success: false)
        }
        
        // Perform sync
        Task {
            // Sync functionality removed - was part of VanillaIce integration
            // For now, just complete the task successfully
            self.logger.info("Background sync placeholder - actual sync removed with VanillaIce")
            task.setTaskCompleted(success: true)
            
            // Schedule next sync
            self.scheduleBackgroundSync()
        }
    }
    #endif
    
    /// Debug: Trigger sync immediately (for testing)
    func debugTriggerSync() {
        #if DEBUG && canImport(UIKit) && canImport(BackgroundTasks)
        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            requests.forEach { request in
                self.logger.debug("Pending task: \(request.identifier)")
            }
        }
        
        // Cancel existing and schedule immediate
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.syncTaskIdentifier)
        
        let request = BGProcessingTaskRequest(identifier: Self.syncTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = nil // ASAP
        
        do {
            try BGTaskScheduler.shared.submit(request)
            self.logger.debug("Debug sync scheduled for immediate execution")
        } catch {
            self.logger.error("Failed to schedule debug sync: \(error.localizedDescription)")
        }
        #else
        logger.debug("Debug sync not available on this platform")
        #endif
    }
}