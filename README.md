# AC3.2-AVPlayerKVO

A lower-level alternative to ```AVPlayerViewController``` for playing Video.
We use an ```AVPlayer``` object to play an ```AVPlayerItem```. We use key-value-observation (KVO)
to observe changes on properties of the item and player in order to update our interface.
