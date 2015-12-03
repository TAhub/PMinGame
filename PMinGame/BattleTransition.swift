//
//  BattleTransition.swift
//  PMinGame
//
//  Created by Theodore Abshire on 12/1/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class BattleTransition: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate
{
	//MARK: delegate stuff
	func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning?
	{
		return self
	}
	
	func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return self
	}
	
	//MARK: transition
	func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval
	{
		return 0.75
	}
	
	func animateTransition(transitionContext: UIViewControllerContextTransitioning)
	{
		//get values
		let to = transitionContext.viewForKey(UITransitionContextToViewKey)!
		let container = transitionContext.containerView()!
		let duration = transitionDuration(transitionContext)
		
		//make the white screen
		let whiteScreen = UIView(frame: container.frame)
		whiteScreen.backgroundColor = UIColor.redColor()
		whiteScreen.alpha = 0
		
		container.addSubview(whiteScreen)
		
		UIView.animateWithDuration(duration / 3, animations:
		{
			whiteScreen.alpha = 1
		})
		{ (success) in
			
			//add the to view
			whiteScreen.removeFromSuperview()
			container.addSubview(to)
			container.addSubview(whiteScreen)
			
			//make the side-split views
			let splitScreen1 = UIView(frame: CGRect(x: 0, y: 0, width: container.frame.width / 2, height: container.frame.height))
			let splitScreen2 = UIView(frame: CGRect(x: container.frame.width / 2, y: 0, width: container.frame.width / 2, height: container.frame.height))
			
			//make gradient layers
			let components = CGColorGetComponents((whiteScreen.backgroundColor!).CGColor)
			let transColor = UIColor(red: components[0], green: components[1], blue: components[2], alpha: 0).CGColor
			let g1 = CAGradientLayer(layer: splitScreen1.layer)
			let g2 = CAGradientLayer(layer: splitScreen2.layer)
			g1.frame = splitScreen1.frame
			g2.frame = splitScreen1.frame
			g1.colors = [whiteScreen.backgroundColor!.CGColor, whiteScreen.backgroundColor!.CGColor, transColor]
			g2.colors = [whiteScreen.backgroundColor!.CGColor, whiteScreen.backgroundColor!.CGColor, transColor]
			g1.startPoint = CGPointMake(0, 0.5)
			g1.endPoint = CGPointMake(1, 0.5)
			g2.startPoint = CGPointMake(1, 0.5)
			g2.endPoint = CGPointMake(0, 0.5)
			g1.locations = [0, 0.65, 1]
			g2.locations = [0, 0.65, 1]
			splitScreen1.layer.insertSublayer(g1, atIndex: 0)
			splitScreen2.layer.insertSublayer(g2, atIndex: 0)
			
			container.addSubview(splitScreen1)
			container.addSubview(splitScreen2)
			
			UIView.animateWithDuration(duration * 2 / 3, animations:
			{
				whiteScreen.alpha = 0
				splitScreen1.alpha = 0.5
				splitScreen2.alpha = 0.5
				splitScreen1.frame.origin.x = -container.frame.width / 2
				splitScreen2.frame.origin.x = container.frame.width
			})
			{ (success) in
				//finish up
				transitionContext.completeTransition(true)
			}
		}
	}
}
