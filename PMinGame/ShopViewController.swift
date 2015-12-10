//
//  ShopViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 12/10/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class ShopViewController: UIViewController, UITableViewDataSource {
	
	var money:Int = 0
	{
		didSet
		{
			setMessage()
		}
	}
	var items:[Item] = [Item]()
	var shopInventory:[Item] = [Item]()
	var saveCompletion:(()->())!
	
	@IBOutlet weak var messageLabel: UILabel!
	{
		didSet
		{
			setMessage()
		}
	}
	private func setMessage()
	{
		if messageLabel != nil
		{
			messageLabel.text = "Howdy! You have \(money) karma to spend!"
		}
	}
	@IBOutlet weak var tableView: UITableView!
	{
		didSet
		{
			tableView.dataSource = self
			tableView.estimatedRowHeight = 100
			tableView.rowHeight = UITableViewAutomaticDimension
		}
	}
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		reloadInventory()
	}
	
	private func reloadInventory()
	{
		//TODO: load an appropriate inventory
		//use the item's "min shop level" property to figure out if you should have it in this shop
		shopInventory = [Item]()
		shopInventory.append(Item(type: "poultice"))
		
		tableView.reloadData()
	}
	
	@IBAction func back()
	{
		navigationController?.popViewControllerAnimated(true)
	}
	
	
	//MARK - table view datasource
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! ItemTableViewCell
		let item = shopInventory[indexPath.row]
		
		cell.nameLabel.text = item.type
		cell.descriptionLabel.text = item.description
		cell.useButton.setTitle("Buy for \(item.cost)", forState: .Normal)
		if item.cost <= money && addItem(&items, newItem: item, actuallyAdd: false)
		{
			//you can add that item
			cell.useClosure =
			{
				addItem(&self.items, newItem: item)
				self.money -= item.cost
				self.saveCompletion()
				self.reloadInventory()
			}
		}
		else
		{
			//you don't have room (or enough money)
			cell.useClosure = nil
		}
		
		return cell
	}
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return shopInventory.count
	}
}
