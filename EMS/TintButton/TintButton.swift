import UIKit

class TintButton: UIButton {
    override var selected: Bool {
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

    func setImage(baseName: String) {
        var normalImage = UIImage(named: "\(baseName)-grey")
        var selectedImage = UIImage(named: "\(baseName)-yellow")

        if (UIImage.instancesRespondToSelector("imageWithRenderingMode:")) {
            normalImage = normalImage?.imageWithRenderingMode(.AlwaysTemplate)
            selectedImage = selectedImage?.imageWithRenderingMode(.AlwaysTemplate)
        }

        self.setImage(normalImage, forState:.Normal)
        self.setImage(selectedImage, forState:.Selected)
    }
}
