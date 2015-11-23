import UIKit

//A view concierge that ensures that a FlokView is ready to be displayed
//and will not block.  Contains a asynchronous loading queue that can
//prioritize views to prep-load based on demands.  Additionally, you
//register views with the Conceierge to have them available for loading
//by setting the registeredViews hash lookup
public class _FlokViewConceierge {
    static var viewNameToKlass: [String:FlokView.Type] = [:]
    
    //Retrieves a view (class) for a specified name
    public func viewWithName(name: String) -> FlokView.Type {
        var klass = _FlokViewConceierge.viewNameToKlass[name]
        if klass == nil {
            klass = NSClassFromString(name.snakeToClassCase) as? FlokView.Type
            if klass == nil {
                puts("Warning: no view named \(name.snakeToClassCase) was found.  Using default debug view")
                klass = FlokDebugView.self
            }
            
            _FlokViewConceierge.viewNameToKlass[name] = klass
        }
        
        return klass!
    }
}

//Default singleton
public var FlokViewConceierge = _FlokViewConceierge()