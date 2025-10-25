//
//  ViewController.swift
//  Multiplier
//
//  Created by HT-Mac-08 on 10/10/25.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    private lazy var tableViewDataSource =  DataSource()

    @IBOutlet weak var collectionVw: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
        loadData()


    }
    func loadData()
    {
        let posts = loadPostsFromJSON()
        print("✅ Loaded posts: \(posts.count)")
        tableViewDataSource.data = posts
        tableViewDataSource.tableView = tableView
        tableViewDataSource.collectionVw = collectionVw
        DispatchQueue.main.async {
            // 4) Refresh UI
            self.tableView.reloadData()
            self.collectionVw.reloadData()
        }

        
    }
    func registerCells()
    {
        let nibTv = UINib(nibName: "TableViewCell", bundle: nil)
        tableView.register(nibTv, forCellReuseIdentifier: "TableViewCell")
        let nibTvVideo = UINib(nibName: "TableViewCellVideo", bundle: nil)
        tableView.register(nibTvVideo, forCellReuseIdentifier: "TableViewCellVideo")
        tableView.rowHeight = 1000
        tableView.estimatedRowHeight = 2000
        let nibCv = UINib(nibName: "CollectionViewCell", bundle: nil)
        collectionVw.register(nibCv, forCellWithReuseIdentifier: "CollectionViewCell")
        tableView.dataSource = tableViewDataSource
        tableView.delegate = tableViewDataSource
        tableView.separatorStyle = .none
        collectionVw.delegate = tableViewDataSource
        collectionVw.dataSource = tableViewDataSource
        
    }
    
}

extension UIImageView {
    func loadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }
}

extension ViewController {
    func loadPostsFromJSON() -> [PostModel] {
        guard let url = Bundle.main.url(forResource: "post", withExtension: "json") else {
            print("❌ posts.json not found")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let posts = try JSONDecoder().decode([PostModel].self, from: data)
            return posts
        } catch {
            print("❌ Failed to load posts: \(error)")
            return []
        }
    }
}
