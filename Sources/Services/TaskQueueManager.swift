import ComposableArchitecture
import Foundation

// MARK: - Task Queue Manager

/// Manages autonomous task execution with queue management, prioritization, and parallel execution
public actor TaskQueueManager {
    // MARK: - Properties

    private var taskQueue: [QueuedTask] = []
    private var executingTasks: [UUID: QueuedTask] = [:]
    private let maxConcurrentTasks: Int
    private let taskExecutor: TaskExecutor

    public init(maxConcurrentTasks: Int = 3, taskExecutor: TaskExecutor) {
        self.maxConcurrentTasks = maxConcurrentTasks
        self.taskExecutor = taskExecutor
    }

    // MARK: - Public Methods

    /// Adds a task to the queue with automatic prioritization
    public func enqueue(_ task: AgentTask, priority: TaskPriority = .normal, dependencies: [UUID] = []) -> QueuedTask {
        let queuedTask = QueuedTask(
            task: task,
            priority: priority,
            dependencies: Set(dependencies),
            status: .queued,
            progress: 0
        )

        taskQueue.append(queuedTask)
        taskQueue.sort { $0.priority.rawValue > $1.priority.rawValue }

        return queuedTask
    }

    /// Processes the queue and executes available tasks
    public func processQueue() async -> [TaskExecutionResult] {
        var results: [TaskExecutionResult] = []

        // Check for tasks that can be executed
        let availableTasks = getExecutableTasks()

        // Execute tasks up to the concurrent limit
        let tasksToExecute = Array(availableTasks.prefix(maxConcurrentTasks - executingTasks.count))

        for queuedTask in tasksToExecute {
            // Move task from queue to executing
            taskQueue.removeAll { $0.id == queuedTask.id }
            var executingTask = queuedTask
            executingTask.status = .executing
            executingTask.startTime = Date()
            executingTasks[queuedTask.id] = executingTask

            // Execute task asynchronously
            Task {
                let result = await executeTask(executingTask)
                results.append(result)
            }
        }

        return results
    }

    /// Cancels a queued or executing task
    public func cancelTask(_ taskId: UUID) -> Bool {
        // Check if task is in queue
        if let index = taskQueue.firstIndex(where: { $0.id == taskId }) {
            taskQueue.remove(at: index)
            return true
        }

        // Check if task is executing
        if let executingTask = executingTasks[taskId] {
            // Mark as cancelled (actual cancellation handled by executor)
            var cancelledTask = executingTask
            cancelledTask.status = .cancelled
            executingTasks[taskId] = cancelledTask
            return true
        }

        return false
    }

    /// Updates task progress
    public func updateProgress(_ taskId: UUID, progress: Double) {
        if var task = executingTasks[taskId] {
            task.progress = min(max(progress, 0), 1.0)
            executingTasks[taskId] = task
        }
    }

    /// Gets the current queue status
    public func getQueueStatus() -> QueueStatus {
        QueueStatus(
            queuedTasks: taskQueue,
            executingTasks: Array(executingTasks.values),
            totalTasks: taskQueue.count + executingTasks.count,
            completedToday: 0 // This would be tracked separately
        )
    }

    // MARK: - Private Methods

    private func getExecutableTasks() -> [QueuedTask] {
        taskQueue.filter { task in
            // Check if all dependencies are completed
            let dependenciesCompleted = task.dependencies.allSatisfy { depId in
                !taskQueue.contains { $0.id == depId } &&
                    !executingTasks.keys.contains(depId)
            }

            return dependenciesCompleted && task.status == .queued
        }
    }

    private func executeTask(_ queuedTask: QueuedTask) async -> TaskExecutionResult {
        do {
            // Update progress callback
            let progressHandler: @Sendable (Double) -> Void = { progress in
                Task {
                    await self.updateProgress(queuedTask.id, progress: progress)
                }
            }

            // Execute the task
            let result = try await taskExecutor.execute(
                queuedTask.task,
                progressHandler: progressHandler
            )

            // Mark as completed
            executingTasks.removeValue(forKey: queuedTask.id)

            return TaskExecutionResult(
                taskId: queuedTask.id,
                result: .success(result),
                executionTime: Date().timeIntervalSince(queuedTask.startTime ?? Date())
            )

        } catch {
            // Handle failure
            executingTasks.removeValue(forKey: queuedTask.id)

            return TaskExecutionResult(
                taskId: queuedTask.id,
                result: .failure(error),
                executionTime: Date().timeIntervalSince(queuedTask.startTime ?? Date())
            )
        }
    }
}

