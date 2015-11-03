//
//  DetailViewController.swift
//  Gist
//
//  Created by CuiMingyu on 10/12/15.
//  Copyright © 2015 CuiMingyu. All rights reserved.
//

import UIKit
import WebKit

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var isStarred: Bool?
    
    var gist: GistClass? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView() {
        if let _ = self.gist {
            fetchStarredStatus()
            if let detailsView = self.tableView {
                detailsView.reloadData()
            }
        }
    }
    
    func fetchStarredStatus() {
        if let gistId = gist?.id {
            GitHubAPIManager.sharedManager.isGistStarred(gistId, completionHandler: { (status, error) -> Void in
                if error != nil {
                    print(error)
                }
                if self.isStarred == nil && status != nil {
                    self.isStarred = status
                    self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: .Automatic)
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let _ = isStarred {
                return 3
            } else {
                return 2
            }
        } else {
            return gist?.files?.count ?? 0
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "About"
        } else {
            return "Files"
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(R.reuseIdentifier.testCell.identifier, forIndexPath: indexPath)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = gist?.description
            } else if indexPath.row == 1 {
                cell.textLabel?.text = gist?.ownerLogin
            } else {
                if let starred = isStarred {
                    if starred {
                        cell.textLabel?.text = "Unstar"
                    } else {
                        cell.textLabel?.text = "Star"
                    }
                }
            }
        } else {
            if let file = gist?.files?[indexPath.row] {
                cell.textLabel?.text = file.fileName
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 2 {
                if let starred = isStarred {
                    if starred {
                        unstarThisGist()
                    } else {
                        starThisGist()
                    }
                }
            }
        }
        if indexPath.section == 1 {
            if let file = gist?.files?[indexPath.row],
                urlString = file.raw_url,
                url = NSURL(string: urlString) {
                    let webView = WKWebView()
                    let webViewWrapperVC = UIViewController()
                    webViewWrapperVC.view = webView
                    webViewWrapperVC.title = file.fileName
                    
                    let request = NSURLRequest(URL: url)
                    webView.loadRequest(request)
                    
                    navigationController?.pushViewController(webViewWrapperVC, animated: true)
            }
        }
    }
    
    func starThisGist() {
        if let gistId = gist?.id {
            GitHubAPIManager.sharedManager.starGist(gistId, completionHandler: { (error) -> Void in
                if error != nil {
                    print(error)
                }
                self.isStarred = true
                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: .Automatic)
            })
        }
    }
    
    func unstarThisGist() {
        if let gistId = gist?.id {
            GitHubAPIManager.sharedManager.unstarGist(gistId, completionHandler: { (error) -> Void in
                if error != nil {
                    print(error)
                }
                self.isStarred = false
                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: .Automatic)
            })
        }
        
    }
}

