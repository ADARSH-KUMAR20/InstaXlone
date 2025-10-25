import AVKit
import AVFoundation
import UIKit

class TableViewCellVideo: UITableViewCell {

    @IBOutlet weak var likeCounter: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var pImage: UIImageView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var desc_TextView: UITextView!

    private(set) var videoUrl: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    private var endObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var tcObserver: NSKeyValueObservation? // timeControlStatus
    private var bufLikelyObserver: NSKeyValueObservation?
    private var bufEmptyObserver: NSKeyValueObservation?
    private var bufFullObserver: NSKeyValueObservation?
    // 🔸 Add this property to TableViewCellVideo
    var onVideoSizeKnown: ((CGSize) -> Void)?
    private var presSizeObserver: NSKeyValueObservation?
    private var loadToken = UUID()
    private var debugEnabled = false
    private lazy var overlayContainer = UIView()
       private lazy var overlayLabels: [DraggableLabel] = []

    private lazy var loader: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // On-screen debug label overlay
    private lazy var debugLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white
        l.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        l.isHidden = true
        l.layer.cornerRadius = 6
        l.clipsToBounds = true
        l.textAlignment = .left
        l.text = "DBG"
        return l
    }()

    // MARK: - Debug control

    func enableDebug(_ on: Bool) {
        debugEnabled = on
        debugLabel.isHidden = !on
        if on { videoView.layer.borderColor = UIColor.systemYellow.cgColor; videoView.layer.borderWidth = 1 }
        else { videoView.layer.borderWidth = 0 }
    }

 

    override func awakeFromNib() {
        super.awakeFromNib()
        pImage.layer.cornerRadius = 20
        pImage.clipsToBounds = true

        videoView.addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: videoView.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: videoView.centerYAnchor)
        ])

        videoView.addSubview(debugLabel)
        NSLayoutConstraint.activate([
            debugLabel.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: 8),
            debugLabel.topAnchor.constraint(equalTo: videoView.topAnchor, constant: 8),
            debugLabel.widthAnchor.constraint(lessThanOrEqualTo: videoView.widthAnchor, multiplier: 0.95)
        ])
        overlayContainer.translatesAutoresizingMaskIntoConstraints = false
        overlayContainer.backgroundColor = .clear
        videoView.addSubview(overlayContainer)
        NSLayoutConstraint.activate([
            overlayContainer.leadingAnchor.constraint(equalTo: videoView.leadingAnchor),
            overlayContainer.trailingAnchor.constraint(equalTo: videoView.trailingAnchor),
            overlayContainer.topAnchor.constraint(equalTo: videoView.topAnchor),
            overlayContainer.bottomAnchor.constraint(equalTo: videoView.bottomAnchor),
        ])
        // Make sure overlays are above the player layer
        videoView.bringSubviewToFront(overlayContainer)
        // helps visually verify the container is visible
       // #if DEBUG
        videoView.backgroundColor = .white
