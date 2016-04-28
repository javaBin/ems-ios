import UIKit

protocol RatingViewCellDelegate {
    func ratingApplied(section: Int, rating: Int) -> Void;
}

class RatingViewCell: UITableViewCell {
    @IBOutlet weak var rating1: TintButton!
    @IBOutlet weak var rating2: TintButton!
    @IBOutlet weak var rating3: TintButton!
    @IBOutlet weak var rating4: TintButton!
    @IBOutlet weak var rating5: TintButton!
    @IBOutlet weak var clearButton: TintButton!
    
    var delegate : RatingViewCellDelegate? = nil
    
    var section : Int = -1;
    
    var rating : Int = 0
    
    @IBAction func ratingButtonClick(sender: TintButton) {
        switch sender {
        case rating1:
            applyRating(1)
        case rating2:
            applyRating(2)
        case rating3:
            applyRating(3)
        case rating4:
            applyRating(4)
        case rating5:
            applyRating(5)
        default:
            applyRating(0)
        }
        
        updateView()
        
        delegate?.ratingApplied(section, rating: rating)
    }
    
    @IBAction func clearRating(sender: TintButton) {
        applyRating(0)
        
        updateView()

    }
    
    func applyRating(newRating: Int) {
        rating = newRating
        
        delegate?.ratingApplied(section, rating: rating)
    }
    
    func updateView() {
        rating1.selected = rating >= 1
        rating2.selected = rating >= 2
        rating3.selected = rating >= 3
        rating4.selected = rating >= 4
        rating5.selected = rating >= 5
    }
    
    override func layoutSubviews() {
        // If we can get this to work by simply setting it in storyboard then these setImage lines can go.
        // But for some reason setting in storyboard isn't triggering the code for setting tint.
        
        rating1.setImage("28-star")
        rating2.setImage("28-star")
        rating3.setImage("28-star")
        rating4.setImage("28-star")
        rating5.setImage("28-star")
        clearButton.setImage(UIImage(named: "298-circlex"), forState: .Normal)

        super.layoutSubviews()
        
        updateView()
    }
}
