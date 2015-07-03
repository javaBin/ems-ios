import UIKit

public class RatingViewController: UITableViewController, RatingViewCellDelegate {
    public var rating : Rating? = nil
    
    var sections = [
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
    
    public override func viewDidAppear(animated: Bool) {
        EMSTracking.trackScreen("Rating Screen")
        
        Log.debug("\(rating)")
        
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentRating = rating {
            sections[0]["rating"] = currentRating.overall
            sections[1]["rating"] = currentRating.relevance
            sections[2]["rating"] = currentRating.content
            sections[3]["rating"] = currentRating.quality
        }
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    public override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return sections[section]["title"] as! String
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RatingViewCell", forIndexPath: indexPath) as! RatingViewCell
        
        cell.section = indexPath.section
        cell.rating = sections[indexPath.section]["rating"] as! Int
        cell.delegate = self
        
        return cell
    }
    
    func ratingApplied(section: Int, rating: Int) {
        sections[section]["rating"] = rating
    }
}
