// A fake closed-source vendor SDK, built locally by build.sh so the husk_sdk
// example has a real binary to link. It has no relation to any real product.
package com.acme.widget;

/** Entry point of the fake AcmeWidgetSDK. */
public final class AcmeWidget {
    /** Version of this fake SDK build. */
    public static final String VERSION = "3.2.0";

    private AcmeWidget() {}

    /** Returns a greeting that proves the binary was linked. */
    public static String greeting(String name) {
        return "Hello " + name + ", from AcmeWidgetSDK " + VERSION;
    }
}
