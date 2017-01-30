//
//  ViewController.swift
//  AVPlayerKVO
//
//  Created by Jason Gresh on 1/25/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import AVFoundation

/*
 You can do this work on the master branch of your fork of https://github.com/C4Q/AC3.2-AVPlayerKVO. I've selected these required exercises. Feel free to do any of the others.

Add total duration and current time labels adjacent to your progress slider.
Create a visualization of loadedTimeRanges and seekableTimeRanges using KVO.
Support rotation by putting controls to the right of the frame on landscape and under it for portrait.
 */

private var kvoContext = 0 //one channel should have one context

class ViewController: UIViewController {
    var player: AVPlayer! {
        //willSet is a better one to remove observers
        willSet {
            //newValue is type AVPlayer!
            if player != nil {
                //About to die
                if let item = self.player.currentItem {
                    item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &kvoContext)
                    item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), context: &kvoContext)
                    item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.seekableTimeRanges), context: &kvoContext)
                }
                if let token = self.timeObserverToken {
                    player.removeTimeObserver(token)
                }
            }
            
            //About to set
            if let item = newValue.currentItem {
                item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: &kvoContext)
                item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: .new, context: &kvoContext)
                item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.seekableTimeRanges), options: .new, context: &kvoContext)
            }
            let timeInterval = CMTime(value: 1, timescale: 2)
            self.timeObserverToken = newValue.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: {  (time: CMTime) in
                print(time)
                self.updatePositionSlider()
            })
        }
        didSet {
            //oldValue is type AVPlayer
        }
    }
    
    // MARK: - Outlet Objects
//    @IBOutlet weak var videoContainer: UIView!
//    @IBOutlet weak var positionSlider: UISlider!
//    
//    @IBOutlet weak var startPauseButton: UIButton!
//    
//    @IBOutlet weak var rateLabel: UILabel!
//    @IBOutlet weak var rateSlider: UISlider!
//    
//    @IBOutlet weak var loadedTimeRangeBarView: UIView!
//    @IBOutlet weak var loadedTimeRangeIndicatorView: UIView!
//    @IBOutlet weak var totalDurationLabel: UILabel!
//    @IBOutlet weak var currentTimeLabel: UILabel!
    
    // MARK: - Constraint Outlets
