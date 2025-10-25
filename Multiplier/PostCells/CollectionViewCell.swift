import UIKit

class CollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var profileName: UILabel!
    @IBOutlet weak var imageV: UIImageView!

    private lazy var imageLoader = UIActivityIndicatorView(style: .medium)

    override func awakeFromNib() {
        super.awakeFromNib()
        imageV.contentMode = .scaleAspectFill
        imageV.clipsToBounds = true
        imageV.layer.cornerRadius = 35.0
        setupLoader(imageLoader, in: imageV)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageV.image = nil
        imageLoader.startAnimating()
    }

    func configure(with imageURL: String, name: String) {
        profileName.text = name
        imageV.image = nil
        imageLoader.startAnimating()

        Helper.loadImage(from: imageURL) { [weak self] image in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.imageLoader.stopAnimating()
                self.imageV.image = image
                self.imageV.layer.cornerRadius = 45.0
            }
        }
    }
    private func setupLoader(_ loader: UIActivityIndicatorView, in container: UIView) {
        guard loader.superview == nil else { return }

        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.hidesWhenStopped = true
        container.addSubview(loader)
        container.bringSubviewToFront(loader)

        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }
}
