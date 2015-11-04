//
//  Attack.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/3/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

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
	
	//diagnostics
	var label:String
	{
		return "\(attack) (\(powerPoints)/\(maxPowerPoints))"
	}
}