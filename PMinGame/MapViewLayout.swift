//
//  MapViewLayout.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/11/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class MapViewLayout: UICollectionViewLayout
{
	private var itemAttributes = [[UICollectionViewLayoutAttributes]]()
	private var itemsSize = [CGSize]()
	private var contentSize:CGSize!
	
	override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool
	{
		return true
	}
	
	override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]?
	{
		var attributes = [UICollectionViewLayoutAttributes]()
		for section in itemAttributes
		{
			let filtered = section.filter()
			{
				CGRectIntersectsRect(rect, $0.frame)
			}
			attributes.appendContentsOf(filtered)
		}
		return attributes
	}
	
	override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	{
		return self.itemAttributes[indexPath.section][indexPath.row]
	}
	
	override func collectionViewContentSize() -> CGSize
	{
		return self.contentSize
	}
	
	override func prepareLayout()
	{
		if self.collectionView!.numberOfSections() == 0
		{
			return
		}
		
		//setup attributes
		let rows = self.collectionView!.numberOfSections()
		let columns = self.collectionView!.numberOfItemsInSection(0)
		let size = CGSize(width: 60, height: 60)
		
		if itemAttributes.count == 0
		{
			//initialize all the attributes
			for section in 0..<rows
			{
				var sectionAttributes = [UICollectionViewLayoutAttributes]()
				for index in 0..<columns
				{
					let indexPath = NSIndexPath(forItem: index, inSection: section)
					let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
					attributes.frame = CGRect(x: CGFloat(index) * size.width, y: CGFloat(section) * size.height, width: size.width, height: size.height)
					sectionAttributes.append(attributes)
				}
				itemAttributes.append(sectionAttributes)
			}
			
			contentSize = CGSize(width: size.width * CGFloat(columns), height: size.height * CGFloat(rows))
		}
		
		//just offset the attributes
		for section in 0..<rows
		{
			for index in 0..<columns
			{
				if section == 0 || index == 0
				{
					let attribute = itemAttributes[section][index]
					if section == 0
					{
						attribute.frame.origin.y = self.collectionView!.contentOffset.y
					}
					if index == 0
					{
						attribute.frame.origin.x = self.collectionView!.contentOffset.x
					}
				}
			}
		}
	}
}