//    @IBOutlet weak var loadedTimeRangeIndicatorViewWidthConstraint: NSLayoutConstraint!
    
    // MARK: - Variables
    var userPlaying: Bool = false
    var userPlayRate: Float = 1.0
    var timeObserverToken: Any?
    var loadedTimeRangeWidth : CGFloat = 10
    var loadedTimeRangeIndicatorViewWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupHierarchy()
        self.configurePortraitConstraints()
        
        //If loadAssetFromFile and load url from file, it will crash eventually because the observer is still there

        loadAssetFromFile(urlString: "debussy.mp3") //This will play audio only
        
        //https://ia801400.us.archive.org/18/items/VoyagetothePlanetofPrehistoricWomen/VoyagetothePlanetofPrehistoricWomen.mp4
        //http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8
        if let url = URL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8") {
            // Added willSet in the AVPlayer object
            let playerItem = AVPlayerItem(url: url)
            
            ///Setting the player's current item to be playerItem, deiniting the old one that has an observer
            player = AVPlayer(playerItem: playerItem)
            
            let playerLayer = AVPlayerLayer(player: player)
            self.videoContainer.layer.addSublayer(playerLayer)

            
            
            
            /* //Refactored code and remove some observer
            let playerItem = AVPlayerItem(url: url)
            
            ////Observe value can be calling for any object we are seeing at the same context
            //playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem), options: .new, context: &kvoContext)
            playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: &kvoContext)
            
            ///Remove the current item before setting the new player's currentItem
            if player != nil {
                if let item = self.player.currentItem {
                    item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &kvoContext)
                }
            }
            
            if let token = self.timeObserverToken {
                player.removeTimeObserver(token)
            }
            
            ///Setting the player's current item to be playerItem, deiniting the old one that has an observer
            player = AVPlayer(playerItem: playerItem)
            
            let playerLayer = AVPlayerLayer(player: player)
            self.videoContainer.layer.addSublayer(playerLayer)

            let timeInterval = CMTime(value: 1, timescale: 2)
            self.timeObserverToken = player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: {  (time: CMTime) in
                print(time)
                self.updatePositionSlider()
            })
            
            */
            
            
            
            
            
            /* //The following is the minimal viable product
             let playerItem = AVPlayerItem(url: url)
            
            ////The old one that's not safe because it's hard coding string keypath value
            playerItem.addObserver(self, forKeyPath: "status", options: .new, context: &kvoContext)

            ///Setting the player's current item to be playerItem
            player = AVPlayer(playerItem: playerItem)
            
            let playerLayer = AVPlayerLayer(player: player)
            //playerLayer.frame = self.videoContainer.bounds
            self.videoContainer.layer.addSublayer(playerLayer)
            
            //Need to comment out because the following also using kvo
            let timeInterval = CMTime(value: 1, timescale: 2)
            player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time: CMTime) in
                print(time)
                self.updatePositionSlider()
            })
            */
        }
    }
    

    override func viewDidLayoutSubviews() {
        guard let sublayers = self.videoContainer.layer.sublayers
            else {
                return
        }
        for layer in sublayers {
            layer.frame = self.videoContainer.bounds
        }
        self.positionSlider.maximumTrackTintColor = UIColor.red
    }
    
    // MARK: - Utility
    func updatePositionSlider() {
        guard let item = player.currentItem else { return }
        
        let currentPlace = Float(item.currentTime().seconds / item.duration.seconds)
        self.positionSlider.value = currentPlace
        DispatchQueue.main.async {
            self.view.layoutIfNeeded()
        }
    }
    
    func loadAssetFromFile(urlString: String) {
        //After Added willSet in AVPlayer!
        guard let dot = urlString.range(of: ".") else { return }
        let fileParts = (resource: urlString.substring(to: dot.lowerBound), extension: urlString.substring(from: dot.upperBound))
        
        if let fileURL = Bundle.main.url(forResource: fileParts.resource, withExtension: fileParts.extension) {
            let asset = AVURLAsset(url: fileURL)
            let playerItem = AVPlayerItem(asset: asset)
            
            self.player = AVPlayer(playerItem: playerItem)
        }


        
        
        /* //Before Using willSet in AVPlayer!
        //Updated the forKeyPath, instead of using a hard coded String
        guard let dot = urlString.range(of: ".") else { return }
        let fileParts = (resource: urlString.substring(to: dot.lowerBound), extension: urlString.substring(from: dot.upperBound))
        
        if let fileURL = Bundle.main.url(forResource: fileParts.resource, withExtension: fileParts.extension) {
            let asset = AVURLAsset(url: fileURL)
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: &kvoContext)
            self.player = AVPlayer(playerItem: playerItem)
            
            let timeInterval = CMTime(value: 1, timescale: 2)
            player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time: CMTime) in
                print(time)
                self.updatePositionSlider()
            })
        }
        */
        
        
        
        
        /* //The following is minimal viable product
        guard let dot = urlString.range(of: ".") else { return }
        let fileParts = (resource: urlString.substring(to: dot.lowerBound), extension: urlString.substring(from: dot.upperBound))
        
        if let fileURL = Bundle.main.url(forResource: fileParts.resource, withExtension: fileParts.extension) {
            let asset = AVURLAsset(url: fileURL)
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.addObserver(self, forKeyPath: "status", options: .new, context: &kvoContext)
            self.player = AVPlayer(playerItem: playerItem)
            
            let timeInterval = CMTime(value: 1, timescale: 2)
            player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time: CMTime) in
                print(time)
                self.updatePositionSlider()
            })
        }
        */
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath else {
            return
        }
//        //This is better because we are checking the object as the particular item, because other may also be observing at the same context
        if context == &kvoContext {
            if let item = object as? AVPlayerItem{
                switch keyPath {
                case #keyPath(AVPlayerItem.status):
                    if item.status == .readyToPlay {
                        startPauseButton.isEnabled = true
                    }
                case #keyPath(AVPlayerItem.loadedTimeRanges):
                    for range in item.loadedTimeRanges {
                        percentLoaded(range)
                    }
                case #keyPath(AVPlayerItem.seekableTimeRanges):
                    for range in item.seekableTimeRanges {
                        //CMTimeRangeGetEnd(range.timeRangeValue)
                        //print(range.timeRangeValue)
                        //self.availableDuration += availableDuration(range)
                    }
                default:
                    break
                }
            }
        }
        /*
        //The following is not working because it's not switching on the keyPath
        guard let keyPath = keyPath else {
            return
        }
        
        if context == &kvoContext {
            switch keyPath {
            case #keyPath(AVPlayerItem.status):
                if let item = object as? AVPlayerItem{
                    if item.status == .readyToPlay {
                        startPauseButton.isEnabled = true
                    }
                }
            default:
                break
            }
        }
        
        if context == &kvoContext {
            if keyPath == "status",
                let item = object as? AVPlayerItem {
                if item.status == .readyToPlay {
                    //player.play() //The position slider slide and will automatically play
                    startPauseButton.isEnabled = true
                }
            }
        }
         */
    }
    
    //http://stackoverflow.com/questions/6815316/ios-how-can-i-get-the-playable-duration-of-avplayer
    func percentLoaded (_ range: NSValue) {
        let timeRange = range.timeRangeValue
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSections = CMTimeGetSeconds(timeRange.duration)
       
        print("startSeconds:\(startSeconds), durationSections\(durationSections) ")
        
        let duration = self.player.currentItem?.asset.duration
        let durationInSeconds : Float64 = CMTimeGetSeconds(duration!)
        
        let result = startSeconds + durationSections
        let percentage = result / durationInSeconds
        
        DispatchQueue.main.async {
           // self.loadedTimeRangeIndicatorViewWidthConstraint.constant = CGFloat(self.loadedTimeRangeBarView.frame.width) * CGFloat(percentage)
            //self.loadedTimeRangeWidth = CGFloat(self.loadedTimeRangeView.frame.width) * CGFloat(percentage)
            self.loadedTimeRangeIndicatorViewWidthConstraint.constant = CGFloat(self.loadedTimeRangeView.frame.width) * CGFloat(percentage)
            self.view.layoutIfNeeded()
            print(percentage)
            
            self.totalDurationLabel.text = "Total Duration: \(durationInSeconds)s"
            self.currentTimeLabel.text = "Current Time: \(self.player.currentItem!.currentTime().seconds)s"
        }
        
        func seekableTimeRangePercentage(_ range: NSValue) {
            var timeRange = range.timeRangeValue
            var startInSeconds = CMTimeGetSeconds(timeRange.start)
            var duration = CMTimeGetSeconds(timeRange.duration)
        }
    
        /*
         - (NSTimeInterval) availableDuration;
         {
         NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
         CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
         Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
         Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
         NSTimeInterval result = startSeconds + durationSeconds;
         return result;
         }
         */
    }
    
    
    // MARK: - Actions
    @IBAction func positionSliderChanged(_ sender: UISlider) {
        guard let item = player.currentItem else { return }

        let newPosition = Double(sender.value) * item.duration.seconds
        
        //player.rate = rateSlider.value
        player.seek(to: CMTime(seconds: newPosition, preferredTimescale: 1000))
        //if userPlaying { //uncomment this will only play when it's playing
            player.playImmediately(atRate: userPlayRate)
        //}
    }
    
    @IBAction func rateChange(_ sender: UISlider) {
        guard let item = player.currentItem else { return }
        userPlayRate = sender.value
        if item.canPlayFastForward {
            print("I can fast forward/ Rate requested: \(sender.value).")
        }
        if item.canPlaySlowForward {
            print("I can slow forward")
        }
        
        if userPlaying {
            player.rate = userPlayRate
        }
        
        //player.rate = userPlayRate
        print("NEW rate: \(player.rate)")
        
    }
    
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        if !userPlaying {
            player.playImmediately(atRate: userPlayRate)
            sender.setTitle("Pause", for: .normal)
        } else {
            player.pause()
            sender.setTitle("Start", for: .normal)
        }
        userPlaying = !userPlaying
        
