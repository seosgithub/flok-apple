@objc class FlokPersistModule : FlokModule {
    override var exports: [String] {
        return ["if_per_set:", "if_per_del:", "if_per_del_ns:", "if_per_get:"]
    }
    
    func if_per_set(args: [AnyObject]) {
        let ns = args[0] as! String
        let key = args[1] as! String
        let value = args[2]
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(value)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: nsk(ns, key))
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func if_per_del(args: [AnyObject]) {
        let ns = args[0] as! String
        let key = args[1] as! String
        NSUserDefaults.standardUserDefaults().removeObjectForKey(nsk(ns, key))
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func if_per_del_ns(args: [AnyObject]) {
        let ns = args[0] as! String
        
        let keys = NSUserDefaults.standardUserDefaults().dictionaryRepresentation().keys
        for e in keys {
            if e.rangeOfString(nsk(ns, nil)) != nil {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(e)
            }
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func if_per_get(args: [AnyObject]) {
        NSUserDefaults.standardUserDefaults().synchronize()
        let s = args[0] as! String
        let ns = args[1] as! String
        let key = args[2] as! String
        
       if let data =  NSUserDefaults.standardUserDefaults().objectForKey(nsk(ns, key)) as? NSData {
           if let res = NSKeyedUnarchiver.unarchiveObjectWithData(data) {
               engine.int_dispatch([4, "int_per_get_res", s, ns, key, res])
           } else {
               puts("FlokPersistModule: Failed to unarchive result for key: \(key) with data: \(data)")
               engine.int_dispatch([4, "int_per_get_res", s, ns, key, NSNull()])
           }
       } else {
           engine.int_dispatch([4, "int_per_get_res", s, ns, key, NSNull()])
       }
    }
}

//Creates a 'namespaced' key for a namespace+non-namespaced key pair
private func nsk(namespace: String, _ key: String?) -> String {
    return "\(namespace)://____\(key ?? "")"
}
