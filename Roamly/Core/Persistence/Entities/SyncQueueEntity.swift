import Foundation
import SwiftData

@Model
public final class SyncQueueEntity {
    @Attribute(.unique) public var id: UUID
    public var entityType: String
    public var payloadData: Data
    public var retryCount: Int
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        entityType: String,
        payloadData: Data,
        retryCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.entityType = entityType
        self.payloadData = payloadData
        self.retryCount = retryCount
        self.createdAt = createdAt
    }
}
