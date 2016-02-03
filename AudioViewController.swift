import UIKit
import MediaPlayer
import AVFoundation

@objc protocol MusicPlayerUIUpdatedProtocol
{
    func musicPlayerInfoDidUpdated(title:String,albume:String,artist:String,ArtWork:UIImage,timeLenght:Float,currentIndex:Int,totalIndex:Int)
    func musicPlayerTimeDidUpdated(currentTime:Float,totalTime:Float)
    func musicPlayerDidPaused()
    func musicPlayerDidPlayed()
    func musicPlayerUIState(isActive:Bool)
}

class MusicPlayer:UIViewController
{
    var MusicPlayerDelegate:MusicPlayerUIUpdatedProtocol?
    private var player:AVPlayer?
    private var filesUrl:[String] = []
    private var currentIndex: Int = 0
    private var paused = true
    private var uniqueID: String = ""
    private var updater : CADisplayLink! = nil
        {
        didSet{
            print("\n--------------\(self.currentIndex)---------------")
            if NSClassFromString("MPNowPlayingInfoCenter") != nil {
                if let Delegate = self.MusicPlayerDelegate
                {
                    Delegate.musicPlayerUIState(false)
                }
                defaultUI()
            }
            else
            {
                print("Shit!!!")
            }
        }
    }
    var playerIsAvailabe: Bool{
        get{
            if player == nil
            {
                return false
            }
            return true
        }
    }
    var musicIsPlaying: Bool{
        get{
            if player == nil
            {
                return false
            }
            if player!.rate == 0
            {
                return false
            }
            if paused
            {
                return true
            }
            return true
        }
    }
    
    func trackAudio() {
        if let p = player, let currentItem = p.currentItem
        {
            let sec = currentItem.currentTime().seconds
            let total = currentItem.duration.seconds
            if sec == total
            {
                stop()
                next()
                return
            }
            if sec < total && sec > 10 && !musicIsPlaying && !self.paused
            {
                play()
            }
            print("trackAudio: \(sec) from \(total)")
            if let Delegate = self.MusicPlayerDelegate
            {
                Delegate.musicPlayerTimeDidUpdated(Float(sec),totalTime: Float(total))
            }
            
        }
        else
        {
            print("trackAudio faild")
        }
    }
    
    func MakeUrl(index:Int) -> String
    {
        var rawUrl = self.filesUrl[index]
        if rawUrl.containsString(" ")
        {
            rawUrl = rawUrl.stringByAddingPercentEncodingWithAllowedCharacters( NSCharacterSet.URLQueryAllowedCharacterSet())!
        }
        return rawUrl
    }
    
