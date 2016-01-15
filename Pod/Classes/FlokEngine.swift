import JavaScriptCore

@objc public protocol FlokEngineExports : JSExport {
    func if_dispatch(q: [AnyObject])
}

//Mostly for spec purposes
@objc public protocol FlokEnginePipeDelegate {
    optional func flokEngineDidReceiveIntDispatch(q: [AnyObject])
}

public protocol FlokEngineDelegate: class {
    //Return the view you wish the flok engine to take over for
    func flokEngineRootView(engine: FlokEngine) -> UIView
    
    //Called when an un-recoverable error is encountered
    func flokEngine(engine: FlokEngine, didPanicWithMessage message: String)
}

enum FlokPriorityQueue: Int {
    case Main = 0
    case Net = 1
    case Disk = 2
    case Cpu = 3
    case Gpu = 4
}

//Very-special class that adds methods from the modules
//at runtime via the objective-c runtime. Since they 
//already have the whole dynamic dispatch thing down,
//we'll use this instead of trying to roll our own.
@objc public class FlokRuntime : NSObject {
    dynamic weak var engine: FlokEngine!
    
    func addModule(module: FlokModule) {
        for e in module.exports {
            let klass = object_getClass(module)
            let method = class_getInstanceMethod(klass, Selector(e))
            
            class_addMethod(FlokRuntime.self, Selector(e), method_getImplementation(method), method_getTypeEncoding(method))
        }
    }
    
    //All runtimes should use this context to store data
    dynamic var context: [String:AnyObject] = [:]
}

@objc class FlokModule : NSObject {
    //List of method selectors that your module supports (for calling
    //via if_dispatch
    var exports: [String] {
        get {
            return [""]
        }
    }
    
    //The methods that are 'exported' are
    //added to 'FlokRuntime'.  So this dosen't actually
    //get called.  The FlokRuntime instance contains the
    //engine variable.
    dynamic var engine: FlokEngine!
    
    dynamic var context: [String:AnyObject]!
}

@objc public class FlokEngine : NSObject, FlokEngineExports {
    let context = JSContext()
    
    //Pointers to internal javascript methods & variables
    var intDispatchMethod: JSValue!
    
    var inPipeMode: Bool = false
    public weak var pipeDelegate: FlokEnginePipeDelegate?
    
    public weak var delegate: FlokEngineDelegate!

    lazy var modules: [FlokModule] = [
        FlokPingModule(),
        FlokUiModule(),
        FlokNetModule(),
        FlokControllerModule(),
        FlokPersistModule(),
        FlokRtcModule(),
        FlokSockioModule(),
        FlokTimerModule(),
        FlokDlinkModule(),
        FlokEventModule(),
        FlokHookModule(),
        FlokAboutModule(),
    ]
    lazy var runtime: FlokRuntime = FlokRuntime()
    
    //Operation queues for net, disk, cpu, and gpu
    lazy var operationQueues: [FlokPriorityQueue:NSOperationQueue] = [.Net:NSOperationQueue(), .Disk:NSOperationQueue(), .Cpu: NSOperationQueue(), .Gpu: NSOperationQueue()]
    
    //This should be moved to the UI module
    public var rootView: UIView {
        return self.delegate.flokEngineRootView(self)
    }
    
    public convenience init(src: String) {
        self.init(src: src, inPipeMode: false)
    }
    
    //Load with a javascript source, pipe mode intercepts
    //if_dispatch & int_dispatch
    var src: String!
    public init(src: String, inPipeMode: Bool) {
        self.src = src
        self.inPipeMode = inPipeMode
        super.init()
    }
    
    public func ready() -> Bool {
        //Add an exception handler
        context.exceptionHandler = { context, exception in
            self.delegate.flokEngine(self, didPanicWithMessage: exception.toString()!)
            return
        }
        
        context.evaluateScript(src)
        
        //Grab the int_dispatch function
        intDispatchMethod = context.objectForKeyedSubscript("int_dispatch")
        if (intDispatchMethod.toString() == "undefined") {
            self.delegate.flokEngine(self, didPanicWithMessage: "Couldn't locate the int_dispatch function within the provided script")
            return false
        }
        
        context.setObject(self, forKeyedSubscript: "swiftFlokEngine")
        context.evaluateScript("if_dispatch_pending = []; function if_dispatch(q) { if_dispatch_pending = q; }")
        
        runtime.engine = self
        for e in modules { runtime.addModule(e) }
        return true
    }
    
    public static func if_dispatch(q: [AnyObject]) {
        
    }
    
    public func boot() {
        runtime.performSelector("if_timer_init:", withObject: [4])
        runtime.performSelector("if_rtc_init:", withObject: [])
        runtime.performSelector("if_about_poll:", withObject: [])
        context.evaluateScript("_embed(\"root\", 0, {});")
        
        int_dispatch([])
    }
    
    //Call into the int_dispatch of the engine
    public func intDispatch(name: String, args: [AnyObject]?) {
        //Construct a packet
        var arr: [AnyObject] = [name]
        if let args = args { arr.appendContentsOf(args) }
        arr.insert(arr.count-1, atIndex: 0)
        
        int_dispatch(arr)
    }
    
    public func int_dispatch(q: [AnyObject]) {
        let block = { [weak self] in
            if (self?.inPipeMode ?? false) {
                self?.pipeDelegate?.flokEngineDidReceiveIntDispatch?(q)
            } else {
                self?.intDispatchMethod.callWithArguments([q])
                
                let pending = self?.context.evaluateScript("if_dispatch_pending").toArray() ?? []
                self?.context.evaluateScript("if_dispatch_pending = []")
                if pending.count > 0 {
                    self?.if_dispatch(pending)
                }
            }
        }
        
        if NSThread.isMainThread() {
            block()
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
                dispatch_async(dispatch_get_main_queue()) {
                    block()
                }
            }
        }
    }
    
    //Will be called by the JS engine itself or pipe to simulate the JS engine
    public func if_dispatch(var q: [AnyObject]) {
        //Priority array
        var isIncomplete = false
        for qq in q {
            if let qq = qq as? String {
                if qq == "i" {
                    isIncomplete = true
                } else {
                    delegate.flokEngine(self, didPanicWithMessage: "Got a string in the if_dispatch, but it wasn't 'i' for incomplete")
                    
                }
            } else if let qq = qq as? [AnyObject] {
                let priorityNum = qq[0] as! Int
                guard let priority =  FlokPriorityQueue(rawValue: priorityNum) else {
                    delegate.flokEngine(self, didPanicWithMessage: "Priority given, '\(priorityNum)' was not an available priority!")
                    return
                }
                
                var i = 1
                while (i < qq.count) {
                    var args: [AnyObject] = []
                    let argCount = qq[i++] as! Int
                    let cmd = qq[i++] as! String
                    args.appendContentsOf(qq[i..<(i+argCount)])
                    i += argCount
                    
                    switch priority {
                    case .Main:
                        handleIfCommand(cmd, withArgs: args)
                    default:
                        operationQueues[priority]?.addOperationWithBlock { [weak self] in
                            self?.handleIfCommand(cmd, withArgs: args)
                        }
                    }
                }
            }
        }
        
        if isIncomplete {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
                dispatch_async(dispatch_get_main_queue()) {
                    self.int_dispatch([])
                }
            }
        }
    }
    
    func handleIfCommand(cmd: String, withArgs args: [AnyObject]) {
        if runtime.respondsToSelector(Selector("\(cmd):")) {
            runtime.performSelector(Selector("\(cmd):"), withObject: args)
        } else {
            NSLog("if_dispatch does not support the command '\(cmd):' with args \(args)")
        }
    }
}
