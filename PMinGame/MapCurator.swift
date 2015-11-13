//
//  MapCurator.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/12/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation

class MapCurator
{
	class func makeMap(type:String) -> ([[Tile]], Int, (Int, Int))
	{
		var sketches = [[[UInt16]]]()
		let startingWidth = 50
		let startingHeight = 50
		
		//TODO: get the start position
		var startPosition = (25, 5)
		
		//TODO: each sketcher should have a go at it
		//a sketcher will make a sketch, which is a layout of a map
		//a 0 means a wall, and a *sketcher number + 1* means a floor
		//each sketcher has a different identity, and different initial values
		//the map type determines the number of sketchers, their identities, and their values
		//the sketches are effectively overlayed over each other
		//and thus the last sketcher has priority, basically
		
		//the ultimate lifeform (cellular smoothing)
		//he is obsessed with perfection
		//he starts with a random group of walls and floors, and smooths them into a nice cave shape
		//he requires a starting chance to place a wall, and a number of smoothings
		
		//ol' twiggy (rooms and coridoors)
		//he has a lewd mind
		//he places rectangles and connects them with lines
		//he requires a min rectangle size, a max rectangle size, a number of rectangles, and a start position
		
		//possibly others in the future?
		
		sketches.append(MapSketcher.twiggy(1, width: startingWidth, height: startingHeight, rectangles: 5, minSize: 4, maxSize: 7, startPosition: startPosition))
		
		
		//next up, overlay the sketches
		var finalSketch = [[UInt16]]()
		for _ in 0..<startingHeight
		{
			var sketchC = [UInt16]()
			for _ in 0..<startingWidth
			{
				sketchC.append(0)
			}
			finalSketch.append(sketchC)
		}
		for sketch in sketches
		{
			for y in 0..<startingHeight
			{
				for x in 0..<startingWidth
				{
					finalSketch[y][x] = max(finalSketch[y][x], sketch[y][x])
				}
			}
		}
		
		//TODO: remove all inaccessable areas (from the perspective of the start position)
		//while you are at it, detect the number of accessable tiles and the furthest tile
		
		//TODO: set the destination position to the furthest point
		let results = mapExplore(finalSketch, startPosition: startPosition)
		finalSketch = results.0
		let accessableTiles = results.1
		var destPosition = results.2
		
		//TODO: if there aren't enough accessable tiles, restart the algorithm
		print("\(accessableTiles) accessable tiles")
		
		
		//TODO: clip the final sketch to size
		//remember to move the start and end positions
		let newWidth = startingWidth
		let newHeight = startingHeight
		
		
		//TODO: place traps, encounters, etc

		
		//translate the final sketch to real tiles
		var tiles = [[Tile]]()
		for y in 0..<newHeight
		{
			var tileC = [Tile]()
			for x in 0..<newWidth
			{
				//TODO: pick an appropriate tile for this spot
				//the type of a floor is based on the sketcher number it is
				//the type of a wall is based on the highest sketcher number in a 3x3 grid surrounding it
				//a wall which is by the edge should be a black wall
				//a wall whose highest nearby sketcher number is 0 should be made into a black wall
				//each sketcher has an associated floor and wall type (ie brick wall + tile floor, cave wall + dirt floor, w/e)
				//also associated versions of traps, etc
				
				tileC.append(Tile(type: finalSketch[y][x] == 0 ? "wall" : "floor"))
			}
			tiles.append(tileC)
		}
		
		
		//finally, return the map
		return (tiles, newWidth, startPosition)
	}
	
	//MARK: helper functions
	private class func mapExplore(var finalSketch:[[UInt16]], startPosition:(Int, Int)) -> ([[UInt16]], Int, (Int, Int))
	{
		var distances = [[Int]]()
		for i in 0..<finalSketch.count
		{
			var subDist = [Int]()
			for _ in 0..<finalSketch[i].count
			{
				subDist.append(-1)
			}
			distances.append(subDist)
		}
		
		var iQ = [(Int, Int)]()
		
		//start with the start position
		iQ.append(startPosition)
		distances[startPosition.1][startPosition.0] = 0
		
		//explore outward
		while !iQ.isEmpty
		{
			let i = iQ.popLast()!
			let distance = distances[i.1][i.0] + 1
			
			func exploreOneDirection(x x:Int, y:Int, distance:Int)
			{
				if x >= 0 && y >= 0 && y < distances.count && x < distances[y].count && (distances[y][x] > distance || distances[y][x] == -1) && finalSketch[y][x] != 0
				{
					distances[y][x] = distance
					iQ.append(x, y)
				}
			}
			exploreOneDirection(x: i.0 - 1, y: i.1, distance: distance)
			exploreOneDirection(x: i.0 + 1, y: i.1, distance: distance)
			exploreOneDirection(x: i.0, y: i.1 - 1, distance: distance)
			exploreOneDirection(x: i.0, y: i.1 + 1, distance: distance)
		}
		
		//fill in inaccessable bits, and also do some analytics while you're at it
		var accessableTiles = 0
		var furthestTile:(Int, Int)?
		for y in 0..<finalSketch.count
		{
			for x in 0..<finalSketch[y].count
			{
				if finalSketch[y][x] != 0 && distances[y][x] != -1
				{
					accessableTiles += 1
					if furthestTile != nil
					{
						if distances[furthestTile!.1][furthestTile!.0] < distances[y][x]
						{
							furthestTile = (x, y)
						}
					}
					else
					{
						furthestTile = (x, y)
					}
				}
				else
				{
					finalSketch[y][x] = 0
				}
			}
		}
		
		return (finalSketch, accessableTiles, furthestTile!)
	}
}