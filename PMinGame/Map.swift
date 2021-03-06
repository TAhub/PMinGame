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
	func startBattle(type:BattleType)
	func partyDamageEffect()
	func nextMap()
	func walkerAttack(num:Int)
}

let kMaxFloor = 3
let kEncounterChance:UInt32 = 27
let kPartyDamagePercent = 5
let kMaxSightline = 4

func saveInventory(items:[Item])
{
	let d = NSUserDefaults.standardUserDefaults()
	
	d.setInteger(items.count, forKey: "items")
	for i in 0..<items.count
	{
		d.setInteger(items[i].number, forKey: "items\(i)Number")
		d.setObject(items[i].type, forKey: "items\(i)Type")
	}
}

func loadInventory()->[Item]
{
	let d = NSUserDefaults.standardUserDefaults()
	
	var items = [Item]()
	let numItems = d.integerForKey("items")
	for i in 0..<numItems
	{
		let number = d.integerForKey("items\(i)Number")
		let type = d.stringForKey("items\(i)Type")!
		let it = Item(type: type)
		it.number = number
		items.append(it)
	}
	return items
}

class Map
{
	var delegate:MapDelegate!
	
	//map variables
	var width:Int!
	var tiles:[[Tile]]!
	var floor:Int!
	var mapType:String!
	var encounterType:String!
	var difficulty:Int!
	var name:String = "MAP NAME HERE"
	
	//map content variables
	var party = [Creature]()
	var reserve = [Creature]()
	var money:Int = 0
	var items = [Item]()
	
	var partyPosition:(Int, Int)!
	var enemyEncounters = [(Int, Int)]()
	
	init(from:Map?)
	{
		if saveState != kSaveStateNone
		{
			//load the map from a save
			load()
		}
		else
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
			enemyEncounters = results.3
		}
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
			
			saveParty()
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
				if self.tiles[to.1][to.0].gate
				{
					self.delegate.nextMap()
				}
				else
				{
					if self.tiles[to.1][to.0].damaging
					{
						self.partyDamage()
					}
					if self.tiles[to.1][to.0].encounters && arc4random_uniform(100) < kEncounterChance
					{
						self.delegate.startBattle(BattleType.Normal)
					}
					
					//did you catch the attention of anything?
					//traps only activate if you DON'T fight someone
					if !self.spotCheck(true)
					{
						self.spotCheck(false)
					}
				}
			}
			
			//save the walkers
			saveWalkers()
		}
	}
	
	private func spotCheck(encounter:Bool)->Bool
	{
		var blocked = [false, false, false, false]
		for i in 1...kMaxSightline
		{
			//check in every direction
			for j in 0..<4
			{
				if !blocked[j]
				{
					var x2 = partyPosition.0
					var y2 = partyPosition.1
					switch(j)
					{
					case 0: x2 -= i
					case 1: x2 += i
					case 2: y2 -= i
					case 3: y2 += i
					default: break
					}
					
					if y2 < 0 || x2 < 0 || y2 >= tiles.count || x2 >= width || tiles[y2][x2].solid
					{
						//the sightline is blocked
						blocked[j] = true
					}
					else if encounter
					{
						//check for encounters here
						for (i, encounter) in enemyEncounters.enumerate()
						{
							if encounter.0 == x2 && encounter.1 == y2
							{
								delegate.walkerAttack(i)
								return true
							}
						}
					}
				}
			}
		}
		
		return false
	}
	
	//MARK: save and load
	func save()
	{
		let d = NSUserDefaults.standardUserDefaults()
		
		//save metadata
		d.setObject(mapType, forKey: "mapType")
		d.setObject(encounterType, forKey: "mapEncounterType")
		d.setObject(name, forKey: "mapName")
		d.setInteger(floor, forKey: "mapFloor")
		d.setInteger(difficulty, forKey: "mapDifficulty")
		
		//save tiles
		d.setInteger(width, forKey: "mapWidth")
		d.setInteger(tiles.count, forKey: "mapHeight")
		let flattened = tiles.reduce([String]())
		{ (first, next) in
			let strA = next.map() { $0.type }
			return first + strA
		}
		d.setObject(flattened, forKey: "mapTiles")
		
		//save walkers
		saveWalkers()
		
		//save party
		saveParty()
		
		//save inventory
		saveInventory(items)
	}
	
	private func load()
	{
		let d = NSUserDefaults.standardUserDefaults()
		
		//load metadata
		mapType = d.stringForKey("mapType")
		encounterType = d.stringForKey("mapEncounterType")
		name = d.stringForKey("mapName")!
		floor = d.integerForKey("mapFloor")
		difficulty = d.integerForKey("mapDifficulty")
		
		//load tiles
		width = d.integerForKey("mapWidth")
		let height = d.integerForKey("mapHeight")
		let mapTiles = d.stringArrayForKey("mapTiles")!
		tiles = [[Tile]]()
		for y in 0..<height
		{
			var row = [Tile]()
			for x in 0..<width
			{
				row.append(Tile(type: mapTiles[x + y * width]))
			}
			tiles.append(row)
		}
		
		//load walkers
		loadWalkers()
		
		//load party
		loadParty()
		
		//load inventory
		items = loadInventory()
	}
	
	private func saveWalkers()
	{
		let d = NSUserDefaults.standardUserDefaults()
		
		d.setInteger(partyPosition.0, forKey: "mapPartyX")
		d.setInteger(partyPosition.1, forKey: "mapPartyY")
		
		d.setInteger(enemyEncounters.count, forKey: "mapEncounters")
		for i in 0..<enemyEncounters.count
		{
			d.setInteger(enemyEncounters[i].0, forKey: "mapEncounters\(i)X")
			d.setInteger(enemyEncounters[i].1, forKey: "mapEncounters\(i)Y")
		}
	}
	
	private func loadWalkers()
	{
		let d = NSUserDefaults.standardUserDefaults()
		
		let pX = d.integerForKey("mapPartyX")
		let pY = d.integerForKey("mapPartyY")
		partyPosition = (pX, pY)
		
		let encounters = d.integerForKey("mapEncounters")
		for i in 0..<encounters
		{
			let eX = d.integerForKey("mapEncounters\(i)X")
			let eY = d.integerForKey("mapEncounters\(i)Y")
			enemyEncounters.append(eX, eY)
		}
	}
	
	func saveParty()
	{
		let d = NSUserDefaults.standardUserDefaults()
	
		d.setInteger(money, forKey: "partyMoney")
		d.setInteger(party.count, forKey: "partySize")
		d.setInteger(reserve.count, forKey: "reserveSize")
		
		for i in 0..<party.count
		{
			savePartyMember(party[i], party: true, number: i)
		}
		for i in 0..<reserve.count
		{
			savePartyMember(reserve[i], party: false, number: i)
		}
	}
	
	private func loadParty()
	{
		let d = NSUserDefaults.standardUserDefaults()
		
		money = d.integerForKey("partyMoney")
		let partySize = d.integerForKey("partySize")
		let reserveSize = d.integerForKey("reserveSize")
		for i in 0..<partySize
		{
			party.append(Creature(string: d.stringForKey("party\(i)")!))
		}
		for i in 0..<reserveSize
		{
			reserve.append(Creature(string: d.stringForKey("party\(i)")!))
		}
	}
}