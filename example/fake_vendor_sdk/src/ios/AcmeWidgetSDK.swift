// A fake closed-source vendor SDK, built locally by build.sh so the husk_sdk
// example has a real binary to link. It has no relation to any real product.

/// Entry point of the fake AcmeWidgetSDK.
public enum AcmeWidget {
    /// Version of this fake SDK build.
    public static let version = "3.2.0"

    /// Returns a greeting that proves the binary was linked.
    public static func greeting(for name: String) -> String {
        "Hello \(name), from AcmeWidgetSDK \(version)"
    }
}
