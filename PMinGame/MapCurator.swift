//
//  MapCurator.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/12/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation
import UIKit

class MapCurator
{
	class func makeMap(type:String) -> ([[Tile]], Int, (Int, Int))
	{
		var finalSketch:[[UInt16]]!
		var startPosition:(Int, Int)!
		var destPosition:(Int, Int)!
		var startingWidth:Int!
		var startingHeight:Int!
		
		while finalSketch == nil
		{
			if let results = getGoodFinalSketch(type)
			{
				finalSketch = results.0
				startPosition = results.1
				destPosition = results.2
				startingWidth = results.3
				startingHeight = results.4
			}
		}
		
		
		//clip the final sketch to size
		let results2 = mapResize(finalSketch, startPosition: startPosition, endPosition: destPosition, width: startingWidth, height: startingHeight)
		finalSketch = results2.0
		startPosition = results2.1
		destPosition = results2.2
		let newWidth = results2.3
		let newHeight = results2.4
		
		
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
				
				if x == destPosition.0 && y == destPosition.1
				{
					tileC.append(Tile(type: "gate"))
				}
				else
				{
					tileC.append(Tile(type: finalSketch[y][x] == 0 ? "wall" : "floor"))
				}
			}
			tiles.append(tileC)
		}
		
		//finally, return the map
		return (tiles, newWidth, startPosition)
	}
	
	class func drawMap(map:[[Tile]], canvas:UIView)
	{
		let backer = UIView(frame: canvas.bounds)
		backer.backgroundColor = UIColor.blackColor()
		canvas.addSubview(backer)
		
		for y in 0..<map.count
		{
			for x in 0..<map[y].count
			{
				if map[y][x].color != UIColor.blackColor()
				{
					let tile = UIView(frame: CGRect(x: 3 * CGFloat(x), y: 3 * CGFloat(y), width: 3, height: 3))
					tile.backgroundColor = map[y][x].color
					canvas.addSubview(tile)
				}
			}
		}
	}
	
	//MARK: helper functions
	private class func getGoodFinalSketch(type:String)->([[UInt16]], (Int, Int), (Int, Int), Int, Int)?
	{
		var sketches = [[[UInt16]]]()
		let startingWidth = PlistService.loadValue("Maps", type, "start size") as! Int
		let startingHeight = startingWidth
		
		//TODO: generate a random starting position
		let startPosition = (startingWidth / 2, 5)
		
		//each sketcher should have a go at it
		//note that at least one sketcher should be twiggy, or someone else who will always draw floors at the start position
		let sketchers = PlistService.loadValue("Maps", type, "sketchers") as! [[String : AnyObject]]
		for (i, sketcher) in sketchers.enumerate()
		{
			switch(sketcher["type"] as! String)
			{
			case "twiggy":
				//ol' twiggy (rooms and coridoors)
				//he has a lewd mind
				//he places rectangles and connects them with lines
				sketches.append(MapSketcher.twiggy(UInt16(i + 1), width: startingWidth, height: startingHeight, rectangles: sketcher["rectangles"] as! Int, minSize: sketcher["min size"] as! Int, maxSize: sketcher["max size"] as! Int, startPosition: startPosition))
			case "ultimate lifeform":
				//the ultimate lifeform (cellular smoothing)
				//he is obsessed with perfection
				//he starts with a random group of walls and floors, and smooths them into a nice cave shape
				sketches.append(MapSketcher.ultimateLifeform(UInt16(i + 1), width: startingWidth, height: startingHeight, startChance: sketcher["start chance"] as! Int, smooths: sketcher["smooths"] as! Int))
			default: break
			}
		}
		
		
		//next up, overlay the sketches
		var finalSketch = MapSketcher.makeEmptyArray(width: startingWidth, height: startingHeight)
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
		
		//remove all accessable tiles
		let results = mapExplore(finalSketch, startPosition: startPosition)
		finalSketch = results.0
		let accessableTiles = results.1
		let destPosition = results.2
		
		//if there aren't enough accessable tiles, restart the algorithm
		let desiredAccessable = startingWidth * startingHeight * 3 / 10
		print("\(accessableTiles) accessable tiles, compared to \(desiredAccessable) desired")
		if accessableTiles < desiredAccessable
		{
			return nil
		}
		
		return (finalSketch, startPosition, destPosition, startingWidth, startingHeight)
	}
	
	private class func mapResize(finalSketch:[[UInt16]], startPosition:(Int, Int), endPosition:(Int, Int), width:Int, height:Int) -> ([[UInt16]], (Int, Int), (Int, Int), Int, Int)
	{
		//find the size of the map
		var top = height + 1
		var bottom = -1
		var left = width + 1
		var right = -1
		for y in 0..<height
		{
			for x in 0..<width
			{
				if finalSketch[y][x] != 0
				{
					top = min(top, y)
					bottom = max(bottom, y)
					left = min(left, x)
					right = max(right, x)
				}
			}
		}
		
		//get the new bounds
		let borderSize = 2
		let newWidth = (right - left + 1) + 2 * borderSize
		let newHeight = (bottom - top + 1) + 2 * borderSize
		
		//resize the map
		var resizedSketch = MapSketcher.makeEmptyArray(width: newWidth, height: newHeight)
		for y in top...bottom
		{
			for x in left...right
			{
				resizedSketch[y - top + borderSize][x - left + borderSize] = finalSketch[y][x]
			}
		}
		
		//move the positions
		var resizedStart = startPosition
		resizedStart.0 += borderSize - left
		resizedStart.1 += borderSize - top
		var resizedEnd = endPosition
		resizedEnd.0 += borderSize - left
		resizedEnd.1 += borderSize - top
		
		return (resizedSketch, resizedStart, resizedEnd, newWidth, newHeight)
	}
	
	
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