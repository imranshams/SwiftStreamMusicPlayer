import UIKit
import MediaPlayer
import AVFoundation

@objc protocol MusicPlayerUIUpdatedProtocol
{
    func musicPlayerInfoDidUpdated(title:String,albume:String,artist:String,ArtWork:UIImage)
    func musicPlayerDidPaused()
    func musicPlayerDidPlayed()
    func musicPlayerUIState(isActive:Bool)
}

class MusicPlayer:UIViewController
{
    var MusicPlayerDelegate:MusicPlayerUIUpdatedProtocol?
    private var player:AVPlayer?
    private var filesUrl:[String] = []
    private var playInQueue:Bool = false
    private var currentIndex: Int = 0
        {
        didSet{
            print("\n--------------------------------")
            if NSClassFromString("MPNowPlayingInfoCenter") != nil {
                if let Delegate = self.MusicPlayerDelegate
                {
                    Delegate.musicPlayerUIState(false)
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                    print("Music index changing: \(self.currentIndex)")
                    let asset = AVAsset(URL: NSURL(string: self.filesUrl[self.currentIndex])!)
                    let image:UIImage = UIImage(named: "artwork")!
                    let albumArt = MPMediaItemArtwork(image: image)
                    var songInfo = [MPMediaItemPropertyTitle: "Unknown Title",
                        MPMediaItemPropertyArtist: "Unknown Artist",
                        AVMetadataCommonKeyAlbumName: "Unknown Albume",
                        MPMediaItemPropertyArtwork: albumArt]
                    for item in asset.commonMetadata
                    {
                        if let stringValue = item.value as? String {
                            //                    print("\(item.commonKey) >>> \(stringValue)")
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
                            //                    print(item.commonKey)
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
                        Delegate.musicPlayerInfoDidUpdated(title,albume: albume,artist: artist,ArtWork: artWork!)
                    }
                    if self.playInQueue
                    {
                        self.playInQueue = false
                        self.play(true)
                    }
                    else
                    {
                        if let Delegate = self.MusicPlayerDelegate
                        {
                            Delegate.musicPlayerUIState(true)
                        }
                    }
                    print("Music index changed: \(self.currentIndex)")
                })
            }
            else
            {
                print("Shit!!!")
            }
            print("*****************************\n")
        }
    }
    var playerIsActive: Bool{
        get{
            if player == nil
            {
                return false
            }
            if player!.rate == 0
            {
                return false
            }
            return true
        }
    }
    
