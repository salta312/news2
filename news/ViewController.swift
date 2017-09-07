//
//  ViewController.swift
//  news
//
//  Created by Saltanat Aimakhanova on 9/4/17.
//  Copyright © 2017 saltaim. All rights reserved.
//

import UIKit
import Alamofire
import Cartography
import SwiftyJSON
import KFSwiftImageLoader
//import Haneke
import CoreData
//import RSLoadingView
import SwiftSpinner
import SideMenu

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView = UITableView()
    var articles = [Article]()
    var sources = [Source]()
    var sourceNum = 0;
    var imageCache = NSCache<NSString, UIImage>()
    let refreshControl = UIRefreshControl()


    override func viewDidLoad() {
        super.viewDidLoad()
        if (self.entityIsEmpty(entity: "Source")){
            self.loadSources()
        }else{
            readFromCoreData()
        }
        self.draw()
          // Do any additional setup after loading the view, typically from a nib.
    }
    func draw(){
        self.view.isUserInteractionEnabled = true
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        self.view.addGestureRecognizer(swipeUp)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(swipeDown)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(swipe), for: .valueChanged)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.addGestureRecognizer(swipeUp)
        self.tableView.addGestureRecognizer(swipeDown)
        self.tableView.contentInset = UIEdgeInsetsMake(-36, 0, 0, 0);
        self.tableView.isUserInteractionEnabled = true
        self.view.backgroundColor = UIColor.blue
        self.view.addSubview(tableView)
        constrain(view, tableView){
            view, tableView in
            tableView.top == view.top + 30;
            tableView.bottom == view.bottom;
            tableView.left == view.left
            tableView.right == view.right
        }
        
    }
    func loadSources(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        var source: Source!
        
        Alamofire.request("https://newsapi.org/v1/sources?language=en").responseJSON { response in
            let json = JSON(data: response.data!)
            for i in 0...json["sources"].count{
                if( json["sources"][i] != JSON.null){
                    source = NSEntityDescription.insertNewObject(forEntityName: "Source", into: context) as! Source
                    source.id = String(describing:json["sources"][i]["id"])
                    source.name = String(describing:json["sources"][i]["name"])
                    source.url = String(describing:json["sources"][i]["url"])
                    source.num = i as! NSDecimalNumber
                    do{
                        try context.save()
                    }catch let err{
                        print(err)
                    }
                }
                
            }
            self.readFromCoreData()
        }
        
    }
    func readFromCoreData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Source")
        do{
            sources = try context.fetch(request) as! [Source]
            self.getNews()
        }catch let err{
            print(err)
        }
    }
    func entityIsEmpty(entity: String) -> Bool
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        do {
            let count = try context.count(for: request)
            if count == 0{
                return true
            }else{
                return false;
            }
            
            
        } catch {
            print("Error info: \(error)")
            
        }
        return false
        
    }

  
    func showAlert(){
        let alert = UIAlertController(title: "Alert", message: "test", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    func swipe(){
       // showAlert()
        sourceNum = 0
        articles = []
        self.getNews()
        refreshControl.endRefreshing()

    }
    func addTapped(){
        dismiss(animated: true, completion: nil)

    }
    func getNews(){
        SwiftSpinner.show("Connecting")
        Alamofire.request("https://newsapi.org/v1/articles?source=\(sources[sourceNum].id!)&apiKey=f70c88f0960d4b11bf656d9f36fd5333").responseJSON { response in
            
            let json = JSON(data: response.data!)
            for i in 0...json["articles"].count{

                if json["articles"][i] != JSON.null{
                    let a = Article()
                    a.author = String(describing:json["articles"][i]["author"])
                    a.title = String(describing: json["articles"][i]["title"])
                    a.description = String(describing: json["articles"][i]["description"])
                    a.url = String(describing:json["articles"][i]["url"])
                    a.urlToImage = String(describing:json["articles"][i]["urlToImage"])
                    a.publishedAt = String(describing:json["articles"][i]["publishedAt"])


                    self.articles.append(a)
                }
                
            }
            SwiftSpinner.hide()
            self.tableView.reloadData()

            
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        print(self.articles.count)
        
        return self.articles.count
        
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 70
    }
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let art1 = self.articles[(indexPath as NSIndexPath).item]
        let vc = ArticleViewController()
        vc.article = art1
        if let imgC = imageCache.object(forKey: NSString(string: articles[(indexPath as NSIndexPath).item].urlToImage!)){
            vc.img = imgC
        }else{
            URLSession.shared.dataTask(with: URL(string:articles[(indexPath as NSIndexPath).item].urlToImage!)!) { (data, response, error) in
                if error != nil{
                    print (error)
                    return
                }
                
                DispatchQueue.main.async() {
                    vc.img = UIImage(data: data!)
                    self.imageCache.setObject(UIImage(data: data!)!, forKey: NSString(string:self.articles[(indexPath as NSIndexPath).item].urlToImage!))
                }
                }.resume()
        }
        self.navigationController?.pushViewController(vc, animated: true)
        return indexPath
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        //    if(tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) && sourceNum >= 0 && sourceNum < sources.count) {
        //        self.sourceNum += 1
        //        self.getNews()
        //            // Start the animation
        //       // print("I am here")
        //        }
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UITableViewCell

        if(articles.count <= indexPath.item){
            return cell
        }
        if(articles.count - 1 == (indexPath as NSIndexPath).item){
            self.sourceNum += 1
            self.getNews()
        }
        cell.textLabel?.text = articles[(indexPath as NSIndexPath).item].title
        cell.textLabel?.numberOfLines = 3
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        if let imgC = imageCache.object(forKey: NSString(string: articles[(indexPath as NSIndexPath).item].urlToImage!)){
            cell.imageView?.image = imgC
        }else{
        URLSession.shared.dataTask(with: URL(string:articles[(indexPath as NSIndexPath).item].urlToImage!)!) { (data, response, error) in
            if error != nil{
                print (error)
                return
            }
            
            DispatchQueue.main.async() {
                cell.imageView?.image = UIImage(data: data!)
                self.imageCache.setObject(UIImage(data: data!)!, forKey: NSString(string:self.articles[(indexPath as NSIndexPath).item].urlToImage!))
            }
        }.resume()
        }
            cell.imageView?.frame = CGRect(x: 10, y: 0, width: 40, height: 40)
            cell.imageView?.contentMode = UIViewContentMode.scaleAspectFit
 
        return cell
    }



    


}

