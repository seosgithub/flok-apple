@objc class FlokHookModule : FlokModule {
    override var exports: [String] {
        return ["if_hook_event:"]
    }
    
    static var hookClassLookup: [String:FlokHookHandler.Type?] = [:]
    
    func if_hook_event(args: [AnyObject]) {
        let name = args[0] as! String
        var info = args[1] as! [String:AnyObject]
        
        //If the key is undefiend, attempt a lookup
        if FlokHookModule.hookClassLookup.indexForKey(name) == nil {
            let hookHandlerClassName = "\(name.snakeToClassCase)Hook"
            let hookHandlerClass = NSClassFromString(hookHandlerClassName) as? FlokHookHandler.Type
            FlokHookModule.hookClassLookup[name] = hookHandlerClass
        }
        
        if let hookKlass = FlokHookModule.hookClassLookup[name] where hookKlass != nil {
            let instance = hookKlass!.init()
            instance.engine = engine
           
            //Replace views array
            var views: [String:FlokView] = [:]
            for (key, bp) in info["views"] as! [String:Int] {
                views[key] = FlokControllerModule.cbpToView[bp]
            }
            
            info["views"] = views
            
            if let cep = info["cep"] as? Int {
                instance.completionEventPointer = cep
            } else {
                instance.completionEventPointer = nil
            }
            
            instance.performSelector("handle:", withObject: info)
        } else {
            puts("Not handling hook \(name)")
        }
    }
}