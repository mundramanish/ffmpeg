//// CameraTextVC.swift
// ffmpegDemo
//
// Created by ffmpegDemo on 16/03/22.
// Copyright © 2021 ffmpegDemo. All rights reserved.
//


import UIKit
import AVKit
import AVFoundation
import mobileffmpeg
import DateHelper
import LinearProgressBar
import KDCircularProgress

/// This screen will be used to record text , image , video
class RecordingTextImageVideoVC: BaseViewController, StoryboardSceneBased, LogDelegate, StatisticsDelegate {
    
    static let sceneStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    // Variables from previous viewcontroller
    var isCameraAudioUse: Bool!
    var isText: Bool!
    var isVideo: Bool!
    
    // Linear progress bar
    @IBOutlet weak var linearProgress: LinearProgressBar!
    @IBOutlet weak var lblTimer: UILabel!
    
    @IBOutlet weak var lblText: UILabel!
    
    // Camera viwe
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var btnRecord: UIButton!
    
    // View contains imageview
    @IBOutlet weak var viewImage: UIView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var viewVideoPlayer: UIView!
    
    // Video player
    var playerVideo: AVPlayer?
    
    // Video player layer
    var playerLayer: AVPlayerLayer?
    
    // counter var for timer
    var counter = 0.0
    
    // Timer object
    var timer: Timer!
    
    // Dictionary to append on top of screen
    var dictDuration = [[String: Any]]()
    
    // Array to setup ffmpeg command
    var arrCommand = [String]()
    
    // Array for input images
    var arrInputImages = [String]()
    
    // Array for input video
    var arrInputVideos = [String]()
    
    // Camera vc
    var vc: CameraVC!
    
    // Video duration
    var durationVideo: Double?
    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isText {
           setupText()
        } else if isVideo {
            setupVideo()
        } else {
            setupImage()
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.vc = CameraVC(nibName: "CameraVC", bundle: nil)
            self?.vc.isCameraAudioUse = self!.isCameraAudioUse
            
            // Set height or width
            self?.vc.view.frame = CGRect(x: 0, y: 0, width: self!.viewMain.frame.size.width, height: self!.viewMain.frame.size.height)
            self?.viewMain.addSubview(self!.vc.view)
            
            self?.vc.playSoundBlock = { [weak self] () in
                DispatchQueue.main.async {
                    self?.btnRecord.isHidden = true
                    self?.btnRecord.isSelected = true
                    self?.setLinearBarNTimer()
                }
            }
            
            self?.vc.executeFFMPEGBlock = { [weak self] (cameraVideoPath) in
                
                if let _ = self?.playerVideo {
                    // Pause video
                    self?.playerVideo?.pause()
                }
                
                if let _ = self?.timer {
                    // Invalidate timer
                    self?.timer.invalidate()
                    self?.timer = nil
                }
                
                self?.durationVideo = AVAsset(url: URL(fileURLWithPath: cameraVideoPath)).duration.seconds

                if let text = self?.isText, let video = self?.isVideo {
                    if text {
                        self?.executeTextFFMPEG(cameraVideoPath: cameraVideoPath)
                    } else if video {
                        self?.executeVideoFFMPEG(cameraVideoPath: cameraVideoPath)
                    } else {
                        self?.executeImageFFMPEG(cameraVideoPath: cameraVideoPath)
                    }
                }
            }
        }
        
