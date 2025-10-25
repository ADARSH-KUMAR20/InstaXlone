//
//  TvDataSource.swift
//  Multiplier
//
//  Created by HT-Mac-08 on 10/10/25.
//

//
//  TvDataSource.swift
//  Multiplier
//
//  Created by HT-Mac-08 on 10/10/25.
//

import Foundation
import UIKit
import AVKit

class DataSource: NSObject,
                    UITableViewDelegate,
                    UITableViewDataSource,
                    UICollectionViewDataSource,
                    UICollectionViewDelegateFlowLayout {

    init(tableView: UITableView? = nil,
         collectionVw: UICollectionView? = nil,
         data: [PostModel]? = nil) {
        self.tableView = tableView
        self.collectionVw = collectionVw
        self.data = data
    }

    private var imageSizes: [IndexPath: CGSize] = [:]
     var tableView: UITableView?
     var collectionVw: UICollectionView?
     var data: [PostModel]?
    private var videoSizes: [IndexPath: CGSize] = [:]

    let profileUrls = [ "https://picsum.photos/1000/1000" ]

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.count ?? 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let post = data?[indexPath.row] else { return UITableViewCell() }

        // ✅ NEW: check if post contains a video URL
        // cellForRowAt
        if let videoURL = post.videoURL, !videoURL.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCellVideo",
                                                     for: indexPath) as! TableViewCellVideo
            cell.configure(name: post.name,
                           description: post.description,
                           profileImageURL: post.profileImage,
                           likeCount: post.likeCount,
                           videoURLString: videoURL,
                           autoplay: false,   // we’ll play only when visible
                           muted: true)
            // 🔸 When the cell learns the presentation size, cache it and update row height smoothly
               cell.onVideoSizeKnown = { [weak self, weak tableView] size in
                   guard let self = self, let tableView = tableView else { return }
                   // ignore absurd/duplicate updates
                   guard size.width > 0, size.height > 0 else { return }
                   // Only update if changed to reduce layout churn
                   if self.videoSizes[indexPath] != size {
                       self.videoSizes[indexPath] = size
                       // Update the specific row if it's visible
                       if tableView.indexPathsForVisibleRows?.contains(indexPath) == true {
                           tableView.beginUpdates()
                           tableView.endUpdates()
                       }
                   }
               }
            // In cellForRowAt (after configure(...)):
//            (cell as? TableViewCellVideo)?.addTextOverlay(
//                "Caption Your Reel",
//                font: .systemFont(ofSize: 16, weight: .bold),
//                color: .white,
//                background: UIColor.black.withAlphaComponent(0.5)
//            )

            // Add multiple:
            cell.addTextOverlay("#Trending -- Test", font: .systemFont(ofSize: 15, weight: .medium), color: .systemGray)
            return cell
        } else {
            // Use normal image cell
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell",
                                                           for: indexPath) as? TableViewCell else {
                return UITableViewCell()
            }

            cell.textVw.text = post.description
            cell.name.text = post.name
            cell.pImage.layer.cornerRadius = 20.0
            cell.likeCounter.text = "\(post.likeCount)"

            cell.configure(with: post.mainImage,
                           indexPath: indexPath,
                           profileURL: post.profileImage) { [weak self] size in
                guard let self = self else { return }
                self.imageSizes[indexPath] = size
                DispatchQueue.main.async {
                    if let visible = tableView.indexPathsForVisibleRows,
                       visible.contains(indexPath) {
                        tableView.beginUpdates()
                        tableView.endUpdates()
                    }
                }
            }
            

            return cell
        }
    }
    // willDisplay / didEndDisplaying to auto-play only when visible
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? TableViewCellVideo)?.play()
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? TableViewCellVideo)?.pause()
    }
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let post = data?[indexPath.row] else { return 300 }
        let availableWidth = tableView.bounds.width

        if let videoURL = post.videoURL, !videoURL.isEmpty {
                    // 🔸 If we know the video’s presentation size, use its aspect
                    if let vSize = videoSizes[indexPath], vSize.width > 0 {
                        let aspect = vSize.height / vSize.width
                        let videoHeight = availableWidth * aspect
                        // Add any extra vertical chrome (labels, etc.). Adjust as needed.
                        let chrome: CGFloat = 400
                        return videoHeight + chrome
                    }
                }

        // Existing height logic for image-based post
        if let size = imageSizes[indexPath], size.width > 0 {
            let r = size.height / size.width
            let imageHeight = availableWidth * r
            return imageHeight + 66
        } else {
            return 300
        }
    }

    // MARK: - CollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "CollectionViewCell",
            for: indexPath) as? CollectionViewCell else {
            return UICollectionViewCell()
        }

        let url = profileUrls[0]
        let name = "\(data?[1].name ?? "Unknown")"
        cell.configure(with: url, name: name)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 90, height: 120)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
}
