// ffmpegDemo
//
// Created by ffmpegDemo on 14/03/22.
// Copyright © 2021 ffmpegDemo. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import Photos
import KDCircularProgress
import mobileffmpeg
import DateHelper

/// This controller used for recording video with background sound and both will merge into single video
class RecordingWithSound: BaseViewController, StoryboardSceneBased, LogDelegate, StatisticsDelegate {
    
    static let sceneStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    // Progress bar
    @IBOutlet weak var progressBar: KDCircularProgress!
    
    // Camera viwe
    @IBOutlet weak var viewMain: UIView!
    
    // Record button
    @IBOutlet weak var btnRecord: UIButton!
    
    // Audio player
    var player: AVAudioPlayer?
    
    // Audio file duration
    var audioDurationSeconds: Double!
    
    // Counte for timer
    var counter = 0.0
    
    // Timer object
    var timer: Timer!
    
    // Variables from previous viewcontroller
    var isCameraAudioUse: Bool!
    
    // Camera VC object
    var vc: CameraVC!
    
    // Video duration
    var durationVideo: Double?
    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async { [weak self] in
            self?.vc = CameraVC(nibName: "CameraVC", bundle: nil)
            self?.vc.isCameraAudioUse = self!.isCameraAudioUse
            
            // Set height or width
            self?.vc.view.frame = CGRect(x: 0, y: 0, width: MAIN_SCREEN.bounds.width, height: MAIN_SCREEN.bounds.height)
            self?.viewMain.addSubview(self!.vc.view)
            
            // When recording will start then this block will be called
            self?.vc.playSoundBlock = {
                
                self?.playSoundOnRecording()
            }
            
            // When recording will stop then this block will be called
            self?.vc.executeFFMPEGBlock = { [weak self] (cameraVideoPath) in
                guard let player = self?.player else { return }
                player.stop()
                
                if let _ = self?.timer {
                    // Invalidate timer
                    self?.timer.invalidate()
                    self?.timer = nil
                }
                
                self?.durationVideo = AVAsset(url: URL(fileURLWithPath: cameraVideoPath)).duration.seconds
                
                // Execute ffmpg command
                self?.executeFFMPEG(cameraVideoPath: cameraVideoPath, fileName: "rabta_mp3", exten: "mp3")
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
        audioDurationSeconds = Utility.sharedUtility.getFileLenght(fileName: "rabta_mp3", exten: "mp3")
        print(audioDurationSeconds ?? 0.0)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
    }
    
    /// Action camera recording
    /// - Parameter sender: Button object
    @IBAction func btnRecordingClick(_ sender: UIButton) {
        vc.toggleMovieRecording(vc.recordButton)
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

extension RecordingWithSound {
    
    /// FFMpeg operation will perform
    /// - Parameters:
    ///   - cameraVideoPath: Camera recorded video path
    ///   - fileName: Audio file name
    ///   - exten: Audio file extension
    func executeFFMPEG(cameraVideoPath: String, fileName: String, exten: String) {
        // Execute ffmeg command
        
        // Get local audio file
        let pathAudio = MAIN_BUNDLE.path(forResource: fileName, ofType: exten)
        
        // Get current date and time
        let currentDateTime = Date().toString(format: .custom("hh_mm_ss"))
        
        // Set destination path
        let distinationPath = FileHelper.getDocumentDirectory()?.appending("\(currentDateTime ?? "").mp4")
        
        let strCompleteCommand = String(format: "-hide_banner -i '%@' -i '%@' -shortest -c:v mpeg4 -y '%@'", pathAudio!, cameraVideoPath, distinationPath!)
        print(strCompleteCommand)
        
        // Result of ffmpeg command
        let result = MobileFFmpeg.execute(strCompleteCommand)
        if result != RETURN_CODE_SUCCESS {
            self.showAlertError()
        } else if result == RETURN_CODE_CANCEL {
            self.showAlertCancel()
        } else {
            self.showAlertSuccess {
                self.navigationController?.popViewController(animated: true)
            }
            
        }
    }
    
    /// Play audio sound
    func playSoundOnRecording() {
        DispatchQueue.main.async {
            self.btnRecord.isHidden = true
            self.btnRecord.isSelected = true
            
            
            // Play mp3 sound
            self.playSound(fileName: "rabta_mp3", exten: "mp3")
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] (timer) in
                self.counter += 1.0
                
                // On which time by default camera will stop
                //                if self.counter == 15.0 {
                //                    self.btnRecord.isEnabled = false
                //                    vc.toggleMovieRecording(vc.recordButton)
                //                }
                
                // Min. duration on which stop button will show
                if self.counter == 5.0 {
                    self.btnRecord.isHidden = false
                }
            }
        }
    }
    
    /// Progress will display based on sound lenght
    /// - Parameter length: Audio file length
    func progressBarTracking(length: Double) {
        DispatchQueue.main.async {
            self.progressBar.startAngle = -90
            self.progressBar.progressThickness = 0.1
            self.progressBar.trackThickness = 0.1
            self.progressBar.clockwise = true
            self.progressBar.roundedCorners = true
            self.progressBar.trackColor = .white
            self.progressBar.progressColors = [.red]
            
            self.progressBar.animate(fromAngle: 0, toAngle: 360, duration: length) { completed in
                if completed {
                    print("animation stopped, completed")
                } else {
                    print("animation stopped, was interrupted")
                }
            }
            
        }
    }
    
    
    func playSound(fileName: String, exten: String) {
        // Start tracking of audio which will run during video recording
        progressBarTracking(length: audioDurationSeconds ?? 0.0)
        
        guard let url = MAIN_BUNDLE.url(forResource: fileName, withExtension: exten) else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