    func SetPlayerItems(urls: [String])
    {
        if let Delegate = self.MusicPlayerDelegate
        {
            Delegate.musicPlayerUIState(false)
        }
        self.filesUrl = urls
        self.currentIndex = 0
        self.player = AVPlayer(playerItem: AVPlayerItem(URL: NSURL(string: urls[0])!))
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if event!.type == UIEventType.RemoteControl {
            
            if event!.subtype == UIEventSubtype.RemoteControlPlay {
                print("received remote play")
                NSNotificationCenter.defaultCenter().postNotificationName("AudioPlayerIsPlaying", object: nil)
                player!.play()
                return
            }
            if event!.subtype == UIEventSubtype.RemoteControlPause {
                print("received remote pause")
                NSNotificationCenter.defaultCenter().postNotificationName("AudioPlayerIsNotPlaying", object: nil)
                player!.pause()
                return
            }
            if event!.subtype == UIEventSubtype.RemoteControlNextTrack
            {
                print("received next")
                stop()
                next()
                return
            }
            if event!.subtype == UIEventSubtype.RemoteControlPreviousTrack
            {
                print("received previus")
                stop()
                prev()
                return
            }
            if event!.subtype == UIEventSubtype.RemoteControlTogglePlayPause{
                print("received toggle")
                return
            }
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
    }
    
    func next()
    {
        defaultUI()
        if currentIndex < filesUrl.count - 1
        {
            currentIndex++
        }
        else
        {
            currentIndex = 0
        }
        playInQueue = true
        self.player = AVPlayer(playerItem: AVPlayerItem(URL: NSURL(string: self.filesUrl[currentIndex])!))
    }
    
    func prev()
    {
        defaultUI()
        if currentIndex > 0
        {
            currentIndex--
        }
        else
        {
            currentIndex = filesUrl.count - 1
        }
        playInQueue = true
        self.player = AVPlayer(playerItem: AVPlayerItem(URL: NSURL(string: self.filesUrl[currentIndex])!))
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
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        print("keyPath:\(keyPath)")
        if let obj = object
        {
            print("obj: \(obj)")
        }
        for ch in change!
        {
            print("change in \(ch.0): \(ch.1)")
        }
        print("context: \(context)")
    }
    
    func play(nextOrPrev:Bool)
    {
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        if player != nil && !nextOrPrev
        {
            if player!.rate == 0
            {
                player!.play()
                if let Delegate = self.MusicPlayerDelegate
                {
                    Delegate.musicPlayerDidPlayed()
                }
            }
            else
            {
                player!.pause()
                if let Delegate = self.MusicPlayerDelegate
                {
                    Delegate.musicPlayerDidPaused()
                }
            }
            return
        }
//        if player == nil && !nextOrPrev
//        {
//            if let Delegate = self.MusicPlayerDelegate
//            {
//                Delegate.musicPlayerDidPaused()
//            }
//        }
        print("start play")
        player!.play()
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
        
        if let Delegate = self.MusicPlayerDelegate
        {
            Delegate.musicPlayerUIState(true)
        }
    }
}

class AudioViewController: UIViewController,UINavigationBarDelegate,MusicPlayerUIUpdatedProtocol {
    
    static let sharedInstance = MusicPlayer()
    
    var buttonPlay: UIButton?
    var buttonNext: UIButton?
    var buttonPrev: UIButton?
    var imgArtWork: UIImageView?
    var navigationBar: UINavigationBar!
    var imgArt: UIImageView?
    var lblTitle: UILabel?
    var lblAlbume: UILabel?
    var lblArtist: UILabel?
    var loader: UIActivityIndicatorView?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad")
        self.title = ""
        self.view.backgroundColor = UIColor.ParseHex(MSGlobal.collors.backgroundApp)
        self.view.tintColor = UIColor.ParseHex(MSGlobal.collors.texts)
        
        
        let height = MSGlobal.UINavigationBarHeight
        let w = Int(self.view.frame.width)
        let maxW = min(w, 300)
        let maxH = 120
        
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
        canvas.backgroundColor = UIColor.redColor()
        self.view.addSubview(canvas)
        
        buttonPlay = UIButton(type: .System)
        if let Play = buttonPlay{
            Play.frame = CGRect(x: (maxW / 2) + 5 - (maxH / 2), y: 5, width: maxH - 10, height:  maxH - 10)
            Play.setImage(UIImage(named: "musicPlay"), forState: .Normal)
//            Play.setTitle("Play", forState: .Normal)
            Play.addTarget(self,
                action: "playItem:",
                forControlEvents: .TouchUpInside)
            canvas.addSubview(Play)
        }
        
        loader = UIActivityIndicatorView()
        loader!.frame = CGRect(x: (maxW / 2) + 5 - (maxH / 2), y: 5, width: maxH - 10, height:  maxH - 10)
        canvas.addSubview(loader!)
        
        buttonNext = UIButton(type: .System)
        if let next = buttonNext{
            next.frame = CGRect(x: maxW - maxH + 20 , y: 20, width:  maxH - 40, height:  maxH - 40)
            next.setImage(UIImage(named: "musicNext"), forState: .Normal)
//            stopPlaying.setTitle("Next", forState: .Normal)
            next.addTarget(self,
                action: "nextItem:",
                forControlEvents: .TouchUpInside)
            canvas.addSubview(next)
        }
        