    func SetPlayerItems(urls: [String],uniqueId:String)
    {
        if self.uniqueID == uniqueId
        {
            return
        }
        if let Delegate = self.MusicPlayerDelegate
        {
            Delegate.musicPlayerUIState(false)
        }
        if self.updater == nil
        {
            self.updater = CADisplayLink(target: self, selector: Selector("trackAudio"))
            self.updater.frameInterval = 10
            self.updater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        }
        self.uniqueID = uniqueId
        self.filesUrl = urls
        self.currentIndex = 0
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),{
            if let url = NSURL(string: self.MakeUrl(0))
            {
                let item = AVPlayerItem(URL: url)
                self.player = AVPlayer(playerItem: item)
                self.updateInfoUI(self.player!.currentItem!.asset)
            }
        })
    }
    
    func seekTime(totalPercent:Float)
    {
        if (playerIsAvailabe && musicIsPlaying) {
            let second = self.player!.currentItem!.duration.seconds * Double(totalPercent)
            self.player!.seekToTime(CMTime(seconds: second, preferredTimescale: 1))
        }
    }
    
    func defaultUI()
    {
        let image:UIImage = UIImage(named: "artwork")!
        let albumArt = MPMediaItemArtwork(image: image)
        let songInfo = [MPMediaItemPropertyTitle: "Unknown Title",
            MPMediaItemPropertyArtist: "Unknown Artist",
            AVMetadataCommonKeyAlbumName: "Unknown Albume",
            MPMediaItemPropertyArtwork: albumArt]
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo as [String : AnyObject]
        if let Delegate = self.MusicPlayerDelegate
        {
            let title = songInfo[MPMediaItemPropertyTitle] as! String
            let albume = songInfo[AVMetadataCommonKeyAlbumName] as! String
            let artist = songInfo[MPMediaItemPropertyArtist] as! String
            let artWork = (songInfo[MPMediaItemPropertyArtwork] as! MPMediaItemArtwork).imageWithSize(CGSize(width: 400, height: 400))
            Delegate.musicPlayerInfoDidUpdated(title,albume: albume,artist: artist,ArtWork: artWork!,timeLenght: 0,currentIndex: 1,totalIndex: 1)
        }
        
    }
    
    func updateInfoUI(asset:AVAsset)
    {
        let image:UIImage = UIImage(named: "artwork")!
        let albumArt = MPMediaItemArtwork(image: image)
        let timeLenght = Float(asset.duration.seconds)
        var songInfo = [MPMediaItemPropertyTitle: "Unknown Title",
            MPMediaItemPropertyArtist: "Unknown Artist",
            AVMetadataCommonKeyAlbumName: "Unknown Albume",
            MPMediaItemPropertyArtwork: albumArt,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(float: 0),
            MPNowPlayingInfoPropertyPlaybackRate: Double(1),
            MPMediaItemPropertyPlaybackDuration: NSNumber(float: timeLenght)]
        for item in asset.commonMetadata
        {
            if let stringValue = item.value as? String {
                if item.commonKey == AVMetadataCommonKeyTitle {
                    songInfo[MPMediaItemPropertyTitle] = stringValue
                }
                if item.commonKey == AVMetadataCommonKeyArtist {
                    songInfo[MPMediaItemPropertyArtist] = stringValue
                }
                if item.commonKey == AVMetadataCommonKeyAlbumName {
                    songInfo[AVMetadataCommonKeyAlbumName] = stringValue
                }
            }
            if let dataValue = item.value as? NSData {
                if item.commonKey == AVMetadataCommonKeyArtwork {
                    let img = UIImage(data: dataValue)
                    songInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: img!)
                }
            }
        }
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo as [String : AnyObject]
        if let Delegate = self.MusicPlayerDelegate
        {
            let title = songInfo[MPMediaItemPropertyTitle] as! String
            let albume = songInfo[AVMetadataCommonKeyAlbumName] as! String
            let artist = songInfo[MPMediaItemPropertyArtist] as! String
            let artWork = (songInfo[MPMediaItemPropertyArtwork] as! MPMediaItemArtwork).imageWithSize(CGSize(width: 400, height: 400))
            Delegate.musicPlayerInfoDidUpdated(title,albume: albume,artist: artist,ArtWork: artWork!,timeLenght: timeLenght,currentIndex: self.currentIndex + 1,totalIndex: self.filesUrl.count)
            Delegate.musicPlayerUIState(true)
        }
    }
    
    func next()
    {
        if self.currentIndex < self.filesUrl.count - 1
        {
            self.currentIndex++
        }
        else
        {
            self.currentIndex = 0
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),{
            self.player = AVPlayer(playerItem: AVPlayerItem(URL: NSURL(string: self.MakeUrl(self.currentIndex))!))
            self.updateInfoUI(self.player!.currentItem!.asset)
            self.play()
        })
    }
    
    func prev()
    {
        if self.currentIndex > 0
        {
            self.currentIndex--
        }
        else
        {
            self.currentIndex = self.filesUrl.count - 1
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),{
            self.player = AVPlayer(playerItem: AVPlayerItem(URL: NSURL(string: self.filesUrl[self.currentIndex])!))
            self.updateInfoUI(self.player!.currentItem!.asset)
            self.play()
        })
    }
    
    func stop()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if let xPlayer = player
        {
            xPlayer.pause()
            do
            {
                print("End Audio Session")
                try AVAudioSession.sharedInstance().setActive(false)
            }
            catch
            {
                print("Audio Session error.")
            }
        }
        
    }
    
    func pause()
    {
        if player != nil
        {
            player!.pause()
            self.paused = true
            if let Delegate = self.MusicPlayerDelegate
            {
                Delegate.musicPlayerDidPaused()
            }
        }
    }
    
    func play()
    {
        print("start play")
        if let p = self.player
        {
            p.play()
            self.paused = false
            if let Delegate = self.MusicPlayerDelegate
            {
                Delegate.musicPlayerDidPlayed()
            }
            do
            {
                print("Receiving remote control events")
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: [])
                try AVAudioSession.sharedInstance().setActive(true)
            }
            catch
            {
                print("Audio Session error.")
            }
        }
        if let Delegate = self.MusicPlayerDelegate
        {
            Delegate.musicPlayerUIState(true)
        }
    }
}

