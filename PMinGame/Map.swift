//
//  Map.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/10/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation

protocol MapDelegate
{
	func playerMoved(completion:()->())
	func startBattle()
	func partyDamageEffect()
}

let kMaxFloor = 3
let kEncounterChance:UInt32 = 13
let kPartyDamagePercent = 5

class Map
{
	var delegate:MapDelegate!
	
	//map variables
	var width:Int!
	var tiles:[[Tile]]!
	let floor:Int
	let mapType:String
	let encounterType:String
	let difficulty:Int
	
	//map content variables
	var party = [Creature]()
	var reserve = [Creature]()
	
	var partyPosition:(Int, Int)
	var enemyEncounters = [(Int, Int)]()
	
	init(from:Map?)
	{
		if let from = from
		{
			if from.floor < kMaxFloor && arc4random_uniform(100) < 45
			{
				//this is a continuation of the previous map type
				floor = from.floor + 1
				encounterType = from.encounterType
				mapType = from.mapType
			}
			else
			{
				//this is a new map entirely
				floor = 1
				
				func pickFromFlat(flat:[String : AnyObject]) -> String
				{
					var possibilities = [String]()
					for (name, _) in flat
					{
						if name != "template"
						{
							possibilities.append(name)
						}
					}
					let pick = Int(arc4random_uniform(UInt32(possibilities.count)))
					return possibilities[pick]
				}
				
				//pick an encounter type
				let encountersFlat = PlistService.loadEntries("EncounterGenerator") as! [String : AnyObject]
				encounterType = pickFromFlat(encountersFlat)
				
				//pick a map generator
				let typesFlat = PlistService.loadEntries("Maps") as! [String : AnyObject]
				mapType = pickFromFlat(typesFlat)
			}

			//and, no matter if it's a continuation or not, this should be one difficulty higher
			difficulty = from.difficulty + 1
		}
		else
		{
			//the starting map type
			floor = 1
			mapType = "meadows"
			encounterType = "bandits"
			difficulty = 1
		}
		
		
		//initialize the map and party position
		let results = MapCurator.makeMap(mapType)
		tiles = results.0
		width = results.1
		partyPosition = results.2
	}
	
	private func partyDamage()
	{
		//damage every non-hardy party member
		//including people in the reserve
		func partyDamageOne(person:Creature) -> Bool
		{
			if !person.jobHardy && person.health > 1
			{
				let damage = min(person.health - 1, person.maxHealth * kPartyDamagePercent / 100)
				person.health -= damage
				return damage > 0
			}
			return false
		}
		
		var hurtAnybody = false
		for p in party
		{
			hurtAnybody = partyDamageOne(p) || hurtAnybody
		}
		for r in reserve
		{
			hurtAnybody = partyDamageOne(r) || hurtAnybody
		}
		
		//only play this effect if people are actually being hurt
		if hurtAnybody
		{
			delegate.partyDamageEffect()
		}
	}
	
	func moveTo(to: (Int, Int))
	{
		if abs(partyPosition.0 - to.0) + abs(partyPosition.1 - to.1) == 1 && !tiles[to.1][to.0].solid
		{
			//move there
			partyPosition.0 = to.0
			partyPosition.1 = to.1
			delegate.playerMoved()
			{
				//move effects
				if self.tiles[to.1][to.0].damaging
				{
					self.partyDamage()
				}
				if self.tiles[to.1][to.0].encounters && arc4random_uniform(100) < kEncounterChance
				{
					self.delegate.startBattle()
				}
			}
		}
	}
}