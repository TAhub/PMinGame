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
	//MARK: value handlers
	class func loadImage(sprite:String) -> UIImage?
	{
		return UIImage(named: sprite)
	}
	
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
	
	
	//MARK: diagnostics
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
	
	class func attackDiagnostic()
	{
		print("Attack type distribution diagnostic:")
		
		var formattedData = [String : (Int, Int)]()
		formattedData["physical"] = (0, 0)
		formattedData["flame"] = (0, 0)
		formattedData["spark"] = (0, 0)
		formattedData["frost"] = (0, 0)
		formattedData["astral"] = (0, 0)
		formattedData["typeless"] = (0, 0)
		
		var total = 0
		let entries = loadEntries("Attacks") as! [String : [String : AnyObject]]
		for (_, entry) in entries
		{
			//ignore non-damaging attacks, their types are irrelevant
			if entry["damage"] != nil
			{
				let type = (entry["type"] as? String) ?? "typeless"
				if entry["clever"] != nil
				{
					formattedData[type]!.1 += 1
				}
				else
				{
					formattedData[type]!.0 += 1
				}
				total += 1
			}
		}
		
		
	}
	
	class func jobAttackDiagnostic()
	{
		print("Job class distribution diagnostic:")
		
		let entries = loadEntries("Jobs") as! [String : [String : AnyObject]]
		for (name, entry) in entries
		{
			var types = [String : Int]()
			var clever = [0, 0]
			var levels = [0, 0, 0]
			if let attacks = entry["attacks"] as? [String : String]
			{
				print("\(name) has \(attacks.count) attacks:")
				
				for (level, attack) in attacks
				{
					if let attack = loadValueFlat("Attacks", attack) as? NSDictionary
					{
						let type = (attack["type"] as? String) ?? "untyped"
						types[type] = (types[type] ?? 0) + 1
						levels[Int(level)! / 10] += 1
						if attack["damage"] != nil
						{
							clever[(attack["clever"] != nil ? 0 : 1)] += 1
						}
					}
					else
					{
						print("   Invalid attack \(attack)!")
					}
				}
				
				for (type, amount) in types
				{
					print("   \(amount * 100 / attacks.count)% \(type)")
				}
				print("")
				for i in 0..<levels.count
				{
					print("   \(levels[i] * 100 / attacks.count)% tier \(i + 1)")
				}
				print("")
				print("   \(clever[0] * 100 / (clever[0] + clever[1]))% clever")
				print("   \(clever[1] * 100 / (clever[0] + clever[1]))% brute")
			}
		}
	}
}