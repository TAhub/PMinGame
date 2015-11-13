//
//  MapSketcher.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/12/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation

class MapSketcher
{
	class func twiggy(myNumber:UInt16, width:Int, height:Int, rectangles:Int, minSize:Int, maxSize:Int, startPosition:(Int, Int)) -> [[UInt16]]
	{
		var ar = makeEmptyArray(width: width, height: height)
		
		var pos = startPosition
		func drawRectAtPos()
		{
			var w = Int(arc4random_uniform(UInt32(maxSize - minSize))) + minSize
			var h = Int(arc4random_uniform(UInt32(maxSize - minSize))) + minSize
			
			//the math is easier if it's an even number, so just make sure it's one
			if w % 2 == 1
			{
				w += 1
			}
			if h % 2 == 1
			{
				h += 1
			}
			
			for y in pos.1-(h/2)...pos.1+(h/2)
			{
				for x in pos.0-(w/2)...pos.0+(w/2)
				{
					if x >= 0 && y >= 0 && x < width && y < height
					{
						ar[y][x] = myNumber
					}
				}
			}
		}
		
		drawRectAtPos()
		
		for _ in 1..<rectangles
		{
			let oldPos = pos
			
			//move to a new position
			if arc4random_uniform(2) == 1
			{
				pos.0 = Int(arc4random_uniform(UInt32(width)))
			}
			else
			{
				pos.1 = Int(arc4random_uniform(UInt32(height)))
			}
			
			//draw a line between your old and new positions
			for y in min(oldPos.1, pos.1)...max(oldPos.1, pos.1)
			{
				for x in min(oldPos.0, pos.0)...max(oldPos.0, pos.0)
				{
					ar[y][x] = myNumber
				}
			}
			
			drawRectAtPos()
		}
		
		return ar
	}
	
	class func ultimateLifeform(myNumber:UInt16, width:Int, height:Int, startChance:Int, smooths:Int) -> [[UInt16]]
	{
		var ar = makeEmptyArray(width: width, height: height)
		
		//this algorithm is based on the algorithm at
		//http://www.roguebasin.com/index.php?title=Cellular_Automata_Method_for_Generating_Random_Cave-Like_Levels
		//all thanks to them
		
		for y in 0..<height
		{
			for x in 0..<width
			{
				if Int(arc4random_uniform(100)) <= startChance
				{
					ar[y][x] = myNumber
				}
			}
		}
		
		func smooth()
		{
			var newAr = makeEmptyArray(width: width, height: height)
			for y in 0..<height
			{
				for x in 0..<width
				{
					//count the number of neighbors who are walls
					var wallNeighbors = 0
					for y2 in y-1...y+1
					{
						for x2 in x-1...x+1
						{
							if x2 < 0 || y2 < 0 || x2 >= width || y2 >= height || ar[y2][x2] == 0
							{
								wallNeighbors += 1
							}
						}
					}
					
					//TODO: set newAr based on the old ar value and the number of wall neighbors I guess
					let wall = (ar[y][x] == 0 && wallNeighbors >= 4) || (ar[y][x] != 0 && wallNeighbors >= 5)
					newAr[y][x] = (wall ? 0 : myNumber)
				}
			}
			
			ar = newAr
		}
		
		for _ in 0..<smooths
		{
			smooth()
		}
		
		return ar
	}
	
	
	//MARK: helper functions
	class func makeEmptyArray(width width:Int, height:Int) -> [[UInt16]]
	{
		var a = [[UInt16]]()
		for _ in 0..<height
		{
			var b = [UInt16]()
			for _ in 0..<width
			{
				b.append(0)
			}
			a.append(b)
		}
		return a
	}
}