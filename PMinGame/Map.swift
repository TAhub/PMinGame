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
	func playerMoved()
	
}

class Map
{
	var delegate:MapDelegate!
	
	//map variables
	var width:Int!
	var tiles:[[Tile]]!
	
	//map content variables
	var party = [Creature]()
	var reserve = [Creature]()
	
	var partyPosition:(Int, Int)
	var enemyEncounters = [(Int, Int)]()
	
	init()
	{
		//initialize the map and party position
		let results = MapCurator.makeMap("meadows")
		tiles = results.0
		width = results.1
		partyPosition = results.2
	}
	
	func moveTo(to: (Int, Int))
	{
		if abs(partyPosition.0 - to.0) + abs(partyPosition.1 - to.1) == 1 && !tiles[to.1][to.0].solid
		{
			//move there
			partyPosition.0 = to.0
			partyPosition.1 = to.1
			delegate.playerMoved()
		}
	}
}