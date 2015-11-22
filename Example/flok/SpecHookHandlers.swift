import UIKit
import flok

@objc(FlokTestHookHandler)
class FlokTestHookHandler : FlokHookHandler {
    override func handle(info: [String:AnyObject]) {
        let res = [
            "name": "test",
            "info": info,
        ]
        PipeViewController.sharedInstance.flok.int_dispatch([1, "hook_dump_res", res])
    }
}

@objc(FlokTest2HookHandler)
class FlokTest2HookHandler : FlokHookHandler {
    override func handle(info: [String:AnyObject]) {
        let res = [
            "name": "test2",
            "info": info,
        ]
        PipeViewController.sharedInstance.flok.int_dispatch([1, "hook_dump_res", res])
    }
}