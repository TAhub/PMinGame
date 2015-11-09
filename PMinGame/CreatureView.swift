//
//  CreatureView.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/8/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

extension UIImage
{
	func colorImage(color:UIColor) -> UIImage
	{
		let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
		
		//get the color space and context
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
		let bitmapContext = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height), 8, 0, colorSpace, bitmapInfo.rawValue)
		
		//draw and fill it
		CGContextClipToMask(bitmapContext, rect, self.CGImage)
		CGContextSetFillColorWithColor(bitmapContext, color.CGColor)
		CGContextFillRect(bitmapContext, rect)
		
		//return a snapshot of that
		return UIImage(CGImage: CGBitmapContextCreateImage(bitmapContext)!)
	}
}

class CreatureView:UIView
{
	internal var creature:Creature?
	{
		didSet
		{
			if !(creature === oldValue)
			{
				if let creature = creature
				{
					func addView(name:String, color:UIColor)
					{
						if let image = PlistService.loadImage(name)?.colorImage(color)
						{
							let subview = UIImageView(image: image)
							if !creature.good
							{
								subview.image = UIImage(CGImage: subview.image!.CGImage!, scale: 1.0, orientation: .UpMirrored)
							}
							subview.tintColor = color
							subview.layer.position.x = bounds.width / 2
							subview.layer.position.y = bounds.height - image.size.height / 2
							addSubview(subview)
						}
					}
					
					for i in 0..<creature.sprites.count
					{
						addView(creature.sprites[i], color: creature.colors[i])
					}
					
					addView(creature.jobSprite, color: UIColor.grayColor())
				}
			}
		}
	}
}