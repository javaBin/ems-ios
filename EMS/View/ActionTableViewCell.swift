//
//  ActionTableViewCell.swift
//  EMS
//
//  Created by Jobb on 03.10.2015.
//  Copyright © 2015 Chris Searle. All rights reserved.
//

import Foundation
import UIKit


public class ActionTableViewCellAction : NSObject {
    
    init(title: String?, handler: () -> Void) {
        self.title = title
        self.handler = handler
        super.init()
    }
    
    var title: String?
    var handler: () -> Void
}

@IBDesignable
class ActionTableViewCell : UITableViewCell {
    
    @IBOutlet private weak var titleLabel : UILabel!
    
    var rowAction : ActionTableViewCellAction? {
        didSet {
            updateValues()
        }
    }
    
    override func tintColorDidChange() {
        self.titleLabel.textColor = self.tintColor
    }
    
    private func updateValues() {
        self.titleLabel.text = self.rowAction?.title
    }
    
    override func prepareForInterfaceBuilder() {
        
    }
}

