//
//  MapViewLayout.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/11/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

let kTileSize = CGSize(width: 60, height: 60)

class MapViewLayout: UICollectionViewLayout
{
	//I was following
	//http://www.brightec.co.uk/ideas/uicollectionview-using-horizontal-and-vertical-scrolling-sticky-rows-and-columns
	//but it didn't seem to work?
	//I tried messing with it some but eh
	//try again later I guess
	
	override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool
	{
		return false
	}
	
	override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]?
	{
		var attributes = [UICollectionViewLayoutAttributes]()
		for section in 0..<collectionView!.numberOfSections()
		{
			for row in 0..<collectionView!.numberOfItemsInSection(section)
			{
				let attr = layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: row, inSection: section))!
				if attr.frame.intersects(rect)
				{
					attributes.append(attr)
				}
			}
		}
		return attributes
	}
	
	override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
	{
		let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
		attributes.frame = CGRect(x: kTileSize.width * CGFloat(indexPath.row), y: kTileSize.height * CGFloat(indexPath.section), width: kTileSize.width, height: kTileSize.height)
		return attributes
	}
	
	override func collectionViewContentSize() -> CGSize
	{
		return CGSize(width: kTileSize.width * CGFloat(collectionView!.numberOfItemsInSection(0)), height: kTileSize.height * CGFloat(collectionView!.numberOfSections()))
	}
}
