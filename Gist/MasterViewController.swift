//
//  MasterViewController.swift
//  Gist
//
//  Created by CuiMingyu on 10/12/15.
//  Copyright © 2015 CuiMingyu. All rights reserved.
//

import UIKit
import Kingfisher
import Alamofire

class MasterViewController: UITableViewController {

    @IBOutlet weak var gistSegmentedControl: UISegmentedControl!
    
    var detailViewController: DetailViewController? = nil
    var gists = [GistClass]()
    
    var nextPageURLString: String?
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        
        if self.refreshControl == nil {
            self.refreshControl = UIRefreshControl()
            self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        }
        
        super.viewWillAppear(animated)
    }
    
    func refresh(sender: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(false, forKey: "loadingOAuthToken")
        
        nextPageURLString = nil
        loadInitialData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if !defaults.boolForKey("loadingOAuthToken") {
            loadInitialData()
        }
    }
    
    func loadInitialData() {
        isLoading = true
        GitHubAPIManager.sharedManager.OAuthTokenCompletionHandler = { (error) -> Void in
            if let receivedError = error {
                print(receivedError)
                self.isLoading = false
                // Got some error, try again
                self.showOAuthLoginView()
            } else {
                self.loadGists(nil)
            }
        }
        
        if !GitHubAPIManager.sharedManager.hasOAuthToken() {
            GitHubAPIManager.sharedManager.startOAuth2Login()
//            self.showOAuthLoginView()
        } else {
            loadGists(nil)
        }
    }
    
    func showOAuthLoginView() {
        if let loginVC = R.storyboard.main.loginViewController {
            loginVC.delegate = self
            self.presentViewController(loginVC, animated: true, completion: nil)
        }
    }
    
    func loadGists(urlToLoad: String?) {
        let completionHandler: (Result<[GistClass]>, String?) -> Void = { (result, nextPage) in
            self.isLoading = false
            self.nextPageURLString = nextPage
            
            if self.refreshControl != nil && self.refreshControl!.refreshing {
                self.refreshControl?.endRefreshing()
            }
            
            guard result.error == nil else {
                print(result.error)
                self.nextPageURLString = nil
                
                self.isLoading = false
                if let error = result.error as? NSError {
                    if error.domain == NSURLErrorDomain && error.code == NSURLErrorUserAuthenticationRequired {
                        self.loadInitialData()
                    }
                }
                return
            }
            
            if let fetchedGists = result.value {
                if self.nextPageURLString != nil {
                    self.gists += fetchedGists
                } else {
                    self.gists = fetchedGists
                }
            }
            self.tableView.reloadData()
        }
        
        isLoading = true
        switch gistSegmentedControl.selectedSegmentIndex {
        case 0:
            GitHubAPIManager.sharedManager.getPublisGists(urlToLoad, completion: completionHandler)
        case 1:
            GitHubAPIManager.sharedManager.getMyStarredGists(urlToLoad, completionHandler: completionHandler)
        case 2:
            GitHubAPIManager.sharedManager.getMyGists(urlToLoad, completionHandler: completionHandler)
        default:
            print("got unexpected index")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        let alert = UIAlertController(title: "Not Implemented", message: "Can't create new gists yet", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }

    @IBAction func segmentedControlValueChanged(sender: AnyObject) {
        loadGists(nil)
    }
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let gist = gists[indexPath.row] as GistClass
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.gist = gist
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gists.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let gist = gists[indexPath.row] as GistClass
        cell.textLabel?.text = gist.description
        cell.detailTextLabel?.text = gist.ownerLogin
        
        if let urlString = gist.ownerAvatarURL,
            url = NSURL(string: urlString) {
                cell.imageView?.kf_setImageWithURL(url, placeholderImage: R.image.placeholder44)
        } else {
            cell.imageView?.image = R.image.placeholder44
        }
        
        let rowsToLoadFromBottom = 5
        let rowsLoaded = gists.count
        if let nextPage = nextPageURLString {
            if (!isLoading && (indexPath.row >= (rowsLoaded - rowsToLoadFromBottom))) {
                self.loadGists(nextPage)
            }
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            gists.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

extension MasterViewController: LoginViewDelegate {
    func didTapLoginButton() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(true, forKey: "loadingOAuthToken")
        
        self.dismissViewControllerAnimated(false, completion: nil)
        GitHubAPIManager.sharedManager.startOAuth2Login()
    }
}