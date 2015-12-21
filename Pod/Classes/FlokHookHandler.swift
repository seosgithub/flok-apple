import UIKit

public class FlokHookHandler : NSObject {
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    weak var engine: FlokEngine!
    var completionEventPointer: Int?

    public func handle(info: [String:AnyObject]) {
        
    }
    
    public override required init() {
        
    }
    
    //Raises a completion event, only used for certain semantics like Goto
    public func completion() {
        if let completionEventPointer = completionEventPointer {
            engine.int_dispatch([3, "int_event", completionEventPointer, "", [:]])
        }
    }
} 