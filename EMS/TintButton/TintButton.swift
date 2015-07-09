import UIKit

public class TintButton: UIButton {
    public override var selected: Bool {
        didSet {
            if (UIImage.instancesRespondToSelector("imageWithRenderingMode:")) {
                if (self.selected) {
                    self.tintColor = nil
                } else {
                    self.tintColor = UIColor.lightGrayColor()
                }
            }
        }
    }
    
    public override func setImage(image: UIImage?, forState state: UIControlState) {
        var img : UIImage? = image
        
        if (UIImage.instancesRespondToSelector("imageWithRenderingMode:")) {
            img = img?.imageWithRenderingMode(.AlwaysTemplate)
        }

        super.setImage(img, forState: state)
    }
    
    public func setImage(name: String) {
        self.setImage(UIImage(named: "\(name)-grey"), forState:.Normal)
        self.setImage(UIImage(named: "\(name)-yellow"), forState:.Selected)
    }
}
