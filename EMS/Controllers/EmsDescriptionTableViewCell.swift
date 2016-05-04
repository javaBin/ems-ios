//
//  EmsDescriptionTableViewCell.swift
//  EMS
//
//  Created by Jobb on 03.10.2015.
//  Copyright © 2015 Chris Searle. All rights reserved.
//

import Foundation
import UIKit

class EmsDescriptionTableViewCell : UITableViewCell {
    
    @IBOutlet weak var preface: UILabel!
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var intendedAudienceTitle: UILabel!
    @IBOutlet weak var intentedAudienceBody: UILabel!
    
    internal var session : Session? {
        didSet {
            updateView()
        }
    }
    
    func updateView() {
        self.accessibilityLanguage = session?.language;
        
        preface.hidden = session?.summary == nil
        preface.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        if session?.summary != nil {
            preface.text = session?.summary
        }
        
        body.hidden = session?.body == nil
        body.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        if session?.body != nil {
            body.text = session?.body
        }
        
        intendedAudienceTitle.hidden = session?.audience == nil
        intendedAudienceTitle.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        
        intentedAudienceBody.hidden = session?.audience == nil
        intentedAudienceBody.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        
        if session?.audience != nil {
            intendedAudienceTitle.text = NSLocalizedString("Intended Audience", comment: "Subtitle for detail view for audience")
            intentedAudienceBody.text = self.session?.audience
        }
        
    }
}