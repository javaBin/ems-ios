import UIKit

public class RatingViewController: UITableViewController, RatingViewCellDelegate, CommentViewCellDelegate {
    public var rating : Rating? = nil
    
    var sections : Array = [
        [
            "title": "Overall",
            "rating": 0
        ],
        [
            "title": "Relevance",
            "rating": 0
        ],
        [
            "title": "Content",
            "rating": 0
        ],
        [
            "title": "Quality",
            "rating": 0
        ]
    ]
    
    var comments = ""
    
    public override func viewDidAppear(animated: Bool) {
        EMSTracking.trackScreen("Rating Screen")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentRating = rating {
            sections[0]["rating"] = currentRating.overall
            sections[1]["rating"] = currentRating.relevance
            sections[2]["rating"] = currentRating.content
            sections[3]["rating"] = currentRating.quality
            comments = currentRating.comments
        }
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count + 1
    }
    
    public override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        if (section < sections.count) {
            if let title = sections[section]["title"] as? String {
                return title
            } else {
                return ""
            }
        } else {
            return "Comments"
        }
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section < sections.count) {
            let cell = tableView.dequeueReusableCellWithIdentifier("RatingViewCell", forIndexPath: indexPath) as! RatingViewCell
        
            cell.section = indexPath.section
            cell.rating = sections[indexPath.section]["rating"] as! Int
            cell.delegate = self
        
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("CommentViewCell", forIndexPath: indexPath) as! CommentViewCell

            cell.ratingComments = comments
            cell.delegate = self
            
            return cell
        }
    }
    
    public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.section < sections.count) {
            return 44
        } else {
            return 120
        }
    }
    
    func ratingApplied(section: Int, rating: Int) {
        sections[section]["rating"] = rating
    }
    
    func commentsApplied(comments: String) {
        self.comments = comments
    }
}
