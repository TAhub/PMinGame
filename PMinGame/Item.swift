//
//  Item.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/7/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

class Item
{
	let type:String
	var number = 1
	
	init(type:String)
	{
		self.type = type
	}
	
	//MARK: computed properties
	var heals:Int?
	{
		return PlistService.loadValue("Items", type, "heals") as? Int
	}
	var cureSteps:Bool
	{
		return PlistService.loadValue("Items", type, "cure steps") != nil
	}
	var cureStatus:Bool
	{
		return PlistService.loadValue("Items", type, "cure status") != nil
	}
	var targetsAlive:Bool
	{
		return PlistService.loadValue("Items", type, "targets alive") != nil
	}
	var targetsDead:Bool
	{
		return PlistService.loadValue("Items", type, "targets dead") != nil
	}
}