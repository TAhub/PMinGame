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
	private var tileImages = [String:UIImage]()
	
	//walkers
	private var partyWalker:UIView!
	private var encounterWalkers = [UIView]()
	
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
		
		
		map = Map(from: nil)
		loadMap()
		
		//sample starting party
		map.party.append(Creature(job: "inventor", level: 1, good: true))
		map.party.append(Creature(job: "sour knight", level: 1, good: true))
		map.party.append(Creature(job: "rogue", level: 1, good: true))
		map.party.append(Creature(job: "pyromaniac", level: 1, good: true))
		map.party.append(Creature(job: "cold killer", level: 1, good: true))
		map.party.append(Creature(job: "cryoman", level: 1, good: true))
		
		
		
		
		//show the debug minimap
//		loadDebugMinimap()
	}
	
	private func loadMap()
	{
		//set yourself as delegate
		map.delegate = self
		
		//setup the walkers
		partyWalker = setUpWalker(map.partyPosition)
		for position in map.enemyEncounters
		{
			encounterWalkers.append(setUpWalker(position))
		}
		
		//move the camera
		self.mapView.layoutIfNeeded()
		self.moveCameraToPlayer(false)
		
		//load tile images
		var tiles = Set<String>()
		for col in map.tiles
		{
			for tile in col
			{
				tiles.insert(tile.type)
			}
		}
		tileImages = [String:UIImage]()
		for type in tiles
		{
			let tile = Tile(type: type)
			if let imageString = tile.image, let image = UIImage(named: imageString)
			{
				let coloredImage = image.colorImage(tile.color)
				tileImages[type] = coloredImage
			}
		}
		
		//reload the appearance
		mapView.reloadData()
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
		map = Map(from: nil)
		loadDebugMinimap()
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if let cvc = segue.destinationViewController as? CampViewController
		{
			//award EXP for finishing the map
			let mapEXP = expToNextLevel(map.difficulty) * 7 / 10
			for person in map.party
			{
				person.experience += mapEXP
			}
			
			
			//unload the walkers
			partyWalker.removeFromSuperview()
			for walker in encounterWalkers
			{
				walker.removeFromSuperview()
			}
			encounterWalkers = [UIView]()
			
			
			//prepare the segue
			cvc.party = map.party
			let nextMap = Map(from: map)
			cvc.nextMap = nextMap
			nextMap.party = map.party
			cvc.completionCallback =
			{ (nextMap) in
				//generate the next map
				self.map = nextMap
				self.loadMap()
			}
		}
		else if let bvc = segue.destinationViewController as? BattleViewController
		{
			bvc.setup(map.party, encounterType: map.encounterType, difficulty: map.difficulty)
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
	
	private func moveWalker(walker:UIView, to:(Int, Int), completion:()->())
	{
		animating = true
		UIView.animateWithDuration(0.25, animations:
		{
			walker.frame.origin.x = CGFloat(to.0) * kTileSize.width
			walker.frame.origin.y = CGFloat(to.1) * kTileSize.height
		})
		{ (success) in
			self.animating = false
			completion()
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
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("mapCell", forIndexPath: indexPath) as! TileCollectionViewCell
		let tile = map.tiles[indexPath.section][indexPath.row]
		cell.backgroundColor = tile.color
		cell.tileImage.image = tileImages[tile.type]
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
	
	private func moveCameraToPlayer(animated:Bool)
	{
		let scrollPosition = UICollectionViewScrollPosition.CenteredHorizontally.rawValue | UICollectionViewScrollPosition.CenteredVertically.rawValue
		mapView.scrollToItemAtIndexPath(NSIndexPath(forItem: map.partyPosition.0, inSection: map.partyPosition.1), atScrollPosition: UICollectionViewScrollPosition.init(rawValue: scrollPosition), animated: animated)
	}
	
	//MARK: map delegate functions
	func playerMoved(completion:()->())
	{
		//move the player
		moveWalker(partyWalker, to: map.partyPosition, completion: completion)
		
		//and move the "camera"
		moveCameraToPlayer(true)
	}
	func startBattle()
	{
		performSegueWithIdentifier("startBattle", sender: self)
		
		//TODO: this should have a cool custom transition
		//some kind of dissolve maybe
		//think a final fantasy battle start
	}
	func partyDamageEffect()
	{
		//play a graphical effect to warn the player that they took damage
		
		//make the view
		let effectView = UIView(frame: view.frame)
		effectView.backgroundColor = UIColor.redColor()
		effectView.alpha = 0
		view.addSubview(effectView)
		
		//and animate it
		UIView.animateWithDuration(0.1, animations: { effectView.alpha = 1 })
		{ (success) in
			UIView.animateWithDuration(0.1, animations: { effectView.alpha = 0 })
			{ (success) in
				effectView.removeFromSuperview()
			}
		}
	}
	func nextMap()
	{
		//go to the next map
		performSegueWithIdentifier("toCamp", sender: self)
	}
}


