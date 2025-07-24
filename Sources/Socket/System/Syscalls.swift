import SystemPackage

#if canImport(Darwin)
import Darwin
#elseif os(Windows)
import CSocket
import ucrt
import WinSDK
import CRT
#elseif canImport(Glibc)
import CSocket
import Glibc
#elseif canImport(Musl)
import CSocket
import Musl
#elseif canImport(WASILibc)
import CSocket
import WASILibc
#elseif canImport(Android)
import CSystem
import Android
#else
#error("Unsupported Platform")
#endif

@inline(__always)
internal var mockingEnabled: Bool {
  // Fast constant-foldable check for release builds
  #if ENABLE_MOCKING
    return contextualMockingEnabled
  #else
    return false
  #endif
}


#if ENABLE_MOCKING
// Strip the mock_system prefix and the arg list suffix
private func originalSyscallName(_ function: String) -> String {
  // `function` must be of format `system_<name>(<parameters>)`
  precondition(function.starts(with: "system_"))
  return String(function.dropFirst("system_".count).prefix { $0 != "(" })
}

private func mockImpl(
  name: String,
  path: UnsafePointer<CInterop.PlatformChar>?,
  _ args: [AnyHashable]
) -> CInt {
  precondition(mockingEnabled)
  let origName = originalSyscallName(name)
  guard let driver = currentMockingDriver else {
    fatalError("Mocking requested from non-mocking context")
  }
  var mockArgs: Array<AnyHashable> = []
  if let p = path {
    mockArgs.append(String(_errorCorrectingPlatformString: p))
  }
  mockArgs.append(contentsOf: args)
  driver.trace.add(Trace.Entry(name: origName, mockArgs))

  switch driver.forceErrno {
  case .none: break
  case .always(let e):
    system_errno = e
    return -1
  case .counted(let e, let count):
    assert(count >= 1)
    system_errno = e
    driver.forceErrno = count > 1 ? .counted(errno: e, count: count-1) : .none
    return -1
  }

  return 0
}

internal func _mock(
  name: String = #function, path: UnsafePointer<CInterop.PlatformChar>? = nil, _ args: AnyHashable...
) -> CInt {
  return mockImpl(name: name, path: path, args)
}
internal func _mockInt(
  name: String = #function, path: UnsafePointer<CInterop.PlatformChar>? = nil, _ args: AnyHashable...
) -> Int {
  Int(mockImpl(name: name, path: path, args))
}

#endif // ENABLE_MOCKING

#if canImport(Darwin)
internal var system_errno: CInt {
  get { Darwin.errno }
  set { Darwin.errno = newValue }
}
#elseif os(Windows)
internal var system_errno: CInt {
  get {
    var value: CInt = 0
    // TODO(compnerd) handle the error?
    _ = ucrt._get_errno(&value)
    return value
  }
  set {
    _ = ucrt._set_errno(newValue)
  }
}
#elseif canImport(Glibc)
internal var system_errno: CInt {
  get { Glibc.errno }
  set { Glibc.errno = newValue }
}
#elseif canImport(Musl)
internal var system_errno: CInt {
  get { Musl.errno }
  set { Musl.errno = newValue }
}
#elseif canImport(WASILibc)
internal var system_errno: CInt {
  get { WASILibc.errno }
  set { WASILibc.errno = newValue }
}
#elseif canImport(Android)
internal var system_errno: CInt {
  get { Android.errno }
  set { Android.errno = newValue }
}
#endif

// close
internal func system_close(_ fd: CInterop.SocketDescriptor) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(CInt(fd)) }
#endif
  #if os(Windows)
  // On Windows, we need to use closesocket for socket descriptors
  return closesocket(fd)
  #else
  return close(fd)
  #endif
}

// write (for sockets)
internal func system_write(
  _ fd: CInterop.SocketDescriptor, _ buf: UnsafeRawPointer!, _ nbyte: Int
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(CInt(fd), buf, nbyte) }
#endif
  #if os(Windows)
  return Int(send(fd, buf.assumingMemoryBound(to: CChar.self), Int32(nbyte), 0))
  #else
  return write(fd, buf, nbyte)
  #endif
}


// read (for sockets)
internal func system_read(
  _ fd: CInterop.SocketDescriptor, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(CInt(fd), buf, nbyte) }
#endif
  #if os(Windows)
  return Int(recv(fd, buf.assumingMemoryBound(to: CChar.self), Int32(nbyte), 0))
  #else
  return read(fd, buf, nbyte)
  #endif
}