//        #endif
    }
   
    deinit { tearDownPlayerAndObservers() }

    override func prepareForReuse() {
        super.prepareForReuse()
        likeCounter.text = nil
        name.text = nil
        desc_TextView.text = nil
        pImage.image = nil
        clearTextOverlays()

        videoUrl = nil
        tearDownPlayerAndObservers()
        loader.stopAnimating()
        debugLabel.text = "DBG"
    }

    // Keep player layer behind overlays after layout changes


    // MARK: - Public API to manage text overlays

    /// Add a text label over the video. Call from VC when user taps "Add Text".
    func addTextOverlay(
        _ text: String,
        font: UIFont = .systemFont(ofSize: 24, weight: .semibold),
        color: UIColor = .white,
        background: UIColor? = UIColor.black.withAlphaComponent(0.35),
        at point: CGPoint? = nil,
        width: CGFloat? = nil
    ) {
        let label = DraggableLabel()
        label.text = text
        label.font = font
        label.textColor = color
        if let bg = background {
            label.backgroundColor = bg
            label.layer.cornerRadius = 8
            label.clipsToBounds = true
        }

        // Initial frame: centered, or at provided point
        let containerSize = overlayContainer.bounds.size
        let maxW = min(containerSize.width * 0.8, width ?? containerSize.width * 0.8)
        let size = (text as NSString).boundingRect(
            with: CGSize(width: maxW, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).integral.size

        let origin: CGPoint = {
            if let p = point { return p }
            return CGPoint(x: 20,
                           y: 20)
        }()

        label.frame = CGRect(origin: origin, size: size)
        overlayContainer.addSubview(label)
        overlayLabels.append(label)
    }

    /// Update an existing overlay’s text (you can track by index)
    func updateTextOverlay(at index: Int, text: String) {
        guard overlayLabels.indices.contains(index) else { return }
        let label = overlayLabels[index]
        label.text = text
        label.sizeToFit()
    }

    /// Remove all overlays (called on reuse or when clearing)
    func clearTextOverlays() {
        overlayLabels.forEach { $0.removeFromSuperview() }
        overlayLabels.removeAll()
    }

    // Optional: snapshot overlays to image/layers for export later
    func currentOverlaySnapshot(scaleTo size: CGSize? = nil) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: overlayContainer.bounds)
        let img = renderer.image { _ in overlayContainer.drawHierarchy(in: overlayContainer.bounds, afterScreenUpdates: true) }
        guard let size = size else { return img }
        // scale if you need to map to renderSize (e.g., 1080x1920)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        let r2 = UIGraphicsImageRenderer(size: size, format: fmt)
        return r2.image { _ in
            img.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    /// Call this from cellForRowAt
    func configure(name: String?,
                   description: String?,
                   profileImageURL: String?,
                   likeCount: Int?,
                   videoURLString: String?,
                   autoplay: Bool = true,
                   muted: Bool = true,
                   debug: Bool = true) {
        self.name.text = name
        self.desc_TextView.text = description
        if let likeCount { self.likeCounter.text = "\(likeCount)" }
        if let profileImageURL,
           let url = URL(string: profileImageURL) {
            DispatchQueue.global(qos: .userInitiated).async
            {
                Helper.loadImage(from: profileImageURL) { [weak self] img in
                    DispatchQueue.main.async{
                        self?.pImage.image = img
                        
                    }
                    
                }}

        }

        guard let videoURLString, let url = URL(string: videoURLString) else {
            tearDownPlayerAndObservers()
            loader.stopAnimating()
            return
        }
        videoUrl = url
        loadToken = UUID()

        loader.startAnimating()

        setNeedsLayout()
        layoutIfNeeded()

        if videoView.bounds.size == .zero {
        //    dlog("⚠️ videoView has zero size. Will retry after next runloop")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.setNeedsLayout(); self.layoutIfNeeded()
                self.buildPlayer(url: url, autoplay: autoplay, muted: muted)
            }
        } else {
            buildPlayer(url: url, autoplay: autoplay, muted: muted)
        }
    }

    private func buildPlayer(url: URL, autoplay: Bool, muted: Bool) {
        tearDownPlayerAndObservers()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = muted
        player.automaticallyWaitsToMinimizeStalling = true
        self.player = player

        // Layer
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = videoView.bounds
        videoView.layer.addSublayer(layer)
        self.playerLayer = layer
        presSizeObserver = item.observe(\.presentationSize, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            let sz = item.presentationSize
            if sz.width > 0 && sz.height > 0 {
                DispatchQueue.main.async {
                    self.onVideoSizeKnown?(sz) // callback to TvDataSource
                }
            }
        }
        // Observe status
        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self = self else { return }
            guard self.videoUrl == url else { return }
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    if autoplay {
                        
                        self.player?.play() }
                case .failed:
                    if item.errorLog() != nil {
                    }
                    self.loader.stopAnimating()
                case .unknown: break
                @unknown default: break
                }
            }
        }

        // Observe timeControlStatus (useful if stuck at .waitingToPlayAtSpecifiedRate)
        tcObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] p, _ in
            guard self != nil else { return }
        }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] t in
            guard let self = self else { return }
            if t.seconds > 0.05 {
                self.loader.stopAnimating()
                if let to = self.timeObserver {
                    self.player?.removeTimeObserver(to)
                    self.timeObserver = nil
                }
            }
        }

        // Loop
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
    
            self.player?.seek(to: .zero)
            self.player?.play()
        }
    }

    func play()  {  player?.play() }
    func pause() {  player?.pause() }

    private func tearDownPlayerAndObservers() {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        presSizeObserver?.invalidate()
        presSizeObserver = nil
        statusObserver?.invalidate(); statusObserver = nil
        tcObserver?.invalidate(); tcObserver = nil
        bufLikelyObserver?.invalidate(); bufLikelyObserver = nil
        bufEmptyObserver?.invalidate(); bufEmptyObserver = nil
        bufFullObserver?.invalidate(); bufFullObserver = nil

        if let to = timeObserver { player?.removeTimeObserver(to); timeObserver = nil }

        playerLayer?.removeFromSuperlayer(); playerLayer = nil

        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let pl = playerLayer, pl.frame != videoView.bounds {
            pl.frame = videoView.bounds
           
        }
        playerLayer?.frame = videoView.bounds
        videoView.bringSubviewToFront(overlayContainer)
    }

}


// Add these at top-level in your cell file
final class DraggableLabel: UILabel {
    override init(frame: CGRect) { super.init(frame: frame); commonInit() }
    required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
    private func commonInit() {
        numberOfLines = 0
        textAlignment = .center
        isUserInteractionEnabled = true
        textColor = .white
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 4
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(_:))))
        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:))))
        addGestureRecognizer(UIRotationGestureRecognizer(target: self, action: #selector(onRotate(_:))))
    }
    @objc private func onPan(_ g: UIPanGestureRecognizer) {
        let t = g.translation(in: superview)
        center = CGPoint(x: center.x + t.x, y: center.y + t.y)
        g.setTranslation(.zero, in: superview)
    }
    @objc private func onPinch(_ g: UIPinchGestureRecognizer) {
        transform = transform.scaledBy(x: g.scale, y: g.scale); g.scale = 1
    }
    @objc private func onRotate(_ g: UIRotationGestureRecognizer) {
        transform = transform.rotated(by: g.rotation); g.rotation = 0
    }
}
