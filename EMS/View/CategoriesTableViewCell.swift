//
//  CollectionTableViewCell.swift
//  EMS
//
//  Created by Jobb on 03.10.2015.
//  Copyright © 2015 Chris Searle. All rights reserved.
//

import Foundation
import UIKit

class CategoriesTableViewCell : UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView : UICollectionView!
    
    internal var categories : NSArray = NSArray() {
        didSet {
            self.collectionView .reloadData()
        }
    }
    
    internal var level : String? {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.dataSource = self;
        collectionView.delegate = self;
    }
    

   
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.categories.count + 1
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell : TypeLabelCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("TypeLabelCell", forIndexPath: indexPath) as! TypeLabelCollectionViewCell
        cell.typeLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        
        if indexPath.row == 0 {
            let colors = EMSSessionCell.colorsForLevel(level) as NSArray
            cell.typeLabel.labelBackgroundColor = colors[0] as? UIColor
            cell.typeLabel.text = level?.capitalizedString.stringByReplacingOccurrencesOfString("-", withString: " ")
        } else {
            let keyword : Keyword? = self.categories.objectAtIndex(indexPath.row - 1) as? Keyword
            let colors = EMSSessionCell.colorsForLevel(level) as NSArray
            cell.typeLabel.labelBackgroundColor = UIColor.lightGrayColor()
            cell.typeLabel.text = keyword?.name
        }
        
        return cell
    }
   
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let label = TypeLabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        
        if indexPath.row == 0 {
            label.text = self.level
        } else {
            label.text = self.categories[indexPath.row - 1].name
        }
        
        return label.intrinsicContentSize()
    }
}