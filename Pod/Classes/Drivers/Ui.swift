@objc class FlokUiModule : FlokModule {
    override var exports: [String] {
        return ["if_ui_spec_init:", "if_init_view:", "if_attach_view:", "if_ui_spec_views_at_spot:", "if_ui_spec_view_exists:", "if_free_view:", "if_ui_spec_view_is_visible:"]
    }
    
    func if_ui_spec_init(args: [AnyObject]) {
        NSLog("spec init")
    }
    
    //Both spots and views
    static var uiTpToSelector: [Int: UIView] = [:]
    
    func if_init_view(args: [AnyObject]) {
        //NSException(name: "fail", reason: "if_ui_spec_init-afil-spec_views_at_spot222", userInfo: nil).raise()
        let name = args[0] as! String
        let context = args[1] as! [String:AnyObject]
        let tpBase = args[2] as! Int
        let tpTargets = args[3] as! [String]
        
        //Get the prototype that mateches
        let proto = FlokViewConceierge.viewWithName(name)

        let view = proto.init(frame: CGRectZero)
        view.bp = tpBase
        view.engine = self.engine
        view.name = name

        //Put the base view inside
        var tpIdx = tpBase  //Start with the base pointer
        for target in tpTargets {
            if target == "main" {
                FlokUiModule.uiTpToSelector[tpIdx] = view
            } else {
                let spot = view.spotWithName(target)
                spot.bp = tpIdx
                FlokUiModule.uiTpToSelector[tpIdx] = spot
            }

            tpIdx += 1
        }
    }
    
    func if_attach_view(args: [AnyObject]) {
        //NSException(name: "fail", reason: "if_attach-afil-spec_views_at_spot", userInfo: nil).raise()
        let vp = args[0] as! Int
        let p = args[1] as! Int

        //Root node
        var target: UIView?
        if p == 0 {
          target = engine.rootView
        } else {
          //Lookup view
          target = FlokUiModule.uiTpToSelector[p]
        }
        
        if target == nil {
            NSException(name: "FlokUIModule", reason: "Tried to if_attach_view with \(args), but the target couldn't be located", userInfo: nil).raise()
            return
        }

        let view = FlokUiModule.uiTpToSelector[vp]
        if let view = view as? FlokView {
            if let spot = target as? FlokSpot {
                spot.views.append(view as! FlokView)
            }
            
            view.parentView = target
            target!.addSubview(view)
            
            //Adding a view to a spot or root view, we need to make sure the view is set to the full size
            if target is FlokSpot || target === engine.rootView {
                view.translatesAutoresizingMaskIntoConstraints = false
                let top = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: target, attribute: .Top, multiplier: 1, constant: 0)
                let bottom = NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: target, attribute: .Bottom, multiplier: 1, constant: 0)
                let left = NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: target, attribute: .Left, multiplier: 1, constant: 0)
                let right = NSLayoutConstraint(item: view, attribute: .Right, relatedBy: .Equal, toItem: target, attribute: .Right, multiplier: 1, constant: 0)
                target!.addConstraints([top, bottom, left, right])
            }
            
        } else {
            NSException(name: "FlokUIModule", reason: "Tried to if_attach_view with \(args), but the view couldn't be located or was not a FlokView", userInfo: nil).raise()
        }
    }
    
    func if_ui_spec_views_at_spot(args: [AnyObject]) {
        let vp = args[0] as! Int
        NSLog("Spec / %d", vp)
        //NSException(name: "fail", reason: "if_ui-spec_views_at_spot", userInfo: nil).raise()
        
        //Root node
        if vp == 0 {
            var subVps: [Int] = []
            for e in engine.rootView.subviews {
               if let fv = e as? FlokView {
                   subVps.append(fv.bp)
               }
            }
            
            engine.intDispatch("spec", args: subVps)
        } else {
            let spot = FlokUiModule.uiTpToSelector[vp] as! FlokSpot
            let viewPointersInSpot = spot.views.map{$0.bp}
            engine.intDispatch("spec", args: viewPointersInSpot)
        }
    }

    func if_ui_spec_view_exists(args: [AnyObject]) {
      let p = args[0] as! Int
      var res = (FlokUiModule.uiTpToSelector[p] != nil)
      self.engine.int_dispatch([1, "spec", res])
    }

    func if_free_view(args: [AnyObject]) {
      let vp = args[0] as! Int

      let view = FlokUiModule.uiTpToSelector[vp]
      if view == nil {
        //For hook transitions, there is a chance that we receive the request to remove a view that was undergoing a transition but was removed when a parent-hierarchy was wiped out. This is a 'feature' as flok dosen't want to waste time managing the view hierarchy
//        NSException(name: "FlokUIModule", reason: "Tried to free view with pointer \(args) but it didn't exist in uiTpToSelector", userInfo: nil).raise()
        return
      }
      if let view = view as? FlokView {
        //Find all child views and spots
        var found = [view.bp]
        var unexploredViews = [view]
        while unexploredViews.count > 0 {
          let unexploredView = unexploredViews.removeLast()
          found.append(unexploredView.bp)
          for s in unexploredView.spots {
            found.append(s.bp)
            unexploredViews.appendContentsOf(s.views)
          }
        }

        //Pointers for both spots and views
        for p in found {
            if p != nil {
          FlokUiModule.uiTpToSelector.removeValueForKey(p)
            }
        }

        if let parentSpot = view.parentView as? FlokSpot {
          let index = parentSpot.views.indexOf(view)
          if let index = index {
            parentSpot.views.removeAtIndex(index)
          } else {
            NSException(name: "FlokUIModule", reason: "The parent spot didn't contain our base pointer when tyring to remove view", userInfo: nil).raise()
          }
        }
        view.removeFromSuperview()

      } else {
        NSException(name: "FlokUIModule", reason: "Tried to free view with pointer \(args) but it wasn't a FlokView: \(view)", userInfo: nil).raise()
      }
    }

    func if_ui_spec_view_is_visible(args: [AnyObject]) {
      let p = args[0] as! Int

      let view = FlokUiModule.uiTpToSelector[p]

      if let view = view as UIView! {
        let isVisible = view.isDescendantOfView(engine.rootView)
        engine.int_dispatch([1, "spec", isVisible])
      } else {
        NSException(name: "FlokUIModule", reason: "Tried to check if view with pointer \(p) was visible, but that pointer was not in the selectors table or it wasn't a UIView", userInfo: nil).raise()
        return
      }
    }
}