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
	private var solid:Bool
	{
		return false
	}
	private var color:UIColor
	{
		return UIColor.blackColor()
	}
}