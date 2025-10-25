//
//  TableViewCell.swift
//  Multiplier
//
//  Created by HT-Mac-08 on 10/10/25.
//

import UIKit
class TableViewCell: UITableViewCell {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var imageV: UIImageView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var likeCounter: UILabel!
    @IBOutlet weak var pImage: UIImageView!
    @IBOutlet weak var textVw: UITextView!
    var aspectRatioConstraint: NSLayoutConstraint?
    private lazy var  mainLoader = UIActivityIndicatorView(style: .medium)
    private lazy var profileLoader = UIActivityIndicatorView(style: .medium)
    @IBOutlet weak var name: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        imageV.contentMode = .scaleToFill
        imageV.clipsToBounds = true
        mainLoader.backgroundColor = .systemGray.withAlphaComponent(0.3)
        setupLoader(mainLoader, in: imageV)
        setupLoader(profileLoader, in: pImage)
        print("Loader frame:", mainLoader.frame)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        imageV.image = nil
        pImage.image = nil
        textVw.text = nil
        name.text = nil
        stopLoader()
        
    }
    func stopLoader()
    {
        mainLoader.stopAnimating()
           profileLoader.stopAnimating()
    }
    func startLoader()
    {
        mainLoader.startAnimating()
        profileLoader.startAnimating()
    }
       /// Loads the image and calls back with the image's original size.
    func configure(with urlString: String,
                   indexPath: IndexPath,
                   profileURL: String,
                   completion: @escaping (CGSize) -> Void) {

        imageV.image = nil
        pImage.image = nil
        DispatchQueue.main.async {
            self.startLoader()
         }

        Helper.loadImage(from: urlString) { [weak self] mainImage in
            guard let self = self, let mainImage = mainImage else { return }
            DispatchQueue.main.async {
                self.imageV.image = mainImage
                completion(mainImage.size)
                    self.stopLoader()
                 
            }
        }

        Helper.loadImage(from: profileURL) { [weak self] profileImage in
            guard let self = self, let profileImage = profileImage else { return }
            DispatchQueue.main.async {
                self.pImage.image = profileImage
                self.profileLoader.stopAnimating()

            }
        }
    }
    private func setupLoader(_ loader: UIActivityIndicatorView, in container: UIView) {
        // Prevent adding it again
        guard loader.superview == nil else { return }

        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.hidesWhenStopped = true
        container.addSubview(loader)

        // Bring to front to be visible above the image
        container.bringSubviewToFront(loader)

        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }
 
}

