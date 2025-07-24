# Windows Support

Learn how to use Socket on Windows with I/O Completion Ports (IOCP).

## Overview

The Socket library provides native Windows support using I/O Completion Ports (IOCP) for high-performance asynchronous I/O operations. This implementation offers an alternative to the polling-based approach used on POSIX systems.

### Key Features

- **Native Windows Socket Support**: Direct use of Winsock2 APIs without POSIX emulation
- **IOCP Integration**: High-performance asynchronous I/O using Windows I/O Completion Ports
- **Automatic Lifecycle Management**: Handles WSAStartup/WSACleanup automatically
- **Windows-Specific Error Handling**: Proper mapping of WSA error codes to Swift errors

## Getting Started

### Basic Usage

Using sockets on Windows is similar to other platforms:

```swift
import Socket

// Create a TCP socket
let socket = try await Socket(.tcp4)

// Bind to a local address
let address = IPv4SocketAddress(address: .any, port: 8080)
try socket.fileDescriptor.bind(address)

// Listen for connections
try socket.fileDescriptor.listen(backlog: 10)

// Accept connections
let client = try await socket.accept()
```

### Windows-Specific Configuration

For optimal performance on Windows, you can use the IOCP-based socket manager:

```swift
#if os(Windows)
// Configure to use Windows IOCP
Socket.useWindowsIOCP(
    log: { message in
        print("[IOCP] \(message)")
    },
    workerThreadCount: 0  // 0 = number of CPUs
)
#endif
```

## Windows Socket Types

### Socket Descriptors

On Windows, socket descriptors use the native `SOCKET` type (64-bit unsigned integer) instead of POSIX file descriptors:

```swift
public struct SocketDescriptor {
    #if os(Windows)
    public typealias RawValue = SOCKET  // UInt64
    #else
    public typealias RawValue = FileDescriptor.RawValue  // Int32
    #endif
}
```

### Socket Operations

All standard socket operations are supported with Windows-specific implementations:

- `socket()` - Create a new socket
- `bind()` - Bind to a local address
- `listen()` - Listen for connections
- `accept()` - Accept incoming connections
- `connect()` - Connect to a remote address
- `send()`/`recv()` - Send and receive data
- `closesocket()` - Close a socket

## Error Handling

Windows socket errors are automatically mapped to Swift's `Errno` type:

```swift
do {
    try socket.fileDescriptor.connect(to: address)
} catch let error as Errno {
    switch error {
    case .connectionRefused:
        print("Connection refused")
    case .timedOut:
        print("Connection timed out")
    default:
        print("Socket error: \(error)")
    }
}
```

### Windows-Specific Errors

The library preserves Windows-specific error codes when they don't have POSIX equivalents:

```swift
// Windows socket errors are accessible through Errno
let wsaError = WSAGetLastError()
let errno = Errno(rawValue: CInt(wsaError))
```

## Performance Considerations

### I/O Completion Ports (IOCP)

The Windows implementation uses IOCP for optimal performance:

- **Thread Pool**: IOCP manages a thread pool for handling completions
- **Scalability**: Efficiently handles thousands of concurrent connections
- **Zero-Copy**: Supports zero-copy operations where possible

### Comparison with Polling

| Feature | IOCP (Windows) | Polling (POSIX) |
|---------|----------------|-----------------|
| Scalability | Excellent | Good |
| CPU Usage | Low | Higher with many sockets |
| Latency | Low | Depends on poll interval |
| Complexity | Higher | Lower |

## Platform Differences

### Non-Blocking I/O

On Windows, non-blocking mode is set using `ioctlsocket` instead of `fcntl`:

```swift
// Windows
var mode: u_long = 1
ioctlsocket(socket, FIONBIO, &mode)

// POSIX
fcntl(socket, F_SETFL, O_NONBLOCK)
```

### Socket Options

Some socket options have different names or behaviors on Windows:

- `SO_REUSEADDR` - Different semantics than POSIX
- `SO_EXCLUSIVEADDRUSE` - Windows-specific option
- `TCP_NODELAY` - Same behavior across platforms

## Limitations

### Current Limitations

1. **WSAPoll vs IOCP**: The default AsyncSocketManager uses WSAPoll. For best performance, use the IOCP manager.
2. **Unix Domain Sockets**: Not supported on Windows versions before Windows 10 build 17063
3. **Some Socket Options**: Platform-specific options may not be available

### Future Improvements

- Full IOCP integration for all async operations
- Support for Windows-specific protocols (Named Pipes, etc.)
- Enhanced performance monitoring and debugging tools

## Example: Echo Server

Here's a complete example of an echo server on Windows:

```swift
import Socket
import Foundation

@main
struct EchoServer {
    static func main() async throws {
        #if os(Windows)
        // Use IOCP for better performance
        Socket.useWindowsIOCP()
        #endif
        
        // Create and bind socket
        let server = try await Socket(.tcp4)
        let address = IPv4SocketAddress(address: .any, port: 7777)
        try server.fileDescriptor.bind(address)
        try server.fileDescriptor.listen(backlog: 10)
        
        print("Echo server listening on port 7777...")
        
        // Accept connections
        while true {
            let client = try await server.accept()
            
            // Handle client in a separate task
            Task {
                await handleClient(client)
            }
        }
    }
    
    static func handleClient(_ client: Socket) async {
        do {
            var buffer = [UInt8](repeating: 0, count: 1024)
            
            while true {
                let bytesRead = try await client.read(into: &buffer)
                guard bytesRead > 0 else { break }
                
                // Echo back
                try await client.write(buffer[..<bytesRead])
            }
        } catch {
            print("Client error: \(error)")
        }
        
        await client.close()
    }
}
```

## See Also

- ``WindowsSocketConfiguration``: Configuration for Windows IOCP
- ``IOCPSocketManager``: IOCP-based socket manager implementation
- ``WindowsSocket``: Windows-specific socket operations