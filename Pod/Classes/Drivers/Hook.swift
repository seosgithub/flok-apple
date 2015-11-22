@objc class FlokHookModule : FlokModule {
    override var exports: [String] {
        return ["if_hook_event:"]
    }
    
    static var hookClassLookup: [String:(exists: Bool, instance: FlokHookHandler?)] = [:]
    
    func if_hook_event(args: [AnyObject]) {
        let name = args[0] as! String
        let info = args[1] as! [String:AnyObject]
        
        var hookClassInfo = FlokHookModule.hookClassLookup[name]
        
        if hookClassInfo == nil {
            let hookHandlerClassName = "Flok\(name.snakeToClassCase)HookHandler"
            let hookHandlerClass = NSClassFromString(hookHandlerClassName) as? FlokHookHandler.Type
            if hookHandlerClass != nil {
                hookClassInfo = (exists: true, instance: hookHandlerClass!.init())
            } else {
                hookClassInfo = (exists: false, instance: nil)
            }
            
            FlokHookModule.hookClassLookup[name] = hookClassInfo
        }
        
        if hookClassInfo!.exists {
            let instance = hookClassInfo!.instance
            instance!.performSelector("handle:", withObject: info)
        }
    }
}