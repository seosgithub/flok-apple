@objc class FlokEventModule : FlokModule {
    override var exports: [String] {
        return ["if_event:"]
    }
    
    func if_event(args: [AnyObject]) {
        let ep = args[0] as! Int
        let name = args[1] as! String
        let info = args[2] as! [String:AnyObject]
        
        //Retrieve the view
        if let view = FlokControllerModule.cbpToView[ep] {
            if name == "action" {
                view.didSwitchFromAction(info["from"] as? String!, toAction: info["to"] as? String!)
            } else {
                let sel = Selector("\(name.snakeToCamelCase):")
                if view.respondsToSelector(sel) {
                    view.performSelector(sel, withObject: info)
                } else {
                    NSLog("Warning: The view named \(view.dynamicType) did not respond to the selector named \(name)")
                }
            }
        } else {
            NSLog("Warning: event sent to view (controller) with controller base pointer \(ep) was dropped because the view no longer exists")
        }
    }
}
