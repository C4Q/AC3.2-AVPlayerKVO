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
    
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var totalDuration: UILabel!
    
    var player: AVPlayer! {
        willSet {
            if player != nil {
                if let item = self.player.currentItem {
                    item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &kvoContext)
                    item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), context: &kvoContext)
                    item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.seekableTimeRanges), context: &kvoContext)
                }
                
                if let token = self.timeObserverToken {
                    player.removeTimeObserver(token)
                }
            }
            
            if let item = newValue.currentItem {
                item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: &kvoContext)
                item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: .new, context: &kvoContext)
                item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.seekableTimeRanges), options: .new, context: &kvoContext)
            }
            
            let timeInterval = CMTime(value: 1, timescale: 2)
            self.timeObserverToken = newValue.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time: CMTime) in
                print(time)
                self.updatePositionSlider()
            })
        }
    }
    var userPlayRate: Float = 1.0
    var userPlaying: Bool = false
    var timeObserverToken: Any?
    
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var positionSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        loadAssetFromFile(urlString: "debussy.mp3")
        
        /// Loading mp4 file:
        if let url = URL(string: "https://archive.org/download/VoyagetothePlanetofPrehistoricWomen/VoyagetothePlanetofPrehistoricWomen.mp4") {
            
            let playerItem = AVPlayerItem(url: url)
            self.player = AVPlayer(playerItem: playerItem)
            
            let playerLayer = AVPlayerLayer(player: player)
            self.videoContainer.layer.addSublayer(playerLayer)
        }
        
        /// Loading mp3 file:
        //        if let url = URL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8") {
        //            let playerItem = AVPlayerItem(url: url)
        //
        //            playerItem.addObserver(self, forKeyPath: "status", options: .new, context: &kvoContext)
        //
        //            player = AVPlayer(playerItem: playerItem)
        //
        //            let playerLayer = AVPlayerLayer(player: player)
        //            //playerLayer.frame = self.videoContainer.bounds
        //            self.videoContainer.layer.addSublayer(playerLayer)
        //
        //            let timeInterval = CMTime(value: 1, timescale: 2)
        //            player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time: CMTime) in
        //                print(time)
        //                self.updatePositionSlider()
        //            })
        //        }
    }
    
    override func viewDidLayoutSubviews() {
        guard let sublayers = self.videoContainer.layer.sublayers else { return }
        
        for layer in sublayers {
            layer.frame = self.videoContainer.bounds
        }
    }
    
    // MARK: - Utility
    func updatePositionSlider() {
        guard let item = player.currentItem else { return }
        
        let totalTime = TimeInterval(item.duration.value) / TimeInterval(item.duration.timescale)
        totalDuration.text = "Total duration: \(totalTime)"
        
        let currentPlace = Float(item.currentTime().seconds / item.duration.seconds)
        self.positionSlider.value = currentPlace
        let current: Double = Double(currentPlace) * 100.0
        let trimmedString = String(format:"%.2f", current)
        currentTime.text = "Current time: \(trimmedString) "
    }
    
    func loadAssetFromFile(urlString: String) {
        guard let dot = urlString.range(of: ".") else { return }
        let fileParts = (resource: urlString.substring(to: dot.lowerBound), extension: urlString.substring(from: dot.upperBound))
        
        if let fileURL = Bundle.main.url(forResource: fileParts.resource, withExtension: fileParts.extension) {
            let asset = AVURLAsset(url: fileURL)
            let playerItem = AVPlayerItem(asset: asset)
            self.player = AVPlayer(playerItem: playerItem)
            /*
             playerItem.addObserver(self, forKeyPath: "status", options: .new, context: &kvoContext)
             self.player = AVPlayer(playerItem: playerItem)
             
             let timeInterval = CMTime(value: 1, timescale: 2)
             player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time: CMTime) in
             print(time)
             self.updatePositionSlider()
             })*/
        }
    }
    
    func availableDurationWithplayerItem() -> TimeInterval? {
        guard let loadedTimeRanges = player.currentItem?.loadedTimeRanges,let first = loadedTimeRanges.first else { return nil }
        let timeRange = first.timeRangeValue
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSecound = CMTimeGetSeconds(timeRange.duration)
        let result = startSeconds + durationSecound
        return result
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath else { return }
        
        if context == &kvoContext {
            if let item = object as? AVPlayerItem {
                switch keyPath {
                case #keyPath(AVPlayerItem.status):
                    if item.status == .readyToPlay {
                        playPauseButton.isEnabled = true
                    }
                case #keyPath(AVPlayerItem.loadedTimeRanges):
                    for range in item.loadedTimeRanges {
                        print(range.timeRangeValue)
                        
                        let loadedTime = availableDurationWithplayerItem()
                        let totalTime = CMTimeGetSeconds(item.duration)
                        let percent = loadedTime!/totalTime
                        self.positionSlider.maximumValue = Float(percent)
                    }
                case #keyPath(AVPlayerItem.seekableTimeRanges):
                    for range in item.seekableTimeRanges {
                        print(range.timeRangeValue)
                    }
                    
                default:
                    break
                }
            }
        }
        
        /*
         if context == &kvoContext {
         if keyPath == "status",
         let item = object as? AVPlayerItem {
         if item.status == .readyToPlay {
         playPauseButton.isEnabled = true
         }
         }
         }*/
    }
    
    // MARK: - Actions
    @IBAction func positionSliderChanged(_ sender: UISlider) {
        guard let item = player.currentItem else { return }
        
        let newPosition = Double(sender.value) * item.duration.seconds
        
        player.seek(to: CMTime(seconds: newPosition, preferredTimescale: 1000))
        
        player.playImmediately(atRate: userPlayRate)
    }
    
    @IBAction func rateChanged(_ sender: UISlider) {
        guard let item = player.currentItem else { return }
        userPlayRate = sender.value
        
        if item.canPlayFastForward {
            print("I can fast forward, rate requested: \(userPlayRate)")
        }
        if item.canPlaySlowForward {
            print("I can slow forward, rate requested: \(userPlayRate)")
        }
        if userPlaying {
            player.rate = userPlayRate
            print("NEW rate: \(player.rate)")
        }
    }
    
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        if userPlaying {
            player.pause()
            sender.setTitle("Play", for: .normal)
        } else {
            player.playImmediately(atRate: userPlayRate)
            sender.setTitle("Pause", for: .normal)
            print("Playing back the Playrate captured: \(userPlayRate)")
        }
        userPlaying = !userPlaying
    }
}

