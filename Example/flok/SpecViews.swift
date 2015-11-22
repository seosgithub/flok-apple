import UIKit
import flok

@objc(SpecBlank)
class SpecBlank: FlokView {
    override func didSwitchFromAction(from: String?, toAction to: String?) {
        let to = to ?? NSNull()
        let from = from ?? NSNull()
        
        emit("action_rcv", withInfo: [
            "from": from,
            "to": to
        ])
    }
    
    func foo(info: [String:AnyObject]) {
        emit("custom_rcv", withInfo: [
            "name": "foo",
            "info": info
        ])
    }
    
    func bar(info: [String:AnyObject]) {
        emit("custom_rcv", withInfo: [
            "name": "bar",
            "info": info
            ])
    }
}

@objc(SpecOneSpot)
class SpecOneSpot: FlokView {
}

@objc(SpecTwoSpot)
class SpecTwoSpot: FlokView {
}

@objc(SpecBlankSendsContext)
class SpecBlankSendsContext: FlokView {
    override func didLoad() {
        emit("context", withInfo: self.context)
    }
}