// MARK: - Supporting Types

public struct QueuedTask: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let task: AgentTask
    public let priority: TaskPriority
    public let dependencies: Set<UUID>
    public var status: TaskStatus
    public var progress: Double
    public var startTime: Date?
    public var completionTime: Date?
    public var retryCount: Int = 0

    public init(
        id: UUID = UUID(),
        task: AgentTask,
        priority: TaskPriority,
        dependencies: Set<UUID> = [],
        status: TaskStatus = .queued,
        progress: Double = 0
    ) {
        self.id = id
        self.task = task
        self.priority = priority
        self.dependencies = dependencies
        self.status = status
        self.progress = progress
    }
}

public enum TaskPriority: Int, Comparable, Sendable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3

    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct TaskError: Error, Equatable, Sendable {
    public let message: String
    public let code: String?

    public init(message: String, code: String? = nil) {
        self.message = message
        self.code = code
    }
}

public enum TaskStatus: Equatable, Sendable {
    case queued
    case executing
    case completed
    case failed(TaskError)
    case cancelled

    public static func == (lhs: TaskStatus, rhs: TaskStatus) -> Bool {
        switch (lhs, rhs) {
        case (.queued, .queued),
             (.executing, .executing),
             (.completed, .completed),
             (.cancelled, .cancelled):
            true
        case let (.failed(lhsError), .failed(rhsError)):
            lhsError == rhsError
        default:
            false
        }
    }
}

public struct TaskExecutionResult: Equatable, Sendable {
    public let taskId: UUID
    public let result: TaskResult
    public let executionTime: TimeInterval
}

public struct QueueStatus: Equatable, Sendable {
    public let queuedTasks: [QueuedTask]
    public let executingTasks: [QueuedTask]
    public let totalTasks: Int
    public let completedToday: Int
}

// MARK: - Task Executor Protocol

public protocol TaskExecutor: Sendable {
    func execute(_ task: AgentTask, progressHandler: @escaping @Sendable (Double) -> Void) async throws -> [String: String]
}

// MARK: - Enhanced Task Queue Feature

public extension AgenticChatFeature {
    struct TaskQueueState: Equatable, Sendable {
        var queueStatus: QueueStatus
        var lastExecutionResults: [TaskExecutionResult] = []

        public init(taskExecutor _: TaskExecutor) {
            queueStatus = QueueStatus(
                queuedTasks: [],
                executingTasks: [],
                totalTasks: 0,
                completedToday: 0
            )
        }

        public static func == (lhs: TaskQueueState, rhs: TaskQueueState) -> Bool {
            lhs.queueStatus == rhs.queueStatus &&
                lhs.lastExecutionResults == rhs.lastExecutionResults
        }
    }

    enum TaskQueueAction {
        case enqueueTask(AgentTask, TaskPriority, [UUID])
        case processQueue
        case cancelTask(UUID)
        case updateTaskProgress(UUID, Double)
        case taskCompleted(TaskExecutionResult)
        case refreshQueueStatus
    }
}

// MARK: - Dependency Key

public struct TaskQueueManagerKey: DependencyKey {
    public nonisolated static let liveValue = TaskQueueManager(
        maxConcurrentTasks: 3,
        taskExecutor: LiveTaskExecutor()
    )
}

public extension DependencyValues {
    var taskQueueManager: TaskQueueManager {
        get { self[TaskQueueManagerKey.self] }
        set { self[TaskQueueManagerKey.self] = newValue }
    }
}

public struct LiveTaskExecutor: TaskExecutor {
    public func execute(_ task: AgentTask, progressHandler: @escaping @Sendable (Double) -> Void) async throws -> [String: String] {
        // Simulate task execution with progress updates
        for i in 1 ... 10 {
            try await Task.sleep(for: .milliseconds(200))
            progressHandler(Double(i) / 10.0)
        }

        // Return mock result based on task type
        switch task.action.type {
        case .gatherMarketResearch:
            return ["vendors": "15", "averagePrice": "50000"]
        case .generateDocuments:
            return ["documents": "SOW,PWS,QASP", "count": "3"]
        case .identifyVendors:
            return ["vendors": "Vendor A,Vendor B,Vendor C", "count": "3"]
        case .scheduleReviews:
            return ["meetings": "3", "nextReview": ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400))]
        case .submitForApproval:
            return ["trackingNumber": "AP-2025-0142", "status": "submitted"]
        case .monitorCompliance:
            return ["complianceScore": "0.95", "issues": "0"]
        }
    }
}
