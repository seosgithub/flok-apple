import Alamofire

extension Alamofire.Method {
    init(withString string: String) {
        switch string {
        case "OPTIONS":
          self = .OPTIONS 
        case "GET":
          self = .GET 
        case "HEAD":
          self = .HEAD 
        case "POST":
          self = .POST 
        case "PUT":
          self = .PUT 
        case "PATCH":
          self = .PATCH 
        case "DELETE":
          self = .DELETE 
        case "TRACE":
          self = .TRACE 
        case "CONNECT":
          self = .CONNECT 
        default:
            NSLog("Warning, unknown HTTP verb \(string), defaulting to GET")
            self = .GET
        }
    }
}

@objc class FlokNetModule : FlokModule {
    override var exports: [String] {
        return ["if_net_req:", "if_net_req2:"]
    }
    
    func if_net_req(args: [AnyObject]) {
        let verb = args[0] as! String
        let url = args[1] as! String
        let params = args[2] as! [String:AnyObject]
        let tpBase = args[3] as! Int
        
        Alamofire.request(Method(withString: verb), url, parameters: params).responseJSON { response in
            switch response.result {
            case .Success:
                if let statusCode = response.response?.statusCode {
                    if let json = response.result.value as? [String:AnyObject] {
                        self.engine.int_dispatch([3, "int_net_cb", tpBase, statusCode, json])
                    } else {
                        self.engine.int_dispatch([3, "int_net_cb", tpBase, -1, "Got back Non JSON response: \(response.result.value)"])
                    }
                } else {
                    self.engine.int_dispatch([3, "int_net_cb", tpBase, -1, "Flok-Apple Internal Error - request was successful but there was no response"])
                }

            case .Failure(let error):
                self.engine.int_dispatch([3, "int_net_cb", tpBase, -1, "Failed to connect: \(error.localizedDescription)"])
            }
        }
    }
    
    func if_net_req2(args: [AnyObject]) {
        let verb = args[0] as! String
        let headers = args[1] as! [String:String]
        let url = args[2] as! String
        let params = args[3] as! [String:AnyObject]
        let tpBase = args[4] as! Int
        
        Alamofire.request(Method(withString: verb), url, parameters: params, headers: headers).responseJSON { response in
            switch response.result {
            case .Success:
                if let statusCode = response.response?.statusCode {
                    if let json = response.result.value as? [String:AnyObject] {
                        self.engine.int_dispatch([3, "int_net_cb", tpBase, statusCode, json])
                    } else {
                        self.engine.int_dispatch([3, "int_net_cb", tpBase, -1, "Got back Non JSON response: \(response.result.value)"])
                    }
                } else {
                    self.engine.int_dispatch([3, "int_net_cb", tpBase, -1, "Flok-Apple Internal Error - request was successful but there was no response"])
                }
                
            case .Failure(let error):
                self.engine.int_dispatch([3, "int_net_cb", tpBase, -1, "Failed to connect: \(error.localizedDescription)"])
            }
        }
    }
    
}
