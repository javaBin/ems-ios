import UIKit

protocol CommentViewCellDelegate {
    func commentsApplied(comments : String) -> Void;
}

class CommentViewCell: UITableViewCell, UITextViewDelegate {
    var ratingComments : String = ""
    
    var delegate : CommentViewCellDelegate?
    
    @IBOutlet weak var commentsField: UITextView!
    @IBOutlet weak var clearButton: TintButton!

    func updateComments() {
        ratingComments = commentsField.text ?? ""
        
        delegate?.commentsApplied(ratingComments)
    }
    
    @IBAction func clearComments(sender: TintButton) {
        commentsField.text = ""

        updateComments()
    }
    

    func textViewDidChange(textView: UITextView) {
        updateComments()
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
        }
        
        return true
    }
    
    override func layoutSubviews() {
        // If we can get this to work by simply setting it in storyboard then these setImage lines can go.
        // But for some reason setting in storyboard isn't triggering the code for setting tint.
        
        clearButton.setImage(UIImage(named: "298-circlex"), forState: .Normal)
        
        super.layoutSubviews()
        
        commentsField.text = ratingComments
    }
}
