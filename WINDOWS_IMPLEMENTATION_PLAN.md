# Windows Socket Implementation Plan

## Overview
This plan outlines the approach for adding Windows support to the Socket library using WinSDK.

## Key Differences Between POSIX and Windows Sockets

1. **Socket Type**: Windows uses `SOCKET` (UINT_PTR/UInt64) vs POSIX `int`
2. **Invalid Socket**: Windows uses `INVALID_SOCKET` (-1 as SOCKET) vs POSIX -1
3. **Error Handling**: Windows uses `WSAGetLastError()` vs POSIX `errno`
4. **Initialization**: Windows requires `WSAStartup()` before socket operations
5. **Cleanup**: Windows uses `closesocket()` vs POSIX `close()`
6. **String Types**: Windows uses UTF-16 (wchar_t) for some APIs

## Implementation Tasks

### 1. Update CSocket Module Headers
- [x] Extend `CSystemWindows.h` to include WinSock2 headers
- [ ] Add necessary Windows socket headers and type definitions

### 2. Fix Type Definitions
- [ ] Define `CInterop.WinSock` type alias as SOCKET
- [ ] Update `SocketDescriptor` to properly handle Windows SOCKET type
- [ ] Fix RawRepresentable conformance for SocketDescriptor on Windows

### 3. Implement Windows System Calls
- [ ] Implement Windows versions of socket syscalls with proper error handling:
  - `system_socket()` - Use `WSASocketW()` or `socket()`
  - `system_bind()` - Direct mapping
  - `system_connect()` - Direct mapping  
  - `system_listen()` - Direct mapping
  - `system_accept()` - Direct mapping
  - `system_send()`/`system_recv()` - Direct mapping
  - `system_sendto()`/`system_recvfrom()` - Direct mapping
  - `system_poll()` - Use `WSAPoll()` or implement with select
  - `system_setsockopt()`/`system_getsockopt()` - Direct mapping
  - `system_shutdown()` - Direct mapping
  - `system_close()` - Use `closesocket()`

### 4. Handle Windows-Specific Requirements
- [ ] Implement WSAStartup/WSACleanup lifecycle management
- [ ] Map Windows socket errors to Swift Errno values
- [ ] Handle string conversions (UTF-8 to UTF-16 where needed)

### 5. Fix Platform-Specific Types
- [ ] Define missing types for Windows:
  - `socklen_t` (use int)
  - `nfds_t` for poll
  - Network interface types (`ifaddrs`, etc.)
  - Address family constants

### 6. Update Socket Manager
- [ ] Ensure SocketManager works with Windows async patterns
- [ ] Implement Windows-specific event handling if needed

### 7. Conditional Compilation
- [ ] Use `#if os(Windows)` for platform-specific code
- [ ] Ensure clean separation between POSIX and Windows implementations

### 8. Testing
- [ ] Create Windows-specific tests using Swift Testing
- [ ] Test all socket operations (TCP, UDP)
- [ ] Test IPv4 and IPv6 support
- [ ] Test error handling

## Windows Socket API Mapping

| POSIX API | Windows API | Notes |
|-----------|-------------|-------|
| socket() | socket() or WSASocketW() | Similar API |
| bind() | bind() | Direct mapping |
| connect() | connect() | Direct mapping |
| listen() | listen() | Direct mapping |
| accept() | accept() | Direct mapping |
| send()/recv() | send()/recv() | Direct mapping |
| sendto()/recvfrom() | sendto()/recvfrom() | Direct mapping |
| close() | closesocket() | Different function |
| poll() | WSAPoll() | Similar to poll |
| errno | WSAGetLastError() | Different error mechanism |
| fcntl() | ioctlsocket() | For non-blocking mode |

## Build Verification
Run `swift build` after each major change to ensure compilation succeeds.