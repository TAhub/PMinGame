//
//  Attack.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/3/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

struct AttackEffect
{
	private let contents:[String : AnyObject]
	
	//get the contents
	var attackStep:Int?
	{
		return contents["attack steps"] as? Int
	}
	var defenseStep:Int?
	{
		return contents["defense steps"] as? Int
	}
	var accuracyStep:Int?
	{
		return contents["accuracy steps"] as? Int
	}
	var dodgeStep:Int?
	{
		return contents["dodge steps"] as? Int
	}
	var paralysisChance:Int?
	{
		return contents["paralysis chance"] as? Int
	}
	var freezeChance:Int?
	{
		return contents["freeze chance"] as? Int
	}
	var bleedChance:Int?
	{
		return contents["bleed chance"] as? Int
	}
	var burningChance:Int?
	{
		return contents["burning chance"] as? Int
	}
	var sleepChance:Int?
	{
		return contents["sleep chance"] as? Int
	}
	var confusionChance:Int?
	{
		return contents["confusion chance"] as? Int
	}
	var nonlethal:Bool
	{
		return contents["nonlethal"] != nil
	}
	var cleanse:Bool
	{
		return contents["cleanse"] != nil
	}
}

class Attack
{
	let attack:String
	var powerPoints:Int = 0
	
	init(attack:String)
	{
		self.attack = attack
	}
	
	//derived variables
	var damage:Int?
	{
		return PlistService.loadValue("Attacks", attack, "damage") as? Int
	}
	var accuracy:Int?
	{
		return PlistService.loadValue("Attacks", attack, "accuracy") as? Int
	}
	var type:String?
	{
		return PlistService.loadValue("Attacks", attack, "type") as? String
	}
	var maxPowerPoints:Int
	{
		return PlistService.loadValue("Attacks", attack, "power points") as! Int
	}
	var upgradeFor:String?
	{
		return PlistService.loadValue("Attacks", attack, "upgrade for") as? String
	}
	var clever:Bool
	{
		return PlistService.loadValue("Attacks", attack, "clever") != nil
	}
	var ranged:Bool
	{
		return PlistService.loadValue("Attacks", attack, "ranged") != nil
	}
	var quick:Bool
	{
		return PlistService.loadValue("Attacks", attack, "quick") != nil
	}
	var leech:Bool
	{
		return PlistService.loadValue("Attacks", attack, "leech") != nil
	}
	var mug:Bool
	{
		return PlistService.loadValue("Attacks", attack, "mug") != nil
	}
	var freeOnMiss:Bool
	{
		return PlistService.loadValue("Attacks", attack, "free on miss") != nil
	}
	var description:String
	{
		let baseD = PlistService.loadValue("Attacks", attack, "description") as! String
		let tier = PlistService.loadValue("Attacks", attack, "tier") as! Int
		
		var d = "This "
		switch(tier)
		{
		case 1: d += "basic "
		case 2: d += "intermediate "
		case 3: d += "advanced "
		default: break
		}
		
		if damage != nil
		{
			if clever
			{
				d += "special "
			}
			
			d += "attack "
		}
		else
		{
			d += "technique "
		}
		
		//add the base description
		d += baseD
		
		//and add damage and accuracy info
		var dString = ""
		var aString = ""
		if let damage = damage
		{
			dString = "\(damage) damage   "
		}
		if let accuracy = accuracy
		{
			aString = "\(accuracy)% accuracy"
		}
		else if damage != nil || enemyEffects != nil
		{
			aString = "never misses"
		}
		
		if !dString.isEmpty || !aString.isEmpty
		{
			d += "\n"
		}
		d += dString
		d += aString
		
		return d
	}
	var message:String
	{
		return PlistService.loadValue("Attacks", attack, "message") as! String
	}
	var missMessage:String
	{
		return PlistService.loadValue("Attacks", attack, "miss message") as! String
	}
	var userEffects:AttackEffect?
	{
		if let contents = PlistService.loadValue("Attacks", attack, "user effects") as? [String : AnyObject]
		{
			return AttackEffect(contents: contents)
		}
		return nil
	}
	var enemyEffects:AttackEffect?
	{
		if let contents = PlistService.loadValue("Attacks", attack, "enemy effects") as? [String : AnyObject]
		{
			return AttackEffect(contents: contents)
		}
		return nil
	}
	
	//diagnostics
	var label:String
	{
		if powerPoints > 100
		{
			//it's basically infinite, so don't list the power points at all
			return attack
		}
		else
		{
			return "\(attack) (\(powerPoints)/\(maxPowerPoints))"
		}
	}
}