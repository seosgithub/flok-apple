import UIKit

@objc class FlokAboutModule : FlokModule {
    override var exports: [String] {
        return ["if_about_poll:"]
    }
    
    func if_about_poll(args: [AnyObject]) {
        let device = UIDevice.currentDevice()
        let _udid = device.identifierForVendor
        let udid = _udid?.UUIDString ?? "<unknown-apple-udid>"
        
        let values: [String] = [device.systemName, device.name, device.systemVersion, device.model, device.localizedModel]
        
        let platform: String = values.joinWithSeparator("--")
        let language: String = NSLocale.preferredLanguages().first ?? "unknown-apple-language"
        
        engine.intDispatch("int_about_poll_cb", args: [[
            "udid": udid,
            "platform": platform,
            "language": language
        ]])
    }
}
