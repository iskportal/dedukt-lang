package type

import kotlin.Any

object Any: DeType, Any() {
    override val name: String
        get() = "any"
}