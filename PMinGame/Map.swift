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
}