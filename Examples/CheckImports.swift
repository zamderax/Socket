//
//  CheckImports.swift
//  
//
//  Check what can be imported on Windows
//

print("Checking imports on Windows:")

#if canImport(Darwin)
print("✓ canImport(Darwin) is TRUE")
#else
print("✗ canImport(Darwin) is FALSE")
#endif

#if os(Windows)
print("✓ os(Windows) is TRUE")
#else
print("✗ os(Windows) is FALSE")
#endif

#if os(Linux)
print("✓ os(Linux) is TRUE")
#else
print("✗ os(Linux) is FALSE")
#endif

#if canImport(WinSDK)
print("✓ canImport(WinSDK) is TRUE")
#else
print("✗ canImport(WinSDK) is FALSE")
#endif

#if canImport(Glibc)
print("✓ canImport(Glibc) is TRUE")
#else
print("✗ canImport(Glibc) is FALSE")
#endif

#if canImport(ucrt)
print("✓ canImport(ucrt) is TRUE")
#else
print("✗ canImport(ucrt) is FALSE")
#endif