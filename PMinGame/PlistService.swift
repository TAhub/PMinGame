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
	
	private class func loadEntries(category:String) -> AnyObject?
	{
		let p = NSBundle.mainBundle().pathForResource(category, ofType: "plist")
		return NSDictionary(contentsOfFile: p!)
	}

	class func loadValueFlat(category:String, _ entry:String) -> AnyObject?
	{
		return loadEntries(category)!.valueForKey(entry)
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
	
	
	//diagnostics
	class func jobStatDiagnostic()
	{
		print("Job stat balance diagnostic:")
		
		let entries = loadEntries("Jobs") as! [String : [String : AnyObject]]
		for (name, entry) in entries
		{
			var points = 0
			points += (entry["health"] as! Int) * 2
			points += ((entry["accuracy"] as! Int) + (entry["dodge"] as! Int)) * 10
			points += ((entry["brute attack"] as! Int) + (entry["brute defense"] as! Int)) * 5
			points += ((entry["clever attack"] as! Int) + (entry["clever defense"] as! Int)) * 5
			print("\(name): \(points)")
		}
	}
}