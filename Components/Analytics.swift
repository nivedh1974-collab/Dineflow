import SwiftUI
import Mixpanel

enum Analytics {
    static func start() {
        Mixpanel.initialize(token: "da5cf8db5cc8e0548e3ff4bb2edb66ae", trackAutomaticEvents: false)
    }

    static func track(_ event: String, _ props: Properties = [:]) {
        Mixpanel.mainInstance().track(event: event, properties: props)
    }

    static func setRole(_ role: String) {
        Mixpanel.mainInstance().registerSuperProperties(["user_role": role])
    }

    /// A screen opened. Event: screen_viewed
    static func screen(_ name: String, _ props: Properties = [:]) {
        var p: Properties = ["screen": name]
        props.forEach { p[$0.key] = $0.value }
        track("screen_viewed", p)
    }

    /// A button or row was tapped. Event: button_tapped
    static func tap(_ screen: String, _ button: String, _ props: Properties = [:]) {
        var p: Properties = ["screen": screen, "button": button]
        props.forEach { p[$0.key] = $0.value }
        track("button_tapped", p)
    }
}

extension View {
    /// Logs screen_viewed each time the view appears.
    func trackScreen(_ name: String, _ props: Properties = [:]) -> some View {
        onAppear { Analytics.screen(name, props) }
    }
}