//        //The way I was initially setting it with selector and buttons
//        player.pause()
//        self.rateSlider.setValue(0.0, animated: true)
//        self.pauseButton.setTitle("Start", for: UIControlState.normal)
//        self.pauseButton.addTarget(self, action: #selector(startButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        
//        Method 1
//        if self.pauseButton.titleLabel?.text == "Pause" {
//            player.pause()
//            self.rateSlider.value = 0.0
//            self.pauseButton.setTitle("Start", for: UIControlState.normal)
//        } else {
//            self.pauseButton.setTitle("Pause", for: UIControlState.normal)
//            self.rateSlider.value = 1.0
//            player.play()
//        }
    }
    
//    func startButtonPressed(_ sender: UIButton) {
//        player.play()
//        self.startPauseButton.setTitle("Pause", for: UIControlState.normal)
//        self.rateSlider.setValue(1.0, animated: true)
//        //self.rateSlider.value = 1.0
//        self.startPauseButton.addTarget(self, action: #selector(pauseButtonPressed(_:)), for: UIControlEvents.touchUpInside)
//    }
    
    lazy var videoContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var positionSlider: UISlider = {
        let slider = UISlider()
        slider.addTarget(self, action: #selector(positionSliderChanged), for: UIControlEvents.valueChanged)
        return slider
    }()
    
    lazy var startPauseButton: UIButton = {
       let button = UIButton()
        button.setTitle("Start", for: .normal)
        button.backgroundColor = UIColor.blue
        button.addTarget(self, action: #selector(pauseButtonPressed), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    lazy var rateLabel: UILabel = {
        let label = UILabel()
        label.text = "Rate"
        return label
    }()
    
    lazy var rateSlider: UISlider = {
        let slider = UISlider()
        slider.addTarget(self, action: #selector(rateChange), for: UIControlEvents.valueChanged)
        return slider
    }()
    
    lazy var loadedTimeRangeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.cyan
        return view
    }()
    
    lazy var loadedTimeRangeIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.orange
        return view
    }()
    
    lazy var totalDurationLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "Time Duration: "
        return label
    }()
    
    lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "Current Time: "
        return label
    }()
    
    lazy var seekableTimeRangeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blue
        return view
    }()
    
    var videoContainerConstraints: [NSLayoutConstraint] = []
    var positionSliderConstraints: [NSLayoutConstraint] = []
    var startPauseButtonConstaints: [NSLayoutConstraint] = []
    var rateLabelConstraints: [NSLayoutConstraint] = []
    var rateSliderConstraints: [NSLayoutConstraint] = []
    var loadedTimeRangeViewConstraints: [NSLayoutConstraint] = []
    var loadedTimeRangeIndicatorViewConstraints: [NSLayoutConstraint] = []
    var totalDurationLabelConstraints: [NSLayoutConstraint] = []
    var currentTimeLabelConstraints: [NSLayoutConstraint] = []
    var seekableTimeRangeViewConstraints: [NSLayoutConstraint] = []
    
    func setupHierarchy() {
        self.view.addSubview(videoContainer)
        self.view.addSubview(positionSlider)
        self.view.addSubview(startPauseButton)
        self.view.addSubview(rateLabel)
        self.view.addSubview(rateSlider)
        self.view.addSubview(loadedTimeRangeView)
        self.loadedTimeRangeView.addSubview(loadedTimeRangeIndicatorView)
        self.view.addSubview(currentTimeLabel)
        self.view.addSubview(totalDurationLabel)
        self.view.addSubview(seekableTimeRangeView)
        
        self.edgesForExtendedLayout = []
    }
    
    func configurePortraitConstraints() {
        videoContainer.accessibilityIdentifier = "VideoContainer"
        positionSlider.accessibilityIdentifier = "PositionSlider"
        startPauseButton.accessibilityIdentifier = "StartPauseButton"
        rateLabel.accessibilityIdentifier = "RateLabel"
        loadedTimeRangeView.accessibilityIdentifier = "LoadedTimeRangeVIew"
        loadedTimeRangeIndicatorView.accessibilityIdentifier = "LoadedTimeRangeIndicatorView"
        totalDurationLabel.accessibilityIdentifier = "TotalDurationLabel"
        currentTimeLabel.accessibilityIdentifier = "CurrentTimeLabel"
        let _ = [
            videoContainer,
            positionSlider,
            startPauseButton,
            rateLabel,
            rateSlider,
            loadedTimeRangeView,
            loadedTimeRangeIndicatorView,
            totalDurationLabel,
            currentTimeLabel,
            seekableTimeRangeView,
            ].map{$0.translatesAutoresizingMaskIntoConstraints = false}
        
        removeParentOwnedConstraints(from: videoContainer)
        removeParentOwnedConstraints(from: positionSlider)
        removeParentOwnedConstraints(from: startPauseButton)
        removeParentOwnedConstraints(from: rateLabel)
        removeParentOwnedConstraints(from: rateSlider)
        removeParentOwnedConstraints(from: loadedTimeRangeView)
        removeParentOwnedConstraints(from: loadedTimeRangeIndicatorView)
        removeParentOwnedConstraints(from: totalDurationLabel)
        removeParentOwnedConstraints(from: currentTimeLabel)
        removeParentOwnedConstraints(from: seekableTimeRangeView)
        
        loadedTimeRangeIndicatorViewWidthConstraint = loadedTimeRangeIndicatorView.widthAnchor.constraint(equalToConstant: 100.0)
        
        videoContainerConstraints = [
            videoContainer.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8.0),
            videoContainer.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            videoContainer.heightAnchor.constraint(equalTo: self.videoContainer.widthAnchor, multiplier: 3/4),
            videoContainer.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -16.0),
        ]
        
        positionSliderConstraints = [
            positionSlider.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8.0),
            positionSlider.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8.0),
            positionSlider.topAnchor.constraint(equalTo: videoContainer.bottomAnchor, constant: 8.0),
            ]
            
            //rateLabel
        rateLabelConstraints = [
            rateLabel.topAnchor.constraint(equalTo: positionSlider.bottomAnchor, constant: 8.0),
            rateLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8.0),
            rateLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8.0),]
            
            //rateSlider
        rateSliderConstraints = [
            rateSlider.topAnchor.constraint(equalTo: self.rateLabel.bottomAnchor, constant: 8.0),
            rateSlider.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8.0),
            rateSlider.trailingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -8.0),]
            
        startPauseButtonConstaints = [
            startPauseButton.topAnchor.constraint(equalTo: self.rateLabel.bottomAnchor, constant: 8.0),
            startPauseButton.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 8.0),
            ]
        
        loadedTimeRangeViewConstraints = [
            loadedTimeRangeView.topAnchor.constraint(equalTo: rateSlider.bottomAnchor, constant: 8.0),
            loadedTimeRangeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0),
            loadedTimeRangeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0),
            loadedTimeRangeView.heightAnchor.constraint(equalToConstant: 30.0),
            ]
        
        loadedTimeRangeIndicatorViewConstraints = [
            loadedTimeRangeIndicatorView.topAnchor.constraint(equalTo: self.loadedTimeRangeView.topAnchor),
            loadedTimeRangeIndicatorView.leadingAnchor.constraint(equalTo: self.loadedTimeRangeView.leadingAnchor),
            loadedTimeRangeIndicatorView.heightAnchor.constraint(equalToConstant: 30.0),
            loadedTimeRangeIndicatorViewWidthConstraint,
            ]
        
        seekableTimeRangeViewConstraints = [
            seekableTimeRangeView.topAnchor.constraint(equalTo: self.loadedTimeRangeView.bottomAnchor, constant: 8.0),
            seekableTimeRangeView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8.0),
            seekableTimeRangeView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8.0),
            seekableTimeRangeView.heightAnchor.constraint(equalToConstant: 30.0)
        ]
        
        totalDurationLabelConstraints = [
            totalDurationLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8.0),
            totalDurationLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8.0),
            totalDurationLabel.bottomAnchor.constraint(equalTo: self.currentTimeLabel.topAnchor, constant: -8.0),
            totalDurationLabel.heightAnchor.constraint(equalToConstant: 30.0)
            ]
            
        currentTimeLabelConstraints = [
            currentTimeLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8.0),
            currentTimeLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8.0),
            currentTimeLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -8.0),
            currentTimeLabel.heightAnchor.constraint(equalToConstant: 30.0)
            ]
        
        let _ = [ videoContainerConstraints,
            positionSliderConstraints,
            startPauseButtonConstaints,
            rateLabelConstraints,
            rateSliderConstraints,
            loadedTimeRangeViewConstraints,
            loadedTimeRangeIndicatorViewConstraints,
            seekableTimeRangeViewConstraints,
            totalDurationLabelConstraints,
            currentTimeLabelConstraints].map {$0.map{$0.isActive = true}}
    }
    
    func configureLandscapeConstraints() {
        videoContainer.accessibilityIdentifier = "VideoContainer"
        positionSlider.accessibilityIdentifier = "PositionSlider"
        startPauseButton.accessibilityIdentifier = "StartPauseButton"
        rateLabel.accessibilityIdentifier = "RateLabel"
        loadedTimeRangeView.accessibilityIdentifier = "LoadedTimeRangeVIew"
        loadedTimeRangeIndicatorView.accessibilityIdentifier = "LoadedTimeRangeIndicatorView"
        totalDurationLabel.accessibilityIdentifier = "TotalDurationLabel"
        currentTimeLabel.accessibilityIdentifier = "CurrentTimeLabel"
    
        removeParentOwnedConstraints(from: videoContainer)
        removeParentOwnedConstraints(from: positionSlider)
        removeParentOwnedConstraints(from: startPauseButton)
        removeParentOwnedConstraints(from: rateLabel)
        removeParentOwnedConstraints(from: rateSlider)
        removeParentOwnedConstraints(from: loadedTimeRangeView)
        removeParentOwnedConstraints(from: loadedTimeRangeIndicatorView)
        removeParentOwnedConstraints(from: totalDurationLabel)
        removeParentOwnedConstraints(from: currentTimeLabel)
        removeParentOwnedConstraints(from: seekableTimeRangeView)
        
        loadedTimeRangeIndicatorViewWidthConstraint = loadedTimeRangeIndicatorView.widthAnchor.constraint(equalToConstant: 100.0)
        
        let _ = [
            videoContainer,
            positionSlider,
            startPauseButton,
            rateLabel,
            rateSlider,
            loadedTimeRangeView,
            loadedTimeRangeIndicatorView,
            totalDurationLabel,
            currentTimeLabel,
            seekableTimeRangeView
            ].map{$0.translatesAutoresizingMaskIntoConstraints = false}
        
        videoContainerConstraints = [
            videoContainer.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8.0),
            videoContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8.0),
            videoContainer.heightAnchor.constraint(equalTo: self.videoContainer.widthAnchor, multiplier: 3/4),
            videoContainer.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.45),
            ]
            
         positionSliderConstraints = [
            positionSlider.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8.0),
            positionSlider.trailingAnchor.constraint(equalTo: self.view.centerXAnchor),
            positionSlider.topAnchor.constraint(equalTo: videoContainer.bottomAnchor, constant: 8.0),
            ]
        
        rateLabelConstraints = [
            rateLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8.0),
            rateLabel.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 8.0),
            rateLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8.0),
            ]
            
          rateSliderConstraints = [
            rateSlider.topAnchor.constraint(equalTo: self.rateLabel.bottomAnchor, constant: 8.0),
            rateSlider.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 8.0),
            rateSlider.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8.0),
            ]
            
        startPauseButtonConstaints = [
            startPauseButton.topAnchor.constraint(equalTo: self.rateSlider.bottomAnchor, constant: 8.0),
            startPauseButton.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 8.0),
            ]
        
        loadedTimeRangeViewConstraints = [
            loadedTimeRangeView.topAnchor.constraint(equalTo: self.positionSlider.bottomAnchor, constant: 8.0),
            loadedTimeRangeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0),
            loadedTimeRangeView.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8.0),
            loadedTimeRangeView.heightAnchor.constraint(equalToConstant: 30.0),
            ]
        
        loadedTimeRangeIndicatorViewConstraints = [
            loadedTimeRangeIndicatorView.topAnchor.constraint(equalTo: self.loadedTimeRangeView.topAnchor),
            loadedTimeRangeIndicatorView.leadingAnchor.constraint(equalTo: self.loadedTimeRangeView.leadingAnchor),
            loadedTimeRangeIndicatorView.heightAnchor.constraint(equalToConstant: 30.0),
            loadedTimeRangeIndicatorViewWidthConstraint,
            ]
        
        seekableTimeRangeViewConstraints = [
            seekableTimeRangeView.topAnchor.constraint(equalTo: self.loadedTimeRangeView.bottomAnchor, constant: 8.0),
            seekableTimeRangeView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: -8.0),
            seekableTimeRangeView.trailingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -8.0),
            seekableTimeRangeView.heightAnchor.constraint(equalToConstant: 30.0)
        ]
            
        totalDurationLabelConstraints = [
            totalDurationLabel.topAnchor.constraint(equalTo: self.startPauseButton.bottomAnchor, constant: 8.0),
            totalDurationLabel.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 8.0),
            totalDurationLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8.0),
            ]
            
         currentTimeLabelConstraints = [
            currentTimeLabel.topAnchor.constraint(equalTo: totalDurationLabel.bottomAnchor, constant: 8.0),
            currentTimeLabel.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 8.0),
            currentTimeLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8.0),
        ]
        let _ = [ videoContainerConstraints,
                  positionSliderConstraints,
                  startPauseButtonConstaints,
                  rateLabelConstraints,
                  rateSliderConstraints,
                  loadedTimeRangeViewConstraints,
                  loadedTimeRangeIndicatorViewConstraints,
                  seekableTimeRangeViewConstraints,
                  totalDurationLabelConstraints,
                  currentTimeLabelConstraints].map {$0.map{$0.isActive = true}}
    }
    
    func removeParentOwnedConstraints(from view: UIView) {
        
        guard let parentView = view.superview else {
            return
        }
        
        let constraintsOwnedByParentView = parentView.constraints.filter { (constraint) -> Bool in
            guard let secondItem = constraint.secondItem else { return false }
            
            if constraint.firstItem === view || secondItem === view {
                return true
            }
            
            return false
        }
        
        parentView.removeConstraints(constraintsOwnedByParentView)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if newCollection.verticalSizeClass == .compact {
            self.configureLandscapeConstraints()
        }
        else {
            self.configurePortraitConstraints()
        }
    }
    
}


