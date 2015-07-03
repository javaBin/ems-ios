import UIKit

class RatingViewCell: UITableViewCell {
    @IBOutlet weak var rating1: UIButton!
    @IBOutlet weak var rating2: UIButton!
    @IBOutlet weak var rating3: UIButton!
    @IBOutlet weak var rating4: UIButton!
    @IBOutlet weak var rating5: UIButton!
    
    var delegate : RatingViewCellDelegate? = nil
    
    var section : Int = -1;
    
    var rating : Int = 0
    
    @IBAction func ratingButtonClick(sender: UIButton) {
        switch sender {
        case rating1:
            rating = 1
        case rating2:
            rating = 2
        case rating3:
            rating = 3
        case rating4:
            rating = 4
        case rating5:
            rating = 5
        default:
            rating = 0
        }
        
        updateView()
        
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
        super.layoutSubviews()
        
        updateView()
    }
}