internal func system_inet_pton(
    _ family: Int32,
    _ cString: UnsafePointer<CChar>,
    _ address: UnsafeMutableRawPointer) -> Int32 {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(family, cString, address) }
  #endif
  #if os(Windows)
  // Windows inet_pton expects char*, not wchar_t*
  return inet_pton(family, cString, address)
  #else
  return inet_pton(family, cString, address)
  #endif
}

internal func system_inet_ntop(_ family: Int32, _ pointer : UnsafeRawPointer, _ string: UnsafeMutablePointer<CChar>, _ length: UInt32) -> UnsafePointer<CChar>? {
  #if ENABLE_MOCKING
  //if mockingEnabled { return _mock(family, pointer, string, length) }
  #endif
  #if os(Windows)
  return inet_ntop(family, pointer, string, Int(length))
  #else
  return inet_ntop(family, pointer, string, length)
  #endif
}

internal func system_socket(_ fd: Int32, _ fd2: Int32, _ fd3: Int32) -> CInterop.SocketDescriptor {
  #if ENABLE_MOCKING
  if mockingEnabled { return CInterop.SocketDescriptor(_mock(fd, fd2, fd3)) }
  #endif
  return socket(fd, fd2, fd3)
}

internal func system_setsockopt(_ fd: CInterop.SocketDescriptor, _ fd2: Int32, _ fd3: Int32, _ pointer: UnsafeRawPointer, _ dataLength: UInt32) -> Int32 {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, fd2, fd3, pointer, dataLength) }
  #endif
  #if os(Windows)
  return setsockopt(fd, fd2, fd3, pointer, Int32(dataLength))
  #else
  return setsockopt(fd, fd2, fd3, pointer, dataLength)
  #endif
}

internal func system_getsockopt(
  _ socket: CInterop.SocketDescriptor,
  _ level: CInt,
  _ option: CInt,
  _ value: UnsafeMutableRawPointer?,
  _ length: UnsafeMutablePointer<UInt32>
) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, level, option, value, length) }
  #endif
  return getsockopt(socket, level, option, value, length)
}

internal func system_bind(
    _ socket: CInterop.SocketDescriptor,
    _ address: UnsafePointer<CInterop.SocketAddress>,
    _ length: UInt32
) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, address, length) }
  #endif
  #if os(Windows)
  return bind(socket, address, Int32(length))
  #else
  return bind(socket, address, length)
  #endif
}

internal func system_connect(
  _ socket: CInterop.SocketDescriptor,
  _ addr: UnsafePointer<sockaddr>,
  _ len: UInt32
) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, addr, len) }
  #endif
  #if os(Windows)
  return connect(socket, addr, Int32(len))
  #else
  return connect(socket, addr, len)
  #endif
}

internal func system_accept(
  _ socket: CInterop.SocketDescriptor,
  _ addr: UnsafeMutablePointer<sockaddr>?,
  _ len: UnsafeMutablePointer<UInt32>?
) -> CInterop.SocketDescriptor {
  #if ENABLE_MOCKING
  if mockingEnabled { return CInterop.SocketDescriptor(_mock(socket, addr, len)) }
  #endif
  return accept(socket, addr, len)
}

internal func system_getaddrinfo(
  _ hostname: UnsafePointer<CChar>?,
  _ servname: UnsafePointer<CChar>?,
  _ hints: UnsafePointer<CInterop.AddressInfo>?,
  _ res: UnsafeMutablePointer<UnsafeMutablePointer<CInterop.AddressInfo>?>
) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled {
    return _mock(hostname,
                 servname,
                 hints, res)
  }
  #endif
  return getaddrinfo(hostname, servname, hints, res)
}

internal func system_getnameinfo(
  _ sa: UnsafePointer<CInterop.SocketAddress>,
  _ salen: UInt32,
  _ host: UnsafeMutablePointer<CChar>?,
  _ hostlen: UInt32,
  _ serv: UnsafeMutablePointer<CChar>?,
  _ servlen: UInt32,
  _ flags: CInt
) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled {
    return _mock(sa, salen, host, hostlen, serv, servlen, flags)
  }
  #endif
  #if os(Windows)
  return getnameinfo(sa, Int32(salen), host, hostlen, serv, servlen, flags)
  #else
  return getnameinfo(sa, salen, host, numericCast(hostlen), serv, numericCast(servlen), flags)
  #endif
}

internal func system_freeaddrinfo(
  _ addrinfo: UnsafeMutablePointer<CInterop.AddressInfo>?
) {
  #if ENABLE_MOCKING
  if mockingEnabled {
    _ = _mock(addrinfo)
    return
  }
  #endif
  return freeaddrinfo(addrinfo)
}

