import SystemPackage

extension SocketDescriptor {
    
    /// Manipulates the underlying device parameters of special files.
    @_alwaysEmitIntoClient
    public func inputOutput<T: IOControlID>(
        _ request: T,
        retryOnInterrupt: Bool = true
    ) throws(Errno) {
        try _inputOutput(request, retryOnInterrupt: true).get()
    }
    
    /// Manipulates the underlying device parameters of special files.
    @usableFromInline
    internal func _inputOutput<T: IOControlID>(
        _ request: T,
        retryOnInterrupt: Bool
    ) -> Result<(), Errno> {
        nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            #if os(Windows)
            system_ioctl(CInt(self.rawValue), request.rawValue)
            #else
            system_ioctl(self.rawValue, request.rawValue)
            #endif
        }
    }
    
    /// Manipulates the underlying device parameters of special files.
    @_alwaysEmitIntoClient
    public func inputOutput<T: IOControlInteger>(
        _ request: T,
        retryOnInterrupt: Bool = true
    ) throws(Errno) {
        try _inputOutput(request, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    /// Manipulates the underlying device parameters of special files.
    @usableFromInline
    internal func _inputOutput<T: IOControlInteger>(
        _ request: T,
        retryOnInterrupt: Bool
    ) -> Result<(), Errno> {
        nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            #if os(Windows)
            system_ioctl(CInt(self.rawValue), T.id.rawValue, request.intValue)
            #else
            system_ioctl(self.rawValue, T.id.rawValue, request.intValue)
            #endif
        }
    }
    
    /// Manipulates the underlying device parameters of special files.
    @_alwaysEmitIntoClient
    public func inputOutput<T: IOControlValue>(
        _ request: inout T,
        retryOnInterrupt: Bool = true
    ) throws(Errno) {
        try _inputOutput(&request, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    /// Manipulates the underlying device parameters of special files.
    @usableFromInline
    internal func _inputOutput<T: IOControlValue>(
        _ request: inout T,
        retryOnInterrupt: Bool
    ) -> Result<(), Errno> {
        nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            request.withUnsafeMutablePointer { pointer in
                #if os(Windows)
                system_ioctl(CInt(self.rawValue), T.id.rawValue, pointer)
                #else
                system_ioctl(self.rawValue, T.id.rawValue, pointer)
                #endif
            }
        }
    }
}
