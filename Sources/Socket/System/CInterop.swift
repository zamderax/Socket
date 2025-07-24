import SystemPackage

#if canImport(Darwin)
import Darwin
#elseif os(Windows)
import CSocket
import ucrt
import WinSDK
#elseif canImport(Glibc)
import CSocket
import Glibc
#elseif canImport(Musl)
import CSocket
import Musl
#elseif canImport(WASILibc)
import CSocket
import WASILibc
#elseif canImport(Bionic)
import CSocket
import Bionic
#else
#error("Unsupported Platform")
#endif

/// A namespace for C and platform types
public extension CInterop {
    
    /// The platform file descriptor set.
    typealias FileDescriptorSet = fd_set
  
    typealias PollFileDescriptor = pollfd
  
    #if os(Windows)
    typealias FileDescriptorCount = ULONG
    #else
    typealias FileDescriptorCount = nfds_t
    #endif
  
    typealias FileEvent = Int16
    
    #if os(Windows)
    /// The platform socket descriptor.
    typealias SocketDescriptor = SOCKET
    #else
    /// The platform socket descriptor, which is the same as a file desciptor on Unix systems.
    typealias SocketDescriptor = CInt
    #endif

    /// The C `msghdr` type
    #if os(Windows)
    // Windows doesn't have msghdr/iovec, we'll need to define compatible structures
    struct iovec {
        var iov_base: UnsafeMutableRawPointer?
        var iov_len: size_t
    }
    
    struct MessageHeader {
        var msg_name: UnsafeMutableRawPointer?
        var msg_namelen: socklen_t
        var msg_iov: UnsafeMutablePointer<iovec>?
        var msg_iovlen: size_t
        var msg_control: UnsafeMutableRawPointer?
        var msg_controllen: size_t
        var msg_flags: CInt
    }
    #else
    typealias MessageHeader = msghdr
    #endif
  
    /// The C `sa_family_t` type
    #if os(Windows)
    typealias SocketAddressFamily = ADDRESS_FAMILY
    #else
    typealias SocketAddressFamily = sa_family_t
    #endif

    /// Socket Type
    #if os(Linux)
    typealias SocketType = __socket_type
    #else
    typealias SocketType = CInt
    #endif
    
    /// The C `addrinfo` type
    typealias AddressInfo = addrinfo
    
    /// The C `in_addr` type
    typealias IPv4Address = in_addr
    
    /// The C `in6_addr` type
    typealias IPv6Address = in6_addr
    
    /// The C `sockaddr_in` type
    typealias SocketAddress = sockaddr
    
    #if !os(Android)
    /// The C `sockaddr_in` type
    typealias UnixSocketAddress = sockaddr_un
    #endif
  
    /// The C `sockaddr_in` type
    typealias IPv4SocketAddress = sockaddr_in
    
    /// The C `sockaddr_in6` type
    typealias IPv6SocketAddress = sockaddr_in6
    
    #if canImport(Darwin)
    /// The C `sockaddr_dl` type
    typealias LinkLayerAddress = sockaddr_dl
    #elseif os(Linux)
    /// The C `sockaddr_ll` type
    typealias LinkLayerAddress = sockaddr_ll
    #endif
    
    /// The C `if_nameindex` type
    #if os(Windows)
    // Windows doesn't have if_nameindex, define a compatible structure
    struct InterfaceNameIndex {
        var if_index: CUnsignedInt
        var if_name: UnsafeMutablePointer<CChar>?
    }
    #else
    typealias InterfaceNameIndex = if_nameindex
    #endif
    
    /// The C  `ifaddrs` type
    #if os(Windows)
    // Windows doesn't have ifaddrs, define a compatible structure
    struct InterfaceLinkedList {
        var ifa_next: UnsafeMutablePointer<InterfaceLinkedList>?
        var ifa_name: UnsafeMutablePointer<CChar>?
        var ifa_flags: CUnsignedInt
        var ifa_addr: UnsafeMutablePointer<sockaddr>?
        var ifa_netmask: UnsafeMutablePointer<sockaddr>?
        var ifa_broadaddr: UnsafeMutablePointer<sockaddr>?
        var ifa_data: UnsafeMutableRawPointer?
    }
    #else
    typealias InterfaceLinkedList = ifaddrs
    #endif
    
    typealias IOControlID = CUnsignedLong
}