/*
 //
//  ViewController.swift
//  AVPlayerKVO
//
//  Created by Jason Gresh on 1/25/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import AVFoundation

private var kvoContext = 0

class ViewController: UIViewController {
    var player: AVPlayer!
    var userPlayRate: Float = 1.0
    var userPlaying: Bool = false
    
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var positionSlider: UISlider!
    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = URL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8") {
            let playerItem = AVPlayerItem(url: url)
            
            playerItem.addObserver(self, forKeyPath: "status", options: .new, context: &kvoContext)
            
            player = AVPlayer(playerItem: playerItem)
            
            let playerLayer = AVPlayerLayer(player: player)
            //playerLayer.frame = self.videoContainer.bounds
            self.videoContainer.layer.addSublayer(playerLayer)
            
            let timeInterval = CMTime(value: 1, timescale: 2)
            player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time: CMTime) in
                print(time)
                self.updatePositionSlider()
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        guard let sublayers = self.videoContainer.layer.sublayers
            else {
                return
        }
        
        for layer in sublayers {
            layer.frame = self.videoContainer.bounds
        }
    }
    
    // MARK: - Utility
    func updatePositionSlider() {
        guard let item = player.currentItem else { return }
        
        let currentPlace = Float(item.currentTime().seconds / item.duration.seconds)
        self.positionSlider.value = currentPlace
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &kvoContext {
            if keyPath == "status",
                let item = object as? AVPlayerItem {
                if item.status == .readyToPlay {
                    playPauseButton.isEnabled = true
                }
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func positionSliderChanged(_ sender: UISlider) {
        guard let item = player.currentItem else { return }

        let newPosition = Double(sender.value) * item.duration.seconds
        
        player.seek(to: CMTime(seconds: newPosition, preferredTimescale: 1000))
    }
    
    @IBAction func rateChange(_ sender: UISlider) {
        guard let item = player.currentItem else { return }
        
        userPlayRate = sender.value
        
        if item.canPlayFastForward {
            print("I can fast forward. Rate requested: \(sender.value).")
        }
        if item.canPlaySlowForward {
            print("I can slow forward")
        }
        
        if userPlaying {
            player.rate = userPlayRate
        }
        //print("NEW rate: \(player.rate).")

    }
    
    @IBAction func playPausePressed(_ sender: UIButton) {
        if !userPlaying {
            player.playImmediately(atRate: userPlayRate)
            sender.setTitle("Pause", for: .normal)
            //userPlaying = false
        }
        else {
            player.pause()
            sender.setTitle("Play", for: .normal)
            //userPlaying = true
        }
        userPlaying = !userPlaying
    }
}
 */
