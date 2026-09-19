import Foundation
import Network
import SwiftData
import Observation

@Observable
public final class SyncEngine {
    public static let shared = SyncEngine()
    
    public private(set) var isOnline: Bool = true
    public private(set) var isSyncing: Bool = false
    public private(set) var lastSyncDate: Date? = nil
    public private(set) var pendingSyncCount: Int = 0
    public private(set) var lastSyncError: String? = nil
    public private(set) var successfulSyncCount: Int = 0
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.roamly.syncMonitorQueue")
    private let urlSession: URLSession
    
    public init(session: URLSession = .shared) {
        self.urlSession = session
        startNetworkMonitoring()
    }
    
    // MARK: - Network Reachability
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let wasOffline = !self.isOnline
                self.isOnline = (path.status == .satisfied)
                
                // If we regained connectivity and have a context, we can notify or auto-trigger
                if wasOffline && self.isOnline {
                    self.lastSyncError = nil
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    // MARK: - Enqueue Operations
    
    @MainActor
    public func enqueue(visit: VisitEntity, in modelContext: ModelContext) {
        guard SupabaseConfigService.shared.isCloudSyncEnabled else { return }
        
        let payload = SupabaseVisitPayload.from(
            visit: visit,
            userId: SupabaseConfigService.shared.userId
        )
        
        guard let data = try? JSONEncoder().encode(payload) else {
            return
        }
        
        // Remove existing queue item for the same visit if present to avoid duplication
        let targetId = visit.id
        let existingDescriptor = FetchDescriptor<SyncQueueEntity>(
            predicate: #Predicate { $0.id == targetId }
        )
        if let duplicates = try? modelContext.fetch(existingDescriptor) {
            for dup in duplicates {
                modelContext.delete(dup)
            }
        }
        
        let queueItem = SyncQueueEntity(
            id: visit.id,
            entityType: "VISIT",
            payloadData: data
        )
        modelContext.insert(queueItem)
        try? modelContext.save()
        
        updatePendingCount(in: modelContext)
        
        // Asynchronously process queue if online
        Task {
            await self.processQueue(modelContext: modelContext)
        }
    }
    
    @MainActor
    public func enqueueAllUnsynced(visits: [VisitEntity], in modelContext: ModelContext) {
        for visit in visits where !visit.isSynced {
            let payload = SupabaseVisitPayload.from(
                visit: visit,
                userId: SupabaseConfigService.shared.userId
            )
            if let data = try? JSONEncoder().encode(payload) {
                let queueItem = SyncQueueEntity(
                    id: visit.id,
                    entityType: "VISIT",
                    payloadData: data
                )
                modelContext.insert(queueItem)
            }
        }
        try? modelContext.save()
        updatePendingCount(in: modelContext)
        
        Task {
            await self.processQueue(modelContext: modelContext)
        }
    }
    
    @MainActor
    public func resyncAllVisits(from visits: [VisitEntity], modelContext: ModelContext) {
        for visit in visits {
            let payload = SupabaseVisitPayload.from(
                visit: visit,
                userId: SupabaseConfigService.shared.userId
            )
            if let data = try? JSONEncoder().encode(payload) {
                let queueItem = SyncQueueEntity(
                    id: visit.id,
                    entityType: "VISIT",
                    payloadData: data
                )
                modelContext.insert(queueItem)
            }
        }
        try? modelContext.save()
        updatePendingCount(in: modelContext)
        
        Task {
            await self.processQueue(modelContext: modelContext)
        }
    }
    
    @MainActor
    public func updatePendingCount(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<SyncQueueEntity>()
        if let count = try? modelContext.fetchCount(descriptor) {
            self.pendingSyncCount = count
        }
    }
    
    @MainActor
    public func clearQueue(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<SyncQueueEntity>()
        if let items = try? modelContext.fetch(descriptor) {
            for item in items {
                modelContext.delete(item)
            }
            try? modelContext.save()
            self.pendingSyncCount = 0
            self.lastSyncError = nil
        }
    }
    
    // MARK: - Queue Processor
    
    public func processQueue(modelContext: ModelContext) async {
        await MainActor.run {
            guard !self.isSyncing else { return }
            guard self.isOnline else {
                self.lastSyncError = "Device is offline. Queued for auto-delivery."
                return
            }
            guard SupabaseConfigService.shared.isCloudSyncEnabled else {
                self.lastSyncError = "Cloud Sync is disabled in settings."
                return
            }
            self.isSyncing = true
            self.lastSyncError = nil
        }
        
        let descriptor = FetchDescriptor<SyncQueueEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        do {
            let pendingItems = try await MainActor.run {
                try modelContext.fetch(descriptor)
            }
            
            await MainActor.run {
                self.pendingSyncCount = pendingItems.count
            }
            
            guard !pendingItems.isEmpty else {
                await MainActor.run {
                    self.isSyncing = false
                }
                return
            }
            
            let config = SupabaseConfigService.shared
            
            for item in pendingItems {
                let success: Bool
                
                if config.isMockMode {
                    // Sandbox / Demo mode: Simulate realistic cloud latency & acknowledge
                    try? await Task.sleep(nanoseconds: 120_000_000)
                    success = true
                } else {
                    // Production Supabase PostGIS endpoint
                    success = await sendToSupabase(item: item, config: config)
                }
                
                if success {
                    await MainActor.run {
                        // Mark corresponding VisitEntity as synced
                        let itemId = item.id
                        let visitDescriptor = FetchDescriptor<VisitEntity>(
                            predicate: #Predicate { $0.id == itemId }
                        )
                        if let matchedVisit = try? modelContext.fetch(visitDescriptor).first {
                            matchedVisit.isSynced = true
                        }
                        
                        // Delete successfully processed item from the queue
                        modelContext.delete(item)
                        try? modelContext.save()
                        
                        self.successfulSyncCount += 1
                        self.pendingSyncCount = max(0, self.pendingSyncCount - 1)
                    }
                } else {
                    // On failure, increment retry count and apply exponential backoff
                    await MainActor.run {
                        item.retryCount += 1
                        try? modelContext.save()
                        self.lastSyncError = "Sync paused: Server unreachable or credentials invalid (Retry #\(item.retryCount))."
                    }
                    // Break batch processing on persistent network/server error to prevent spamming
                    break
                }
            }
            
            await MainActor.run {
                self.lastSyncDate = Date()
                self.isSyncing = false
                self.updatePendingCount(in: modelContext)
            }
        } catch {
            await MainActor.run {
                self.lastSyncError = error.localizedDescription
                self.isSyncing = false
            }
        }
    }
    
    // MARK: - HTTP Dispatcher to Supabase PostGIS
    
    private func sendToSupabase(item: SyncQueueEntity, config: SupabaseConfigService) async -> Bool {
        guard let baseUrl = URL(string: config.projectUrl) else {
            return false
        }
        
        let endpoint = baseUrl.appendingPathComponent("rest/v1/visits")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        // Idempotent upsert directive: merge on conflict with primary key (id)
        components?.queryItems = [
            URLQueryItem(name: "on_conflict", value: "id")
        ]
        
        guard let finalUrl = components?.url else { return false }
        
        var request = URLRequest(url: finalUrl)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = item.payloadData
        request.timeoutInterval = 15.0
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            if let http = response as? HTTPURLResponse {
                // 200 OK, 201 Created, 204 No Content are idempotent success codes in PostgREST
                if (200...299).contains(http.statusCode) {
                    return true
                }
            }
            return false
        } catch {
            return false
        }
    }
}
