//
//  Map.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/10/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation

class Map
{
	//map variables
	var width:Int!
	var tiles:[Tile]!
	
	//map content variables
	internal var party = [Creature]()
	internal var reserve = [Creature]()
	
	init()
	{
		//initialize the map
		//TODO: get a real map
		width = 100
		tiles = [Tile]()
		for _ in 0..<10000
		{
			tiles.append(Tile(type: "floor"))
		}
	}
}