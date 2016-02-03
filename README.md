# SwiftStreamMusicPlayer
Stream music from internet with ability to play/pause/next/prev

Features:
 - Stream musics from internet
 - Ability to Play/Pause
 - First time show `UIViewControler` like apple music app
 - Ability to show music info in `UIViewController` (if exist, because of user can close UI and music can play in background) and RemoteControl and LockScreen
 - Ability to control from RemoteControl and LockScreen
 - Ability to handle errors like (connection poor, connection lost or any interrupt)
 - Ability to show time and seek time (tap on a line to seek specific time)
 
 
# How to use
 You can use this player in any place of your code. It is possible to use without UI or in background

var files: [String] = ["http url 1 of a mp3 file","http url 2 of a mp3 file"]
// unique id used to detect playlist items
var uniqueID = ""
for file in files
{
    uniqueID += file
}
AudioViewController.sharedInstance.SetPlayerItems(files,uniqueId: uniqueID)
let appDelegate : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
let vc = AudioViewController()
appDelegate.window!.rootViewController.presentViewController(vc, animated: true, completion: nil)


