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
	
	class func loadEntries(category:String) -> AnyObject?
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
			if name != "template"
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
		for (name, entry) in entries
		{
			if name != "template"
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
		
		for (name, entry) in formattedData
		{
			let attacks = entry.0 + entry.1
			print("\(name) has \(attacks) damaging attacks (\(attacks * 100 / total)% of total)")
			print("  \(entry.0 * 100 / attacks)% of those are brute")
			print("  \(entry.1 * 100 / attacks)% of those are clever")
		}
	}
	
	class func attackUsageDiagnostic()
	{
		var attackUses = [String : Int]()
		
		let attackEntries = loadEntries("Attacks") as! [String : [String : AnyObject]]
		for (name, entry) in attackEntries
		{
			if name != "template" && (entry["power points"] as! Int) < 900 //don't count desperation attacks, or the template
			{
				attackUses[name] = 0
			}
		}
		
		let jobEntries = loadEntries("Jobs") as! [String : [String : AnyObject]]
		for (name, entry) in jobEntries
		{
			if name != "template"
			{
				if let attacks = entry["attacks"] as? [String : String]
				{
					//TODO: this doesn't take into account the possibility of a given job
					//getting the same attack twice
					for (_, attack) in attacks
					{
						if attackUses[attack] != nil
						{
							attackUses[attack]! += 1
						}
					}
				}
			}
		}
		
		print("Attack appearances diagnostic:")
		for (attack, number) in attackUses.sort({ $0.1 > $1.1 })
		{
			print("  \(attack) is known by \(number) job(s)")
		}
	}
	
	class func attackPowerDiagnostic()
	{
		var estimatedTierData = [String : (Int, Int, Int)]()
		
		let jobEntries = loadEntries("Jobs") as! [String : [String : AnyObject]]
		for (name, entry) in jobEntries
		{
			if name != "template"
			{
				if let attacks = entry["attacks"] as? [String : String]
				{
					for (level, attack) in attacks
					{
						if loadValue("Attacks", attack, "damage") != nil
						{
							if estimatedTierData[attack] == nil
							{
								estimatedTierData[attack] = (0, 0, 0)
							}
							
							if level.characters.count == 1
							{
								estimatedTierData[attack]!.0 += 1
							}
							else if level.characters.first == "1".characters.first
							{
								estimatedTierData[attack]!.1 += 1
							}
							else if level.characters.first == "2".characters.first
							{
								estimatedTierData[attack]!.2 += 1
							}
						}
					}
				}
			}
		}
		
		let attackEntries = loadEntries("Attacks") as! [String : [String : AnyObject]]
		func displayForType(type:String)
		{
			print("  \(type):")
			displayForTypeForTier(type, tier: 1)
			displayForTypeForTier(type, tier: 2)
			displayForTypeForTier(type, tier: 3)
		}
		
		func displayForTypeForTier(type:String, tier:Int)
		{
			print("    tier \(tier):")
			for (name, entry) in attackEntries
			{
				if name != "template" && entry["damage"] != nil && ((entry["type"] as? String) ?? "typeless") == type && (entry["power points"] as! Int) < 900
				{
					if let etd = estimatedTierData[name]
					{
						var netTier = Float(etd.0)
						netTier += Float(etd.1) * 2
						netTier += Float(etd.2) * 3
						let averageTier = Int(round(netTier / Float(etd.0 + etd.1 + etd.2)))
						if averageTier == tier
						{
							let accuracy = (entry["accuracy"] as? Int) ?? 100
							
							var damage = entry["damage"] as! Int
							damage = (damage * accuracy / 100)
							if averageTier == 2
							{
								damage = damage * 3 / 4
							}
							else if averageTier == 3
							{
								damage /= 2
							}
							
							print("      \(name): adjusted \(damage) damage vs benchmark 14")
						}
					}
				}
			}
		}
		
		print("Attack power diagnostic:")
		displayForType("physical")
		displayForType("astral")
		displayForType("flame")
		displayForType("spark")
		displayForType("frost")
		displayForType("typeless")
	}
	
	class func jobAttackDiagnostic()
	{
		print("Job class distribution diagnostic:")
		
		let entries = loadEntries("Jobs") as! [String : [String : AnyObject]]
		for (name, entry) in entries
		{
			if name != "template"
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
					print("   \(clever[0] * 100 / (clever[0] + clever[1]))% damaging clever")
					print("   \(clever[1] * 100 / (clever[0] + clever[1]))% damaging brute")
				}
			}
		}
	}
}