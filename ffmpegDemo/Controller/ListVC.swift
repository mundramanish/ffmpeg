//// ListVC.swift
// ffmpegDemo
//
// Created by ffmpegDemo on 16/03/22.
// Copyright © 2021 ffmpegDemo. All rights reserved.
//

import UIKit
import AVKit

class ListVC: UITableViewController, StoryboardSceneBased {
    
    static let sceneStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    var arrList = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        arrList = FileHelper.getFiles(directoryName: "", directory: document) as! [String]
        print(arrList)
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return arrList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        let arrTemp = self.arrList.sorted()
        
        cell.textLabel?.text = arrTemp[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let path = FileHelper.getDocumentDirectory()?.appending(self.arrList[indexPath.row]) ?? ""

        let videoURL = URL(fileURLWithPath: path)
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.view.clipsToBounds = true
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
        
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let path = FileHelper.getDocumentDirectory()?.appending(self.arrList[indexPath.row]) ?? ""
            do {
                if FileManager.default.fileExists(atPath: path) {
                    try FileManager.default.removeItem(atPath: path)
                    arrList = FileHelper.getFiles(directoryName: "", directory: document) as! [String]
                    self.tableView.reloadData()
                }
            } catch {
                
            }
            // Delete the row from the data source
//            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new insta       nce of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

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