internal func system_gai_strerror(_ error: CInt) -> UnsafePointer<CChar> {
  #if ENABLE_MOCKING
  // FIXME
  #endif
  #if os(Windows)
  // Windows uses different error handling for getaddrinfo
  // Return a simple error message
  let message = "Address info error"
  let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: message.count + 1)
  message.withCString { src in
    _ = strcpy_s(buffer, rsize_t(message.count + 1), src)
  }
  return UnsafePointer(buffer)
  #else
  return gai_strerror(error)
  #endif
}

internal func system_shutdown(_ socket: CInterop.SocketDescriptor, _ how: CInt) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, how) }
  #endif
  return shutdown(socket, how)
}

internal func system_listen(_ socket: CInterop.SocketDescriptor, _ backlog: CInt) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, backlog) }
  #endif
  return listen(socket, backlog)
}

internal func system_send(
  _ socket: CInterop.SocketDescriptor, 
  _ buffer: UnsafeRawPointer,
  _ len: Int,
  _ flags: Int32
) -> Int {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, buffer, len, flags) }
  #endif
  #if os(Windows)
  return Int(send(socket, buffer.assumingMemoryBound(to: CChar.self), Int32(len), flags))
  #else
  return send(socket, buffer, len, flags)
  #endif
}

internal func system_recv(
  _ socket: CInterop.SocketDescriptor,
  _ buffer: UnsafeMutableRawPointer?,
  _ len: Int,
  _ flags: Int32
) -> Int {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, buffer, len, flags) }
  #endif
  #if os(Windows)
  return Int(recv(socket, buffer?.assumingMemoryBound(to: CChar.self), Int32(len), flags))
  #else
  return recv(socket, buffer, len, flags)
  #endif
}

internal func system_sendto(
  _ socket: CInterop.SocketDescriptor,
  _ buffer: UnsafeRawPointer,
  _ length: Int,
  _ flags: CInt,
  _ dest_addr: UnsafePointer<CInterop.SocketAddress>?,
  _ dest_len: UInt32
) -> Int {
  #if ENABLE_MOCKING
  if mockingEnabled {
    return _mockInt(socket, buffer, length, flags, dest_addr, dest_len)
  }
  #endif
  #if os(Windows)
  return Int(sendto(socket, buffer.assumingMemoryBound(to: CChar.self), Int32(length), flags, dest_addr, Int32(dest_len)))
  #else
  return sendto(socket, buffer, length, flags, dest_addr, dest_len)
  #endif
}

internal func system_recvfrom(
  _ socket: CInterop.SocketDescriptor,
  _ buffer: UnsafeMutableRawPointer?,
  _ length: Int,
  _ flags: CInt,
  _ address: UnsafeMutablePointer<CInterop.SocketAddress>?,
  _ addres_len: UnsafeMutablePointer<UInt32>?
) -> Int {
  #if ENABLE_MOCKING
  if mockingEnabled {
    return _mockInt(socket, buffer, length, flags, address, addres_len)
  }
  #endif
  #if os(Windows)
  return Int(recvfrom(socket, buffer?.assumingMemoryBound(to: CChar.self), Int32(length), flags, address, addres_len))
  #else
  return recvfrom(socket, buffer, length, flags, address, addres_len)
  #endif
}

internal func system_poll(
    _ fileDescriptors: UnsafeMutablePointer<CInterop.PollFileDescriptor>,
    _ fileDescriptorsCount: CInterop.FileDescriptorCount,
    _ timeout: CInt
) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(fileDescriptors, fileDescriptorsCount, timeout) }
  #endif
  #if os(Windows)
  // Windows uses WSAPoll instead of poll
  return WSAPoll(fileDescriptors, fileDescriptorsCount, timeout)
  #else
  return poll(fileDescriptors, fileDescriptorsCount, timeout)
  #endif
}

internal func system_sendmsg(
  _ socket: CInterop.SocketDescriptor,
  _ message: UnsafePointer<CInterop.MessageHeader>,
  _ flags: CInt
) -> Int {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, message, flags) }
  #endif
  #if os(Windows)
  // Windows doesn't have sendmsg, would need to implement with WSASendMsg
  system_errno = CInt(WSAENOTSOCK)
  return -1
  #else
  return sendmsg(socket, message, flags)
  #endif
}

