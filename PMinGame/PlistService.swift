//
//  PlistService.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/3/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class PlistService
{
	class func loadColor(colorCode:String!) -> UIColor
	{
		if colorCode == nil
		{
			return UIColor.whiteColor()
		}
		
		let rString = colorCode.substringToIndex(colorCode.startIndex.advancedBy(2))
		let gString = colorCode.substringFromIndex(colorCode.startIndex.advancedBy(2)).substringToIndex(colorCode.startIndex.advancedBy(2))
		let bString = colorCode.substringFromIndex(colorCode.startIndex.advancedBy(4)).substringToIndex(colorCode.startIndex.advancedBy(2))
		var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0
		NSScanner(string: rString).scanHexInt(&r)
		NSScanner(string: gString).scanHexInt(&g)
		NSScanner(string: bString).scanHexInt(&b)
		
		return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1)
	}

	class func loadValueFlat(category:String, _ entry:String) -> AnyObject?
	{
		let p = NSBundle.mainBundle().pathForResource(category, ofType: "plist")
		let d = NSDictionary(contentsOfFile: p!)
		return d!.valueForKey(entry)
	}

	class func loadValue(category:String, _ entry:String, _ key:String) -> AnyObject?
	{
		if let e = loadValueFlat(category, entry) as? NSDictionary
		{
			return e.valueForKey(key)
		}
		else
		{
			//that entry does not exist
			return nil
		}
	}
}