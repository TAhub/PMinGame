//
//  ViewExtensions.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/16/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

extension UIView
{
	func shake(delay:UInt32)
	{
		let shakeMag:CGFloat = 8
		let shakeLength = 0.1
		if delay == 0
		{
			shakePart(shakeMag, length: shakeLength)
		}
		else
		{
			dispatch_async(dispatch_queue_create("waitQueue", nil))
			{
				sleep(delay)
				dispatch_async(dispatch_get_main_queue())
				{
					self.shakePart(shakeMag, length: shakeLength)
				}
			}
		}
	}
	
	private func shakePart(mag:CGFloat, length:Double)
	{
		//FIXME: this can crash the game
		//if a battle is won with a critical hit
		//or whatnot
		//that should probably be fixed
		
		UIView.animateWithDuration(length, animations:
		{
			self.layer.position.x += mag
		})
		{ (success) in
			UIView.animateWithDuration(length, animations:
			{
				self.layer.position.x -= mag
			})
			{ (success) in
				if mag > 2
				{
					self.shakePart(mag - 2, length: length)
				}
			}
		}
	}
}