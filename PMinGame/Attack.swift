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
	var mug:Bool
	{
		return contents["mug"] != nil
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
	var message:String
	{
		return PlistService.loadValue("Attacks", attack, "message") as! String
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