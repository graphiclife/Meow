import Foundation

fileprivate let currentObjectContextKey = "Meow.currentContext"
internal var context: Meow.Context { return Meow.Context.current }

extension Meow {
    public class Context {
        public init() {}
        
        public static func reset() {
            Context.current = Context()
        }
        
        public static var current: Context {
            get {
                if let context = Thread.current.threadDictionary[currentObjectContextKey] as? Context {
                    return context
                }
                
                let context = Context()
                Context.current = context
                
                return context
            }
            
            set {
                Thread.current.threadDictionary[currentObjectContextKey] = newValue
            }
        }
        
        /// The amount of objects to keep strong references to
        public var strongReferenceAmount = 0
        
        private var strongReferences = [_Model]()
        
        /// The internal storage that's used to hold metadata and references to objects
        internal private(set) var storage = [ObjectId: (instance: Weak<AnyObject>, instantiation: Date)](minimumCapacity: 10)
        
        /// A set of entity's ObjectIds that are invalidated because they were removed
        private var invalidatedObjectIds = Set<ObjectId>()
        
        /// Instantiates a model from a Document unless the model is already in-memory
        public func instantiateIfNeeded<M : _Model>(type: M.Type, document: Document) throws -> M {
            guard let id = ObjectId(document["_id"]) else {
                throw Error.missingOrInvalidValue(key: "_id", expected: ObjectId.self, got: document["_id"])
            }
            
            let existingInstance: M? = storage[id]?.instance.value as? M
            
            // Return the existing instance from the pool if possible
            if let existingInstance = existingInstance {
                return existingInstance
            }
            
            // Decode the instance
            let decoder = M.decoder
            let instance = try decoder.decode(M.self, from: document)
            
            self.pool(instance)
            
            return instance
        }
        
        /// Stores an entity in the object pool
        public func pool<M: _Model>(_ instance: M) {
            let current = storage[instance._id]?.instance.value
            
            // remove old strong reference
            if let current = current, let index = self.strongReferences.index(where: { $0 === current }) {
                self.strongReferences.remove(at: index)
            }
            
            // keep a strong reference
            if self.strongReferenceAmount > 0 {
                self.strongReferences.insert(instance, at: 0)
            }
            
            // clean up strong references
            if self.strongReferences.count > self.strongReferenceAmount {
                self.strongReferences.removeLast(self.strongReferences.count - self.strongReferenceAmount)
            }
            
            if let current = current {
                assert(current === instance, "two model instances with the same _id is invalid")
                return
            }
            
            // Only pool it if the instance is not invalidated
            if !invalidatedObjectIds.contains(instance._id) {
                storage[instance._id] = (instance: Weak(instance), instantiation: Date())
            }
        }
        
        public func getPooledInstance<M: _Model>(withIdentifier id: ObjectId) -> M? {
            return storage[id]?.instance.value as? M
        }
        
        /// Invalidates the given ObjectId. Called when removing an object
        internal func invalidate(_ id: ObjectId) {
            // remove the instance from the pool
            self.storage[id] = nil
            self.invalidatedObjectIds.insert(id)
        }
        
        /// Returns if `instance` is currently in the pool
        public func isPooled<M: Model>(_ instance: M) -> Bool {
            return storage[instance._id] != nil
        }
        
        /// The amount of pooled objects
        public var count: Int {
            self.clean()
            return storage.count
        }
        
        /// Removes deallocated entries from the pool
        @discardableResult
        public func clean() -> Int {
            var cleanedCount = 0
            
            for (id, val) in storage {
                if val.instance.value == nil {
                    storage[id] = nil
                    cleanedCount += 1
                }
            }
            
            return cleanedCount
        }
    }
}

