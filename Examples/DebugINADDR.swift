import Socket

print("Testing INADDR constants on Windows...")

// This should use the Windows-specific implementation
print("\nAccessing IPv4Address.loopback...")
do {
    let loopback = IPv4Address.loopback
    print("✓ IPv4Address.loopback accessed successfully")
    print("  Value: \(loopback.rawValue)")
} catch {
    print("✗ Failed to access IPv4Address.loopback: \(error)")
}

// Try accessing the any address too
print("\nAccessing IPv4Address.any...")
do {
    let any = IPv4Address.any
    print("✓ IPv4Address.any accessed successfully")
    print("  Value: \(any.rawValue)")
} catch {
    print("✗ Failed to access IPv4Address.any: \(error)")
}

print("\nTest completed")