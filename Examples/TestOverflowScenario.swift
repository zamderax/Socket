//
//  TestOverflowScenario.swift
//  
//
//  Try to replicate the overflow scenario
//

import Socket

print("Testing overflow scenario...")

// First let's check if the issue happens when creating file events
print("\nTesting FileEvents creation:")
let events: FileEvents = [.read, .write]
print("Created FileEvents: \(events)")

// Test creating PollFileDescriptor
print("\nTesting PollFileDescriptor creation:")
let socket = SocketDescriptor(rawValue: 100) // arbitrary socket
var pollfd = CInterop.PollFileDescriptor(
    fd: socket.rawValue,
    events: events.rawValue,
    revents: 0
)
print("Created PollFileDescriptor")
print("  fd: \(pollfd.fd)")
print("  events: \(pollfd.events)")
print("  revents: \(pollfd.revents)")

// Try creating a Poll struct
print("\nTesting Poll creation:")
let poll = SocketDescriptor.Poll(socket: socket, events: events)
print("Created Poll")
print("  socket: \(poll.socket)")
print("  events: \(poll.events)")

// Test multiple event combinations
print("\nTesting various event combinations:")
let combinations: [FileEvents] = [
    .read,
    .write,
    .error,
    .hangup,
    .invalidRequest,
    [.read, .write],
    [.read, .write, .error],
    [.read, .readUrgent, .write]
]

for combo in combinations {
    print("  Events \(combo): rawValue = \(combo.rawValue)")
    let testPoll = SocketDescriptor.Poll(socket: socket, events: combo)
    print("    Created Poll successfully")
}

print("\nAll tests passed!")