internal func system_recvmsg(
  _ socket: CInterop.SocketDescriptor,
  _ message: UnsafeMutablePointer<CInterop.MessageHeader>,
  _ flags: CInt
) -> Int {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, message, flags) }
  #endif
  #if os(Windows)
  // Windows doesn't have recvmsg, would need to implement with WSARecvMsg
  system_errno = CInt(WSAENOTSOCK)
  return -1
  #else
  return recvmsg(socket, message, flags)
  #endif
}

#if os(Linux) || os(Android)
internal func system_eventfd(
  _ initval: CUnsignedInt,
  _ flags: CInt
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(initval, flags) }
#endif
  return eventfd(initval, flags)
}
#endif

internal func system_fcntl(
  _ fd: Int32,
  _ cmd: Int32
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, cmd) }
#endif
  return _fcntl(fd, cmd)
}

internal func system_fcntl(
  _ fd: Int32,
  _ cmd: Int32,
  _ value: Int32
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, cmd, value) }
#endif
  return _fcntl(fd, cmd, value)
}

internal func system_fcntl(
  _ fd: Int32,
  _ cmd: Int32,
  _ pointer: UnsafeMutableRawPointer
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, cmd, pointer) }
#endif
  return _fcntl(fd, cmd, pointer)
}

// ioctl
internal func system_ioctl(
  _ fd: Int32,
  _ request: CInterop.IOControlID
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, request) }
#endif
  return _ioctl(fd, request)
}

// ioctl
internal func system_ioctl(
  _ fd: Int32,
  _ request: CInterop.IOControlID,
  _ value: CInt
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, request, value) }
#endif
  return _ioctl(fd, request, value)
}

// ioctl
internal func system_ioctl(
  _ fd: Int32,
  _ request: CInterop.IOControlID,
  _ pointer: UnsafeMutableRawPointer
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, request, pointer) }
#endif
  return _ioctl(fd, request, pointer)
}

// if_nameindex
internal func system_if_nameindex() -> UnsafeMutablePointer<CInterop.InterfaceNameIndex>? {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock() }
#endif
    #if os(Windows)
    // Windows doesn't have if_nameindex
    return nil
    #else
    return if_nameindex()
    #endif
}

// if_nameindex
internal func system_if_freenameindex(_ pointer: UnsafeMutablePointer<CInterop.InterfaceNameIndex>?) {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(pointer) }
#endif
    #if os(Windows)
    // Windows doesn't have if_freenameindex
    return
    #else
    return if_freenameindex(pointer)
    #endif
}

internal func system_getifaddrs(_ pointer: UnsafeMutablePointer<UnsafeMutablePointer<CInterop.InterfaceLinkedList>?>) -> CInt {
#if ENABLE_MOCKING
    if mockingEnabled { return _mock(pointer) }
#endif
    #if os(Windows)
    // Windows doesn't have getifaddrs
    return -1
    #else
    return getifaddrs(pointer)
    #endif
}

internal func system_freeifaddrs(_ pointer: UnsafeMutablePointer<CInterop.InterfaceLinkedList>?) {
#if ENABLE_MOCKING
    if mockingEnabled { return _mock(pointer) }
#endif
    #if os(Windows)
    // Windows doesn't have freeifaddrs
    return
    #else
    return freeifaddrs(pointer)
    #endif
}

#if canImport(Darwin)
internal func system_link_addr(_ cString: UnsafePointer<CChar>, _ address: UnsafeMutablePointer<sockaddr_dl>) {
#if ENABLE_MOCKING
    if mockingEnabled { return _mock(cString) }
#endif
    return link_addr(cString, address)
}

internal func system_link_ntoa(_ address: UnsafePointer<sockaddr_dl>) -> UnsafeMutablePointer<CChar> {
#if ENABLE_MOCKING
    if mockingEnabled { return _mock(cString) }
#endif
    return link_ntoa(address)
}
#endif

internal func system_getsockname(_ fd: CInterop.SocketDescriptor, _ address: UnsafeMutablePointer<CInterop.SocketAddress>, _ length: UnsafeMutablePointer<UInt32>) -> CInt {
#if ENABLE_MOCKING
    if mockingEnabled { return _mock(fd, address) }
#endif
    return getsockname(fd, address, length)
}

internal func system_getpeername(_ fd: CInterop.SocketDescriptor, _ address: UnsafeMutablePointer<CInterop.SocketAddress>, _ length: UnsafeMutablePointer<UInt32>) -> CInt {
#if ENABLE_MOCKING
    if mockingEnabled { return _mock(fd, address) }
#endif
    return getpeername(fd, address, length)
}

