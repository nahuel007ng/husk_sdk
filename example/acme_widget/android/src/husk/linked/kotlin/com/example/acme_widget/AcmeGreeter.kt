package com.example.acme_widget

import com.acme.widget.AcmeWidget

/** Linked build: calls the vendor SDK. The stub twin lives in src/husk/stub. */
internal object AcmeGreeter {
    fun greeting(name: String): String? = AcmeWidget.greeting(name)
}
