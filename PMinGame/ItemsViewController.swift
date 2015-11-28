//
//  ItemsViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/28/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class ItemsViewController: UIViewController, UITableViewDataSource {

    internal var person:Creature?
	internal var items:[Item]?
	var saveClosure:(()->())!
	
	@IBOutlet weak var portraitView: CreatureView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var itemTable: UITableView!
	{
		didSet
		{
			itemTable.dataSource = self
			itemTable.estimatedRowHeight = 100
			itemTable.rowHeight = UITableViewAutomaticDimension
		}
	}
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		nameLabel.text = person!.name
		portraitView.creature = person
	}
	
	@IBAction func returnButton()
	{
		navigationController!.popViewControllerAnimated(true)
	}
	
	//MARK: table view datasource
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("itemCell") as! ItemTableViewCell
		
		let item = items![indexPath.row]
		cell.nameLabel.text = item.type
		if item.number > 1
		{
			cell.nameLabel.text = "\(item.type) x\(item.number)"
		}
		cell.descriptionLabel.text = item.description
		
		//detect if the item is valid to use
		if item.canUseOn(person!)
		{
			cell.useClosure =
			{
				//use the item
				self.person!.useItem(item)
				{ (_, _) in
					//empty message handler
				}
				
				//use up the item
				self.items = self.items!.filter() { $0.number > 0 }
				self.itemTable.reloadData()
				
				//save the player
				self.saveClosure()
				
				//save the inventory
				saveInventory(self.items!)
			}
		}
		else
		{
			cell.useClosure = nil
		}
		
		return cell
	}
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items!.count
	}
}
