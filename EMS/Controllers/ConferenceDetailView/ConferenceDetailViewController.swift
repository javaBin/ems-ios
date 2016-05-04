import UIKit
import CocoaLumberjack

class ConferenceDetailViewController: UITableViewController {
    var conference : Conference?
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        EMSTracking.trackScreen("Conference Detail Screen")
    }
}

extension ConferenceDetailViewController {
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return indexPath.section == 1 ? indexPath : nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.section == 1 && indexPath.row == 0) {
            
            let alert = UIAlertController(title: NSLocalizedString("Delete all sessions", comment: "Delete Conference Confirmation Dialog Title"),
                                          message: NSLocalizedString("This will remove all sessions including any favourite marks. Session information will then have to be downloaded again.", comment: "Delete Conference Confirmation Dialog Description"),
                                          preferredStyle: .Alert)
            

            let action = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Delete Conference Confirmation Dialog Cancel"),
                                       style: .Default, handler: nil)
            
            let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete Conference Confirmation Dialog Delete"),
                                             style: .Destructive, handler: { (action) in
                                                
                                                DDLogVerbose("Deleting all sessions for conference \(self.conference!.href)")
                                                
                                                EMSAppDelegate.sharedAppDelegate().model.clearConference(self.conference!)

                                                tableView.reloadData()
            })

            alert.addAction(action)
            alert.addAction(deleteAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

extension ConferenceDetailViewController  {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return conference!.sessions!.count > 0 ? 2 : 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            if let _ = conference!.start, _ = conference!.end {
                return 4
            } else {
                return 3
            }
        case 1:
            return 1;
        default:
            return 0;
        }
    }
    
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        switch (indexPath.row) {
            
        case 0:
            cell.textLabel!.text = NSLocalizedString("Name", comment: "Conference detail name label.")
            cell.detailTextLabel!.text = conference!.name
            
        case 1:
            cell.textLabel!.text = NSLocalizedString("Venue", comment: "Conference detail venue label.")
            cell.detailTextLabel!.text = conference!.venue

        case 2:
            cell.textLabel!.text = NSLocalizedString("# Sessions", comment: "Conference detail #Sessions label.")

            if (conference!.sessions!.count > 0) {
                cell.detailTextLabel!.text = "\(conference!.sessions!.count)"
            } else {
                let string = String.localizedStringWithFormat(NSLocalizedString("~ %@ available for download",
                    comment: "~ {Number of sessions} available for download"), conference!.hintCount!)
                
                cell.detailTextLabel!.text = string
            }

        case 3:
            cell.textLabel!.text = NSLocalizedString("Dates", comment: "Conference detail dates label.")

            let dateFormatter = NSDateFormatter()

            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .NoStyle

            cell.detailTextLabel!.text = [conference!.start, conference!.end].filter({ date in
                date != nil
            }).map({ (date : NSDate?) in
                dateFormatter.stringFromDate(date!)
            }).joinWithSeparator(" - ")
            
        default: break
        }
    }
    
    func configureActionCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == 0) {
            cell.textLabel!.text = NSLocalizedString("Delete all sessions", comment: "Conference detail delete all sessions button title.")
            cell.textLabel!.textColor = UIColor.redColor()
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell?
        
        switch (indexPath.section) {
        case 0:
            cell = tableView.dequeueReusableCellWithIdentifier("ConferenceDetailCell")
            
            if (cell == nil) {
                cell = UITableViewCell(style: .Value2, reuseIdentifier: "ConferenceDetailCell")
            }
            
            configureCell(cell!, atIndexPath: indexPath)
        case 1:
            cell = tableView.dequeueReusableCellWithIdentifier("ConferenceDetailActionCell")
            
            if (cell == nil) {
                cell = UITableViewCell(style: .Default, reuseIdentifier: "ConferenceDetailActionCell")
            }
            
            configureActionCell(cell!, atIndexPath: indexPath)

        default: break
        }
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {

        case 0:
            return NSLocalizedString("Details", comment: "Conference Details Section Header")
            
        case 1:
            return NSLocalizedString("Actions", comment: "Conference Actions Section Header")
            
        default:
            return ""
        }
    }
    
}