        //  Delegates Log and Statistics
        DispatchQueue.main.async {
            MobileFFmpegConfig.setLogDelegate(self)
            MobileFFmpegConfig.setStatisticsDelegate(self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
    }
    
    private func setupText() {
        self.viewImage.isHidden = true
        self.viewVideoPlayer.isHidden = true
        self.lblText.isHidden = false
        
        dictDuration = [
            ["text":"Mango", "duration": 1],
            ["text":"Pineapple", "duration": 4],
            ["text":"Orange", "duration": 7],
            ["text":"Grapes", "duration": 10]
        ]
    }
    
    private func setupImage() {
        self.viewImage.isHidden = false
        self.viewVideoPlayer.isHidden = true
        self.lblText.isHidden = true
        
        // Local image
        let path1 = MAIN_BUNDLE.path(forResource: "uglysweater2", ofType: "jpg")
        let path2 = MAIN_BUNDLE.path(forResource: "uglysweater3", ofType: "jpg")
        let path3 = MAIN_BUNDLE.path(forResource: "us_blank", ofType: "jpg")
        let path4 = MAIN_BUNDLE.path(forResource: "us_home", ofType: "jpg")
        let path5 = MAIN_BUNDLE.path(forResource: "us_lab", ofType: "jpg")
        let path6 = MAIN_BUNDLE.path(forResource: "us_office1", ofType: "jpg")
        let path7 = MAIN_BUNDLE.path(forResource: "us_office2", ofType: "jpg")
        let path8 = MAIN_BUNDLE.path(forResource: "us_outerworlds", ofType: "jpg")
        let path9 = MAIN_BUNDLE.path(forResource: "valentines", ofType: "jpg")
        let path10 = MAIN_BUNDLE.path(forResource: "wave", ofType: "jpg")
        
        dictDuration = [
            ["image":path1 ?? "", "duration": 1],
            ["image":path2 ?? "", "duration": 3],
            ["image":path3 ?? "", "duration": 5],
            ["image":path4 ?? "", "duration": 7],
            ["image":path5 ?? "", "duration": 9],
            ["image":path6 ?? "", "duration": 11],
            ["image":path7 ?? "", "duration": 13],
            ["image":path8 ?? "", "duration": 15],
            ["image":path9 ?? "", "duration": 17],
            ["image":path10 ?? "", "duration": 20]
        ]
    }

    private func setupVideo() {
        self.viewImage.isHidden = true
        self.viewVideoPlayer.isHidden = false
        self.lblText.isHidden = true
        
        let path1 = MAIN_BUNDLE.path(forResource: "potraitsmall", ofType: "mp4")
        let path2 = MAIN_BUNDLE.path(forResource: "landscape", ofType: "mp4")
        
        setupVideoPlayer(path: path1 ?? "")
        
        dictDuration = [
            ["video": path1 ?? "", "duration": 1],
            ["video": path2 ?? "", "duration": 5],
            ["video": path1 ?? "", "duration": 9],
            ["video": path2 ?? "", "duration": 12],
            ["video": path1 ?? "", "duration": 18],
            ["video": path2 ?? "", "duration": 20],
            ["video": path1 ?? "", "duration": 25],
            ["video": path2 ?? "", "duration": 27]]
    }
    
    /// Action camera recording
    /// - Parameter sender: Button object
    @IBAction func btnRecordingClick(_ sender: UIButton) {
        vc.toggleMovieRecording(vc.recordButton)
    }
    
    /// Liner progress bar and timer
    func setLinearBarNTimer() {

        var counterDecrease = 30.0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] (timer) in
            counterDecrease -= 1.0
            
            let formatedTime = Utility.sharedUtility.secondsToHoursMinutesSeconds(seconds: Int(counterDecrease))
            let hours = "\(formatedTime.0)" == "0" ? "00" : "\(formatedTime.0)"
            let minutes = "\(formatedTime.1)" == "0" ? "00" : "\(formatedTime.1)"
            let seconds = "\(formatedTime.2)" == "0" ? "00" : "\(formatedTime.2)"
            
            let uH = hours.count == 2 ? hours : "0\(hours)"
            let uM = minutes.count == 2 ? minutes : "0\(minutes)"
            let uS = seconds.count == 2 ? seconds : "0\(seconds)"
            self.lblTimer.text = uH + ":" + uM + ":" + uS
            
            self.counter += 1.0
            self.linearProgress.progressValue = CGFloat(100 / 30 * self.counter)
            
            
            if isText {
                displayTextAndSetFFMPEGCommad()
            } else if isVideo {
                displayVideoAndSetFFMPEGCommad()
            } else {
                displayImageAndSetFFMPEGCommad()
            }
            
            // On which time by default camera will stop
//            if self.counter == 15.0 {
//                self.btnRecord.isEnabled = false
//                vc.toggleMovieRecording(vc.recordButton)
//            }

            
            if counterDecrease == 0.0 {
                self.btnRecord.isEnabled = false
                vc.toggleMovieRecording(vc.recordButton)
            }

            // Min. duration on which stop button will show
            if self.counter == 5.0 {
                self.btnRecord.isHidden = false
            }
        }
    }
    
    /// Play video in player layer
    /// - Parameter path: Video path
    func setupVideoPlayer(path: String) {
        DispatchQueue.main.async {
            
            self.playerVideo = AVPlayer(url: URL(fileURLWithPath: path))
            self.playerLayer = AVPlayerLayer(player: self.playerVideo)
            self.playerLayer?.videoGravity = .resizeAspectFill
            self.playerLayer?.frame = self.viewVideoPlayer.bounds
            self.viewVideoPlayer.layer.addSublayer(self.playerLayer!)
            
        }
    }
    
    /// Play video
    /// - Parameter path: Video path
    func playVideo(path: String) {
        DispatchQueue.main.async {
            // Play mp4
            self.playerVideo?.pause()
            self.playerLayer?.player?.isMuted = true
            self.playerVideo?.play()
        }
    }

    // Video related ffmpeg operations and command is generated sequentially
    func displayVideoAndSetFFMPEGCommad() {
        for (indexx, dict) in self.dictDuration.enumerated() {
            if (Int(dict["duration"]! as? Int ?? 0) == Int(self.counter)) {
                
                arrInputVideos.append(String(format: "-i %@", (dict["video"] as? String) ?? ""))
                
                setupVideoPlayer(path: (dict["video"] as? String) ?? "")
                playVideo(path: (dict["video"] as? String) ?? "")
                
                if indexx == 0 && self.dictDuration.count > 1 {
                    // Set scaling on overlayed image
                    self.arrCommand.append("[\(indexx + 1)]scale=200:200[v\(indexx + 1)]")
                    // Set duration on index 0
                    self.arrCommand.append(String(format: "[0][v\(indexx + 1)]overlay=x=main_w/2-overlay_w/2:y=60:enable='between(t,0,%d)'[v1]", (self.dictDuration[indexx + 1]["duration"] as! Int)))
                } else if indexx == 0 && self.dictDuration.count == 1 {
                    // Set scaling on overlayed image
                    self.arrCommand.append("[\(indexx + 1)]scale=200:200[v\(indexx + 1)]")
                    // Set duration on index 0
                    self.arrCommand.append(String(format: "[0][v\(indexx + 1)]overlay=x=main_w/2-overlay_w/2:y=60:enable='between(t,0,%d)'[v1]", (self.dictDuration[indexx]["duration"] as! Int)))
                } else if (self.dictDuration.count - 1) != indexx {
                    // Set scaling on overlayed image
                    self.arrCommand.append("[\(indexx + 1)]scale=200:200[v\(indexx + 1)]")
                    // Set duration on index next to 0 and previous last
                    self.arrCommand.append(String(format: "[v1][v\(indexx + 1)]overlay=x=main_w/2-overlay_w/2:y=60:enable='between(t,%d,%d)'[v1]", (self.dictDuration[indexx]["duration"] as! Int), (self.dictDuration[indexx + 1]["duration"] as! Int)))
                } else {
                    // Set duration on index next to 0 and previous last
                    self.arrCommand.append("[\(indexx + 1)]scale=200:200[v\(indexx + 1)]")
                    // Set duration on last
                    self.arrCommand.append(String(format: "[v1][v\(indexx + 1)]overlay=x=main_w/2-overlay_w/2:y=60:enable='gt(t,%d)'[v1]", (self.dictDuration[indexx]["duration"] as! Int)))
                }
            }
        }
    }

    /// ffmpeg video related operation will be performed
    /// - Parameter cameraVideoPath: Camera recorded video apth
    func executeVideoFFMPEG(cameraVideoPath: String) {
        
        // Current date and time
        let currentDateTime = Date().toString(format: .custom("hh_mm_ss"))
        
        // Output file path
        let distinationPath = FileHelper.getDocumentDirectory()?.appending("\(currentDateTime ?? "").mp4") ?? ""
        
        var strCompleteCommand = ""
        
        strCompleteCommand = String(format: "-hide_banner -i %@ %@ -filter_complex \"%@\" -map \"[v1]\" -map 0:a -shortest -c:v mpeg4 -y %@", cameraVideoPath, self.arrInputVideos.joined(separator: " "), self.arrCommand.joined(separator: ";"), distinationPath)
        
        print(strCompleteCommand)
        let result1 = MobileFFmpeg.execute(strCompleteCommand)
        
        if result1 != RETURN_CODE_SUCCESS {
            self.showAlertError()
        } else if result1 == RETURN_CODE_CANCEL {
            self.showAlertCancel()
        } else {
            
            self.showAlertSuccess {
                self.navigationController?.popViewController(animated: true)
            }

        }
    }
    
    // Image related ffmpeg operations and command is generated sequentially
    func displayImageAndSetFFMPEGCommad() {
        
        for (indexx, dict) in self.dictDuration.enumerated() {
            if (Int(dict["duration"]! as? Int ?? 0) == Int(self.counter)) {
                
                arrInputImages.append(String(format: "-i %@", (dict["image"] as? String) ?? ""))
                
                self.imgView.image = UIImage(contentsOfFile: (dict["image"] as? String ?? ""))
                
                if indexx == 0 && self.dictDuration.count > 1 {
                    // Set scaling on overlayed image
                    self.arrCommand.append("[\(indexx + 1)]scale=150:150[v\(indexx + 1)]")
                    // Set duration on index 0
                    self.arrCommand.append(String(format: "[0][v\(indexx + 1)]overlay=x=main_w/2-overlay_w/2:y=60:enable='between(t,0,%d)'[v1]", (self.dictDuration[indexx + 1]["duration"] as! Int)))
                } else if indexx == 0 && self.dictDuration.count == 1 {
                    // Set scaling on overlayed image
                    self.arrCommand.append("[\(indexx + 1)]scale=150:150[v\(indexx + 1)]")
                    // Set duration on index 0
                    self.arrCommand.append(String(format: "[0][v\(indexx + 1)]overlay=x=main_w/2-overlay_w/2:y=60:enable='between(t,0,%d)'[v1]", (self.dictDuration[indexx]["duration"] as! Int)))
                } else if (self.dictDuration.count - 1) != indexx {
                    // Set scaling on overlayed image
                    self.arrCommand.append("[\(indexx + 1)]scale=150:150[v\(indexx + 1)]")
                    // Set duration on index next to 0 and previous last
                    self.arrCommand.append(String(format: "[v1][v\(indexx + 1)]overlay=x=main_w/2-overlay_w/2:y=60:enable='between(t,%d,%d)'[v1]", (self.dictDuration[indexx]["duration"] as! Int), (self.dictDuration[indexx + 1]["duration"] as! Int)))
                } else {
                    // Set duration on index next to 0 and previous last
                    self.arrCommand.append("[\(indexx + 1)]scale=150:150[v\(indexx + 1)]")
                    // Set duration on last
                    self.arrCommand.append(String(format: "[v1][v\(indexx + 1)]overlay=x=main_w/2-overlay_w/2:y=60:enable='gt(t,%d)'[v1]", (self.dictDuration[indexx]["duration"] as! Int)))
                }
            }
        }
    }
    
    /// ffmpeg image related operation will be performed
    /// - Parameter cameraVideoPath: Camera recorded video apth
    func executeImageFFMPEG(cameraVideoPath: String) {
        
        // Current date and time
        let currentDateTime = Date().toString(format: .custom("hh_mm_ss"))
        
        // Output file path
        let distinationPath = FileHelper.getDocumentDirectory()?.appending("\(currentDateTime ?? "").mp4") ?? ""
        
        var strCompleteCommand = ""
        
        strCompleteCommand = String(format: "-hide_banner -i %@ %@ -filter_complex \"%@\" -map \"[v1]\" -map 0:a -c:v mpeg4 -y %@", cameraVideoPath, self.arrInputImages.joined(separator: " "), self.arrCommand.joined(separator: ";"), distinationPath)
        
        print(strCompleteCommand)
        let result1 = MobileFFmpeg.execute(strCompleteCommand)
        
        if result1 != RETURN_CODE_SUCCESS {
            self.showAlertError()
        } else if result1 == RETURN_CODE_CANCEL {
            self.showAlertCancel()
        } else {
            
            self.showAlertSuccess {
                self.navigationController?.popViewController(animated: true)
            }

        }
    }
    
    // Text related operations and command is generated sequentially
    func displayTextAndSetFFMPEGCommad() {
        for (indexx, dict) in self.dictDuration.enumerated() {
            if (Int(dict["duration"]! as? Int ?? 0) == Int(self.counter)) {
                self.lblText.isHidden = false
                self.lblText.text = (dict["text"] as? String) ?? ""
                
                guard let font = MAIN_BUNDLE.path(forResource: "BebasNeueBold", ofType: "ttf") else {
                    debugPrint("Font not found")
                    return
                }
                
                if indexx == 0 && self.dictDuration.count > 1 {
                    // Set duration on index 0
                    self.arrCommand.append(String(format: "drawtext=fontfile=%@:text=%@:fontcolor=white:fontsize=100:x=(w-text_w)/2:y=(h-text_h)/2:enable='between(t,0, %d)'", font, ((dict["text"] as? String) ?? ""), (self.dictDuration[indexx + 1]["duration"] as! Int)))
                } else if indexx == 0 && self.dictDuration.count == 1 {
                    // Set duration on index 0
                    self.arrCommand.append(String(format: "drawtext=fontfile=%@:text=%@:fontcolor=white:fontsize=100:x=(w-text_w)/2:y=(h-text_h)/2:enable='between(t,0, %d)'", font, ((dict["text"] as? String) ?? ""), (self.dictDuration[indexx]["duration"] as! Int)))
                } else if (self.dictDuration.count - 1) != indexx {
                    // Set duration on index next to 0 and previous last
                    self.arrCommand.append(String(format: "drawtext=fontfile=%@:text=%@:fontcolor=white:fontsize=100:x=(w-text_w)/2:y=(h-text_h)/2:enable='between(t,%d, %d)'", font, ((dict["text"] as? String) ?? ""), (self.dictDuration[indexx]["duration"] as! Int), (self.dictDuration[indexx + 1]["duration"] as! Int)))
                } else {
                    // Set duration on last
                    self.arrCommand.append(String(format: "drawtext=fontfile=%@:text=%@:fontcolor=white:fontsize=100:x=(w-text_w)/2:y=(h-text_h)/2:enable='gte(t,%d)'", font, ((dict["text"] as? String) ?? ""), (self.dictDuration[indexx]["duration"] as! Int)))
                }
            } else if (Int(self.counter) > Int(dict["duration"]! as? Int ?? 0)) {                self.lblText.isHidden = true
                self.lblText.text = ""
            }
            
        }
    }
    
    /// ffmpeg text related operation will be performed
    /// - Parameter cameraVideoPath: Camera recorded video apth
    func executeTextFFMPEG(cameraVideoPath: String) {
        
        // Current date and time
        let currentDateTime = Date().toString(format: .custom("hh_mm_ss"))
        
        // Output file path
        let distinationPath = FileHelper.getDocumentDirectory()?.appending("\(currentDateTime ?? "").mp4") ?? ""
        
        var strCompleteCommand = ""
        
        strCompleteCommand = String(format: "-hide_banner -i %@ -vf \"%@\" -c:v mpeg4 -y %@", cameraVideoPath, self.arrCommand.joined(separator: ","), distinationPath)
        
        print(strCompleteCommand)
        let result1 = MobileFFmpeg.execute(strCompleteCommand)
        
        if result1 != RETURN_CODE_SUCCESS {
            self.showAlertError()

        } else if result1 == RETURN_CODE_CANCEL {
            self.showAlertCancel()
        } else {
            
            UIAlertController.showAlertWithOkButton(controller: self, message: "Saved.") { _, _ in
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func logCallback(_ executionId: Int, _ level: Int32, _ message: String!) {
        print(message ?? "")
    }
    
    func statisticsCallback(_ statistics: Statistics!) {
        if statistics == nil {
            return
        }
        
        // Will get video duration , like how much processing is completed
        let timeInMilliseconds = statistics?.getTime() ?? 0
        if timeInMilliseconds > 0 {
            
            print((Int(timeInMilliseconds) / 1000 * (100 / Int(self.durationVideo ?? 0.0))))
        }
    }
}
