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
	
	
	//MARK: helper functions
	private class func makeEmptyArray(width width:Int, height:Int) -> [[UInt16]]
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