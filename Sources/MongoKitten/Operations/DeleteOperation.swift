import BSON
import Async

public struct Delete: Command, Operation {
    public struct Single: Encodable {
        public var q: Query
        public var limit: RemoveLimit
        public var collation: Collation?
        
        public init(matching query: Query, limit: RemoveLimit = .one) {
            self.q = query
            self.limit = limit
        }
        
        public func execute(on connection: DatabaseConnection, collection: Collection) throws -> Future<Int> {
            let deletes = Delete([self], from: collection)
            
            return try deletes.execute(on: connection)
        }
    }
    
    var targetCollection: MongoCollection {
        return delete
    }
    
    public let delete: Collection
    public var deletes: [Single]
    public var ordered: Bool?
    public var writeConcern: WriteConcern?
    public var bypassDocumentValidation: Bool?
    
    static var writing = true
    static var emitsCursor = false
    
    public init(_ deletes: [Single], from collection: Collection) {
        self.delete = collection
        self.deletes = Array(deletes)
        
        self.writeConcern = collection.default.writeConcern
    }
    
    @discardableResult
    public func execute(on connection: DatabaseConnection) throws -> Future<Int> {
        return try connection.execute(self, expecting: Reply.Delete.self) { reply, _ in
            guard let n = reply.n, reply.ok == 1 else {
                throw reply
            }
            
            return n
        }
    }
}

extension Reply {
    public struct Delete: Codable, Error {
        public var n: Int?
        public var ok: Int
        public var writeErrors: [Errors.Write]?
        public var writeConcernError: [Errors.WriteConcern]?
    }
}

