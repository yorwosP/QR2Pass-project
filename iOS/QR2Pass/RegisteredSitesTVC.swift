//
//  RegisteredSitesTVC.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 5/30/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import UIKit

class RegisteredSitesTVC: UITableViewController {
    
    var listOfRegisteredSites:[WebSite]? //this will be passed by the main view controller
    

    override func viewDidLoad() {
        super.viewDidLoad()
        

        

//        listOfRegisteredSites = [website1, website2, website3, website4]

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return listOfRegisteredSites?.count ?? 1
    }

   
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "site cell", for: indexPath)
        let registeredSite = listOfRegisteredSites?[indexPath.row] ?? nil
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        
//        !!CHECK!! if lastLoggedin is not defined then it will show today's date. FIX THAT!!
        cell.textLabel!.text = (registeredSite != nil) ? "\(registeredSite!.siteName)  (\(registeredSite!.url.absoluteString))"  : "You haven't registered to any sites yet"
        
        cell.detailTextLabel!.text = (registeredSite != nil) ?
            "Last logged in at:\(dateFormatter.string(from: registeredSite!.lastLoginAt ?? Date())) (\(registeredSite!.user.username))" :
            ""


        return cell
    }
  
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
