// ffmpegDemo
//
// Created by ffmpegDemo on 14/03/22.
// Copyright © 2021 ffmpegDemo. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import mobileffmpeg
import DateHelper
import LinearProgressBar

/// This controller will be used for recording Horizontal & Vertical form and respective ffmpeg operation
class RecordingHVVC: BaseViewController, StoryboardSceneBased, LogDelegate, StatisticsDelegate {
    
    static let sceneStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    // Camera view
    @IBOutlet weak var viewMain: UIView!
    
    // Record button
    @IBOutlet weak var btnRecord: UIButton!
    
    // Stack view for H & V
    @IBOutlet weak var stackview: UIStackView!
    
    // Is horizonal and vertical bool if horizonal thne true else false
    var isHorizontalStack: Bool?
    
    // Audio file duration
    var audioDurationSeconds: Double?
    
    // Video player
    @IBOutlet weak var viewVideo: UIView!
    
    // Video player object
    var playerVideo: AVPlayer?
    
    // Video player layer object
    var playerLayer: AVPlayerLayer?
    
    // Variables from previous viewcontroller
    var isCameraAudioUse: Bool!
    
    // Camera screen object
    var vc: CameraVC!
    
    // Linear progress bar
    @IBOutlet weak var linearProgress: LinearProgressBar!
    
    @IBOutlet weak var lblTimer: UILabel!
    @IBOutlet weak var lblProgress: UILabel!
    
    var counter = 0.0
    var timer: Timer!
    
    var currentDateTime: String!
    
    // Video duration
    var durationVideo: Double?
    
    var distinationCamera = ""
    
    // MARK: View Controller Life Cycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isHorizontalStack! {
            stackview.axis = .vertical
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.vc = CameraVC(nibName: "CameraVC", bundle: nil)
            self?.vc.isCameraAudioUse = self!.isCameraAudioUse
            self?.vc.isHVView = true
            // Set height or width
            self?.vc.view.frame = CGRect(x: 0, y: 0, width: self!.viewMain.frame.size.width, height: self!.viewMain.frame.size.height)
            self?.viewMain.addSubview(self!.vc.view)
            self?.view.bringSubviewToFront(self!.viewMain)
            
            self?.vc.playSoundBlock = { [weak self] () in
                
                DispatchQueue.main.async {
                    // Play mp4
                    self!.playerVideo?.play()
                    
                    self?.btnRecord.isHidden = true
                    self?.btnRecord.isSelected = true
                    self?.setLinearBarNTimer()
                }
            }
            
            self?.vc.executeFFMPEGBlock = { [weak self] (cameraVideoPath) in
                
                self?.durationVideo = AVAsset(url: URL(fileURLWithPath: cameraVideoPath)).duration.seconds
                
                // Pause video
                self?.playerVideo?.pause()
                
                // Invalidate timer
                self?.timer.invalidate()
                self?.timer = nil
                
                self?.executeFFMPEG(cameraVideoPath: cameraVideoPath, fileName: "potrait", exten: "mp4")
                
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
        
        // Get file lenght
        audioDurationSeconds = Utility.sharedUtility.getFileLenght(fileName: "potrait", exten: "mp4")
        print(audioDurationSeconds ?? 0.0)
        
        // Play local video
        self.playVideo(fileName: "potrait", exten: "mp4")
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
    }
    
    /// Action camera recording
    /// - Parameter sender: Button object
    @IBAction func btnRecordingClick(_ sender: UIButton) {
        vc.toggleMovieRecording(vc.recordButton)
    }
    
    /// Play video
    /// - Parameters:
    ///   - fileName: Video file name
    ///   - exten: Video file extension
    func playVideo(fileName: String, exten: String) {
        DispatchQueue.main.async {
            guard let path = MAIN_BUNDLE.path(forResource: fileName, ofType:exten) else {
                debugPrint("video not found")
                return
            }
            
            self.playerVideo = AVPlayer(url: URL(fileURLWithPath: path))
            self.playerLayer = AVPlayerLayer(player: self.playerVideo)
            self.playerLayer?.videoGravity = .resizeAspect
            self.playerLayer?.frame = self.viewVideo.frame
            self.viewVideo.layer.addSublayer(self.playerLayer!)
            
            try! AVAudioSession.sharedInstance().setCategory(.playback)

        }
    }
    
