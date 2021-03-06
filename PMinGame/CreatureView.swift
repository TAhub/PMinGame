//
//  CreatureView.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/8/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

let kColorGood = UIColor(red: 0.4, green: 0.4, blue: 0.65, alpha: 1)
let kColorBad = UIColor(red: 0.65, green: 0.4, blue: 0.4, alpha: 1)
let kColorBlendAmount:CGFloat = 0.45

class CreatureView:UIView
{
	private var subview:UIImageView?
	
	internal var creature:Creature?
	{
		didSet
		{
			if !(creature === oldValue)
			{
				if let creature = creature
				{
					var images = [UIImage]()
					
					func addImage(name:String, color:UIColor)
					{
						if let image = PlistService.loadImage(name)?.colorImage(color)
						{
							images.append(image)
						}
						if let image = PlistService.loadImage("\(name)_back")?.colorImage(color)
						{
							images.insert(image, atIndex: 0)
						}
					}
					
					for i in 0..<creature.sprites.count
					{
						addImage(creature.sprites[i], color: PlistService.loadColor(creature.colors[i]))
					}
					
					//add the job's armor (or top layer, anyway)
					let sideColor = (creature.good ? kColorGood : kColorBad)
					let blendColor = creature.jobBlendColor
					addImage(creature.jobSprite, color: UIColor.colorLerp(kColorBlendAmount, color1: blendColor, color2: sideColor))
					
					//add the job's weapon
					if let weaponSprite = creature.weaponSprite
					{
						addImage(weaponSprite, color: blendColor)
					}
					
					if subview != nil
					{
						subview!.removeFromSuperview()
					}
					subview = UIImageView(image: UIImage.combineImages(images, anchorAt: CGPoint(x: 0.5, y: 1)))
					if !creature.good
					{
						subview!.image = UIImage(CGImage: subview!.image!.CGImage!, scale: 1.0, orientation: .UpMirrored)
					}
					subview!.layer.position.x = bounds.width / 2
					subview!.layer.position.y = bounds.height - subview!.image!.size.height / 2
					addSubview(subview!)
				}
			}
		}
	}
}