        buttonPrev = UIButton(type: .System)
        if let prev = buttonPrev{
            prev.frame = CGRect(x: 20, y: 20, width:  maxH - 40, height:  maxH - 40)
            prev.setImage(UIImage(named: "musicPrev"), forState: .Normal)
//            stopPlaying.setTitle("Prev", forState: .Normal)
            prev.addTarget(self,
                action: "prevItem:",
                forControlEvents: .TouchUpInside)
            canvas.addSubview(prev)
        }
//        play()
        
        
        navigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: w, height: height))
        navigationBar.delegate = self;
        
        // Create a navigation item with a title
        let navigationItem = UINavigationItem()
        navigationItem.title = ""
        
        // Create left and right button for navigation item
        var backButton =  UIBarButtonItem(image: UIImage(named:"back-ltr"), landscapeImagePhone: UIImage(named:"back-ltr"), style: UIBarButtonItemStyle.Plain, target: self, action: "cb_back:")
        if MSGlobal.setting.language.direction == .R2L
        {
            backButton = UIBarButtonItem(image: UIImage(named:"back-rtl"), landscapeImagePhone: UIImage(named:"back-rtl"), style: UIBarButtonItemStyle.Plain, target: self, action: "cb_back:")
            navigationItem.rightBarButtonItem = backButton
        }
        else
        {
             navigationItem.leftBarButtonItem = backButton
        }
        
        AudioViewController.sharedInstance.MusicPlayerDelegate = self
        
        navigationBar.items = [navigationItem]
        view.addSubview(navigationBar)
        
        MSTools.updateNavigatorController2(self.navigationBar, background: MSGlobal.collors.actionBarBackground, text: MSGlobal.collors.actionBarText)
        
        let isActive = AudioViewController.sharedInstance.playerIsActive
        if isActive
        {
            buttonPlay?.setImage(UIImage(named: "musicPause"), forState: .Normal)
        }
        else
        {
            buttonPlay?.setImage(UIImage(named: "musicPlay"), forState: .Normal)
        }
        buttonNext?.enabled = isActive
        buttonPrev?.enabled = isActive
        buttonPlay?.enabled = isActive
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
    
    func musicPlayerDidPaused() {
        buttonPlay?.setImage(UIImage(named: "musicPlay"), forState: .Normal)
        buttonPlay?.setNeedsDisplay()
    }
    
    func musicPlayerDidPlayed() {
        buttonPlay?.setImage(UIImage(named: "musicPause"), forState: .Normal)
        buttonPlay?.setNeedsDisplay()
    }
    
    func musicPlayerUIState(isActive: Bool) {
        print("UI is \((isActive ? "active" : "deactive"))")
        dispatch_async(dispatch_get_main_queue(),
            {
                self.buttonNext?.enabled = isActive
                self.buttonPrev?.enabled = isActive
                self.buttonPlay?.enabled = isActive
                self.buttonNext?.setNeedsDisplay()
                self.buttonPrev?.setNeedsDisplay()
                self.buttonPlay?.setNeedsDisplay()
                self.loader?.hidden = isActive
                if isActive
                {
                    self.loader!.stopAnimating()
                }
                else
                {
                    self.loader!.startAnimating()
                }
                self.loader?.setNeedsDisplay()
            })
        }
    
    func musicPlayerInfoDidUpdated(title: String, albume: String, artist: String, ArtWork: UIImage) {
        print("update UI")
        lblTitle?.text = title
        lblAlbume?.text = albume
        lblArtist?.text = artist
        imgArt?.image = ArtWork
        imgArtWork?.image = ArtWork
        lblTitle?.setNeedsDisplay()
        lblAlbume?.setNeedsDisplay()
        lblArtist?.setNeedsDisplay()
        imgArt?.setNeedsDisplay()
        imgArtWork?.setNeedsDisplay()
    }
    
    func playItem(sender: UIButton)
    {
        AudioViewController.sharedInstance.play(false)
    }
    
    func nextItem(sender: UIButton)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),{
            AudioViewController.sharedInstance.next()
        })
    }
    
    func prevItem(sender: UIButton)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),{
            AudioViewController.sharedInstance.prev()
        })
    }
    
    func cb_back(sender: UIButton)
    {
        self.dismissViewControllerAnimated(true, completion: {
            
        })
    }
    
    
    
    
}
