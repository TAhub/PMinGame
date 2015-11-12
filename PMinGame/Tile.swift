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
		return false
	}
	var color:UIColor
	{
		return type == "wall" ? UIColor.blackColor() : UIColor.whiteColor()
	}
}