    /// Linear progress bar and timer
    func setLinearBarNTimer() {
        var counterDecrease = 125.0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
            counterDecrease -= 1.0
            
            //            if self.counter > 0 {
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
            
            // On which time by default camera will stop
            //                if self.counter == 15.0 {
            //                    self.btnRecord.isEnabled = false
            //                    self.vc.toggleMovieRecording(self.vc.recordButton)
            //                }
            
            if counterDecrease == 0.0 {
                self.btnRecord.isEnabled = false
                self.vc.toggleMovieRecording(self.vc.recordButton)
            }
            
            // Min. duration on which stop button will show
            if self.counter == 5.0 {
                self.btnRecord.isHidden = false
            }
            
            //            } else {
            //                timer.invalidate()
            //            }
        }
    }
    
    /// Function to set FPS 30 for picked video
    /// - Parameters:
    ///   - fileName: Picked video file name
    ///   - exten: Picked video
    ///   - resolution: SCreen resolution
    ///   - completion: completion block after successully command done
    private func setFPSForPickedVideo(fileName: String, exten: String, resolution: CGSize, completion: ((String) -> Void)) {
        // Picked video path
        guard let pickedVideoPath = MAIN_BUNDLE.path(forResource: fileName, ofType:exten) else {
            debugPrint("video.m4v not found")
            return
        }
        
        // Current date and time
        currentDateTime = Date().toString(format: .custom("hh_mm_ss"))
        
        // Output file path
        let distinationTrim = FileHelper.getDocumentDirectory()?.appending("\(currentDateTime ?? "").mp4")
        
        // Trim to left video same as camera recorded video
        let trimVideoPath: String = distinationTrim ?? ""
        
        // ffmpeg command to set fps of picked video
        let trimVideo = "-hide_banner -i '\(pickedVideoPath)' -filter:v fps=30 -ss 00:00 -to \(durationVideo ?? 0) -preset fast -c:v mpeg4 -y '\(trimVideoPath)'"
        print(trimVideo)
        
        let resultTrimVideo = MobileFFmpeg.execute(trimVideo)
        
        if resultTrimVideo == RETURN_CODE_SUCCESS {
            completion(trimVideoPath)
        } else if resultTrimVideo == RETURN_CODE_CANCEL {
            self.showAlertCancel()
        } else {
            self.showAlertError()
        }
    }
    
    /// Function to set FPS 30 for camera recorded video
    /// - Parameters:
    ///   - cameraVideoPath: Picked video file name
    ///   - resolution: SCreen resolution
    ///   - completion: completion block after successully command done
    private func setFPAForCameraVideo(cameraVideoPath: String, resolution: CGSize, completion: (() -> Void)) {
        
        // Current date and time
        currentDateTime = Date().toString(format: .custom("hh_mm_ss"))
        
        // Output file path
        distinationCamera = FileHelper.getDocumentDirectory()?.appending("\(currentDateTime ?? "").mp4") ?? ""
        
        // ffmpeg command to set fps of camera recorded video
        let strChangeFPS = "-hide_banner -i '\(cameraVideoPath)' -filter:v fps=30 -preset fast -c:v mpeg4 -y '\(distinationCamera)'"
        print(strChangeFPS)
        
        let result = MobileFFmpeg.execute(strChangeFPS)
        
        if result == RETURN_CODE_SUCCESS {
            completion()
        } else if result == RETURN_CODE_CANCEL {
            self.showAlertCancel()
        } else {
            self.showAlertError()
        }
    }
    
    /// Function to scale picked video
    /// - Parameters:
    ///   - trimVideoPath: Picked video path
    ///   - scalledVideo: Scalled video destination path
    ///   - resolution: SCreen resolution
    ///   - completion: completion block after successully command done
    private func scallingVideo(trimVideoPath: String, scalledVideo: String, resolution: CGSize, completion: (() -> Void)) {
      
        var strCommandScalling = ""
        if !isHorizontalStack! {
            strCommandScalling = "-hide_banner -i '\(trimVideoPath)' -vf scale=\(abs(resolution.width )):-1:force_original_aspect_ratio=1 -preset fast -y '\(scalledVideo)'"
        } else {
            strCommandScalling = "-hide_banner -i '\(trimVideoPath)' -vf scale=-1:\(abs(resolution.height )):force_original_aspect_ratio=1 -preset fast -c:v mpeg4 -y '\(scalledVideo)'"
        }
            
        print(strCommandScalling)
        
        let result = MobileFFmpeg.execute(strCommandScalling)
        if result == RETURN_CODE_SUCCESS {
            completion()
        } else if result == RETURN_CODE_CANCEL {
            self.showAlertCancel()
        } else {
            self.showAlertError()
        }
    }
    
    /// Function to merge 2 video [Picked video and Camera video]
    /// - Parameters:
    ///   - scalledVideo: Scalled video path which is picked by user
    ///   - trimVideoPath: Picked video is trimmed duration same as camera duration
    ///   - completion: completion block after successully command done
    private func merge2Video(scalledVideo: String, trimVideoPath: String, completion: ((String) -> Void)) {
        
        // Current date and time
        currentDateTime = Date().toString(format: .custom("hh_mm_ss"))
        let distinationMergedPath = FileHelper.getDocumentDirectory()?.appending("\(currentDateTime ?? "").mp4")
        
        var strCompleteCommand = ""
        var strStack = ""
        if !isHorizontalStack! {
            strStack = "vstack"
        } else {
            strStack = "hstack"
        }
        strCompleteCommand = "-hide_banner -i '\(scalledVideo)' -i '\(distinationCamera)' -filter_complex \(strStack)=inputs=2:shortest=1 -shortest -preset fast -c:v mpeg4 -y \(distinationMergedPath!)"
        print(strCompleteCommand)
        
        let result = MobileFFmpeg.execute(strCompleteCommand)
        
        if result == RETURN_CODE_SUCCESS {
            completion(distinationMergedPath ?? "")
        } else if result == RETURN_CODE_CANCEL {
            self.showAlertCancel()
        } else {
            self.showAlertError()
        }
    }
    
    /// FFMpeg operation will be performed
    /// - Parameters:
    ///   - cameraVideoPath: Camera recordrd video apth
    ///   - fileName: Video file name
    ///   - exten: Video file extension
    func executeFFMPEG(cameraVideoPath: String, fileName: String, exten: String) {

        let resolution = getVideoResolution(url: cameraVideoPath)

        setFPSForPickedVideo(fileName: fileName, exten: exten, resolution: resolution!) {trimVideoPath in
            setFPAForCameraVideo(cameraVideoPath: cameraVideoPath, resolution: resolution!) {
                
                // Current date and time
                currentDateTime = Date().toString(format: .custom("hh_mm_ss"))
                
                // Output file path
                let distinationScalled = FileHelper.getDocumentDirectory()?.appending("\(currentDateTime ?? "").mp4")
                
                // Scalling to left video same as camera recorded videos
                let scalledVideo: String = distinationScalled ?? ""
                
                scallingVideo(trimVideoPath: trimVideoPath, scalledVideo: scalledVideo, resolution: resolution!) {
                    
                    if isHorizontalStack! {
                        merge2Video(scalledVideo: scalledVideo, trimVideoPath: trimVideoPath, completion: {_ in
                            self.showAlertSuccess {
                                do {
                                    if FileManager.default.fileExists(atPath: scalledVideo) {
                                        try FileManager.default.removeItem(atPath: scalledVideo)
                                    }
                                    if FileManager.default.fileExists(atPath: trimVideoPath) {
                                        try FileManager.default.removeItem(atPath: trimVideoPath)
                                    }
                                    if FileManager.default.fileExists(atPath: self.distinationCamera) {
                                        try FileManager.default.removeItem(atPath: self.distinationCamera)
                                    }
                                } catch {
                                    print(error)
                                }
                                self.navigationController?.popViewController(animated: true)
                            }
                        })
                    } else {
                        merge2Video(scalledVideo: scalledVideo, trimVideoPath: trimVideoPath) { merge2Video in
                            
                            // Current date and time
                            currentDateTime = Date().toString(format: .custom("hh_mm_ss"))
                            
                            // Output file path
                            let distinationScalled = FileHelper.getDocumentDirectory()?.appending("\(currentDateTime ?? "").mp4")
                            
                            // Scalling to left video same as camera recorded videos
                            let scalledVideoAfterMerge: String = distinationScalled ?? ""
                            
                            scallingVideo(trimVideoPath: merge2Video, scalledVideo: scalledVideoAfterMerge, resolution: CGSize(width: 520, height: 0)) {
                                self.showAlertSuccess {
                                    do {
                                        if FileManager.default.fileExists(atPath: scalledVideo) {
                                            try FileManager.default.removeItem(atPath: scalledVideo)
                                        }
                                        if FileManager.default.fileExists(atPath: merge2Video) {
                                            try FileManager.default.removeItem(atPath: merge2Video)
                                        }
                                        if FileManager.default.fileExists(atPath: trimVideoPath) {
                                            try FileManager.default.removeItem(atPath: trimVideoPath)
                                        }
                                        if FileManager.default.fileExists(atPath: self.distinationCamera) {
                                            try FileManager.default.removeItem(atPath: self.distinationCamera)
                                        }

                                    } catch {
                                        print(error)
                                    }
                                    self.navigationController?.popViewController(animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getVideoResolution(url: String) -> CGSize? {
        guard let track = AVURLAsset(url: URL(fileURLWithPath: url)).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return size
    }
    
    func logCallback(_ executionId: Int, _ level: Int32, _ message: String!) {
        print("===================")
        print(message ?? "")
    }
    
    func statisticsCallback(_ statistics: Statistics!) {
        if statistics == nil {
            return
        }
        
        //        // Will get video duration , like how much processing is completed
        //        let timeInMilliseconds = statistics?.getTime() ?? 0
        //        if timeInMilliseconds > 0 {
        //
        //            print((Int(timeInMilliseconds) / 1000 * (100 / Int(self.durationVideo ?? 0.0))))
        //        }
    }
    
}