#if os(Android)
func _fcntl(_ fd: Int32, _ cmd: Int32) -> Int32 {
    android_fcntl(fd, cmd)
}

func _fcntl(_ fd: Int32, _ cmd: Int32, _ value: Int32) -> Int32 {
    android_fcntl_value(fd, cmd, value)
}

func _fcntl(_ fd: Int32, _ cmd: Int32, _ ptr: UnsafeMutableRawPointer) -> Int32 {
    android_fcntl_ptr(fd, cmd, ptr)
}

func _ioctl(_ fd: CInt, _ request: CInterop.IOControlID, _ value: CInt) -> CInt {
    android_ioctl_value(fd, request, value)
}

func _ioctl(_ fd: CInt, _ request: CInterop.IOControlID, _ ptr: UnsafeMutableRawPointer) -> CInt {
    android_ioctl_ptr(fd, request, ptr)
}

func _ioctl(_ fd: CInt, _ request: CInterop.IOControlID) -> CInt {
    android_ioctl(fd, request)
}

@_silgen_name("android_fcntl")
func android_fcntl(_ fd: Int32, _ cmd: Int32) -> Int32

@_silgen_name("android_fcntl_value")
func android_fcntl_value(_ fd: Int32, _ cmd: Int32, _ value: Int32) -> Int32

@_silgen_name("android_fcntl_ptr")
func android_fcntl_ptr(_ fd: Int32, _ cmd: Int32, _ ptr: UnsafeMutableRawPointer) -> Int32

@_silgen_name("android_ioctl_value")
func android_ioctl_value(_ fd: CInt, _ request: CInterop.IOControlID, _ value: CInt) -> CInt

@_silgen_name("android_ioctl_ptr")
func android_ioctl_ptr(_ fd: CInt, _ request: CInterop.IOControlID, _ ptr: UnsafeMutableRawPointer) -> CInt

@_silgen_name("android_ioctl")
func android_ioctl(_ fd: CInt, _ request: CInterop.IOControlID) -> CInt

#elseif os(Windows)
// Windows doesn't have fcntl, emulate with ioctlsocket for socket operations
func _fcntl(_ fd: Int32, _ cmd: Int32) -> Int32 {
    // fcntl is not available on Windows
    system_errno = CInt(WSAEOPNOTSUPP)
    return -1
}

func _fcntl(_ fd: Int32, _ cmd: Int32, _ value: Int32) -> Int32 {
    // fcntl is not available on Windows
    system_errno = CInt(WSAEOPNOTSUPP)
    return -1
}

func _fcntl(_ fd: Int32, _ cmd: Int32, _ ptr: UnsafeMutableRawPointer) -> Int32 {
    // fcntl is not available on Windows
    system_errno = CInt(WSAEOPNOTSUPP)
    return -1
}

func _ioctl(_ fd: CInt, _ request: CInterop.IOControlID, _ value: CInt) -> CInt {
    var val = CUnsignedLong(value)
    return ioctlsocket(CInterop.SocketDescriptor(fd), Int32(request), &val)
}

func _ioctl(_ fd: CInt, _ request: CInterop.IOControlID, _ ptr: UnsafeMutableRawPointer) -> CInt {
    return ioctlsocket(CInterop.SocketDescriptor(fd), Int32(request), ptr.assumingMemoryBound(to: CUnsignedLong.self))
}

func _ioctl(_ fd: CInt, _ request: CInterop.IOControlID) -> CInt {
    return ioctlsocket(CInterop.SocketDescriptor(fd), Int32(request), nil)
}
#else
func _fcntl(_ fd: Int32, _ cmd: Int32) -> Int32 {
    fcntl(fd, cmd)
}

func _fcntl(_ fd: Int32, _ cmd: Int32, _ value: Int32) -> Int32 {
    fcntl(fd, cmd, value)
}

func _fcntl(_ fd: Int32, _ cmd: Int32, _ ptr: UnsafeMutableRawPointer) -> Int32 {
    fcntl(fd, cmd, ptr)
}

func _ioctl(_ fd: CInt, _ request: CInterop.IOControlID, _ value: CInt) -> CInt {
    ioctl(fd, request, value)
}

func _ioctl(_ fd: CInt, _ request: CInterop.IOControlID, _ ptr: UnsafeMutableRawPointer) -> CInt {
    ioctl(fd, request, ptr)
}

func _ioctl(_ fd: CInt, _ request: CInterop.IOControlID) -> CInt {
    ioctl(fd, request)
}
#endif
