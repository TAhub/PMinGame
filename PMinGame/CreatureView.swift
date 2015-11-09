//
//  CreatureView.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/8/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

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
						
						//TODO: add a system for back sprites (back of hair, etc)
						//it should go here
						//as it should allow you to have backsprites for things without, uh
						//front-sprites I guess?
					}
					
					for i in 0..<creature.sprites.count
					{
						addImage(creature.sprites[i], color: creature.colors[i])
					}
					
					addImage(creature.jobSprite, color: (creature.good ? UIColor.greenColor() : UIColor.redColor()))
					
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