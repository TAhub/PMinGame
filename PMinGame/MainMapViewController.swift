//
//  MainMapViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/9/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

let kMaxPartySize:Int = 6

class MainMapViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MapDelegate {
	internal var map:Map!
	
	//walkers
	private var partyWalker:UIView!
	private var encounterWalkers = [UIView]()
	
	//TODO: this should have a collection view in it
	//each cell has a background color and (optionally) a transparent png in front of it
	//for example, a tile of red brick would have a dark red background color and a generic "brick pattern" image in front of it
	//this should be a nice way to handle the map, and using background colors will make the images popping in as they load not be too bad
	//obviously you then draw the map objects over this, etc
	@IBOutlet weak var mapView: UICollectionView!
	{
		didSet
		{
			mapView.dataSource = self
			mapView.delegate = self
		}
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		//diagnostics
		
		//turn this diagnostic on if you want to see if a job's stats are in-line with the standard
//		PlistService.jobStatDiagnostic()
		
		//turn this diagnostic on if you want to see if a job's attacks have the right balance of brute and clever, types, etc
//		PlistService.jobAttackDiagnostic()
		
		//turn this diagnostic on if you want to see if one type has too many attacks, etc
//		PlistService.attackDiagnostic()
		
		//turn this diagnostic on if you want to see if any attack is overused, underused, or not used at all
//		PlistService.attackUsageDiagnostic()
		
		//turn this diagnostic on if you want to see if any attack is too strong, too weak, etc
//		PlistService.attackPowerDiagnostic()
		
		map = Map()
		map.delegate = self
		
		//setup the walkers
		partyWalker = setUpWalker(map.partyPosition)
		for position in map.enemyEncounters
		{
			encounterWalkers.append(setUpWalker(position))
		}
		
		//sample starting party
		map.party.append(Creature(job: "inventor", level: 1, good: true))
		map.party.append(Creature(job: "sour knight", level: 1, good: true))
		map.party.append(Creature(job: "rogue", level: 1, good: true))
		map.party.append(Creature(job: "pyromaniac", level: 1, good: true))
		map.party.append(Creature(job: "cold killer", level: 1, good: true))
		map.party.append(Creature(job: "cryoman", level: 1, good: true))
		
//		map.party.append(Creature(job: "warbot", level: 1, good: true))
//		map.party.append(Creature(job: "exterminator", level: 1, good: true))
//		map.party.append(Creature(job: "AI", level: 1, good: true))
//		map.party.append(Creature(job: "lightning bot", level: 1, good: true))
//		map.party.append(Creature(job: "soldier robot", level: 1, good: true))
//		map.party.append(Creature(job: "AI", level: 1, good: true))
		
		//TODO: the reserve should be cleared when you get to a new map
		//output a message in the camp screen saying those people ran away, whatever
		
		//move the camera
		self.mapView.layoutIfNeeded()
		self.moveCameraToPlayer(false)
		
		//show the debug minimap
//		loadDebugMinimap()
	}
	
	private func loadDebugMinimap()
	{
		MapCurator.drawMap(map.tiles, canvas: view)
		let button = UIButton(frame: CGRect(x: 0, y: 0, width: 3 * CGFloat(map.tiles[0].count), height: 3 * CGFloat(map.tiles.count)))
		view.addSubview(button)
		button.addTarget(self, action: "reloadDebugMinimap", forControlEvents: .TouchUpInside)
	}
	
	func reloadDebugMinimap()
	{
		let newView = UIView(frame: view.bounds)
		view = newView
		map = Map()
		loadDebugMinimap()
	}
	
	@IBAction func tempBattleButton()
	{
		startBattle()
	}
	
	private func startBattle()
	{
		performSegueWithIdentifier("startBattle", sender: self)
		
		//TODO: this should have a cool custom transition
		//some kind of dissolve maybe
		//think a final fantasy battle start
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if let bvc = segue.destinationViewController as? BattleViewController
		{
			bvc.setup(map.party)
			{ (lost, newAdditions, moneyChange) in
				
				if lost
				{
					//TODO: end the game or whatever
					print("You lost!")
				}
				else
				{
					//TODO: change your money total based on moneyChange
					
					if let newAdditions = newAdditions
					{
						for new in newAdditions
						{
							if self.map.party.count < kMaxPartySize
							{
								self.map.party.append(new)
							}
							else
							{
								self.map.reserve.append(new)
							}
						}
					}
				}
			}
		}
	}
	
	//MARK: walker code
	private var animating = false
	private func setUpWalker(position:(Int, Int))->UIView
	{
		let walker = UIView(frame: CGRect(x: kTileSize.width * CGFloat(position.0), y: kTileSize.height * CGFloat(position.1), width: kTileSize.width, height: kTileSize.height))
		walker.backgroundColor = UIColor.redColor()
		mapView.addSubview(walker)
		return walker
	}
	
	private func moveWalker(walker:UIView, to:(Int, Int))
	{
		animating = true
		UIView.animateWithDuration(0.25, animations:
		{
			walker.frame.origin.x = CGFloat(to.0) * kTileSize.width
			walker.frame.origin.y = CGFloat(to.1) * kTileSize.height
		})
		{ (success) in
			self.animating = false
		}
	}
	
	//MARK: collection view datasource and delegate
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
	{
		return map.tiles.count
	}
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return map.tiles[section].count
	}
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("mapCell", forIndexPath: indexPath)
		cell.backgroundColor = map.tiles[indexPath.section][indexPath.row].color
		return cell
	}
	func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool
	{
		//try to move there
		if !animating
		{
			map.moveTo((indexPath.row, indexPath.section))
		}
		return false
	}
	
	//MARK: map delegate functions
	func playerMoved()
	{
		//move the player
		moveWalker(partyWalker, to: map.partyPosition)
		
		//and move the "camera"
		moveCameraToPlayer(true)
	}
	private func moveCameraToPlayer(animated:Bool)
	{
		let scrollPosition = UICollectionViewScrollPosition.CenteredHorizontally.rawValue | UICollectionViewScrollPosition.CenteredVertically.rawValue
		mapView.scrollToItemAtIndexPath(NSIndexPath(forItem: map.partyPosition.0, inSection: map.partyPosition.1), atScrollPosition: UICollectionViewScrollPosition.init(rawValue: scrollPosition), animated: animated)
	}
}


