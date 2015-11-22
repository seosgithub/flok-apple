//If the user does not define any custom view, this view is used. It acts
//as a useful debugging aid by showing the name of the view and the names
//of spots as well as showing all the available spots

import UIKit

public class FlokDebugView: FlokView
{
    //Maps spot names to autospot
    var autoSpots = WeakValueDictionary<String, FlokSpot>()
    var autoSpotConstraints = WeakValueDictionary<String, NSLayoutConstraint>()

    lazy var nameLabel: UILabel! = UILabel()
    
    //Returns an auto-created spot if there is no spot
    public override func spotWithName(name: String) -> FlokSpot! {
        //It was already created
        if let autoSpot = autoSpots[name] {
            return autoSpot
        }
        
        //No? Add it to our special list so we know to update constraints
        let autoSpot = super.spotWithName(name)
        autoSpots[name] = autoSpot
        self.setNeedsLayout()
        return autoSpot
    }
    
    public override func didLoad() {
        self.backgroundColor = UIColor(red:0.094, green:0.094, blue:0.125, alpha: 1)
        
        //Add 'view' nameLabel
        self.addSubview(nameLabel)
        nameLabel.text = self.name.snakeToClassCase
        nameLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 12)
        nameLabel.textColor = UIColor(white: 1, alpha: 1)
        nameLabel.textAlignment = .Left
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: nameLabel, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 15)
        let right = NSLayoutConstraint(item: nameLabel, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: nameLabel, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: nameLabel, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 20)
        self.addConstraints([left, right, top, height])
    }
    
    public override func updateConstraints() {
        //Dump all the old constraints we added
        for c in autoSpotConstraints.values { c.active = false }
        autoSpotConstraints = WeakValueDictionary<String, NSLayoutConstraint>()
        
        var lastTop: UIView = nameLabel
        for (idx, spot) in autoSpots.values.enumerate() {
            //All are attached to the left and right sides
            let left = NSLayoutConstraint(item: spot, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0)
            let right = NSLayoutConstraint(item: spot, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: 0)

            //Attach it to the 'lastTop', if it's the first one, attach it to
            //the very top of the superview
            if idx == 0 {
                let top = NSLayoutConstraint(item: spot, attribute: .Top, relatedBy: .Equal, toItem: lastTop, attribute: .Bottom, multiplier: 1, constant: 0)
                self.addConstraints([left, right, top])
                autoSpotConstraints[spot.name+".0"] = left
                autoSpotConstraints[spot.name+".1"] = right
                autoSpotConstraints[spot.name+".2"] = top
            } else {
                let top = NSLayoutConstraint(item: spot, attribute: .Height, relatedBy: .Equal, toItem: lastTop, attribute: .Height, multiplier: 1, constant: 0)
                let height = NSLayoutConstraint(item: spot, attribute: .Top, relatedBy: .Equal, toItem: lastTop, attribute: .Bottom, multiplier: 1, constant: 0)
                self.addConstraints([left, right, top, height])
                autoSpotConstraints[spot.name+".0"] = left
                autoSpotConstraints[spot.name+".1"] = right
                autoSpotConstraints[spot.name+".2"] = top
                autoSpotConstraints[spot.name+".3"] = height
            }

            lastTop = spot
        }

        //Last one should be attached to the bottom
        let bottom = NSLayoutConstraint(item: lastTop, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
        autoSpotConstraints["bottom"] = bottom
        self.addConstraint(bottom)
        
        super.updateConstraints()
    }
}
