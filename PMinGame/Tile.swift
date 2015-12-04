//
//  Tile.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/10/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation
import UIKit

struct Tile
{
	let type:String
	
	//MARK: derived variables
	var solid:Bool
	{
		return PlistService.loadValue("Tiles", type, "solid") != nil
	}
	var damaging:Bool
	{
		return PlistService.loadValue("Tiles", type, "damaging") != nil
	}
	var encounters:Bool
	{
		return PlistService.loadValue("Tiles", type, "encounters") != nil
	}
	var gate:Bool
	{
		return PlistService.loadValue("Tiles", type, "gate") != nil
	}
	var image:String?
	{
		return PlistService.loadValue("Tiles", type, "image") as? String
	}
	var dart:String?
	{
		return PlistService.loadValue("Tiles", type, "dart") as? String
	}
	var visible:Bool
	{
		return PlistService.loadValue("Tiles", type, "color") != nil
	}
	var color:UIColor
	{
		return PlistService.loadColor(PlistService.loadValue("Tiles", type, "color") as! String)
	}
}