class AudioViewController: UIViewController,UINavigationBarDelegate,MusicPlayerUIUpdatedProtocol {
    
    static let sharedInstance = MusicPlayer()
    
    var buttonPlay: UIButton?
    var buttonPause: UIButton?
    var buttonNext: UIButton?
    var buttonPrev: UIButton?
    var imgArtWork: UIImageView?
    var navigationBar: UINavigationBar!
    var imgArt: UIImageView?
    var lblTitle: UILabel?
    var lblAlbume: UILabel?
    var lblArtist: UILabel?
    var sldSeek: UISlider?
    var lblTimeCurrent: UILabel?
    var lblTimeTotal: UILabel?
    var loader: UIActivityIndicatorView?
    var navItem: UINavigationItem?
    
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad")
        self.view.backgroundColor = UIColor.ParseHex(MSGlobal.collors.backgroundApp)
        self.view.tintColor = UIColor.ParseHex(MSGlobal.collors.texts)
        
        
        let height = MSGlobal.UINavigationBarHeight
        let w = Int(self.view.frame.width)
        let maxW = min(w, 300)
        let maxH = 180
        
        imgArtWork = UIImageView()
        if let art = imgArtWork {
            art.frame = CGRect(x: 0, y: height, width: w, height: Int(self.view.frame.height) - maxH - height)
            art.image = UIImage(named: "artwork")
            art.contentMode = .ScaleAspectFill
            art.layer.masksToBounds = true
            view.addSubview(art)
            
            let blur = UIBlurEffect(style: .Dark)
            let blurView = UIVisualEffectView(effect: blur)
            blurView.frame = art.bounds
            blurView.frame.origin.y = CGFloat(height)
            blurView.alpha = 0.9
            view.addSubview(blurView)
            
            imgArt = UIImageView(image: art.image!)
            imgArt!.frame = CGRect(x: Int(self.view.frame.width / 2) - (maxW / 4), y: Int(art.frame.height / 2) - (maxW / 4) + height, width: maxW / 2, height: maxW / 2)
            imgArt!.layer.cornerRadius = CGFloat(maxW / 4)
            imgArt!.layer.masksToBounds = true
            view.addSubview(imgArt!)
            
            lblTitle = UILabel()
            lblTitle!.text = ""
            lblTitle!.textAlignment = .Center
            lblTitle!.textColor = UIColor.whiteColor()
            lblTitle!.frame = CGRect(x: 0, y: Int(imgArt!.frame.origin.y + imgArt!.frame.size.height) , width: Int(self.view.frame.width), height: 20)
            view.addSubview(lblTitle!)
            
            lblAlbume = UILabel()
            lblAlbume!.text = ""
            lblAlbume!.textAlignment = .Center
            lblAlbume!.textColor = UIColor.whiteColor()
            lblAlbume!.frame = CGRect(x: 0, y: Int(imgArt!.frame.origin.y + imgArt!.frame.size.height + 20) , width: Int(self.view.frame.width), height: 20)
            view.addSubview(lblAlbume!)
            
            lblArtist = UILabel()
            lblArtist!.text = ""
            lblArtist!.textAlignment = .Center
            lblArtist!.textColor = UIColor.whiteColor()
            lblArtist!.frame = CGRect(x: 0, y: Int(imgArt!.frame.origin.y + imgArt!.frame.size.height + 40) , width: Int(self.view.frame.width), height: 20)
            view.addSubview(lblArtist!)
        }
        
        let canvas = UIView(frame: CGRect(x: (w - maxW) / 2, y: Int(self.view.frame.height) - maxH, width: maxW, height: maxH))
//        canvas.backgroundColor = UIColor.redColor()
        self.view.addSubview(canvas)
        
        buttonPlay = UIButton(type: .System)
        if let Play = buttonPlay{
            Play.frame = CGRect(x: (maxW / 2) + 30 - (maxH / 2), y: 60, width: maxH - 60, height:  maxH - 60)
            Play.setImage(UIImage(named: "musicPlay"), forState: .Normal)
            Play.addTarget(self,
                action: "playItem:",
                forControlEvents: .TouchUpInside)
            canvas.addSubview(Play)
        }
        
        buttonPause = UIButton(type: .System)
        if let Pause = buttonPause{
            Pause.frame = CGRect(x: (maxW / 2) + 30 - (maxH / 2), y: 60, width: maxH - 60, height:  maxH - 60)
            Pause.setImage(UIImage(named: "musicPause"), forState: .Normal)
            Pause.addTarget(self,
                action: "pauseItem:",
                forControlEvents: .TouchUpInside)
            canvas.addSubview(Pause)
        }
        
        loader = UIActivityIndicatorView()
        loader!.frame = CGRect(x: (maxW / 2) + 30 - (maxH / 2), y: 60, width: maxH - 60, height:  maxH - 60)
        canvas.addSubview(loader!)
        
        buttonNext = UIButton(type: .System)
        if let next = buttonNext{
            next.frame = CGRect(x: maxW - maxH + 100 , y: 75, width:  maxH - 100, height:  maxH - 100)
            next.setImage(UIImage(named: "musicNext"), forState: .Normal)
            next.addTarget(self,
                action: "nextItem:",
                forControlEvents: .TouchUpInside)
            canvas.addSubview(next)
        }
        
        buttonPrev = UIButton(type: .System)
        if let prev = buttonPrev{
            prev.frame = CGRect(x: 0, y: 75, width:  maxH - 100, height:  maxH - 100)
            prev.setImage(UIImage(named: "musicPrev"), forState: .Normal)
            prev.addTarget(self,
                action: "prevItem:",
                forControlEvents: .TouchUpInside)
            canvas.addSubview(prev)
        }
        
        
        let timeCanvas = UIView(frame: CGRect(x: 0, y: Int(self.view.frame.height) - maxH, width: Int(self.view.frame.width), height: 50))
        timeCanvas.backgroundColor = UIColor.ParseHex("#000000", alpha: 0.5)
        self.view.addSubview(timeCanvas)
        
        lblTimeCurrent = UILabel()
        lblTimeCurrent!.text = "--:--"
        lblTimeCurrent!.textAlignment = .Center
        lblTimeCurrent!.textColor = UIColor.ParseHex(MSGlobal.collors.texts)
        lblTimeCurrent!.frame = CGRect(x: 0, y: 15 , width: 40, height: 20)
        lblTimeCurrent!.font = UIFont(name: MSGlobal.font.fontName, size: 14)
        timeCanvas.addSubview(lblTimeCurrent!)
        
        lblTimeTotal = UILabel()
        lblTimeTotal!.text = "--:--"
        lblTimeTotal!.textAlignment = .Center
        lblTimeTotal!.textColor = UIColor.ParseHex(MSGlobal.collors.texts)
        lblTimeTotal!.frame = CGRect(x: self.view.frame.width - 40 , y: 15 , width: 40, height: 20)
        lblTimeTotal!.font = UIFont(name: MSGlobal.font.fontName, size: 14)
        timeCanvas.addSubview(lblTimeTotal!)
        
        sldSeek = UISlider(frame: CGRect(x: 40, y: 20, width: self.view.frame.width - 80, height: 10))
        sldSeek!.minimumValue = 0
        sldSeek!.maximumValue = 100
        sldSeek!.addTarget(self, action: "sliderValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        timeCanvas.addSubview(sldSeek!)
        
        navigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: w, height: height))
        navigationBar.delegate = self;
        
        navItem = UINavigationItem()
        navItem?.title = ""
        
        var backButton =  UIBarButtonItem(image: UIImage(named:"back-ltr"), landscapeImagePhone: UIImage(named:"back-ltr"), style: UIBarButtonItemStyle.Plain, target: self, action: "cb_back:")
        if MSGlobal.setting.language.direction == .R2L
        {
            backButton = UIBarButtonItem(image: UIImage(named:"back-rtl"), landscapeImagePhone: UIImage(named:"back-rtl"), style: UIBarButtonItemStyle.Plain, target: self, action: "cb_back:")
            navItem?.rightBarButtonItem = backButton
        }
        else
        {
             navItem?.leftBarButtonItem = backButton
        }
        
        AudioViewController.sharedInstance.MusicPlayerDelegate = self
        
        navigationBar.items = [navItem!]
        view.addSubview(navigationBar)
        
        MSTools.updateNavigatorController2(self.navigationBar, background: MSGlobal.collors.actionBarBackground, text: MSGlobal.collors.actionBarText)
        
        let isPlaying = AudioViewController.sharedInstance.musicIsPlaying
        if isPlaying
        {
            musicPlayerDidPlayed()
        }
        else
        {
            musicPlayerDidPaused()
        }
        let isActive = AudioViewController.sharedInstance.playerIsAvailabe
        buttonNext?.enabled = isActive
        buttonPrev?.enabled = isActive
        buttonPlay?.enabled = isActive
        buttonPause?.enabled = isActive
        loader?.hidden = isActive
        if isActive
        {
            loader!.stopAnimating()
        }
        else
        {
            loader!.startAnimating()
        }
    }
    
    func sliderValueChanged(sender: UISlider) {
//        print("time changed: \(sender.value)")
        AudioViewController.sharedInstance.seekTime(sender.value / 100)
    }
    
    func musicPlayerDidPaused() {
        buttonPlay?.hidden = false
        buttonPause?.hidden = true
    }
    
    func musicPlayerDidPlayed() {
        buttonPause?.hidden = false
        buttonPlay?.hidden = true
    }
    
    func musicPlayerUIState(isActive: Bool) {
        print("UI is \((isActive ? "active" : "deactive"))")
        dispatch_async(dispatch_get_main_queue(),
            {
                self.buttonNext?.enabled = isActive
                self.buttonPrev?.enabled = isActive
                self.buttonPlay?.enabled = isActive
                self.buttonPause?.enabled = isActive
                self.loader?.hidden = isActive
                if isActive
                {
                    self.loader!.stopAnimating()
                }
                else
                {
                    self.loader!.startAnimating()
                }
            })
        }
    
    func musicPlayerInfoDidUpdated(title: String, albume: String, artist: String, ArtWork: UIImage, timeLenght: Float, currentIndex: Int, totalIndex: Int) {
        print("update UI: Info")
        dispatch_async(dispatch_get_main_queue(),
            {
                self.lblTitle?.text = title
                self.lblAlbume?.text = albume
                self.lblArtist?.text = artist
                self.imgArt?.image = ArtWork
                self.imgArtWork?.image = ArtWork
                self.sldSeek?.value = 0
                self.lblTimeCurrent?.text = self.makeTimeString(0)
                self.lblTimeTotal?.text = self.makeTimeString(timeLenght)
                self.navItem?.title = "\(currentIndex)/\(totalIndex)"
            })
    }
    
    func musicPlayerTimeDidUpdated(currentTime: Float, totalTime: Float) {
        let percent = (currentTime / totalTime) * 100
//        print("update UI: Time \(percent)")
        dispatch_async(dispatch_get_main_queue(), {
                self.sldSeek?.value = percent
                self.lblTimeCurrent?.text = self.makeTimeString(currentTime)
        })
    }
    
    func playItem(sender: UIButton)
    {
        AudioViewController.sharedInstance.play()
    }
    
    func pauseItem(sender: UIButton)
    {
        AudioViewController.sharedInstance.pause()
    }
    
    func nextItem(sender: UIButton)
    {
        AudioViewController.sharedInstance.next()
    }
    
    func prevItem(sender: UIButton)
    {
        AudioViewController.sharedInstance.prev()
    }
    
    func cb_back(sender: UIButton)
    {
        self.dismissViewControllerAnimated(true, completion: {
            
        })
    }
    
    func makeTimeString(value:Float) -> String
    {
        if value == 0 || value.isNaN
        {
            return "00:00"
        }
        let min = (Int)(value / 60)
        let sec = (Int)(value % 60)
        return "\(min.format("02")):\(sec.format("02"))"
    }
    
    
}
